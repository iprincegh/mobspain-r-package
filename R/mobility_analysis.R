#' Get mobility matrix
#'
#' @param dates Date range (character vector of length 1 or 2)
#' @param level Spatial level ("dist", "muni", "lua")
#' @param time_window Hour range (e.g. c(7,9))
#' @param aggregate_by Aggregation level: "none", "daily", "hourly" (default: "none")
#' @return Data frame with mobility data
#' @export
get_mobility_matrix <- function(dates, level = "dist", time_window = NULL, aggregate_by = "none") {
  # Enhanced input validation
  dates <- validate_dates(dates)
  level <- validate_level(level)
  time_window <- validate_time_window(time_window)
  
  if(!aggregate_by %in% c("none", "daily", "hourly")) {
    stop("aggregate_by must be one of: 'none', 'daily', 'hourly'", call. = FALSE)
  }
  # Try to connect to DuckDB
  con <- tryCatch({
    connect_mobility_db()
  }, error = function(e) {
    message("Database connection failed: ", e$message)
    return(NULL)
  })

  if(is.null(con)) {
    message("Using direct CSV access")
    result <- spanishoddata::spod_get(
      type = "od",
      zones = level,
      dates = dates
    )
    
    # Ensure we return a proper data.frame
    return(
      result %>%
        dplyr::mutate(
          date = as.Date(date),
          weekday = lubridate::wday(date, label = TRUE)
        ) %>%
        as.data.frame()
    )
  }

  # Proceed with DuckDB query
  table <- paste0("v2_od_", level)

  query <- glue::glue_sql(
    "SELECT date, hour, id_origin, id_destination, n_trips
     FROM {`table`}
     WHERE date BETWEEN {start} AND {end}",
    start = dates[1],
    end = dates[2],
    .con = con
  )

  if(!is.null(time_window)) {
    query <- glue::glue_sql(
      "{query} AND hour BETWEEN {min} AND {max}",
      min = time_window[1],
      max = time_window[2],
      .con = con
    )
  }

  # Try to execute the query, fall back to CSV if it fails
  result <- tryCatch({
    DBI::dbGetQuery(con, query)
  }, error = function(e) {
    DBI::dbDisconnect(con)
    message("Database query failed, falling back to CSV access: ", e$message)
    
    # Fallback to CSV access
    csv_result <- spanishoddata::spod_get(
      type = "od",
      zones = level,
      dates = dates
    )
    
    return(csv_result %>%
      dplyr::mutate(
        date = as.Date(date),
        weekday = lubridate::wday(date, label = TRUE)
      ) %>%
      as.data.frame())
  })
  
  # If we got here with a connection still open, close it and process result
  if(DBI::dbIsValid(con)) {
    DBI::dbDisconnect(con)
  }
  
  # If result is already processed (from error handler), return it
  if("weekday" %in% names(result)) {
    return(result)
  }

  # Ensure we return a data.frame, not a lazy query
  result %>%
    dplyr::mutate(
      date = as.Date(date),
      weekday = lubridate::wday(date, label = TRUE)
    ) %>%
    dplyr::collect() %>%  # Force evaluation if it's a lazy query
    as.data.frame()       # Ensure it's a proper data.frame
}

#' Calculate self-containment index
#'
#' @param od_data Mobility matrix
#' @return Data frame with containment metrics
#' @export
calculate_containment <- function(od_data) {
  od_data %>%
    dplyr::group_by(id_origin) %>%
    dplyr::summarise(
      total_trips = sum(n_trips),
      internal_trips = sum(n_trips[id_origin == id_destination]),
      containment = internal_trips / total_trips,
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(containment))
}

