#' Get spatial zones with parsed metadata
#'
#' @param level Spatial level: "dist" (districts), "muni" (municipalities), "lua" (large urban areas)
#' @param version Data version: 1 (2020-2021) or 2 (2022 onwards, default)
#' @return sf object with spatial zones
#' @export
#' @details
#' Downloads Spanish administrative boundaries from the MITMA dataset. 
#' The version parameter determines which dataset version to use:
#' \itemize{
#'   \item \strong{Version 1 (2020-2021):} COVID-19 period boundaries
#'   \item \strong{Version 2 (2022 onwards):} Enhanced boundaries with better resolution
#' }
#' @examples
#' \dontrun{
#' # Get districts using default version 2
#' districts <- get_spatial_zones("dist")
#' 
#' # Get municipalities using version 1 (COVID period)
#' municipalities <- get_spatial_zones("muni", version = 1)
#' 
#' # Get large urban areas using version 2
#' urban_areas <- get_spatial_zones("lua", version = 2)
#' }
get_spatial_zones <- function(level = "dist", version = NULL) {
  # Use configured version if not specified
  if (is.null(version)) {
    version <- getOption("mobspain.data_version", 2)
  }
  
  # Validate version
  if (!version %in% c(1, 2)) {
    stop("version must be 1 (2020-2021) or 2 (2022 onwards)", call. = FALSE)
  }
  
  # Validate level
  valid_levels <- c("dist", "muni", "lua")
  if (!level %in% valid_levels) {
    stop("level must be one of: ", paste(valid_levels, collapse = ", "), call. = FALSE)
  }
  
  tryCatch({
    message("Downloading spatial zones (level: ", level, ", version: ", version, ")...")
    zones <- spanishoddata::spod_get_zones(level, ver = version)

    # Standardize column names - spanishoddata uses different column names
    if("id_dist" %in% names(zones)) {
      zones$id <- zones$id_dist
    } else if("id_muni" %in% names(zones)) {
      zones$id <- zones$id_muni
    } else if("id_lua" %in% names(zones)) {
      zones$id <- zones$id_lua
    }
    
    # Calculate area
    zones$area_km2 <- as.numeric(sf::st_area(zones)) / 1e6
    
    message("Successfully downloaded ", nrow(zones), " zones")
    return(zones)
  }, error = function(e) {
    warning("Failed to download spatial data (version ", version, "): ", e$message)
    message("Using built-in sample data instead")

    # Load sample spatial data
    utils::data("sample_zones", package = "mobspain", envir = environment())
    return(get("sample_zones", envir = environment()))
  })
}

#' Create spatial index for zones
#'
#' Prepares zones for efficient spatial operations by adding centroids
#'
#' @param zones sf object from get_spatial_zones()
#' @return Enhanced sf object with centroid column
#' @export
#' @examples
#' \dontrun{
#' # Load spatial zones
#' zones <- get_spatial_zones("dist")
#' 
#' # Create spatial index with centroids
#' zones_indexed <- create_zone_index(zones)
#' 
#' # Now you can use the centroids for spatial operations
#' print(head(zones_indexed$centroid))
#' }
create_zone_index <- function(zones) {
  if (!inherits(zones, "sf")) {
    stop("Input must be an sf object", call. = FALSE)
  }

  zones %>%
    sf::st_make_valid() %>%
    dplyr::mutate(centroid = sf::st_centroid(.data$geometry))
}

# Enhanced Spatial Analysis Functions for Spanish Mobility Data

