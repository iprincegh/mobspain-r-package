#' Interactive Dashboard Creation for Spanish Mobility Data
#'
#' This module provides functions to create comprehensive interactive dashboards
#' for Spanish mobility data analysis and visualization.

#' Create interactive mobility dashboard
#'
#' @param mobility_data Data frame with mobility data
#' @param spatial_zones SF object with spatial zones (optional)
#' @param dashboard_type Type of dashboard ("overview", "temporal", "spatial", "comparative")
#' @param title Dashboard title
#' @param theme Dashboard theme ("default", "dark", "light")
#' @param include_filters Whether to include interactive filters
#' @param save_path Path to save dashboard HTML file (optional)
#' @return List with dashboard components or saved file path
#' @export
#' @examples
#' \dontrun{
#' # Create overview dashboard
#' mobility_data <- get_mobility_matrix(dates = c("2022-01-01", "2022-01-07"))
#' dashboard <- create_mobility_dashboard(
#'   mobility_data,
#'   dashboard_type = "overview",
#'   title = "Spanish Mobility Overview"
#' )
#' 
#' # Create spatial dashboard with zones
#' districts <- get_spatial_zones("districts", version = 2)
#' spatial_dashboard <- create_mobility_dashboard(
#'   mobility_data,
#'   districts,
#'   dashboard_type = "spatial",
#'   title = "Spatial Mobility Patterns"
#' )
#' }
create_mobility_dashboard <- function(mobility_data,
                                    spatial_zones = NULL,
                                    dashboard_type = "overview",
                                    title = "Spanish Mobility Dashboard",
                                    theme = "default",
                                    include_filters = TRUE,
                                    save_path = NULL) {
  
  # Validate inputs
  valid_types <- c("overview", "temporal", "spatial", "comparative")
  if(!dashboard_type %in% valid_types) {
    stop(sprintf("Invalid dashboard_type. Must be one of: %s", paste(valid_types, collapse = ", ")))
  }
  
  # Prepare data for dashboard
  dashboard_data <- prepare_dashboard_data(mobility_data, spatial_zones)
  
  # Create dashboard components based on type
  dashboard_components <- switch(dashboard_type,
    "overview" = create_overview_dashboard(dashboard_data, title, theme, include_filters),
    "temporal" = create_temporal_dashboard(dashboard_data, title, theme, include_filters),
    "spatial" = create_spatial_dashboard(dashboard_data, title, theme, include_filters),
    "comparative" = create_comparative_dashboard(dashboard_data, title, theme, include_filters)
  )
  
  # Save dashboard if path provided
  if(!is.null(save_path)) {
    save_dashboard(dashboard_components, save_path)
    message(sprintf("Dashboard saved to: %s", save_path))
    return(invisible(save_path))
  }
  
  return(dashboard_components)
}

#' Prepare data for dashboard components
#'
#' @param mobility_data Data frame with mobility data
#' @param spatial_zones SF object with spatial zones
#' @return List with prepared data components
#' @keywords internal
prepare_dashboard_data <- function(mobility_data, spatial_zones) {
  
  # Basic data validation
  if(nrow(mobility_data) == 0) {
    stop("mobility_data is empty")
  }
  
  # Prepare temporal data
  temporal_data <- prepare_temporal_data(mobility_data)
  
  # Prepare spatial data if zones provided
  spatial_data <- NULL
  if(!is.null(spatial_zones)) {
    spatial_data <- prepare_spatial_data(mobility_data, spatial_zones)
  }
  
  # Calculate summary statistics
  summary_stats <- calculate_dashboard_stats(mobility_data)
  
  # Prepare filter options
  filter_options <- prepare_filter_options(mobility_data)
  
  return(list(
    raw_data = mobility_data,
    temporal_data = temporal_data,
    spatial_data = spatial_data,
    summary_stats = summary_stats,
    filter_options = filter_options
  ))
}