#' Calculate mobility indicators
#'
#' @param od_data Mobility matrix
#' @param zones Optional spatial zones for additional metrics
#' @return Data frame with comprehensive mobility indicators
#' @export
calculate_mobility_indicators <- function(od_data, zones = NULL) {
  if(!"n_trips" %in% names(od_data)) {
    stop("Data must contain 'n_trips' column", call. = FALSE)
  }
  
  # Basic indicators
  indicators <- od_data %>%
    dplyr::group_by(id_origin) %>%
    dplyr::summarise(
      total_outflow = sum(n_trips),
      total_inflow = sum(od_data$n_trips[od_data$id_destination == id_origin[1]]),
      internal_trips = sum(n_trips[id_origin == id_destination]),
      external_trips = sum(n_trips[id_origin != id_destination]),
      n_destinations = dplyr::n_distinct(id_destination[n_trips > 0]),
      containment = internal_trips / total_outflow,
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      net_flow = total_inflow - total_outflow,
      connectivity_index = n_destinations / max(n_destinations, na.rm = TRUE)
    )
  
  # Add spatial metrics if zones provided
  if(!is.null(zones) && inherits(zones, "sf")) {
    zone_areas <- zones %>%
      sf::st_drop_geometry() %>%
      dplyr::select(id, area_km2)
    
    indicators <- indicators %>%
      dplyr::left_join(zone_areas, by = c("id_origin" = "id")) %>%
      dplyr::mutate(
        trip_density = total_outflow / area_km2,
        internal_density = internal_trips / area_km2
      )
  }
  
  return(indicators)
}

#' Detect anomalous mobility patterns
#'
#' @param od_data Mobility matrix with date column
#' @param method Detection method: "zscore", "iqr", "isolation_forest"
#' @param threshold Threshold for anomaly detection (default: 2 for zscore, 1.5 for iqr)
#' @return Data frame with anomaly flags
#' @export
detect_mobility_anomalies <- function(od_data, method = "zscore", threshold = NULL) {
  if(!"date" %in% names(od_data)) {
    stop("Data must contain 'date' column", call. = FALSE)
  }
  
  if(is.null(threshold)) {
    threshold <- ifelse(method == "zscore", 2, 1.5)
  }
  
  daily_totals <- od_data %>%
    dplyr::group_by(date) %>%
    dplyr::summarise(total_trips = sum(n_trips), .groups = "drop") %>%
    dplyr::arrange(date)
  
  if(method == "zscore") {
    daily_totals <- daily_totals %>%
      dplyr::mutate(
        z_score = abs(scale(total_trips)[,1]),
        is_anomaly = z_score > threshold
      )
  } else if(method == "iqr") {
    q1 <- quantile(daily_totals$total_trips, 0.25)
    q3 <- quantile(daily_totals$total_trips, 0.75)
    iqr <- q3 - q1
    
    daily_totals <- daily_totals %>%
      dplyr::mutate(
        is_anomaly = total_trips < (q1 - threshold * iqr) | 
                     total_trips > (q3 + threshold * iqr)
      )
  }
  
  return(daily_totals)
}

#' Calculate distance-decay parameters
#'
#' @param od_data Mobility matrix
#' @param zones Spatial zones with geometry
#' @param model Model type: "power" or "exponential"
#' @return List with model parameters and fit statistics
#' @export
calculate_distance_decay <- function(od_data, zones, model = "power") {
  if(!inherits(zones, "sf")) {
    stop("zones must be an sf object", call. = FALSE)
  }
  
  # Calculate distances between zone centroids
  centroids <- sf::st_centroid(zones)
  distances <- sf::st_distance(centroids)
  
  # Create distance matrix with zone IDs
  zone_ids <- zones$id
  dist_df <- expand.grid(
    id_origin = zone_ids,
    id_destination = zone_ids,
    stringsAsFactors = FALSE
  )
  
  # Add distances (convert to km)
  dist_df$distance_km <- as.numeric(distances) / 1000
  
  # Merge with mobility data
  model_data <- od_data %>%
    dplyr::group_by(id_origin, id_destination) %>%
    dplyr::summarise(total_trips = sum(n_trips), .groups = "drop") %>%
    dplyr::inner_join(dist_df, by = c("id_origin", "id_destination")) %>%
    dplyr::filter(distance_km > 0, total_trips > 0)  # Remove intra-zonal and zero trips
  
  # Fit distance decay model
  if(model == "power") {
    # Power model: trips = a * distance^(-b)
    fit <- lm(log(total_trips) ~ log(distance_km), data = model_data)
    params <- list(
      a = exp(coef(fit)[1]),
      b = -coef(fit)[2],
      r_squared = summary(fit)$r.squared,
      model = "power"
    )
  } else if(model == "exponential") {
    # Exponential model: trips = a * exp(-b * distance)
    fit <- lm(log(total_trips) ~ distance_km, data = model_data)
    params <- list(
      a = exp(coef(fit)[1]),
      b = -coef(fit)[2],
      r_squared = summary(fit)$r.squared,
      model = "exponential"
    )
  }
  
  return(list(
    parameters = params,
    data = model_data,
    fit = fit
  ))
}