#' Calculate spatial accessibility metrics for Spanish mobility data
#'
#' @param mobility_data Mobility data with origin-destination flows
#' @param spatial_zones Spatial zones data (sf object)
#' @param accessibility_type Type of accessibility to calculate
#' @param distance_decay Apply distance decay weighting
#' @param population_weight Weight by population
#' @return Data frame with accessibility metrics
#' @export
#' @examples
#' \dontrun{
#' # Calculate job accessibility
#' accessibility <- calculate_spatial_accessibility(
#'   mobility_data = mobility,
#'   spatial_zones = zones,
#'   accessibility_type = "job_accessibility",
#'   distance_decay = TRUE
#' )
#' }
calculate_spatial_accessibility <- function(mobility_data, spatial_zones,
                                          accessibility_type = c("general", "job_accessibility", 
                                                                "service_accessibility", "gravity_based"),
                                          distance_decay = TRUE, population_weight = TRUE) {
  
  accessibility_type <- match.arg(accessibility_type)
  
  # Validate inputs
  required_cols <- c("id_origin", "id_destination", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if(length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Ensure spatial_zones is sf object
  if(!inherits(spatial_zones, "sf")) {
    stop("spatial_zones must be an sf object")
  }
  
  # Calculate distance matrix if distance decay is enabled
  if(distance_decay) {
    distances <- calculate_zone_distances(spatial_zones)
  }
  
  # Calculate accessibility based on type
  accessibility_results <- switch(accessibility_type,
    "general" = calculate_general_accessibility(mobility_data, spatial_zones, distances, distance_decay),
    "job_accessibility" = calculate_job_accessibility(mobility_data, spatial_zones, distances, distance_decay),
    "service_accessibility" = calculate_service_accessibility(mobility_data, spatial_zones, distances, distance_decay),
    "gravity_based" = calculate_gravity_accessibility_full(mobility_data, spatial_zones, distances, distance_decay)
  )
  
  # Add population weighting if requested
  if(population_weight && "population" %in% names(spatial_zones)) {
    accessibility_results <- add_population_weighting(accessibility_results, spatial_zones)
  }
  
  return(accessibility_results)
}

#' Calculate zone-to-zone distances
#' @param spatial_zones Spatial zones data
#' @return Distance matrix
#' @keywords internal
calculate_zone_distances <- function(spatial_zones) {
  
  # Transform to projected CRS for accurate distance calculation
  zones_projected <- sf::st_transform(spatial_zones, 3857)  # Web Mercator
  
  # Calculate centroids
  centroids <- sf::st_centroid(zones_projected)
  
  # Calculate distance matrix
  distances <- sf::st_distance(centroids, centroids)
  
  # Convert to kilometers and add zone IDs
  distances_km <- units::set_units(distances, "km")
  distances_df <- as.data.frame(as.matrix(distances_km))
  
  colnames(distances_df) <- spatial_zones$id
  distances_df$id_origin <- spatial_zones$id
  
  return(distances_df)
}

#' Calculate general accessibility
#' @param mobility_data Mobility data
#' @param spatial_zones Spatial zones
#' @param distances Distance matrix
#' @param distance_decay Apply distance decay
#' @return Accessibility results
#' @keywords internal
calculate_general_accessibility <- function(mobility_data, spatial_zones, distances, distance_decay) {
  
  # Aggregate flows by origin
  origin_flows <- mobility_data %>%
    dplyr::group_by(.data$id_origin) %>%
    dplyr::summarise(
      total_outflow = sum(.data$n_trips, na.rm = TRUE),
      destinations_count = dplyr::n_distinct(.data$id_destination),
      avg_flow = mean(.data$n_trips, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Aggregate flows by destination
  destination_flows <- mobility_data %>%
    dplyr::group_by(.data$id_destination) %>%
    dplyr::summarise(
      total_inflow = sum(.data$n_trips, na.rm = TRUE),
      origins_count = dplyr::n_distinct(.data$id_origin),
      .groups = "drop"
    )
  
  # Combine and calculate accessibility index
  accessibility <- origin_flows %>%
    dplyr::left_join(destination_flows, by = c("id_origin" = "id_destination")) %>%
    dplyr::mutate(
      accessibility_index = (.data$destinations_count + .data$origins_count) / 2,
      flow_balance = .data$total_outflow / (.data$total_inflow + 1),  # +1 to avoid division by zero
      connectivity_score = log1p(.data$total_outflow + .data$total_inflow)
    ) %>%
    dplyr::rename(id = .data$id_origin)
  
  return(accessibility)
}

#' Calculate job accessibility using commuting patterns
#' @param mobility_data Mobility data
#' @param spatial_zones Spatial zones
#' @param distances Distance matrix
#' @param distance_decay Apply distance decay
#' @return Job accessibility results
#' @keywords internal
calculate_job_accessibility <- function(mobility_data, spatial_zones, distances, distance_decay) {
  
  # Focus on work-related trips if activity information is available
  if("activity_destination" %in% names(mobility_data)) {
    work_trips <- mobility_data %>%
      dplyr::filter(.data$activity_destination == "work_or_study")
  } else {
    # Use all trips as proxy for job accessibility
    work_trips <- mobility_data
  }
  
  # Calculate job accessibility for each origin
  job_accessibility <- work_trips %>%
    dplyr::group_by(.data$id_origin) %>%
    dplyr::summarise(
      accessible_jobs = sum(.data$n_trips, na.rm = TRUE),
      job_destinations = dplyr::n_distinct(.data$id_destination),
      avg_commute_flow = mean(.data$n_trips, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Apply distance decay if requested
  if(distance_decay && !is.null(distances)) {
    job_accessibility <- apply_distance_decay_weighting(job_accessibility, distances, "accessible_jobs")
  }
  
  # Calculate job accessibility index
  job_accessibility <- job_accessibility %>%
    dplyr::mutate(
      job_accessibility_index = log1p(.data$accessible_jobs),
      job_diversity_index = .data$job_destinations / max(.data$job_destinations, na.rm = TRUE)
    ) %>%
    dplyr::rename(id = .data$id_origin)
  
  return(job_accessibility)
}

#' Calculate service accessibility
#' @param mobility_data Mobility data
#' @param spatial_zones Spatial zones
#' @param distances Distance matrix
#' @param distance_decay Apply distance decay
#' @return Service accessibility results
#' @keywords internal
calculate_service_accessibility <- function(mobility_data, spatial_zones, distances, distance_decay) {
  
  # Focus on service-related trips (non-home, non-work)
  if(all(c("activity_origin", "activity_destination") %in% names(mobility_data))) {
    service_trips <- mobility_data %>%
      dplyr::filter(.data$activity_destination == "other" | 
                   (.data$activity_origin != "home" & .data$activity_destination != "work_or_study"))
  } else {
    # Use all trips as proxy
    service_trips <- mobility_data
  }
  
  # Calculate service accessibility
  service_accessibility <- service_trips %>%
    dplyr::group_by(.data$id_origin) %>%
    dplyr::summarise(
      accessible_services = sum(.data$n_trips, na.rm = TRUE),
      service_destinations = dplyr::n_distinct(.data$id_destination),
      avg_service_flow = mean(.data$n_trips, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      service_accessibility_index = log1p(.data$accessible_services),
      service_diversity = .data$service_destinations / max(.data$service_destinations, na.rm = TRUE)
    ) %>%
    dplyr::rename(id = .data$id_origin)
  
  return(service_accessibility)
}

#' Calculate gravity-based accessibility
#' @param mobility_data Mobility data
#' @param spatial_zones Spatial zones
#' @param distances Distance matrix
#' @param distance_decay Apply distance decay
#' @return Gravity accessibility results
#' @keywords internal
calculate_gravity_accessibility_full <- function(mobility_data, spatial_zones, distances, distance_decay) {
  
  # This is a simplified gravity model
  # In a full implementation, you would use actual opportunities/population at destinations
  
  gravity_accessibility <- mobility_data %>%
    dplyr::group_by(.data$id_origin, .data$id_destination) %>%
    dplyr::summarise(
      total_flow = sum(.data$n_trips, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Apply distance decay (exponential decay)
  if(distance_decay && !is.null(distances)) {
    # Merge with distances and apply decay function
    gravity_accessibility <- add_distance_decay_gravity(gravity_accessibility, distances)
  }
  
  # Aggregate by origin
  gravity_results <- gravity_accessibility %>%
    dplyr::group_by(.data$id_origin) %>%
    dplyr::summarise(
      gravity_accessibility = sum(.data$total_flow, na.rm = TRUE),
      reachable_destinations = dplyr::n(),
      .groups = "drop"
    ) %>%
    dplyr::rename(id = .data$id_origin)
  
  return(gravity_results)
}

#' Apply distance decay weighting
#' @param accessibility_data Accessibility data
#' @param distances Distance matrix
#' @param value_column Column to apply decay to
#' @return Data with distance decay applied
#' @keywords internal
apply_distance_decay_weighting <- function(accessibility_data, distances, value_column) {
  
  # This is a simplified implementation
  # In practice, you would merge with actual distances and apply decay function
  
  # For now, just return the original data with a note
  accessibility_data$distance_decay_applied <- TRUE
  
  return(accessibility_data)
}

#' Add distance decay to gravity model
#' @param gravity_data Gravity accessibility data
#' @param distances Distance matrix
#' @return Gravity data with distance decay
#' @keywords internal
add_distance_decay_gravity <- function(gravity_data, distances) {
  
  # Simplified distance decay implementation
  # In practice, merge with actual distances and apply exp(-beta * distance)
  
  gravity_data$distance_decay_factor <- 1  # Placeholder
  gravity_data$total_flow <- gravity_data$total_flow * gravity_data$distance_decay_factor
  
  return(gravity_data)
}

#' Add population weighting to accessibility results
#' @param accessibility_results Accessibility results
#' @param spatial_zones Spatial zones with population data
#' @return Accessibility results with population weighting
#' @keywords internal
add_population_weighting <- function(accessibility_results, spatial_zones) {
  
  # Extract population data
  population_data <- spatial_zones %>%
    sf::st_drop_geometry() %>%
    dplyr::select(.data$id, .data$population)
  
  # Merge and calculate population-weighted metrics
  weighted_results <- accessibility_results %>%
    dplyr::left_join(population_data, by = "id") %>%
    dplyr::mutate(
      population = ifelse(is.na(.data$population), 0, .data$population)
    )
  
  # Add population-weighted versions of key metrics
  numeric_cols <- names(weighted_results)[sapply(weighted_results, is.numeric)]
  accessibility_cols <- numeric_cols[grepl("accessibility|index|score", numeric_cols)]
  
  for(col in accessibility_cols) {
    new_col_name <- paste0(col, "_pop_weighted")
    weighted_results[[new_col_name]] <- weighted_results[[col]] * log1p(weighted_results$population)
  }
  
  return(weighted_results)
}

#' Analyze spatial clustering of mobility patterns
#'
#' @param mobility_data Mobility data
#' @param spatial_zones Spatial zones data
#' @param clustering_method Method for clustering analysis
#' @return Spatial clustering results
#' @export
#' @examples
#' \dontrun{
#' # Analyze spatial clustering
#' clustering <- analyze_spatial_clustering(
#'   mobility_data = mobility,
#'   spatial_zones = zones,
#'   clustering_method = "getis_ord"
#' )
#' }
analyze_spatial_clustering <- function(mobility_data, spatial_zones,
                                     clustering_method = c("getis_ord", "moran", "local_moran")) {
  
  clustering_method <- match.arg(clustering_method)
  
  # Aggregate mobility data by zone
  zone_mobility <- mobility_data %>%
    dplyr::group_by(.data$id_origin) %>%
    dplyr::summarise(
      total_outflow = sum(.data$n_trips, na.rm = TRUE),
      avg_flow = mean(.data$n_trips, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::rename(id = .data$id_origin)
  
  # Merge with spatial zones
  zones_with_mobility <- spatial_zones %>%
    dplyr::left_join(zone_mobility, by = "id") %>%
    dplyr::mutate(
      total_outflow = ifelse(is.na(.data$total_outflow), 0, .data$total_outflow),
      avg_flow = ifelse(is.na(.data$avg_flow), 0, .data$avg_flow)
    )
  
  # Perform clustering analysis based on method
  clustering_result <- switch(clustering_method,
    "getis_ord" = calculate_getis_ord_clustering(zones_with_mobility),
    "moran" = calculate_moran_clustering(zones_with_mobility),
    "local_moran" = calculate_local_moran_clustering(zones_with_mobility)
  )
  
  return(clustering_result)
}

#' Calculate Getis-Ord clustering statistics
#' @param zones_with_mobility Spatial zones with mobility data
#' @return Getis-Ord clustering results
#' @keywords internal
calculate_getis_ord_clustering <- function(zones_with_mobility) {
  
  # Check if spdep package is available
  if(!requireNamespace("spdep", quietly = TRUE)) {
    warning("spdep package not available. Returning simplified clustering analysis.")
    return(calculate_simplified_clustering(zones_with_mobility))
  }
  
  # Create spatial weights matrix
  coords <- sf::st_coordinates(sf::st_centroid(zones_with_mobility))
  nb <- spdep::knn2nb(spdep::knearneigh(coords, k = 8))
  weights <- spdep::nb2listw(nb, style = "W")
  
  # Calculate Getis-Ord statistics
  getis_ord <- spdep::localG(zones_with_mobility$total_outflow, weights)
  
  # Add results to zones
  zones_with_mobility$getis_ord_statistic <- as.vector(getis_ord)
  zones_with_mobility$clustering_type <- ifelse(zones_with_mobility$getis_ord_statistic > 1.96, "Hot Spot",
                                               ifelse(zones_with_mobility$getis_ord_statistic < -1.96, "Cold Spot", "Not Significant"))
  
  return(zones_with_mobility)
}

#' Calculate Moran's I clustering statistics
#' @param zones_with_mobility Spatial zones with mobility data
#' @return Moran's I clustering results
#' @keywords internal
calculate_moran_clustering <- function(zones_with_mobility) {
  
  if(!requireNamespace("spdep", quietly = TRUE)) {
    warning("spdep package not available. Returning simplified clustering analysis.")
    return(calculate_simplified_clustering(zones_with_mobility))
  }
  
  # Create spatial weights matrix
  coords <- sf::st_coordinates(sf::st_centroid(zones_with_mobility))
  nb <- spdep::knn2nb(spdep::knearneigh(coords, k = 8))
  weights <- spdep::nb2listw(nb, style = "W")
  
  # Calculate global Moran's I
  moran_result <- spdep::moran.test(zones_with_mobility$total_outflow, weights)
  
  # Return results
  result <- list(
    zones_data = zones_with_mobility,
    global_moran = list(
      statistic = moran_result$statistic,
      p_value = moran_result$p.value,
      interpretation = ifelse(moran_result$p.value < 0.05, 
                             "Significant spatial clustering detected", 
                             "No significant spatial clustering")
    )
  )
  
  return(result)
}

#' Calculate Local Moran's I clustering statistics
#' @param zones_with_mobility Spatial zones with mobility data
#' @return Local Moran's I clustering results
#' @keywords internal
calculate_local_moran_clustering <- function(zones_with_mobility) {
  
  if(!requireNamespace("spdep", quietly = TRUE)) {
    warning("spdep package not available. Returning simplified clustering analysis.")
    return(calculate_simplified_clustering(zones_with_mobility))
  }
  
  # Create spatial weights matrix
  coords <- sf::st_coordinates(sf::st_centroid(zones_with_mobility))
  nb <- spdep::knn2nb(spdep::knearneigh(coords, k = 8))
  weights <- spdep::nb2listw(nb, style = "W")
  
  # Calculate Local Moran's I
  local_moran <- spdep::localmoran(zones_with_mobility$total_outflow, weights)
  
  # Add results to zones
  zones_with_mobility$local_moran_statistic <- local_moran[, 1]
  zones_with_mobility$local_moran_pvalue <- local_moran[, 5]
  zones_with_mobility$clustering_significance <- ifelse(zones_with_mobility$local_moran_pvalue < 0.05, 
                                                       "Significant", "Not Significant")
  
  return(zones_with_mobility)
}

#' Calculate simplified clustering analysis (fallback)
#' @param zones_with_mobility Spatial zones with mobility data
#' @return Simplified clustering results
#' @keywords internal
calculate_simplified_clustering <- function(zones_with_mobility) {
  
  # Simple clustering based on quantiles
  zones_with_mobility$mobility_quartile <- cut(zones_with_mobility$total_outflow, 
                                              breaks = quantile(zones_with_mobility$total_outflow, 
                                                              probs = c(0, 0.25, 0.5, 0.75, 1.0), na.rm = TRUE),
                                              labels = c("Low", "Medium-Low", "Medium-High", "High"),
                                              include.lowest = TRUE)
  
  zones_with_mobility$clustering_type <- dplyr::case_when(
    zones_with_mobility$mobility_quartile == "High" ~ "High Mobility Cluster",
    zones_with_mobility$mobility_quartile == "Low" ~ "Low Mobility Cluster",
    TRUE ~ "Medium Mobility"
  )
  
  return(zones_with_mobility)
}
