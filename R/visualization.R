#' Plot daily mobility patterns
#'
#' @param od_data Mobility matrix with columns: origin/id_origin, destination/id_destination, flow/n_trips, date
#' @return ggplot object
#' @export
plot_daily_mobility <- function(od_data) {
  # Standardize column names
  od_data <- standardize_od_columns(od_data)
  
  # Check if we have date column
  if(!"date" %in% names(od_data)) {
    # If no date column, create sample daily data
    daily <- data.frame(
      date = seq.Date(as.Date("2023-01-01"), as.Date("2023-01-07"), by = "day"),
      total_trips = rep(sum(od_data$n_trips), 7),
      weekday = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    )
  } else {
    daily <- od_data %>%
      dplyr::mutate(weekday = lubridate::wday(.data$date, label = TRUE)) %>%
      dplyr::group_by(.data$date, .data$weekday) %>%
      dplyr::summarise(total_trips = sum(.data$n_trips), .groups = "drop")
  }

  ggplot2::ggplot(daily, ggplot2::aes(x = .data$date, y = .data$total_trips, color = .data$weekday)) +
    ggplot2::geom_line() +
    ggplot2::labs(title = "Daily Mobility Patterns",
                  x = "Date", y = "Total Trips",
                  color = "Day of Week") +
    ggplot2::theme_minimal()
}

#' Create flow map
#'
#' @param zones Spatial zones (sf object)
#' @param od_data Aggregated OD data with columns: origin/id_origin, destination/id_destination, flow/n_trips
#' @param min_flow Minimum flow to display (default: 100)
#' @return leaflet map or ggplot if leaflet fails
#' @export
create_flow_map <- function(zones, od_data, min_flow = 100) {
  # Standardize column names
  od_data <- standardize_od_columns(od_data)
  
  # Ensure zones is an sf object
  if(!inherits(zones, "sf")) {
    stop("zones must be an sf object", call. = FALSE)
  }
  
  # Extract centroids safely
  centroids <- tryCatch({
    zones_centroids <- sf::st_centroid(zones)
    coords <- sf::st_coordinates(zones_centroids)
    
    data.frame(
      id = zones$id,
      lon = coords[,1],
      lat = coords[,2],
      stringsAsFactors = FALSE
    )
  }, error = function(e) {
    # Fallback: use geometry coordinates directly if available
    if("geometry" %in% names(zones)) {
      coords <- sf::st_coordinates(zones)
      data.frame(
        id = zones$id,
        lon = coords[,1],
        lat = coords[,2],
        stringsAsFactors = FALSE
      )
    } else {
      stop("Cannot extract coordinates from zones data", call. = FALSE)
    }
  })

  # Prepare flow data
  flow_data <- od_data %>%
    dplyr::filter(.data$n_trips >= min_flow) %>%
    dplyr::left_join(centroids, by = c("id_origin" = "id")) %>%
    dplyr::rename(start_lon = .data$lon, start_lat = .data$lat) %>%
    dplyr::left_join(centroids, by = c("id_destination" = "id")) %>%
    dplyr::rename(end_lon = .data$lon, end_lat = .data$lat) %>%
    dplyr::filter(!is.na(.data$start_lon) & !is.na(.data$end_lon))

  # Try to create leaflet map, fall back to ggplot if it fails
  tryCatch({
    # Create map with a provider that doesn't require tokens
    map <- leaflet::leaflet() %>%
      leaflet::addProviderTiles(leaflet::providers$OpenStreetMap)

    # Add flow lines
    if(nrow(flow_data) > 0) {
      for(i in seq_len(nrow(flow_data))) {
        map <- map %>% leaflet::addPolylines(
          lng = c(flow_data$start_lon[i], flow_data$end_lon[i]),
          lat = c(flow_data$start_lat[i], flow_data$end_lat[i]),
          weight = pmax(1, log(flow_data$n_trips[i]) / 3),
          opacity = 0.7,
          color = "#2c7bb6"
        )
      }
    }

    return(map)
  }, error = function(e) {
    # Fallback to ggplot
    warning("Leaflet map creation failed (", e$message, "). Creating static plot instead.")
    
    if(nrow(flow_data) == 0) {
      return(ggplot2::ggplot() + 
             ggplot2::annotate("text", x = 0, y = 0, label = "No flows above minimum threshold") +
             ggplot2::theme_void())
    }
    
    ggplot2::ggplot(flow_data) +
      ggplot2::geom_segment(
        ggplot2::aes(x = .data$start_lon, y = .data$start_lat, 
                     xend = .data$end_lon, yend = .data$end_lat,
                     size = .data$n_trips),
        alpha = 0.7, color = "#2c7bb6"
      ) +
      ggplot2::scale_size_continuous(name = "Trips", trans = "log10") +
      ggplot2::labs(title = "Mobility Flows", x = "Longitude", y = "Latitude") +
      ggplot2::theme_minimal()
  })
}