#' Prepare temporal data for dashboard
#'
#' @param mobility_data Data frame with mobility data
#' @return Data frame with temporal aggregations
#' @keywords internal
prepare_temporal_data <- function(mobility_data) {
  
  if(!"date" %in% names(mobility_data)) {
    return(NULL)
  }
  
  if(requireNamespace("dplyr", quietly = TRUE)) {
    temporal_data <- mobility_data %>%
      dplyr::mutate(
        date = as.Date(date),
        weekday = weekdays(date),
        month = format(date, "%Y-%m"),
        week = format(date, "%Y-W%U")
      ) %>%
      dplyr::group_by(date, weekday, month, week) %>%
      dplyr::summarise(
        total_trips = sum(n_trips, na.rm = TRUE),
        avg_distance = mean(trips_total_length_km / n_trips, na.rm = TRUE),
        n_flows = n(),
        .groups = "drop"
      )
  } else {
    # Base R implementation
    mobility_data$date <- as.Date(mobility_data$date)
    mobility_data$weekday <- weekdays(mobility_data$date)
    mobility_data$month <- format(mobility_data$date, "%Y-%m")
    mobility_data$week <- format(mobility_data$date, "%Y-W%U")
    
    temporal_data <- aggregate(
      cbind(n_trips, trips_total_length_km) ~ date + weekday + month + week,
      data = mobility_data,
      FUN = function(x) c(sum = sum(x, na.rm = TRUE), mean = mean(x, na.rm = TRUE))
    )
  }
  
  return(temporal_data)
}

#' Prepare spatial data for dashboard
#'
#' @param mobility_data Data frame with mobility data
#' @param spatial_zones SF object with spatial zones
#' @return SF object with aggregated spatial data
#' @keywords internal
prepare_spatial_data <- function(mobility_data, spatial_zones) {
  
  if(is.null(spatial_zones)) {
    return(NULL)
  }
  
  # Check if we have origin-destination data
  if(all(c("id_origin", "id_destination") %in% names(mobility_data))) {
    # Aggregate by origin
    if(requireNamespace("dplyr", quietly = TRUE)) {
      origin_data <- mobility_data %>%
        dplyr::group_by(id_origin) %>%
        dplyr::summarise(
          outgoing_trips = sum(n_trips, na.rm = TRUE),
          avg_outgoing_distance = mean(trips_total_length_km / n_trips, na.rm = TRUE),
          .groups = "drop"
        )
      
      # Aggregate by destination
      destination_data <- mobility_data %>%
        dplyr::group_by(id_destination) %>%
        dplyr::summarise(
          incoming_trips = sum(n_trips, na.rm = TRUE),
          avg_incoming_distance = mean(trips_total_length_km / n_trips, na.rm = TRUE),
          .groups = "drop"
        )
      
      # Merge with spatial zones
      spatial_data <- spatial_zones %>%
        dplyr::left_join(origin_data, by = c("id" = "id_origin")) %>%
        dplyr::left_join(destination_data, by = c("id" = "id_destination"))
    } else {
      # Base R implementation
      origin_data <- aggregate(
        cbind(n_trips, trips_total_length_km) ~ id_origin,
        data = mobility_data,
        FUN = sum, na.rm = TRUE
      )
      names(origin_data) <- c("id", "outgoing_trips", "outgoing_distance")
      
      destination_data <- aggregate(
        cbind(n_trips, trips_total_length_km) ~ id_destination,
        data = mobility_data,
        FUN = sum, na.rm = TRUE
      )
      names(destination_data) <- c("id", "incoming_trips", "incoming_distance")
      
      spatial_data <- merge(spatial_zones, origin_data, by = "id", all.x = TRUE)
      spatial_data <- merge(spatial_data, destination_data, by = "id", all.x = TRUE)
    }
  } else {
    # Node-level data
    spatial_data <- spatial_zones
  }
  
  return(spatial_data)
}

#' Calculate dashboard summary statistics
#'
#' @param mobility_data Data frame with mobility data
#' @return List with summary statistics
#' @keywords internal
calculate_dashboard_stats <- function(mobility_data) {
  
  stats <- list()
  
  # Basic counts
  stats$total_trips <- sum(mobility_data$n_trips, na.rm = TRUE)
  stats$total_distance <- sum(mobility_data$trips_total_length_km, na.rm = TRUE)
  stats$avg_trip_distance <- stats$total_distance / stats$total_trips
  
  # Date range
  if("date" %in% names(mobility_data)) {
    stats$date_range <- range(as.Date(mobility_data$date), na.rm = TRUE)
    stats$n_days <- as.numeric(diff(stats$date_range)) + 1
  }
  
  # Spatial coverage
  if("id_origin" %in% names(mobility_data)) {
    stats$n_origins <- length(unique(mobility_data$id_origin))
    stats$n_destinations <- length(unique(mobility_data$id_destination))
    stats$n_unique_zones <- length(unique(c(mobility_data$id_origin, mobility_data$id_destination)))
  }
  
  # Temporal patterns
  if("hour" %in% names(mobility_data)) {
    stats$peak_hour <- names(sort(table(mobility_data$hour), decreasing = TRUE))[1]
  }
  
  return(stats)
}

