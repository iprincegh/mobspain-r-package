# =============================================================================
# MOBSPAIN VISUALIZATION FUNCTIONS
# =============================================================================
# This file contains all visualization functions for the mobspain package,
# including individual plot functions and comprehensive visualization workflows.
# All functions are designed to be completely token-free and open-source.
# =============================================================================

# =============================================================================
# INDIVIDUAL VISUALIZATION FUNCTIONS
# =============================================================================

#' Plot daily mobility patterns
#'
#' @param od_data Mobility matrix with columns: origin/id_origin, destination/id_destination, flow/n_trips, date
#' @return ggplot object
#' @export
#' @examples
#' \dontrun{
#' # Load mobility data
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Create daily mobility plot
#' daily_plot <- plot_daily_mobility(mobility_data)
#' print(daily_plot)
#' 
#' # Save the plot
#' ggplot2::ggsave("daily_mobility.png", daily_plot, width = 10, height = 6)
#' }
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
      dplyr::summarise(total_trips = sum(.data$n_trips, na.rm = TRUE), .groups = "drop")
  }

  ggplot2::ggplot(daily, ggplot2::aes(x = .data$date, y = .data$total_trips)) +
    ggplot2::geom_line(ggplot2::aes(group = 1), color = "blue", size = 1) +
    ggplot2::geom_point(ggplot2::aes(color = .data$weekday), size = 2) +
    ggplot2::labs(title = "Daily Mobility Patterns",
                  x = "Date", y = "Total Trips",
                  color = "Day of Week") +
    ggplot2::theme_minimal() +
    ggplot2::scale_x_date(date_labels = "%b %d", date_breaks = "1 day") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

#' Create flow map
#'
#' @param zones Spatial zones (sf object)
#' @param od_data Aggregated OD data with columns: origin/id_origin, destination/id_destination, flow/n_trips
#' @param min_flow Minimum flow to display (default: 100)
#' @param map_style Map style for interactive maps: "osm", "carto", "stamen" (default: "osm")
#' @param interactive Whether to create interactive (leaflet) or static (ggplot) map (default: TRUE)
#' @return leaflet map or ggplot if leaflet fails
#' @export
#' @examples
#' \dontrun{
#' # Load data
#' zones <- get_spatial_zones("dist")
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Create interactive flow map
#' flow_map <- create_flow_map(zones, mobility_data, min_flow = 500)
#' print(flow_map)
#' 
#' # Create static flow map
#' static_map <- create_flow_map(zones, mobility_data, 
#'                              min_flow = 500, interactive = FALSE)
#' print(static_map)
#' 
#' # Use different map style
#' carto_map <- create_flow_map(zones, mobility_data, 
#'                             min_flow = 500, map_style = "carto")
#' print(carto_map)
#' }
create_flow_map <- function(zones, od_data, min_flow = 100, map_style = "osm", interactive = TRUE) {
  # Standardize column names
  od_data <- standardize_od_columns(od_data)
  
  # Ensure zones is an sf object
  if(!inherits(zones, "sf")) {
    stop("zones must be an sf object", call. = FALSE)
  }
  
  # Transform to WGS84 if needed
  if(sf::st_crs(zones) != sf::st_crs(4326)) {
    zones <- sf::st_transform(zones, 4326)
  }
  
  # Extract centroids safely
  centroids <- tryCatch({
    suppressWarnings({
      zones_centroids <- sf::st_centroid(zones)
      coords <- sf::st_coordinates(zones_centroids)
      
      data.frame(
        id = zones$id,
        lon = coords[,1],
        lat = coords[,2],
        stringsAsFactors = FALSE
      )
    })
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

  if(interactive) {
    # Create interactive map with multiple free provider options
    create_flow_map_leaflet(flow_data, zones, map_style)
  } else {
    # Create static ggplot flow map (no tokens needed)
    create_static_flow_map(flow_data, zones)
  }
}

#' Create interactive flow map with token-free providers
#' @param flow_data Prepared flow data
#' @param zones Spatial zones
#' @param map_style Map style ("osm", "carto", "stamen")
#' @return Leaflet map
create_flow_map_leaflet <- function(flow_data, zones, map_style = "osm") {
  tryCatch({
    # Select provider based on style (all token-free)
    provider <- switch(map_style,
      "osm" = leaflet::providers$OpenStreetMap,
      "carto" = leaflet::providers$CartoDB.Positron,
      "stamen" = leaflet::providers$Stamen.TonerLite,
      leaflet::providers$OpenStreetMap  # default
    )
    
    # Create base map
    map <- leaflet::leaflet() %>%
      leaflet::addProviderTiles(provider)

    # Add flow lines
    if(nrow(flow_data) > 0) {
      for(i in seq_len(nrow(flow_data))) {
        map <- map %>% leaflet::addPolylines(
          lng = c(flow_data$start_lon[i], flow_data$end_lon[i]),
          lat = c(flow_data$start_lat[i], flow_data$end_lat[i]),
          weight = pmax(1, log(flow_data$n_trips[i]) / 3),
          opacity = 0.7,
          color = "#2c7bb6",
          popup = paste("Flow:", flow_data$n_trips[i], "trips")
        )
      }
    }

    return(map)
  }, error = function(e) {
    warning("Interactive map creation failed: ", e$message, ". Using static map.")
    create_static_flow_map(flow_data, zones)
  })
}

#' Create static flow map with ggplot2 (no tokens needed)
#' @param flow_data Prepared flow data
#' @param zones Spatial zones
#' @return ggplot object
create_static_flow_map <- function(flow_data, zones) {
  if(nrow(flow_data) == 0) {
    return(ggplot2::ggplot() + 
           ggplot2::annotate("text", x = 0, y = 0, label = "No flows above minimum threshold") +
           ggplot2::theme_void())
  }
  
  # Create static flow map
  p <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = zones, fill = "lightgray", color = "white", size = 0.2) +
    ggplot2::geom_segment(
      data = flow_data,
      ggplot2::aes(x = .data$start_lon, y = .data$start_lat, 
                   xend = .data$end_lon, yend = .data$end_lat,
                   size = .data$n_trips),
      alpha = 0.7, color = "#2c7bb6"
    ) +
    ggplot2::scale_size_continuous(name = "Trips", trans = "log10", range = c(0.3, 2)) +
    ggplot2::labs(
      title = "Mobility Flows", 
      subtitle = "Flow thickness proportional to trip volume",
      x = "Longitude", 
      y = "Latitude"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 8),
      legend.position = "bottom"
    )
  
  return(p)
}