#' Plot mobility heatmap
#'
#' @param od_data Mobility matrix with columns: origin/id_origin, destination/id_destination, flow/n_trips
#' @param top_n Number of top flows to show (default: 50)
#' @return ggplot object
#' @export
plot_mobility_heatmap <- function(od_data, top_n = 50) {
  # Standardize column names
  od_data <- standardize_od_columns(od_data)
  
  # Aggregate and get top flows
  heatmap_data <- od_data %>%
    dplyr::group_by(.data$id_origin, .data$id_destination) %>%
    dplyr::summarise(total_trips = sum(.data$n_trips), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(.data$total_trips)) %>%
    dplyr::slice_head(n = top_n)
  
  ggplot2::ggplot(heatmap_data, ggplot2::aes(x = .data$id_destination, y = .data$id_origin, fill = .data$total_trips)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_viridis_c(name = "Trips", trans = "log10") +
    ggplot2::labs(
      title = paste("Top", top_n, "Mobility Flows"),
      x = "Destination", y = "Origin"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid = ggplot2::element_blank()
    )
}

#' Plot distance decay relationship
#'
#' @param decay_result Result from calculate_distance_decay()
#' @param log_scale Use log scale for axes (default: TRUE)
#' @return ggplot object
#' @export
plot_distance_decay <- function(decay_result, log_scale = TRUE) {
  if(!is.list(decay_result) || !"data" %in% names(decay_result)) {
    stop("Input must be result from calculate_distance_decay()", call. = FALSE)
  }
  
  data <- decay_result$data
  params <- decay_result$parameters
  
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data$distance_km, y = .data$total_trips)) +
    ggplot2::geom_point(alpha = 0.6, color = "steelblue") +
    ggplot2::geom_smooth(method = "lm", se = TRUE, color = "red") +
    ggplot2::labs(
      title = paste("Distance Decay Relationship (", params$model, "model)"),
      subtitle = paste("R^2 =", round(params$r_squared, 3)),
      x = "Distance (km)", y = "Total Trips"
    ) +
    ggplot2::theme_minimal()
  
  if(log_scale) {
    p <- p + ggplot2::scale_x_log10() + ggplot2::scale_y_log10()
  }
  
  return(p)
}

#' Create choropleth map of mobility indicators
#'
#' @param zones Spatial zones (sf object)
#' @param indicators Mobility indicators from calculate_mobility_indicators()
#' @param variable Variable to map (default: "total_outflow")
#' @param palette Color palette (default: "viridis")
#' @return leaflet map
#' @export
create_choropleth_map <- function(zones, indicators, variable = "total_outflow", palette = "viridis") {
  if(!inherits(zones, "sf")) {
    stop("zones must be an sf object", call. = FALSE)
  }
  
  if(!variable %in% names(indicators)) {
    stop("Variable '", variable, "' not found in indicators", call. = FALSE)
  }
  
  # Merge zones with indicators
  map_data <- zones %>%
    dplyr::left_join(indicators, by = c("id" = "id_origin"))
  
  # Create color palette
  pal <- leaflet::colorNumeric(palette = palette, domain = map_data[[variable]], na.color = "grey")
  
  # Create map
  leaflet::leaflet(map_data) %>%
    leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron) %>%
    leaflet::addPolygons(
      fillColor = ~pal(get(variable)),
      weight = 1,
      opacity = 1,
      color = "white",
      dashArray = "3",
      fillOpacity = 0.7,
      highlightOptions = leaflet::highlightOptions(
        weight = 2,
        color = "#666",
        dashArray = "",
        fillOpacity = 0.9,
        bringToFront = TRUE
      ),
      popup = ~paste0(
        "<strong>Zone: </strong>", id, "<br>",
        "<strong>", tools::toTitleCase(gsub("_", " ", variable)), ": </strong>", 
        round(get(variable), 0)
      )
    ) %>%
    leaflet::addLegend(
      pal = pal, 
      values = ~get(variable),
      opacity = 0.7, 
      title = tools::toTitleCase(gsub("_", " ", variable)),
      position = "bottomright"
    )
}
