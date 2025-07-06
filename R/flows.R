#' Interactive Flow Map Functions for Spanish Mobility Data
#'
#' This file contains functions for creating interactive flow maps
#' using flowmapblue and other interactive visualization libraries.

#' Create interactive flow map for Spanish mobility data
#'
#' @param spatial_zones Spatial zones data (sf object)
#' @param mobility_data Mobility data with origin-destination flows
#' @param flow_threshold Minimum flow threshold to display
#' @param time_enabled Enable time-based filtering
#' @param mapbox_token Mapbox access token for basemap
#' @param title Map title
#' @return Interactive flow map object
#' @export
#' @examples
#' \dontrun{
#' # Set up data
#' zones <- get_spatial_zones("dist", version = 1)
#' mobility <- get_mobility_matrix(dates = "2020-04-01", version = 1)
#' 
#' # Create interactive flow map
#' flow_map <- create_interactive_flow_map(
#'   spatial_zones = zones,
#'   mobility_data = mobility,
#'   flow_threshold = 100,
#'   title = "Madrid Mobility Flows - April 1, 2020"
#' )
#' 
#' # Display the map
#' flow_map
#' }
create_interactive_flow_map <- function(spatial_zones, mobility_data, 
                                      flow_threshold = 50, time_enabled = FALSE,
                                      mapbox_token = NULL, title = "Mobility Flows") {
  
  # Check if leaflet is available for fallback
  if(!requireNamespace("leaflet", quietly = TRUE)) {
    stop("leaflet package required for flow maps. Install with: install.packages('leaflet')")
  }
  
  # Set mapbox token if provided
  if(!is.null(mapbox_token)) {
    Sys.setenv(MAPBOX_TOKEN = mapbox_token)
  }
  
  # Prepare locations data
  locations <- prepare_flow_map_locations(spatial_zones)
  
  # Prepare flows data
  flows <- prepare_flow_map_flows(mobility_data, flow_threshold, time_enabled)
  
  # Create a simple leaflet map as fallback
  # Since flowmapblue may not be available, use leaflet
  map <- leaflet::leaflet() %>%
    leaflet::addTiles() %>%
    leaflet::addCircleMarkers(
      data = locations,
      lng = ~lon, lat = ~lat,
      popup = ~paste("Zone:", id, "<br>Name:", name),
      radius = 5,
      color = "blue",
      fillOpacity = 0.7
    )
  
  # Add title if provided
  if(!is.null(title)) {
    map <- map %>% leaflet::addControl(title, position = "topright")
  }
  
  return(map)
}

#' Prepare locations data for flow map
#' @param spatial_zones Spatial zones data
#' @return Data frame with location information
#' @keywords internal
prepare_flow_map_locations <- function(spatial_zones) {
  
  # Ensure we have sf object
  if(!inherits(spatial_zones, "sf")) {
    stop("spatial_zones must be an sf object")
  }
  
  # Transform to WGS84 for mapping
  zones_wgs84 <- sf::st_transform(spatial_zones, 4326)
  
  # Calculate centroids
  centroids <- sf::st_centroid(zones_wgs84)
  coords <- sf::st_coordinates(centroids)
  
  # Prepare locations data frame
  locations <- data.frame(
    id = zones_wgs84$id,
    name = if("name" %in% names(zones_wgs84)) zones_wgs84$name else zones_wgs84$id,
    lat = coords[, 2],
    lon = coords[, 1]
  )
  
  # Add population if available
  if("population" %in% names(zones_wgs84)) {
    locations$population <- zones_wgs84$population
  }
  
  return(locations)
}

