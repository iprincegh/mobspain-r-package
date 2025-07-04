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
      dplyr::group_by(date) %>%
      dplyr::summarise(
        daily_trips = sum(n_trips, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      dplyr::summarise(
        avg_daily_trips = mean(daily_trips, na.rm = TRUE),
        max_daily_trips = max(daily_trips, na.rm = TRUE),
        min_daily_trips = min(daily_trips, na.rm = TRUE),
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
