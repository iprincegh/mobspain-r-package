#' Get mobility matrix
#'
#' @param dates Date range (character vector of length 1 or 2). Default: last 7 days
#' @param level Spatial level ("dist", "muni", "lua")
#' @param time_window Hour range (e.g. c(7,9))
#' @param aggregate_by Aggregation level: "none", "daily", "hourly" (default: "none")
#' @return Data frame with mobility data
#' @export
get_mobility_matrix <- function(dates = NULL, level = "dist", time_window = NULL, aggregate_by = "none") {
  # Set default dates if not provided
  if(is.null(dates)) {
    # Use a valid date range from the dataset
    dates <- c("2023-01-01", "2023-01-07")
    message("Using default date range: ", dates[1], " to ", dates[2])
  }
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
    message("Database connection failed, falling back to CSV access: ", e$message)
    return(NULL)
  })

  if(is.null(con)) {
    message("Using direct CSV access (recommended for reliability)")
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
#' @param od_data Mobility matrix with columns: origin/id_origin, destination/id_destination, flow/n_trips
#' @return Data frame with containment metrics
#' @export
calculate_containment <- function(od_data) {
  # Standardize column names
  od_data <- standardize_od_columns(od_data)
  
  od_data %>%
    dplyr::group_by(.data$id_origin) %>%
    dplyr::summarise(
      total_trips = sum(.data$n_trips),
      internal_trips = sum(.data$n_trips[.data$id_origin == .data$id_destination]),
      containment = .data$internal_trips / .data$total_trips,
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(.data$containment))
}

#' Calculate mobility indicators
#'
#' @param od_data Mobility matrix with columns: origin/id_origin, destination/id_destination, flow/n_trips
#' @param zones Optional spatial zones for additional metrics
#' @return Data frame with comprehensive mobility indicators
#' @export
calculate_mobility_indicators <- function(od_data, zones = NULL) {
  # Standardize column names
  od_data <- standardize_od_columns(od_data)
  
  # Calculate inflow separately
  inflow_data <- od_data %>%
    dplyr::group_by(.data$id_destination) %>%
    dplyr::summarise(total_inflow = sum(.data$n_trips), .groups = "drop")
  
  # Basic indicators
  indicators <- od_data %>%
    dplyr::group_by(.data$id_origin) %>%
    dplyr::summarise(
      total_outflow = sum(.data$n_trips),
      internal_trips = sum(.data$n_trips[.data$id_origin == .data$id_destination]),
      external_trips = sum(.data$n_trips[.data$id_origin != .data$id_destination]),
      n_destinations = dplyr::n_distinct(.data$id_destination[.data$n_trips > 0]),
      containment = .data$internal_trips / .data$total_outflow,
      .groups = "drop"
    ) %>%
    dplyr::left_join(inflow_data, by = c("id_origin" = "id_destination")) %>%
    dplyr::mutate(
      total_inflow = ifelse(is.na(.data$total_inflow), 0, .data$total_inflow),
      net_flow = .data$total_inflow - .data$total_outflow,
      connectivity_index = .data$n_destinations / max(.data$n_destinations, na.rm = TRUE)
    )
  
  # Add spatial metrics if zones provided
  if(!is.null(zones) && inherits(zones, "sf")) {
    zone_areas <- zones %>%
      sf::st_drop_geometry() %>%
      dplyr::select(.data$id, .data$area_km2)
    
    indicators <- indicators %>%
      dplyr::left_join(zone_areas, by = c("id_origin" = "id")) %>%
      dplyr::mutate(
        trip_density = .data$total_outflow / .data$area_km2,
        internal_density = .data$internal_trips / .data$area_km2
      )
  }
  
  return(indicators)
}

#' Detect anomalous mobility patterns
#'
#' @param od_data Mobility matrix with date column
#' @param method Detection method: "zscore", "iqr", "isolation_forest"
#' @param threshold Threshold for anomaly detection (default: 2 for zscore, 1.5 for iqr)
#' @param by_weekday Separate analysis for weekdays vs weekends (default: TRUE)
#' @return Data frame with anomaly flags
#' @export
detect_mobility_anomalies <- function(od_data, method = "zscore", threshold = NULL, by_weekday = TRUE) {
  if(!"date" %in% names(od_data)) {
    stop("Data must contain 'date' column", call. = FALSE)
  }
  
  if(is.null(threshold)) {
    threshold <- ifelse(method == "zscore", 2, 1.5)
  }
  
  daily_totals <- od_data %>%
    dplyr::group_by(.data$date) %>%
    dplyr::summarise(total_trips = sum(.data$n_trips), .groups = "drop") %>%
    dplyr::arrange(.data$date) %>%
    dplyr::mutate(
      weekday = lubridate::wday(.data$date, label = TRUE),
      is_weekend = lubridate::wday(.data$date) %in% c(1, 7)  # Sunday = 1, Saturday = 7
    )
  
  if(by_weekday) {
    # Separate analysis for weekdays and weekends
    daily_totals <- daily_totals %>%
      dplyr::group_by(.data$is_weekend) %>%
      dplyr::mutate(
        group_mean = mean(.data$total_trips, na.rm = TRUE),
        group_sd = sd(.data$total_trips, na.rm = TRUE)
      ) %>%
      dplyr::ungroup()
  }
  
  if(method == "zscore") {
    if(by_weekday) {
      daily_totals <- daily_totals %>%
        dplyr::mutate(
          z_score = abs((.data$total_trips - .data$group_mean) / .data$group_sd),
          is_anomaly = .data$z_score > threshold
        )
    } else {
      daily_totals <- daily_totals %>%
        dplyr::mutate(
          z_score = abs(scale(.data$total_trips)[,1]),
          is_anomaly = .data$z_score > threshold
        )
    }
  } else if(method == "iqr") {
    if(by_weekday) {
      daily_totals <- daily_totals %>%
        dplyr::group_by(.data$is_weekend) %>%
        dplyr::mutate(
          q1 = quantile(.data$total_trips, 0.25),
          q3 = quantile(.data$total_trips, 0.75),
          iqr = .data$q3 - .data$q1,
          is_anomaly = .data$total_trips < (.data$q1 - threshold * .data$iqr) | 
                       .data$total_trips > (.data$q3 + threshold * .data$iqr)
        ) %>%
        dplyr::ungroup()
    } else {
      q1 <- quantile(daily_totals$total_trips, 0.25)
      q3 <- quantile(daily_totals$total_trips, 0.75)
      iqr <- q3 - q1
      
      daily_totals <- daily_totals %>%
        dplyr::mutate(
          is_anomaly = .data$total_trips < (q1 - threshold * iqr) | 
                       .data$total_trips > (q3 + threshold * iqr)
        )
    }
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
    dplyr::group_by(.data$id_origin, .data$id_destination) %>%
    dplyr::summarise(total_trips = sum(.data$n_trips), .groups = "drop") %>%
    dplyr::inner_join(dist_df, by = c("id_origin", "id_destination")) %>%
    dplyr::filter(.data$distance_km > 0, .data$total_trips > 0)  # Remove intra-zonal and zero trips
  
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
    model_summary = summary(fit),
    r_squared = summary(fit)$r.squared,
    decay_exponent = ifelse(model == "power", -coef(fit)[2], -coef(fit)[2]),
    parameters = params,
    data = model_data,
    fit = fit
  ))
}