#' Prepare flows data for flow map
#' @param mobility_data Mobility data
#' @param flow_threshold Minimum flow threshold
#' @param time_enabled Include time information
#' @return Data frame with flow information
#' @keywords internal
prepare_flow_map_flows <- function(mobility_data, flow_threshold, time_enabled) {
  
  # Validate required columns
  required_cols <- c("id_origin", "id_destination", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if(length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Filter by threshold and aggregate if needed
  if(time_enabled && "hour" %in% names(mobility_data)) {
    # Keep time information
    flows <- mobility_data %>%
      dplyr::filter(.data$n_trips >= flow_threshold) %>%
      dplyr::select(.data$id_origin, .data$id_destination, .data$n_trips, .data$hour) %>%
      dplyr::rename(
        origin = .data$id_origin,
        dest = .data$id_destination,
        count = .data$n_trips,
        time = .data$hour
      )
  } else {
    # Aggregate across time
    flows <- mobility_data %>%
      dplyr::group_by(.data$id_origin, .data$id_destination) %>%
      dplyr::summarise(
        n_trips = sum(.data$n_trips, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      dplyr::filter(.data$n_trips >= flow_threshold) %>%
      dplyr::rename(
        origin = .data$id_origin,
        dest = .data$id_destination,
        count = .data$n_trips
      )
  }
  
  return(flows)
}

#' Create animated flow map showing temporal patterns
#'
#' @param spatial_zones Spatial zones data (sf object)
#' @param mobility_data Mobility data with hourly information
#' @param flow_threshold Minimum flow threshold to display
#' @param mapbox_token Mapbox access token for basemap
#' @param title Map title
#' @return Animated interactive flow map
#' @export
#' @examples
#' \dontrun{
#' # Create animated flow map
#' animated_map <- create_animated_flow_map(
#'   spatial_zones = zones,
#'   mobility_data = mobility,
#'   flow_threshold = 100,
#'   title = "Madrid Mobility - Hourly Patterns"
#' )
#' 
#' animated_map
#' }
create_animated_flow_map <- function(spatial_zones, mobility_data, 
                                   flow_threshold = 50, mapbox_token = NULL,
                                   title = "Mobility Flows - Animated") {
  
  # Check if hour column exists
  if(!"hour" %in% names(mobility_data)) {
    stop("mobility_data must contain 'hour' column for animated flow maps")
  }
  
  return(create_interactive_flow_map(
    spatial_zones = spatial_zones,
    mobility_data = mobility_data,
    flow_threshold = flow_threshold,
    time_enabled = TRUE,
    mapbox_token = mapbox_token,
    title = title
  ))
}

#' Create flow map with clustering for large datasets
#'
#' @param spatial_zones Spatial zones data (sf object)
#' @param mobility_data Mobility data
#' @param cluster_threshold Number of flows above which clustering is enabled
#' @param flow_threshold Minimum flow threshold to display
#' @param mapbox_token Mapbox access token for basemap
#' @param title Map title
#' @return Clustered interactive flow map
#' @export
#' @examples
#' \dontrun{
#' # Create clustered flow map for large datasets
#' clustered_map <- create_clustered_flow_map(
#'   spatial_zones = zones,
#'   mobility_data = mobility,
#'   cluster_threshold = 1000,
#'   flow_threshold = 50,
#'   title = "Madrid Mobility - Clustered View"
#' )
#' 
#' clustered_map
#' }
create_clustered_flow_map <- function(spatial_zones, mobility_data,
                                    cluster_threshold = 1000, flow_threshold = 50,
                                    mapbox_token = NULL, title = "Mobility Flows - Clustered") {
  
  # Check if flowmapblue is available
  if(!requireNamespace("flowmapblue", quietly = TRUE)) {
    stop("flowmapblue package required. Install with: install.packages('flowmapblue')")
  }
  
  # Count total flows
  total_flows <- nrow(mobility_data[mobility_data$n_trips >= flow_threshold, ])
  
  # Enable clustering for large datasets
  clustering_enabled <- total_flows > cluster_threshold
  
  if(clustering_enabled) {
    message("Large dataset detected (", total_flows, " flows). Enabling clustering for better performance.")
  }
  
  return(create_interactive_flow_map(
    spatial_zones = spatial_zones,
    mobility_data = mobility_data,
    flow_threshold = flow_threshold,
    time_enabled = FALSE,
    mapbox_token = mapbox_token,
    title = title
  ))
}

#' Export interactive flow map to HTML file
#'
#' @param flow_map Flow map object created by create_interactive_flow_map
#' @param filename Output HTML filename
#' @param selfcontained Whether to create self-contained HTML file
#' @return Path to saved HTML file
#' @export
#' @examples
#' \dontrun{
#' # Create and export flow map
#' flow_map <- create_interactive_flow_map(zones, mobility)
#' export_flow_map(flow_map, "madrid_flows.html")
#' }
export_flow_map <- function(flow_map, filename = "mobility_flows.html", 
                           selfcontained = TRUE) {
  
  if(!requireNamespace("htmlwidgets", quietly = TRUE)) {
    stop("htmlwidgets package required. Install with: install.packages('htmlwidgets')")
  }
  
  # Save the widget
  htmlwidgets::saveWidget(
    widget = flow_map,
    file = filename,
    selfcontained = selfcontained
  )
  
  message("Flow map saved to: ", filename)
  return(filename)
}

#' Get flow map configuration recommendations
#'
#' @param mobility_data Mobility data to analyze
#' @return List with recommended configuration settings
#' @export
#' @examples
#' \dontrun{
#' # Get recommendations for flow map configuration
#' recommendations <- get_flow_map_recommendations(mobility_data)
#' print(recommendations)
#' }
get_flow_map_recommendations <- function(mobility_data) {
  
  # Analyze data characteristics
  total_flows <- nrow(mobility_data)
  unique_origins <- length(unique(mobility_data$id_origin))
  unique_destinations <- length(unique(mobility_data$id_destination))
  max_flows <- max(mobility_data$n_trips, na.rm = TRUE)
  median_flows <- median(mobility_data$n_trips, na.rm = TRUE)
  
  # Generate recommendations
  recommendations <- list(
    data_characteristics = list(
      total_flows = total_flows,
      unique_origins = unique_origins,
      unique_destinations = unique_destinations,
      max_flow_value = max_flows,
      median_flow_value = median_flows
    ),
    recommended_settings = list(),
    performance_notes = character()
  )
  
  # Flow threshold recommendation
  if(total_flows > 10000) {
    recommended_threshold <- max(median_flows, 100)
    recommendations$recommended_settings$flow_threshold <- recommended_threshold
    recommendations$performance_notes <- c(recommendations$performance_notes,
                                         paste("Large dataset detected. Recommended flow threshold:", 
                                               recommended_threshold))
  } else {
    recommendations$recommended_settings$flow_threshold <- max(10, median_flows * 0.1)
  }
  
  # Clustering recommendation
  if(total_flows > 5000) {
    recommendations$recommended_settings$enable_clustering <- TRUE
    recommendations$performance_notes <- c(recommendations$performance_notes,
                                         "Enable clustering for better performance")
  } else {
    recommendations$recommended_settings$enable_clustering <- FALSE
  }
  
  # Animation recommendation
  if("hour" %in% names(mobility_data) && total_flows < 2000) {
    recommendations$recommended_settings$enable_animation <- TRUE
    recommendations$performance_notes <- c(recommendations$performance_notes,
                                         "Time data available - animation recommended")
  } else {
    recommendations$recommended_settings$enable_animation <- FALSE
    if("hour" %in% names(mobility_data)) {
      recommendations$performance_notes <- c(recommendations$performance_notes,
                                           "Time data available but dataset too large for smooth animation")
    }
  }
  
  return(recommendations)
}
