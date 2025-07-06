#' Get mobility matrix from Spanish MITMA data
#'
#' @param dates Date range (character vector of length 1 or 2). Default: last 7 days
#' @param level Spatial level: "dist" (districts), "muni" (municipalities), "lua" (large urban areas)
#' @param time_window Hour range for filtering (e.g. c(7,9) for 7-9 AM)
#' @param aggregate_by Aggregation level: "none", "daily", "hourly" (default: "none")
#' @param version Data version: 1 (2020-2021) or 2 (2022 onwards, default)
#' @return Data frame with mobility data
#' @export
#' @details
#' Downloads Spanish origin-destination mobility data from MITMA. The version parameter
#' determines which dataset to use:
#' \itemize{
#'   \item \strong{Version 1 (2020-2021):} COVID-19 period data with basic trip information
#'   \item \strong{Version 2 (2022 onwards):} Enhanced data with sociodemographic factors
#' }
#' @examples
#' \dontrun{
#' # Get mobility data using default version 2
#' mobility <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Get COVID-period data (version 1)
#' covid_mobility <- get_mobility_matrix(
#'   dates = c("2020-03-01", "2020-03-07"), 
#'   version = 1
#' )
#' 
#' # Get morning rush hour data
#' morning_rush <- get_mobility_matrix(
#'   dates = c("2023-01-01", "2023-01-07"),
#'   time_window = c(7, 9),
#'   version = 2
#' )
#' }
get_mobility_matrix <- function(dates = NULL, level = "dist", time_window = NULL, 
                               aggregate_by = "none", version = NULL) {
  # Use configured version if not specified
  if (is.null(version)) {
    version <- getOption("mobspain.data_version", 2)
  }
  
  # Validate version
  if (!version %in% c(1, 2)) {
    stop("version must be 1 (2020-2021) or 2 (2022 onwards)", call. = FALSE)
  }
  
  # Set default dates if not provided
  if(is.null(dates)) {
    # Use appropriate default dates based on version
    if (version == 1) {
      dates <- c("2020-03-01", "2020-03-07")  # COVID period
      message("Using default COVID-period dates (version 1): ", dates[1], " to ", dates[2])
    } else {
      dates <- c("2023-01-01", "2023-01-07")  # Recent data
      message("Using default recent dates (version 2): ", dates[1], " to ", dates[2])
    }
  }
  
  # Enhanced input validation
  dates <- validate_dates(dates)
  level <- validate_level(level)
  time_window <- validate_time_window(time_window)
  
  if(!aggregate_by %in% c("none", "daily", "hourly")) {
    stop("aggregate_by must be one of: 'none', 'daily', 'hourly'", call. = FALSE)
  }
  
  message("Downloading mobility data (level: ", level, ", version: ", version, ")...")
  
  # Always use CSV access for reliability (recommended approach)
  # Database access is experimental and may not work with all data versions
  use_csv <- getOption("mobspain.use_csv", TRUE)
  
  if(use_csv) {
    message("Using CSV access (recommended for reliability)")
    result <- spanishoddata::spod_get(
      type = "od",
      zones = level,
      dates = dates
    )
    
    # Ensure we return a proper data.frame
    return(
      result %>%
        dplyr::mutate(
          date = as.Date(.data$date),
          weekday = lubridate::wday(.data$date, label = TRUE)
        ) %>%
        as.data.frame()
    )
  }
  
  # Try to connect to DuckDB (experimental)
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
          date = as.Date(.data$date),
          weekday = lubridate::wday(.data$date, label = TRUE)
        ) %>%
        as.data.frame()
    )
  }

  # Proceed with DuckDB query (experimental - may fail with different data versions)
  # Version-specific table names (these may not exist in all installations)
  table_name <- paste0("v", version, "_od_", level)
  
  # Check if table exists first
  tryCatch({
    tables <- DBI::dbListTables(con)
    if(!table_name %in% tables) {
      DBI::dbDisconnect(con)
      message("Table '", table_name, "' does not exist in database. Available tables: ", 
              paste(tables, collapse = ", "))
      message("Falling back to CSV access (recommended)")
      
      result <- spanishoddata::spod_get(
        type = "od",
        zones = level,
        dates = dates
      )
      
      return(
        result %>%
          dplyr::mutate(
            date = as.Date(.data$date),
            weekday = lubridate::wday(.data$date, label = TRUE)
          ) %>%
          as.data.frame()
      )
    }
  }, error = function(e) {
    DBI::dbDisconnect(con)
    message("Could not check database tables: ", e$message)
    message("Falling back to CSV access")
    
    result <- spanishoddata::spod_get(
      type = "od",
      zones = level,
      dates = dates
    )
    
    return(
      result %>%
        dplyr::mutate(
          date = as.Date(.data$date),
          weekday = lubridate::wday(.data$date, label = TRUE)
        ) %>%
        as.data.frame()
    )
  })

  query <- glue::glue_sql(
    "SELECT date, hour, id_origin, id_destination, n_trips
     FROM {`table_name`}
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
    
    # Fallback to CSV access (version is set globally via init_data_dir)
    csv_result <- spanishoddata::spod_get(
      type = "od",
      zones = level,
      dates = dates
    )
    
    return(csv_result %>%
      dplyr::mutate(
        date = as.Date(.data$date),
        weekday = lubridate::wday(.data$date, label = TRUE)
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
#' @examples
#' \dontrun{
#' # Load mobility data
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Calculate containment index for all zones
#' containment_data <- calculate_containment(mobility_data)
#' print(head(containment_data))
#' 
#' # View zones with highest containment (most self-contained)
#' top_contained <- containment_data[order(-containment_data$containment), ][1:10, ]
#' print(top_contained)
#' 
#' # View zones with lowest containment (most externally connected)
#' low_contained <- containment_data[order(containment_data$containment), ][1:10, ]
#' print(low_contained)
#' 
#' # Calculate average containment
#' avg_containment <- weighted.mean(containment_data$containment, 
#'                                 containment_data$total_trips)
#' cat("Average containment:", round(avg_containment, 3), "\n")
#' }
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
#' @examples
#' \dontrun{
#' # Load data
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Calculate basic mobility indicators
#' indicators <- calculate_mobility_indicators(mobility_data)
#' print(head(indicators))
#' 
#' # Calculate indicators with spatial zones for additional metrics
#' zones <- get_spatial_zones("dist")
#' indicators_spatial <- calculate_mobility_indicators(mobility_data, zones)
#' print(head(indicators_spatial))
#' 
#' # View top zones by outflow
#' top_outflow <- indicators[order(-indicators$total_outflow), ][1:10, ]
#' print(top_outflow)
#' 
#' # View zones with highest containment
#' top_containment <- indicators[order(-indicators$containment), ][1:10, ]
#' print(top_containment)
#' }
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
#' @examples
#' \dontrun{
#' # Load mobility data with date column
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-31"))
#' 
#' # Detect anomalies using z-score method
#' anomalies_zscore <- detect_mobility_anomalies(mobility_data, method = "zscore")
#' print(anomalies_zscore[anomalies_zscore$anomaly, ])
#' 
#' # Detect anomalies using IQR method with custom threshold
#' anomalies_iqr <- detect_mobility_anomalies(mobility_data, method = "iqr", threshold = 2)
#' print(anomalies_iqr[anomalies_iqr$anomaly, ])
#' 
#' # Detect anomalies without weekday separation
#' anomalies_simple <- detect_mobility_anomalies(mobility_data, by_weekday = FALSE)
#' print(anomalies_simple[anomalies_simple$anomaly, ])
#' 
#' # Count anomalies by method
#' cat("Z-score anomalies:", sum(anomalies_zscore$anomaly), "\n")
#' cat("IQR anomalies:", sum(anomalies_iqr$anomaly), "\n")
#' }
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
#' @examples
#' \dontrun{
#' # Load data
#' zones <- get_spatial_zones("dist")
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Calculate distance decay with power model
#' decay_power <- calculate_distance_decay(mobility_data, zones, model = "power")
#' print(decay_power$parameters)
#' 
#' # Calculate distance decay with exponential model
#' decay_exp <- calculate_distance_decay(mobility_data, zones, model = "exponential")
#' print(decay_exp$parameters)
#' 
#' # Plot the results
#' plot_distance_decay(decay_power)
#' 
#' # Compare model quality
#' cat("Power model R²:", decay_power$parameters$r_squared, "\n")
#' cat("Exponential model R²:", decay_exp$parameters$r_squared, "\n")
#' }
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

# Advanced Spanish Mobility Data Access and Integration

#' Get mobility data with intelligent version detection and caching
#'
#' @param dates Date range (character vector, Date vector, or named vector with start/end)
#' @param data_type Type of data ("od", "nt", "os")
#' @param zone_level Spatial level ("districts", "municipalities", "luas")
#' @param version Data version (1 or 2). If NULL, auto-detected from dates
#' @param use_cache Whether to use cached data (default: TRUE)
#' @param aggregate_temporal Whether to aggregate across time periods
#' @param demographic_filter List of demographic filters (age, sex, income)
#' @return Data frame with mobility data
#' @export
#' @examples
#' \dontrun{
#' # Get OD data with auto-detection
#' od_data <- get_enhanced_mobility_data(
#'   dates = c("2022-01-01", "2022-01-07"),
#'   data_type = "od",
#'   zone_level = "districts"
#' )
#' 
#' # Get demographic-filtered data
#' demographic_data <- get_enhanced_mobility_data(
#'   dates = c("2022-01-01", "2022-01-07"),
#'   data_type = "od",
#'   zone_level = "districts",
#'   demographic_filter = list(age = c("25-45"), sex = c("female"))
#' )
#' }
get_enhanced_mobility_data <- function(dates, 
                                     data_type = "od",
                                     zone_level = "districts", 
                                     version = NULL,
                                     use_cache = TRUE,
                                     aggregate_temporal = FALSE,
                                     demographic_filter = NULL) {
  
  # Auto-detect version if not specified
  if(is.null(version)) {
    version <- detect_data_version(dates)
    message(sprintf("Auto-detected data version %d based on dates", version))
  }
  
  # Validate inputs
  validate_enhanced_data_request(data_type, zone_level, version, demographic_filter)
  
  # Get metadata for request
  metadata <- get_data_type_metadata(data_type, version, zone_level)
  
  # Process dates to spanishoddata format
  processed_dates <- process_dates_for_spanishoddata(dates)
  
  # Get data using spanishoddata with fallback
  mobility_data <- get_data_with_fallback(
    data_type = data_type,
    zone_level = zone_level,
    dates = processed_dates,
    version = version,
    use_cache = use_cache
  )
  
  # Apply demographic filters if specified and available
  if(!is.null(demographic_filter) && version == 2) {
    mobility_data <- apply_demographic_filters(mobility_data, demographic_filter)
  }
  
  # Aggregate temporal data if requested
  if(aggregate_temporal) {
    mobility_data <- aggregate_temporal_data(mobility_data, data_type)
  }
  
  # Add metadata attributes
  attr(mobility_data, "mobspain_metadata") <- metadata
  attr(mobility_data, "mobspain_version") <- version
  attr(mobility_data, "mobspain_date_range") <- range(processed_dates)
  
  return(mobility_data)
}

#' Get data with intelligent fallback strategies
#'
#' @param data_type Type of data
#' @param zone_level Spatial level
#' @param dates Processed dates
#' @param version Data version
#' @param use_cache Whether to use cache
#' @return Data frame with mobility data
#' @keywords internal
get_data_with_fallback <- function(data_type, zone_level, dates, version, use_cache) {
  
  # Try database first (faster)
  if(use_cache) {
    tryCatch({
      data_dir <- getOption("mobspain.data_dir")
      if(!is.null(data_dir) && file.exists(file.path(data_dir, "spanishoddata.duckdb"))) {
        return(get_data_from_database(data_type, zone_level, dates, version))
      }
    }, error = function(e) {
      message("Database access failed, trying CSV fallback...")
    })
  }
  
  # Fallback to CSV/direct download
  return(get_data_from_csv(data_type, zone_level, dates, version))
}

#' Get data from DuckDB database
#'
#' @param data_type Type of data
#' @param zone_level Spatial level
#' @param dates Processed dates
#' @param version Data version
#' @return Data frame with mobility data
#' @keywords internal
get_data_from_database <- function(data_type, zone_level, dates, version) {
  
  # Map parameters to spanishoddata format
  zones_param <- switch(zone_level,
    "districts" = "dist",
    "municipalities" = "muni", 
    "luas" = "lua",
    zone_level
  )
  
  type_param <- switch(data_type,
    "od" = "od",
    "nt" = "nt",
    "os" = "os",
    data_type
  )
  
  # Use spanishoddata function
  if(requireNamespace("spanishoddata", quietly = TRUE)) {
    return(spanishoddata::spod_get(
      type = type_param,
      zones = zones_param,
      dates = dates,
      ver = version
    ))
  } else {
    stop("spanishoddata package required but not available")
  }
}

#' Get data from CSV files
#'
#' @param data_type Type of data
#' @param zone_level Spatial level
#' @param dates Processed dates
#' @param version Data version
#' @return Data frame with mobility data
#' @keywords internal
get_data_from_csv <- function(data_type, zone_level, dates, version) {
  
  # Download if needed
  if(requireNamespace("spanishoddata", quietly = TRUE)) {
    
    zones_param <- switch(zone_level,
      "districts" = "dist",
      "municipalities" = "muni", 
      "luas" = "lua",
      zone_level
    )
    
    type_param <- switch(data_type,
      "od" = "od",
      "nt" = "nt", 
      "os" = "os",
      data_type
    )
    
    # Download data if not cached
    spanishoddata::spod_download(
      type = type_param,
      zones = zones_param,
      dates = dates,
      max_download_size_gb = 5,
      quiet = TRUE
    )
    
    # Get data
    return(spanishoddata::spod_get(
      type = type_param,
      zones = zones_param,
      dates = dates,
      ver = version
    ))
    
  } else {
    stop("spanishoddata package required but not available")
  }
}

#' Process dates for spanishoddata compatibility
#'
#' @param dates Date input in various formats
#' @return Processed dates for spanishoddata
#' @keywords internal
process_dates_for_spanishoddata <- function(dates) {
  
  if(is.null(dates)) {
    stop("Dates must be specified")
  }
  
  # Handle different date formats
  if(length(dates) == 1) {
    # Single date
    return(as.character(dates))
  } else if(length(dates) == 2 && !is.null(names(dates))) {
    # Named vector with start/end
    if(all(c("start", "end") %in% names(dates))) {
      return(dates)
    }
  } else if(length(dates) == 2) {
    # Unnamed vector assumed to be start/end
    names(dates) <- c("start", "end")
    return(dates)
  }
  
  # Vector of dates
  return(as.character(dates))
}

#' Apply demographic filters to mobility data
#'
#' @param mobility_data Data frame with mobility data
#' @param demographic_filter List of demographic filters
#' @return Filtered data frame
#' @keywords internal
apply_demographic_filters <- function(mobility_data, demographic_filter) {
  
  if(is.null(demographic_filter)) {
    return(mobility_data)
  }
  
  # Apply age filter
  if(!is.null(demographic_filter$age)) {
    if("age" %in% names(mobility_data)) {
      mobility_data <- mobility_data[mobility_data$age %in% demographic_filter$age, ]
    } else {
      warning("Age filter requested but age column not available")
    }
  }
  
  # Apply sex filter
  if(!is.null(demographic_filter$sex)) {
    if("sex" %in% names(mobility_data)) {
      mobility_data <- mobility_data[mobility_data$sex %in% demographic_filter$sex, ]
    } else {
      warning("Sex filter requested but sex column not available")
    }
  }
  
  # Apply income filter
  if(!is.null(demographic_filter$income)) {
    if("income" %in% names(mobility_data)) {
      mobility_data <- mobility_data[mobility_data$income %in% demographic_filter$income, ]
    } else {
      warning("Income filter requested but income column not available")
    }
  }
  
  return(mobility_data)
}

#' Aggregate temporal data
#'
#' @param mobility_data Data frame with mobility data
#' @param data_type Type of data
#' @return Aggregated data frame
#' @keywords internal
aggregate_temporal_data <- function(mobility_data, data_type) {
  
  if(!"hour" %in% names(mobility_data)) {
    return(mobility_data)
  }
  
  # Group by all columns except hour and aggregate
  group_cols <- setdiff(names(mobility_data), c("hour", "n_trips", "trips_total_length_km"))
  
  if(data_type == "od") {
    # Origin-destination data
    if(requireNamespace("dplyr", quietly = TRUE)) {
      mobility_data <- mobility_data %>%
        dplyr::group_by(across(all_of(group_cols))) %>%
        dplyr::summarise(
          n_trips = sum(n_trips, na.rm = TRUE),
          trips_total_length_km = sum(trips_total_length_km, na.rm = TRUE),
          .groups = "drop"
        )
    } else {
      # Base R aggregation
      mobility_data <- aggregate(
        cbind(n_trips, trips_total_length_km) ~ .,
        data = mobility_data[, setdiff(names(mobility_data), "hour")],
        FUN = sum, na.rm = TRUE
      )
    }
  } else {
    # Node-level data (nt, os)
    if(requireNamespace("dplyr", quietly = TRUE)) {
      mobility_data <- mobility_data %>%
        dplyr::group_by(across(all_of(group_cols))) %>%
        dplyr::summarise(
          n_trips = sum(n_trips, na.rm = TRUE),
          .groups = "drop"
        )
    } else {
      # Base R aggregation
      mobility_data <- aggregate(
        n_trips ~ .,
        data = mobility_data[, setdiff(names(mobility_data), "hour")],
        FUN = sum, na.rm = TRUE
      )
    }
  }
  
  return(mobility_data)
}

#' Validate enhanced data request
#'
#' @param data_type Type of data
#' @param zone_level Spatial level
#' @param version Data version
#' @param demographic_filter Demographic filters
#' @keywords internal
validate_enhanced_data_request <- function(data_type, zone_level, version, demographic_filter) {
  
  # Validate data type
  valid_types <- c("od", "nt", "os")
  if(!data_type %in% valid_types) {
    stop(sprintf("Invalid data_type. Must be one of: %s", paste(valid_types, collapse = ", ")))
  }
  
  # Validate zone level
  valid_zones <- c("districts", "municipalities", "luas")
  if(!zone_level %in% valid_zones) {
    stop(sprintf("Invalid zone_level. Must be one of: %s", paste(valid_zones, collapse = ", ")))
  }
  
  # Validate version
  if(!version %in% c(1, 2)) {
    stop("Invalid version. Must be 1 or 2")
  }
  
  # Version-specific validations
  if(version == 1) {
    if(data_type == "os") {
      stop("Overnight stays data not available in version 1")
    }
    if(zone_level == "luas") {
      stop("Large urban areas not available in version 1")
    }
    if(!is.null(demographic_filter)) {
      warning("Demographic filters not available in version 1")
    }
  }
  
  # Validate demographic filters
  if(!is.null(demographic_filter) && version == 2) {
    if(!is.list(demographic_filter)) {
      stop("demographic_filter must be a list")
    }
    
    valid_demo_vars <- c("age", "sex", "income")
    invalid_vars <- setdiff(names(demographic_filter), valid_demo_vars)
    if(length(invalid_vars) > 0) {
      stop(sprintf("Invalid demographic variables: %s", paste(invalid_vars, collapse = ", ")))
    }
  }
}

#' Get spatial zones with enhanced metadata
#'
#' @param zone_level Spatial level
#' @param version Data version
#' @param include_metadata Whether to include additional metadata
#' @return SF object with spatial zones
#' @export
#' @examples
#' \dontrun{
#' # Get districts for v2 data
#' districts <- get_enhanced_spatial_zones("districts", version = 2)
#' 
#' # Get municipalities with metadata
#' municipalities <- get_enhanced_spatial_zones("municipalities", version = 2, include_metadata = TRUE)
#' }
get_enhanced_spatial_zones <- function(zone_level, version = NULL, include_metadata = TRUE) {
  
  if(is.null(version)) {
    version <- getOption("mobspain.data_version", 2)
  }
  
  # Map zone level to spanishoddata format
  zones_param <- switch(zone_level,
    "districts" = "dist",
    "municipalities" = "muni",
    "luas" = "lua",
    zone_level
  )
  
  # Get zones using spanishoddata
  if(requireNamespace("spanishoddata", quietly = TRUE)) {
    zones <- spanishoddata::spod_get_zones(zones_param, ver = version)
    
    if(include_metadata) {
      # Add enhanced metadata
      metadata <- get_data_version_info()
      attr(zones, "mobspain_metadata") <- metadata
      attr(zones, "mobspain_version") <- version
      attr(zones, "mobspain_zone_level") <- zone_level
    }
    
    return(zones)
  } else {
    stop("spanishoddata package required but not available")
  }
}

#' Get comprehensive data summary
#'
#' @param dates Date range
#' @param version Data version
#' @return List with data availability and characteristics
#' @export
#' @examples
#' \dontrun{
#' # Get summary for date range
#' summary <- get_data_summary(c("2022-01-01", "2022-01-07"), version = 2)
#' print(summary$availability)
#' print(summary$recommended_analysis)
#' }
get_data_summary <- function(dates, version = NULL) {
  
  if(is.null(version)) {
    version <- detect_data_version(dates)
  }
  
  # Get version info
  version_info <- get_data_version_info()
  
  # Process dates
  date_range <- range(as.Date(dates))
  n_days <- as.numeric(diff(date_range)) + 1
  
  # Calculate data characteristics
  data_chars <- list(
    version = version,
    date_range = date_range,
    n_days = n_days,
    data_type = "od"  # Default
  )
  
  # Get recommendations
  recommendations <- get_analysis_recommendations(data_chars)
  
  summary <- list(
    version_info = version_info,
    date_characteristics = list(
      range = date_range,
      n_days = n_days,
      period_type = if(version == 1) "COVID-19 period" else "Post-pandemic period"
    ),
    availability = list(
      data_types = names(version_info$data_types),
      spatial_levels = version_info$spatial_levels,
      has_demographics = version == 2,
      international_coverage = version == 2
    ),
    recommended_analysis = recommendations,
    data_size_estimate = estimate_data_size(n_days, version),
    processing_recommendations = get_processing_recommendations(n_days, version)
  )
  
  return(summary)
}

#' Estimate data size for planning
#'
#' @param n_days Number of days
#' @param version Data version
#' @return List with size estimates
#' @keywords internal
estimate_data_size <- function(n_days, version) {
  
  # Rough estimates based on documentation
  if(version == 1) {
    daily_size_mb <- 50  # Approximate MB per day
    total_size_mb <- n_days * daily_size_mb
  } else {
    daily_size_mb <- 150  # Larger due to demographics
    total_size_mb <- n_days * daily_size_mb
  }
  
  list(
    daily_mb = daily_size_mb,
    total_mb = total_size_mb,
    total_gb = round(total_size_mb / 1024, 2),
    recommendation = if(total_size_mb > 5000) "Consider data subsetting" else "Manageable size"
  )
}

#' Get processing recommendations
#'
#' @param n_days Number of days
#' @param version Data version
#' @return List with processing recommendations
#' @keywords internal
get_processing_recommendations <- function(n_days, version) {
  
  recommendations <- list()
  
  if(n_days > 30) {
    recommendations$temporal <- "Consider temporal aggregation for large date ranges"
  }
  
  if(version == 2) {
    recommendations$demographics <- "Use demographic filters to reduce data size"
  }
  
  recommendations$caching <- "Enable caching for repeated access"
  recommendations$performance <- "Use database access when available"
  
  return(recommendations)
}
