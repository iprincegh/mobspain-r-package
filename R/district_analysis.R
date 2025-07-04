#' Analyze and visualize mobility patterns for a specific district
#'
#' @param district_id Character or numeric ID of the district to analyze
#' @param dates Date range for analysis (character vector)
#' @param zones Spatial zones data (sf object). If NULL, will load automatically
#' @param mobility_data Mobility data. If NULL, will load automatically
#' @param time_range Hour range to analyze (e.g., c(7, 9) for morning rush)
#' @param plot_type Type of visualization: "all", "heatmap", "flows", "timeseries"
#' @param top_n Number of top flows to show (default: 10)
#' @return List containing plots and summary statistics
#' @export
#' @examples
#' \dontrun{
#' # Analyze district mobility patterns
#' result <- analyze_district_mobility(
#'   district_id = "28079",
#'   dates = c("2023-01-01", "2023-01-07"),
#'   time_range = c(7, 9),
#'   plot_type = "all"
#' )
#' 
#' # View the plots
#' result$heatmap
#' result$flow_plot
#' result$timeseries_plot
#' }
analyze_district_mobility <- function(district_id, dates, zones = NULL, mobility_data = NULL, 
                                    time_range = NULL, plot_type = "all", top_n = 10) {
  
  # Input validation
  if(missing(district_id) || is.null(district_id)) {
    stop("district_id is required", call. = FALSE)
  }
  
  if(missing(dates) || is.null(dates)) {
    stop("dates is required", call. = FALSE)
  }
  
  # Convert district_id to character for consistency
  district_id <- as.character(district_id)
  
  # Load zones if not provided
  if(is.null(zones)) {
    message("Loading spatial zones...")
    zones <- get_spatial_zones("dist")
  }
  
  # Validate district exists
  if(!district_id %in% zones$id) {
    stop("District ID '", district_id, "' not found in zones data", call. = FALSE)
  }
  
  # Load mobility data if not provided
  if(is.null(mobility_data)) {
    message("Loading mobility data...")
    mobility_data <- get_mobility_matrix(dates = dates, level = "dist")
  }
  
  # Filter mobility data for the specific district
  district_flows <- mobility_data %>%
    dplyr::filter(id_origin == district_id | id_destination == district_id)
  
  # Apply time filter if specified
  if(!is.null(time_range)) {
    district_flows <- district_flows %>%
      dplyr::filter(hour >= time_range[1] & hour <= time_range[2])
  }
  
  # Get district name for titles
  district_name <- zones$name[zones$id == district_id][1]
  if(is.na(district_name)) district_name <- paste("District", district_id)
  
  # Create result list
  result <- list(
    district_id = district_id,
    district_name = district_name,
    date_range = dates,
    time_range = time_range,
    summary_stats = calculate_district_summary(district_flows, district_id)
  )
  
  # Generate requested plots
  if(plot_type %in% c("all", "heatmap")) {
    result$heatmap <- create_district_heatmap(district_flows, district_id, district_name, time_range)
  }
  
  if(plot_type %in% c("all", "flows")) {
    result$flow_plot <- create_district_flow_plot(district_flows, zones, district_id, district_name, top_n)
  }
  
  if(plot_type %in% c("all", "timeseries")) {
    result$timeseries_plot <- create_district_timeseries(district_flows, district_id, district_name)
  }
  
  # Add interactive map if requested
  if(plot_type %in% c("all", "map")) {
    result$interactive_map <- create_district_flow_map(district_flows, zones, district_id, district_name, top_n)
  }
  
  class(result) <- "district_analysis"
  return(result)
}