#' Prepare filter options for dashboard
#'
#' @param mobility_data Data frame with mobility data
#' @return List with filter options
#' @keywords internal
prepare_filter_options <- function(mobility_data) {
  
  filters <- list()
  
  # Date filters
  if("date" %in% names(mobility_data)) {
    filters$dates <- sort(unique(as.Date(mobility_data$date)))
  }
  
  # Hour filters
  if("hour" %in% names(mobility_data)) {
    filters$hours <- sort(unique(mobility_data$hour))
  }
  
  # Demographic filters (if available)
  if("age" %in% names(mobility_data)) {
    filters$age_groups <- sort(unique(mobility_data$age))
  }
  
  if("sex" %in% names(mobility_data)) {
    filters$sex <- sort(unique(mobility_data$sex))
  }
  
  if("income" %in% names(mobility_data)) {
    filters$income_groups <- sort(unique(mobility_data$income))
  }
  
  # Distance filters
  if("distance" %in% names(mobility_data)) {
    filters$distance_groups <- sort(unique(mobility_data$distance))
  }
  
  return(filters)
}

#' Create overview dashboard
#'
#' @param dashboard_data Prepared dashboard data
#' @param title Dashboard title
#' @param theme Dashboard theme
#' @param include_filters Whether to include filters
#' @return List with dashboard components
#' @keywords internal
create_overview_dashboard <- function(dashboard_data, title, theme, include_filters) {
  
  components <- list()
  
  # Key metrics cards
  components$metrics <- create_metrics_cards(dashboard_data$summary_stats)
  
  # Temporal trend chart
  if(!is.null(dashboard_data$temporal_data)) {
    components$temporal_trend <- create_temporal_trend_chart(dashboard_data$temporal_data)
  }
  
  # Spatial overview map
  if(!is.null(dashboard_data$spatial_data)) {
    components$spatial_overview <- create_spatial_overview_map(dashboard_data$spatial_data)
  }
  
  # Distribution charts
  components$distributions <- create_distribution_charts(dashboard_data$raw_data)
  
  # Filters
  if(include_filters) {
    components$filters <- create_dashboard_filters(dashboard_data$filter_options)
  }
  
  # Layout
  components$layout <- create_dashboard_layout(components, title, theme)
  
  return(components)
}

#' Create temporal dashboard
#'
#' @param dashboard_data Prepared dashboard data
#' @param title Dashboard title
#' @param theme Dashboard theme
#' @param include_filters Whether to include filters
#' @return List with dashboard components
#' @keywords internal
create_temporal_dashboard <- function(dashboard_data, title, theme, include_filters) {
  
  components <- list()
  
  if(!is.null(dashboard_data$temporal_data)) {
    # Time series plots
    components$time_series <- create_time_series_plots(dashboard_data$temporal_data)
    
    # Seasonal patterns
    components$seasonal <- create_seasonal_pattern_charts(dashboard_data$temporal_data)
    
    # Hourly patterns
    components$hourly <- create_hourly_pattern_charts(dashboard_data$raw_data)
  }
  
  # Filters
  if(include_filters) {
    components$filters <- create_temporal_filters(dashboard_data$filter_options)
  }
  
  # Layout
  components$layout <- create_dashboard_layout(components, title, theme)
  
  return(components)
}

#' Create spatial dashboard
#'
#' @param dashboard_data Prepared dashboard data
#' @param title Dashboard title
#' @param theme Dashboard theme
#' @param include_filters Whether to include filters
#' @return List with dashboard components
#' @keywords internal
create_spatial_dashboard <- function(dashboard_data, title, theme, include_filters) {
  
  components <- list()
  
  if(!is.null(dashboard_data$spatial_data)) {
    # Choropleth maps
    components$choropleth <- create_choropleth_maps(dashboard_data$spatial_data)
    
    # Flow maps
    components$flow_maps <- create_flow_maps(dashboard_data$raw_data, dashboard_data$spatial_data)
    
    # Spatial statistics
    components$spatial_stats <- create_spatial_statistics(dashboard_data$spatial_data)
  }
  
  # Filters
  if(include_filters) {
    components$filters <- create_spatial_filters(dashboard_data$filter_options)
  }
  
  # Layout
  components$layout <- create_dashboard_layout(components, title, theme)
  
  return(components)
}

#' Create comparative dashboard
#'
#' @param dashboard_data Prepared dashboard data
#' @param title Dashboard title
#' @param theme Dashboard theme
#' @param include_filters Whether to include filters
#' @return List with dashboard components
#' @keywords internal
create_comparative_dashboard <- function(dashboard_data, title, theme, include_filters) {
  
  components <- list()
  
  # Comparison charts
  components$comparisons <- create_comparison_charts(dashboard_data$raw_data)
  
  # Ranking tables
  components$rankings <- create_ranking_tables(dashboard_data$spatial_data)
  
  # Filters
  if(include_filters) {
    components$filters <- create_comparison_filters(dashboard_data$filter_options)
  }
  
  # Layout
  components$layout <- create_dashboard_layout(components, title, theme)
  
  return(components)
}

