#' Plot daily mobility patterns
#'
#' @param od_data Mobility matrix
#' @return ggplot object
#' @export
plot_daily_mobility <- function(od_data) {
  daily <- od_data %>%
    dplyr::group_by(date, weekday) %>%
    dplyr::summarise(total_trips = sum(n_trips), .groups = "drop")

  ggplot2::ggplot(daily, ggplot2::aes(x = date, y = total_trips, color = weekday)) +
    ggplot2::geom_line() +
    ggplot2::labs(title = "Daily Mobility Patterns",
                  x = "Date", y = "Total Trips",
                  color = "Day of Week") +
    ggplot2::theme_minimal()
}

#' Create flow map
#'
#' @param od_data Aggregated OD data
#' @param zones Spatial zones
#' @param min_flow Minimum flow to display (default: 100)
#' @return leaflet map
#' @export
create_flow_map <- function(od_data, zones, min_flow = 100) {
  # Extract centroids
  centroids <- sf::st_centroid(zones) %>%
    dplyr::mutate(
      lon = sf::st_coordinates(.)[,1],
      lat = sf::st_coordinates(.)[,2]
    ) %>%
    sf::st_drop_geometry() %>%
    dplyr::select(id, lon, lat)

  # Prepare flow data
  flow_data <- od_data %>%
    dplyr::filter(n_trips >= min_flow) %>%
    dplyr::left_join(centroids, by = c("id_origin" = "id")) %>%
    dplyr::rename(start_lon = lon, start_lat = lat) %>%
    dplyr::left_join(centroids, by = c("id_destination" = "id")) %>%
    dplyr::rename(end_lon = lon, end_lat = lat)

  # Create map
  map <- leaflet::leaflet() %>%
    leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron)

  # Add flow lines
  for(i in 1:nrow(flow_data)) {
    map <- map %>% leaflet::addPolylines(
      lng = c(flow_data$start_lon[i], flow_data$end_lon[i]),
      lat = c(flow_data$start_lat[i], flow_data$end_lat[i]),
      weight = log(flow_data$n_trips[i]) / 3,
      opacity = 0.7,
      color = "#2c7bb6"
    )
  }

  return(map)
}

#' Plot mobility heatmap
#'
#' @param od_data Mobility matrix
#' @param top_n Number of top flows to show (default: 50)
#' @return ggplot object
#' @export
plot_mobility_heatmap <- function(od_data, top_n = 50) {
  # Aggregate and get top flows
  heatmap_data <- od_data %>%
    dplyr::group_by(id_origin, id_destination) %>%
    dplyr::summarise(total_trips = sum(n_trips), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(total_trips)) %>%
    dplyr::slice_head(n = top_n)
  
  ggplot2::ggplot(heatmap_data, ggplot2::aes(x = id_destination, y = id_origin, fill = total_trips)) +
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
  
  p <- ggplot2::ggplot(data, ggplot2::aes(x = distance_km, y = total_trips)) +
    ggplot2::geom_point(alpha = 0.6, color = "steelblue") +
    ggplot2::geom_smooth(method = "lm", se = TRUE, color = "red") +
    ggplot2::labs(
      title = paste("Distance Decay Relationship (", params$model, "model)"),
      subtitle = paste("R² =", round(params$r_squared, 3)),
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