#' Calculate summary statistics for a district
#' @param district_flows Filtered mobility data for the district
#' @param district_id District ID
#' @return Data frame with summary statistics
calculate_district_summary <- function(district_flows, district_id) {
  
  # Outbound flows (from district)
  outbound <- district_flows %>%
    dplyr::filter(id_origin == district_id) %>%
    dplyr::summarise(
      total_outbound = sum(n_trips, na.rm = TRUE),
      avg_outbound = mean(n_trips, na.rm = TRUE),
      unique_destinations = dplyr::n_distinct(id_destination),
      .groups = "drop"
    )
  
  # Inbound flows (to district)
  inbound <- district_flows %>%
    dplyr::filter(id_destination == district_id) %>%
    dplyr::summarise(
      total_inbound = sum(n_trips, na.rm = TRUE),
      avg_inbound = mean(n_trips, na.rm = TRUE),
      unique_origins = dplyr::n_distinct(id_origin),
      .groups = "drop"
    )
  
  # Internal flows (within district)
  internal <- district_flows %>%
    dplyr::filter(id_origin == district_id & id_destination == district_id) %>%
    dplyr::summarise(
      total_internal = sum(n_trips, na.rm = TRUE),
      avg_internal = mean(n_trips, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Combine statistics
  summary_stats <- data.frame(
    district_id = district_id,
    total_outbound = ifelse(nrow(outbound) > 0, outbound$total_outbound, 0),
    avg_outbound = ifelse(nrow(outbound) > 0, outbound$avg_outbound, 0),
    unique_destinations = ifelse(nrow(outbound) > 0, outbound$unique_destinations, 0),
    total_inbound = ifelse(nrow(inbound) > 0, inbound$total_inbound, 0),
    avg_inbound = ifelse(nrow(inbound) > 0, inbound$avg_inbound, 0),
    unique_origins = ifelse(nrow(inbound) > 0, inbound$unique_origins, 0),
    total_internal = ifelse(nrow(internal) > 0, internal$total_internal, 0),
    avg_internal = ifelse(nrow(internal) > 0, internal$avg_internal, 0),
    net_flow = ifelse(nrow(inbound) > 0 && nrow(outbound) > 0, 
                      inbound$total_inbound - outbound$total_outbound, 0)
  )
  
  return(summary_stats)
}

#' Create heatmap visualization for district mobility
#' @param district_flows Filtered mobility data
#' @param district_id District ID
#' @param district_name District name
#' @param time_range Time range for title
#' @return ggplot object
create_district_heatmap <- function(district_flows, district_id, district_name, time_range) {
  
  # Prepare data for heatmap
  heatmap_data <- district_flows %>%
    dplyr::mutate(
      flow_type = dplyr::case_when(
        id_origin == district_id & id_destination == district_id ~ "Internal",
        id_origin == district_id ~ "Outbound",
        id_destination == district_id ~ "Inbound",
        TRUE ~ "Other"
      ),
      date = as.Date(date),
      weekday = lubridate::wday(date, label = TRUE)
    ) %>%
    dplyr::group_by(date, hour, flow_type) %>%
    dplyr::summarise(total_trips = sum(n_trips, na.rm = TRUE), .groups = "drop")
  
  # Create time range label
  time_label <- if(!is.null(time_range)) {
    paste0(" (Hours ", time_range[1], "-", time_range[2], ")")
  } else {
    ""
  }
  
  # Create heatmap
  p <- ggplot2::ggplot(heatmap_data, ggplot2::aes(x = hour, y = date, fill = total_trips)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_gradient(low = "lightblue", high = "darkred", name = "Trips") +
    ggplot2::facet_wrap(~flow_type, scales = "free") +
    ggplot2::labs(
      title = paste("Mobility Heatmap:", district_name, time_label),
      subtitle = paste("District ID:", district_id),
      x = "Hour of Day",
      y = "Date"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      strip.text = ggplot2::element_text(face = "bold")
    )
  
  return(p)
}

#' Create flow plot showing top destinations/origins
#' @param district_flows Filtered mobility data
#' @param zones Spatial zones data
#' @param district_id District ID
#' @param district_name District name
#' @param top_n Number of top flows to show
#' @return ggplot object
create_district_flow_plot <- function(district_flows, zones, district_id, district_name, top_n) {
  
  # Get top outbound destinations
  top_outbound <- district_flows %>%
    dplyr::filter(id_origin == district_id, id_destination != district_id) %>%
    dplyr::group_by(id_destination) %>%
    dplyr::summarise(total_trips = sum(n_trips, na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(desc(total_trips)) %>%
    dplyr::slice_head(n = top_n) %>%
    dplyr::left_join(zones %>% sf::st_drop_geometry() %>% dplyr::select(id, name), 
                     by = c("id_destination" = "id")) %>%
    dplyr::mutate(
      flow_type = "Outbound",
      destination_name = ifelse(is.na(name), id_destination, name)
    )
  
  # Get top inbound origins
  top_inbound <- district_flows %>%
    dplyr::filter(id_destination == district_id, id_origin != district_id) %>%
    dplyr::group_by(id_origin) %>%
    dplyr::summarise(total_trips = sum(n_trips, na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(desc(total_trips)) %>%
    dplyr::slice_head(n = top_n) %>%
    dplyr::left_join(zones %>% sf::st_drop_geometry() %>% dplyr::select(id, name), 
                     by = c("id_origin" = "id")) %>%
    dplyr::mutate(
      flow_type = "Inbound",
      destination_name = ifelse(is.na(name), id_origin, name)
    )
  
  # Combine data
  flow_data <- dplyr::bind_rows(
    top_outbound %>% dplyr::select(destination_name, total_trips, flow_type),
    top_inbound %>% dplyr::select(destination_name, total_trips, flow_type)
  )
  
  # Create flow plot
  p <- ggplot2::ggplot(flow_data, ggplot2::aes(x = reorder(destination_name, total_trips), 
                                              y = total_trips, fill = flow_type)) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::facet_wrap(~flow_type, scales = "free") +
    ggplot2::labs(
      title = paste("Top", top_n, "Mobility Flows:", district_name),
      subtitle = paste("District ID:", district_id),
      x = "Destination/Origin",
      y = "Total Trips",
      fill = "Flow Type"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "none",
      strip.text = ggplot2::element_text(face = "bold")
    )
  
  return(p)
}

#' Create time series plot for district mobility
#' @param district_flows Filtered mobility data
#' @param district_id District ID
#' @param district_name District name
#' @return ggplot object
create_district_timeseries <- function(district_flows, district_id, district_name) {
  
  # Prepare time series data
  ts_data <- district_flows %>%
    dplyr::mutate(
      flow_type = dplyr::case_when(
        id_origin == district_id & id_destination == district_id ~ "Internal",
        id_origin == district_id ~ "Outbound",
        id_destination == district_id ~ "Inbound",
        TRUE ~ "Other"
      ),
      datetime = as.POSIXct(paste(date, sprintf("%02d:00:00", hour)))
    ) %>%
    dplyr::group_by(datetime, flow_type) %>%
    dplyr::summarise(total_trips = sum(n_trips, na.rm = TRUE), .groups = "drop")
  
  # Create time series plot
  p <- ggplot2::ggplot(ts_data, ggplot2::aes(x = datetime, y = total_trips, color = flow_type)) +
    ggplot2::geom_line(size = 1) +
    ggplot2::geom_point(alpha = 0.6) +
    ggplot2::labs(
      title = paste("Mobility Time Series:", district_name),
      subtitle = paste("District ID:", district_id),
      x = "Date and Time",
      y = "Total Trips",
      color = "Flow Type"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      legend.position = "bottom"
    )
  
  return(p)
}

#' Create interactive flow map for district
#' @param district_flows Filtered mobility data
#' @param zones Spatial zones data
#' @param district_id District ID
#' @param district_name District name
#' @param top_n Number of top flows to show
#' @return leaflet map object
create_district_flow_map <- function(district_flows, zones, district_id, district_name, top_n) {
  
  # Get district geometry
  district_geom <- zones %>% dplyr::filter(id == district_id)
  
  # Get top flow destinations
  top_flows <- district_flows %>%
    dplyr::filter(id_origin == district_id | id_destination == district_id) %>%
    dplyr::filter(!(id_origin == district_id & id_destination == district_id)) %>%
    dplyr::mutate(
      connected_zone = ifelse(id_origin == district_id, id_destination, id_origin),
      flow_type = ifelse(id_origin == district_id, "Outbound", "Inbound")
    ) %>%
    dplyr::group_by(connected_zone, flow_type) %>%
    dplyr::summarise(total_trips = sum(n_trips, na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(desc(total_trips)) %>%
    dplyr::slice_head(n = top_n)
  
  # Join with zone geometries
  flow_zones <- zones %>%
    dplyr::filter(id %in% top_flows$connected_zone) %>%
    dplyr::left_join(top_flows, by = c("id" = "connected_zone"))
  
  # Create base map
  map <- leaflet::leaflet() %>%
    leaflet::addTiles() %>%
    leaflet::addPolygons(
      data = district_geom,
      fillColor = "red",
      fillOpacity = 0.7,
      color = "darkred",
      weight = 3,
      popup = paste("Selected District:", district_name)
    )
  
  # Add flow zones with different colors for inbound/outbound
  if(nrow(flow_zones) > 0) {
    # Outbound flows
    outbound_zones <- flow_zones %>% dplyr::filter(flow_type == "Outbound")
    if(nrow(outbound_zones) > 0) {
      map <- map %>%
        leaflet::addPolygons(
          data = outbound_zones,
          fillColor = "blue",
          fillOpacity = 0.5,
          color = "darkblue",
          weight = 2,
          popup = ~paste("Outbound to:", name, "<br>Total Trips:", total_trips)
        )
    }
    
    # Inbound flows
    inbound_zones <- flow_zones %>% dplyr::filter(flow_type == "Inbound")
    if(nrow(inbound_zones) > 0) {
      map <- map %>%
        leaflet::addPolygons(
          data = inbound_zones,
          fillColor = "green",
          fillOpacity = 0.5,
          color = "darkgreen",
          weight = 2,
          popup = ~paste("Inbound from:", name, "<br>Total Trips:", total_trips)
        )
    }
  }
  
  # Add legend
  map <- map %>%
    leaflet::addLegend(
      position = "bottomright",
      colors = c("red", "blue", "green"),
      labels = c("Selected District", "Outbound Destinations", "Inbound Origins"),
      title = "Flow Types"
    )
  
  return(map)
}

#' Print method for district analysis
#' @param x district_analysis object
#' @param ... Additional arguments
#' @export
print.district_analysis <- function(x, ...) {
  cat("District Mobility Analysis\n")
  cat("==========================\n\n")
  
  cat("District:", x$district_name, "(", x$district_id, ")\n")
  cat("Date Range:", paste(x$date_range, collapse = " to "), "\n")
  if(!is.null(x$time_range)) {
    cat("Time Range:", paste(x$time_range, collapse = "-"), "hours\n")
  }
  cat("\n")
  
  cat("Summary Statistics:\n")
  cat("-------------------\n")
  stats <- x$summary_stats
  cat("Total Outbound Trips:", stats$total_outbound, "\n")
  cat("Total Inbound Trips:", stats$total_inbound, "\n")
  cat("Total Internal Trips:", stats$total_internal, "\n")
  cat("Net Flow (In - Out):", stats$net_flow, "\n")
  cat("Unique Destinations:", stats$unique_destinations, "\n")
  cat("Unique Origins:", stats$unique_origins, "\n")
  cat("\n")
  
  cat("Available Visualizations:\n")
  cat("-------------------------\n")
  if(!is.null(x$heatmap)) cat("- Heatmap: x$heatmap\n")
  if(!is.null(x$flow_plot)) cat("- Flow Plot: x$flow_plot\n")
  if(!is.null(x$timeseries_plot)) cat("- Time Series: x$timeseries_plot\n")
  if(!is.null(x$interactive_map)) cat("- Interactive Map: x$interactive_map\n")
}