#' Create metrics cards for dashboard
#'
#' @param summary_stats Summary statistics
#' @return List with metrics card components
#' @keywords internal
create_metrics_cards <- function(summary_stats) {
  
  metrics <- list()
  
  # Total trips card
  metrics$total_trips <- list(
    title = "Total Trips",
    value = format(summary_stats$total_trips, big.mark = ","),
    icon = "car",
    color = "primary"
  )
  
  # Average distance card
  metrics$avg_distance <- list(
    title = "Average Distance",
    value = sprintf("%.1f km", summary_stats$avg_trip_distance),
    icon = "road",
    color = "success"
  )
  
  # Date range card
  if(!is.null(summary_stats$date_range)) {
    metrics$date_range <- list(
      title = "Date Range",
      value = sprintf("%d days", summary_stats$n_days),
      icon = "calendar",
      color = "info"
    )
  }
  
  # Spatial coverage card
  if(!is.null(summary_stats$n_unique_zones)) {
    metrics$spatial_coverage <- list(
      title = "Zones Covered",
      value = format(summary_stats$n_unique_zones, big.mark = ","),
      icon = "map",
      color = "warning"
    )
  }
  
  return(metrics)
}

#' Create dashboard layout
#'
#' @param components Dashboard components
#' @param title Dashboard title
#' @param theme Dashboard theme
#' @return HTML layout structure
#' @keywords internal
create_dashboard_layout <- function(components, title, theme) {
  
  # This would typically create an HTML layout
  # For now, return a simple structure
  layout <- list(
    title = title,
    theme = theme,
    components = components,
    structure = "grid-layout"
  )
  
  return(layout)
}

#' Save dashboard to HTML file
#'
#' @param dashboard_components Dashboard components
#' @param save_path Path to save file
#' @keywords internal
save_dashboard <- function(dashboard_components, save_path) {
  
  # This would typically render the dashboard to HTML
  # For now, save as RDS
  saveRDS(dashboard_components, gsub("\\.html$", ".rds", save_path))
  
  message("Dashboard saved (as RDS for now - HTML rendering would require additional dependencies)")
}

#' Create placeholder chart functions
#' These would be implemented with specific plotting libraries
#' @keywords internal

create_temporal_trend_chart <- function(temporal_data) {
  list(type = "line_chart", data = temporal_data, description = "Temporal trend chart")
}

create_spatial_overview_map <- function(spatial_data) {
  list(type = "leaflet_map", data = spatial_data, description = "Spatial overview map")
}

create_distribution_charts <- function(raw_data) {
  list(type = "histogram", data = raw_data, description = "Distribution charts")
}

create_dashboard_filters <- function(filter_options) {
  list(type = "filters", options = filter_options, description = "Interactive filters")
}

create_time_series_plots <- function(temporal_data) {
  list(type = "time_series", data = temporal_data, description = "Time series plots")
}

create_seasonal_pattern_charts <- function(temporal_data) {
  list(type = "seasonal", data = temporal_data, description = "Seasonal patterns")
}

create_hourly_pattern_charts <- function(raw_data) {
  list(type = "hourly", data = raw_data, description = "Hourly patterns")
}

create_choropleth_maps <- function(spatial_data) {
  list(type = "choropleth", data = spatial_data, description = "Choropleth maps")
}

create_flow_maps <- function(raw_data, spatial_data) {
  list(type = "flow_map", data = raw_data, spatial = spatial_data, description = "Flow maps")
}

create_spatial_statistics <- function(spatial_data) {
  list(type = "spatial_stats", data = spatial_data, description = "Spatial statistics")
}

create_comparison_charts <- function(raw_data) {
  list(type = "comparison", data = raw_data, description = "Comparison charts")
}

create_ranking_tables <- function(spatial_data) {
  list(type = "ranking", data = spatial_data, description = "Ranking tables")
}

create_temporal_filters <- function(filter_options) {
  list(type = "temporal_filters", options = filter_options, description = "Temporal filters")
}

create_spatial_filters <- function(filter_options) {
  list(type = "spatial_filters", options = filter_options, description = "Spatial filters")
}

create_comparison_filters <- function(filter_options) {
  list(type = "comparison_filters", options = filter_options, description = "Comparison filters")
}