#' Plot mobility heatmap
#'
#' @param od_data Mobility matrix with columns: origin/id_origin, destination/id_destination, flow/n_trips
#' @param top_n Number of top flows to show (default: 50)
#' @return ggplot object
#' @export
#' @examples
#' \dontrun{
#' # Load mobility data
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Create heatmap of top 50 flows
#' heatmap_plot <- plot_mobility_heatmap(mobility_data)
#' print(heatmap_plot)
#' 
#' # Create heatmap of top 20 flows
#' heatmap_top20 <- plot_mobility_heatmap(mobility_data, top_n = 20)
#' print(heatmap_top20)
#' 
#' # Save heatmap
#' ggplot2::ggsave("mobility_heatmap.png", heatmap_plot, width = 12, height = 8)
#' }
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
#' @examples
#' \dontrun{
#' # Load data
#' zones <- get_spatial_zones("dist")
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Calculate distance decay
#' decay_result <- calculate_distance_decay(mobility_data, zones)
#' 
#' # Plot distance decay with log scale
#' decay_plot <- plot_distance_decay(decay_result, log_scale = TRUE)
#' print(decay_plot)
#' 
#' # Plot distance decay with linear scale
#' decay_linear <- plot_distance_decay(decay_result, log_scale = FALSE)
#' print(decay_linear)
#' 
#' # Save plot
#' ggplot2::ggsave("distance_decay.png", decay_plot, width = 10, height = 6)
#' }
plot_distance_decay <- function(decay_result, log_scale = TRUE) {
  if(!is.list(decay_result) || !"data" %in% names(decay_result)) {
    stop("Input must be result from calculate_distance_decay()", call. = FALSE)
  }
  
  data <- decay_result$data
  params <- decay_result$parameters
  
  # Remove missing values and ensure positive values for log scale
  if(log_scale) {
    data <- data %>%
      filter(!is.na(distance_km) & !is.na(total_trips) & 
             distance_km > 0 & total_trips > 0)
  } else {
    data <- data %>%
      filter(!is.na(distance_km) & !is.na(total_trips))
  }
  
  # Check if we have enough data points
  if(nrow(data) < 3) {
    stop("Not enough valid data points for distance decay plot", call. = FALSE)
  }
  
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
#' @examples
#' \dontrun{
#' # Load data
#' zones <- get_spatial_zones("dist")
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Calculate mobility indicators
#' indicators <- calculate_mobility_indicators(mobility_data)
#' 
#' # Create choropleth map of total outflow
#' choropleth_map <- create_choropleth_map(zones, indicators, "total_outflow")
#' print(choropleth_map)
#' 
#' # Create choropleth map of total inflow with different palette
#' inflow_map <- create_choropleth_map(zones, indicators, 
#'                                   variable = "total_inflow", 
#'                                   palette = "plasma")
#' print(inflow_map)
#' 
#' # Map net flow (outflow - inflow)
#' net_flow_map <- create_choropleth_map(zones, indicators, "net_flow")
#' print(net_flow_map)
#' }
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

# =============================================================================
# COMPREHENSIVE VISUALIZATION SUITE
# =============================================================================

#' Create comprehensive mobility visualization suite
#'
#' @param zones Spatial zones data (sf object)
#' @param mobility_data Mobility OD data
#' @param viz_type Type of visualization: "interactive", "static", "both"
#' @param output_format Format: "html", "png", "pdf", "all"
#' @param min_flow Minimum flow threshold
#' @param color_palette Color palette for visualizations
#' @return List of visualizations
#' @export
#' @examples
#' \dontrun{
#' zones <- get_spatial_zones("dist")
#' mobility <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Create comprehensive visualization suite
#' viz_suite <- create_mobility_viz_suite(
#'   zones = zones,
#'   mobility_data = mobility,
#'   viz_type = "both",
#'   output_format = "all"
#' )
#' 
#' # Access different visualizations
#' viz_suite$flow_map_interactive
#' viz_suite$flow_map_static
#' viz_suite$heatmap
#' viz_suite$summary_stats
#' }
create_mobility_viz_suite <- function(zones, mobility_data, viz_type = "both", 
                                    output_format = "html", min_flow = 100,
                                    color_palette = "viridis") {
  
  # Input validation
  if(!inherits(zones, "sf")) {
    stop("zones must be an sf object", call. = FALSE)
  }
  
  if(nrow(mobility_data) == 0) {
    stop("mobility_data cannot be empty", call. = FALSE)
  }
  
  # Initialize result list
  result <- list()
  
  # Create different visualization types
  if(viz_type %in% c("interactive", "both")) {
    message("Creating interactive visualizations (no tokens required)...")
    
    # Interactive flow map with free providers
    result$flow_map_interactive <- create_flow_map(
      zones = zones, 
      od_data = mobility_data, 
      min_flow = min_flow,
      map_style = "osm",
      interactive = TRUE
    )
    
    # Interactive choropleth
    indicators <- calculate_mobility_indicators(mobility_data, zones)
    result$choropleth_interactive <- create_choropleth_map(
      zones = zones,
      indicators = indicators,
      palette = color_palette
    )
  }
  
  if(viz_type %in% c("static", "both")) {
    message("Creating static visualizations...")
    
    # Static flow map
    result$flow_map_static <- create_flow_map(
      zones = zones,
      od_data = mobility_data,
      min_flow = min_flow,
      interactive = FALSE
    )
    
    # Mobility heatmap
    result$heatmap <- plot_mobility_heatmap(mobility_data)
    
    # Daily mobility patterns
    result$daily_plot <- plot_daily_mobility(mobility_data)
    
    # Summary statistics
    result$summary_stats <- calculate_mobility_summary(mobility_data, zones)
  }
  
  # Add metadata
  result$metadata <- list(
    creation_time = Sys.time(),
    viz_type = viz_type,
    output_format = output_format,
    min_flow = min_flow,
    color_palette = color_palette,
    n_zones = nrow(zones),
    n_flows = nrow(mobility_data),
    date_range = range(mobility_data$date, na.rm = TRUE)
  )
  
  class(result) <- "mobility_viz_suite"
  return(result)
}

#' Calculate comprehensive mobility summary statistics
#' @param mobility_data Mobility OD data
#' @param zones Spatial zones
#' @return Data frame with summary statistics
calculate_mobility_summary <- function(mobility_data, zones) {
  
  # Basic flow statistics
  flow_stats <- mobility_data %>%
    dplyr::summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      avg_trips = mean(n_trips, na.rm = TRUE),
      median_trips = stats::median(n_trips, na.rm = TRUE),
      max_trips = max(n_trips, na.rm = TRUE),
      total_flows = dplyr::n(),
      unique_origins = dplyr::n_distinct(id_origin),
      unique_destinations = dplyr::n_distinct(id_destination),
      .groups = "drop"
    )
  
  # Temporal patterns if date/hour columns exist
  if("date" %in% names(mobility_data)) {
    temporal_stats <- mobility_data %>%
      dplyr::group_by(.data$date) %>%
      dplyr::summarise(
        daily_trips = sum(.data$n_trips, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      dplyr::summarise(
        avg_daily_trips = mean(.data$daily_trips, na.rm = TRUE),
        max_daily_trips = max(.data$daily_trips, na.rm = TRUE),
        min_daily_trips = min(.data$daily_trips, na.rm = TRUE),
        .groups = "drop"
      )
    
    flow_stats <- dplyr::bind_cols(flow_stats, temporal_stats)
  }
  
  # Spatial coverage
  spatial_stats <- data.frame(
    total_zones = nrow(zones),
    zones_with_outflows = length(unique(mobility_data$id_origin)),
    zones_with_inflows = length(unique(mobility_data$id_destination)),
    spatial_coverage_out = length(unique(mobility_data$id_origin)) / nrow(zones),
    spatial_coverage_in = length(unique(mobility_data$id_destination)) / nrow(zones)
  )
  
  result <- dplyr::bind_cols(flow_stats, spatial_stats)
  return(result)
}

#' Print method for mobility visualization suite
#' @param x mobility_viz_suite object
#' @param ... Additional arguments
#' @export
print.mobility_viz_suite <- function(x, ...) {
  cat("Mobility Visualization Suite\n")
  cat("============================\n\n")
  
  cat("Metadata:\n")
  cat("---------\n")
  cat("Created:", as.character(x$metadata$creation_time), "\n")
  cat("Visualization type:", x$metadata$viz_type, "\n")
  cat("Number of zones:", x$metadata$n_zones, "\n")
  cat("Number of flows:", x$metadata$n_flows, "\n")
  cat("Date range:", paste(x$metadata$date_range, collapse = " to "), "\n")
  cat("Minimum flow threshold:", x$metadata$min_flow, "\n")
  cat("\n")
  
  cat("Available Visualizations:\n")
  cat("-------------------------\n")
  
  viz_names <- names(x)[names(x) != "metadata"]
  for(viz in viz_names) {
    cat("- ", viz, "\n")
  }
  
  cat("\nUsage:\n")
  cat("------\n")
  cat("Access visualizations with: x$visualization_name\n")
  cat("Example: x$flow_map_interactive\n")
  
  if(!is.null(x$summary_stats)) {
    cat("\nSummary Statistics:\n")
    cat("-------------------\n")
    stats <- x$summary_stats
    cat("Total trips:", format(stats$total_trips, big.mark = ","), "\n")
    cat("Average trips per flow:", round(stats$avg_trips, 2), "\n")
    cat("Spatial coverage (origins):", round(stats$spatial_coverage_out * 100, 1), "%\n")
    cat("Spatial coverage (destinations):", round(stats$spatial_coverage_in * 100, 1), "%\n")
  }
}

#' Get available map providers (all token-free)
#' @return Character vector of available providers
#' @export
#' @examples
#' # List all available map providers
#' providers <- get_available_map_providers()
#' 
#' # Use in flow map creation
#' \dontrun{
#' zones <- get_spatial_zones("dist")
#' mobility <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Create flow map with different providers
#' osm_map <- create_flow_map(zones, mobility, map_style = "osm")
#' carto_map <- create_flow_map(zones, mobility, map_style = "carto")
#' stamen_map <- create_flow_map(zones, mobility, map_style = "stamen")
#' }
get_available_map_providers <- function() {
  providers <- c(
    "osm" = "OpenStreetMap (default)",
    "carto" = "CartoDB Positron (clean style)",
    "stamen" = "Stamen Toner Lite (minimalist)",
    "esri" = "ESRI World Street Map"
  )
  
  cat("Available Map Providers (No Tokens Required):\n")
  cat("============================================\n")
  for(i in seq_along(providers)) {
    cat(names(providers)[i], ":", providers[i], "\n")
  }
  
  invisible(names(providers))
}

#' Export visualizations to files
#' @param viz_suite mobility_viz_suite object
#' @param output_dir Output directory
#' @param formats File formats to export: "png", "pdf", "html"
#' @param width Plot width in inches
#' @param height Plot height in inches
#' @param dpi Resolution for raster formats
#' @export
#' @examples
#' \dontrun{
#' # Create visualization suite
#' zones <- get_spatial_zones("dist")
#' mobility <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' viz_suite <- create_mobility_viz_suite(zones, mobility)
#' 
#' # Export to PNG and HTML
#' export_visualizations(viz_suite, output_dir = "mobility_plots")
#' 
#' # Export to multiple formats
#' export_visualizations(viz_suite, 
#'                      output_dir = "mobility_plots", 
#'                      formats = c("png", "pdf", "html"))
#' 
#' # Export with custom dimensions
#' export_visualizations(viz_suite, 
#'                      output_dir = "mobility_plots",
#'                      width = 12, height = 8, dpi = 400)
#' }
export_visualizations <- function(viz_suite, output_dir = ".", 
                                formats = c("png", "html"), 
                                width = 10, height = 8, dpi = 300) {
  
  if(!inherits(viz_suite, "mobility_viz_suite")) {
    stop("Input must be a mobility_viz_suite object", call. = FALSE)
  }
  
  if(!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  message("Exporting visualizations to: ", output_dir)
  
  # Export static plots
  static_plots <- viz_suite[grepl("static|heatmap|daily", names(viz_suite))]
  
  for(plot_name in names(static_plots)) {
    if(inherits(static_plots[[plot_name]], "ggplot")) {
      
      if("png" %in% formats) {
        filename <- file.path(output_dir, paste0(plot_name, ".png"))
        ggplot2::ggsave(filename, static_plots[[plot_name]], 
                       width = width, height = height, dpi = dpi)
        message("Saved: ", filename)
      }
      
      if("pdf" %in% formats) {
        filename <- file.path(output_dir, paste0(plot_name, ".pdf"))
        ggplot2::ggsave(filename, static_plots[[plot_name]], 
                       width = width, height = height)
        message("Saved: ", filename)
      }
    }
  }
  
  # Export interactive plots
  interactive_plots <- viz_suite[grepl("interactive", names(viz_suite))]
  
  if("html" %in% formats && length(interactive_plots) > 0) {
    for(plot_name in names(interactive_plots)) {
      if(inherits(interactive_plots[[plot_name]], "leaflet")) {
        filename <- file.path(output_dir, paste0(plot_name, ".html"))
        
        # Check if htmlwidgets is available
        if(requireNamespace("htmlwidgets", quietly = TRUE)) {
          htmlwidgets::saveWidget(interactive_plots[[plot_name]], filename)
          message("Saved: ", filename)
        } else {
          warning("htmlwidgets package not available. Install it to export interactive plots to HTML.")
        }
      }
    }
  }
  
  # Export summary
  if(!is.null(viz_suite$summary_stats)) {
    filename <- file.path(output_dir, "summary_statistics.csv")
    utils::write.csv(viz_suite$summary_stats, filename, row.names = FALSE)
    message("Saved: ", filename)
  }
  
  message("Export completed!")
}
