#' Calculate activity-based mobility patterns
#'
#' Analyzes mobility flows by activity types (home, work, frequent_activity, other_activity)
#'
#' @param mobility_data Data frame with mobility data including activity_origin and activity_destination
#' @param min_trips Minimum trips threshold for inclusion (default: 10)
#' @param normalize Whether to normalize by total trips (default: TRUE)
#' @return Data frame with activity-based mobility metrics
#' @export
#' @examples
#' \dontrun{
#' # Analyze activity patterns
#' activity_patterns <- calculate_activity_patterns(mobility_data)
#' print(activity_patterns)
#' 
#' # Focus on work commuting patterns
#' work_patterns <- calculate_activity_patterns(
#'   mobility_data,
#'   activity_filter = c("home", "frequent_activity"),
#'   min_trips = 20
#' )
#' }
calculate_activity_patterns <- function(mobility_data, min_trips = 10, normalize = TRUE) {
  # Validate required columns
  required_cols <- c("activity_origin", "activity_destination", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Calculate activity transition matrix
  activity_matrix <- mobility_data %>%
    filter(!is.na(activity_origin) & !is.na(activity_destination)) %>%
    group_by(activity_origin, activity_destination) %>%
    summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      avg_trips = mean(n_trips, na.rm = TRUE),
      flow_count = n(),
      .groups = "drop"
    ) %>%
    filter(total_trips >= min_trips)
  
  # Calculate activity-specific metrics
  origin_totals <- activity_matrix %>%
    group_by(activity_origin) %>%
    summarise(origin_total = sum(total_trips), .groups = "drop")
  
  dest_totals <- activity_matrix %>%
    group_by(activity_destination) %>%
    summarise(dest_total = sum(total_trips), .groups = "drop")
  
  # Add proportions if normalizing
  if (normalize) {
    activity_matrix <- activity_matrix %>%
      left_join(origin_totals, by = "activity_origin") %>%
      left_join(dest_totals, by = "activity_destination") %>%
      mutate(
        origin_proportion = total_trips / origin_total,
        dest_proportion = total_trips / dest_total,
        overall_proportion = total_trips / sum(total_trips)
      )
  }
  
  # Calculate activity balance (symmetry)
  activity_balance <- activity_matrix %>%
    select(from = activity_origin, to = activity_destination, trips = total_trips) %>%
    bind_rows(
      activity_matrix %>%
        select(from = activity_destination, to = activity_origin, trips = total_trips)
    ) %>%
    group_by(from, to) %>%
    summarise(
      total_flow = sum(trips),
      flow_balance = diff(trips)[1],
      .groups = "drop"
    ) %>%
    filter(as.character(from) < as.character(to))  # Remove duplicates, handle factors
  
  return(list(
    activity_matrix = activity_matrix,
    activity_balance = activity_balance,
    summary = list(
      total_activity_flows = sum(activity_matrix$total_trips),
      unique_activity_pairs = nrow(activity_matrix),
      most_common_flow = activity_matrix[which.max(activity_matrix$total_trips), ]
    )
  ))
}

#' Calculate distance-based mobility analysis
#'
#' Analyzes mobility patterns by distance bands and trip characteristics
#'
#' @param mobility_data Data frame with distance and trips_total_length_km columns
#' @param distance_bands Vector of distance band thresholds in km (default: c(2, 10, 50, 200))
#' @param min_trips Minimum trips threshold (default: 5)
#' @return Data frame with distance-based mobility metrics
#' @export
#' @examples
#' \dontrun{
#' # Analyze distance patterns
#' distance_analysis <- calculate_distance_analysis(mobility_data)
#' print(distance_analysis$summary)
#' 
#' # Custom distance bands
#' urban_analysis <- calculate_distance_analysis(
#'   mobility_data,
#'   distance_bands = c(1, 5, 15, 30),
#'   min_trips = 10
#' )
#' }
calculate_distance_analysis <- function(mobility_data, 
                                      distance_bands = c(2, 10, 50, 200), 
                                      min_trips = 5) {
  # Validate required columns
  required_cols <- c("distance", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Convert distance factor to numeric if needed
  if (is.factor(mobility_data$distance)) {
    # Map standard MITMA distance categories
    distance_mapping <- c(
      "0.5-2" = 1.25,
      "2-10" = 6,
      "10-50" = 30,
      "50+" = 100
    )
    mobility_data$distance_km <- distance_mapping[as.character(mobility_data$distance)]
  } else {
    mobility_data$distance_km <- as.numeric(mobility_data$distance)
  }
  
  # Create distance bands
  mobility_data$distance_band <- cut(
    mobility_data$distance_km,
    breaks = c(0, distance_bands, Inf),
    labels = c(
      paste0("0-", distance_bands[1], "km"),
      paste0(distance_bands[-length(distance_bands)], "-", distance_bands[-1], "km"),
      paste0(">", distance_bands[length(distance_bands)], "km")
    ),
    include.lowest = TRUE
  )
  
  # Calculate distance band statistics
  distance_stats <- mobility_data %>%
    filter(!is.na(distance_band) & n_trips >= min_trips) %>%
    group_by(distance_band) %>%
    summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      avg_trips_per_flow = mean(n_trips, na.rm = TRUE),
      median_trips = median(n_trips, na.rm = TRUE),
      flow_count = n(),
      avg_distance = mean(distance_km, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      trips_proportion = total_trips / sum(total_trips),
      flows_proportion = flow_count / sum(flow_count)
    )
  
  # Calculate total distance traveled if available
  if ("trips_total_length_km" %in% names(mobility_data)) {
    distance_travel <- mobility_data %>%
      filter(!is.na(distance_band) & n_trips >= min_trips) %>%
      group_by(distance_band) %>%
      summarise(
        total_distance_km = sum(trips_total_length_km, na.rm = TRUE),
        avg_distance_per_trip = mean(trips_total_length_km / n_trips, na.rm = TRUE),
        .groups = "drop"
      )
    
    distance_stats <- distance_stats %>%
      left_join(distance_travel, by = "distance_band") %>%
      mutate(distance_proportion = total_distance_km / sum(total_distance_km, na.rm = TRUE))
  }
  
  # Calculate distance efficiency metrics
  efficiency_metrics <- distance_stats %>%
    mutate(
      trips_per_km_efficiency = total_trips / ifelse(is.na(total_distance_km), avg_distance * total_trips, total_distance_km),
      distance_utilization = ifelse(is.na(total_distance_km), NA, total_distance_km / (avg_distance * total_trips))
    )
  
  return(list(
    distance_stats = distance_stats,
    efficiency_metrics = efficiency_metrics,
    summary = list(
      total_trips = sum(distance_stats$total_trips),
      total_flows = sum(distance_stats$flow_count),
      avg_trip_distance = weighted.mean(distance_stats$avg_distance, distance_stats$total_trips),
      most_popular_band = distance_stats$distance_band[which.max(distance_stats$total_trips)]
    )
  ))
}

#' Calculate activity-distance interaction patterns
#'
#' Analyzes how activity types relate to travel distances
#'
#' @param mobility_data Data frame with activity and distance columns
#' @param min_trips Minimum trips threshold (default: 10)
#' @return Data frame with activity-distance interaction analysis
#' @export
#' @examples
#' \dontrun{
#' # Analyze activity-distance relationships
#' activity_distance <- calculate_activity_distance_patterns(mobility_data)
#' print(activity_distance$interaction_matrix)
#' 
#' # Focus on work-related travel
#' work_distance <- calculate_activity_distance_patterns(
#'   mobility_data %>% filter(
#'     activity_origin == "home" | activity_destination == "frequent_activity"
#'   )
#' )
#' }
calculate_activity_distance_patterns <- function(mobility_data, min_trips = 10) {
  # Validate required columns
  required_cols <- c("activity_origin", "activity_destination", "distance", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Create activity pair labels
  mobility_data <- mobility_data %>%
    mutate(
      activity_pair = paste(activity_origin, "->", activity_destination),
      activity_type = case_when(
        activity_origin == "home" & activity_destination == "frequent_activity" ~ "Home to Work",
        activity_origin == "frequent_activity" & activity_destination == "home" ~ "Work to Home",
        activity_origin == "home" & activity_destination == "other_activity" ~ "Home to Other",
        activity_origin == "other_activity" & activity_destination == "home" ~ "Other to Home",
        activity_origin == activity_destination ~ "Internal Activity",
        TRUE ~ "Other Combinations"
      )
    )
  
  # Calculate interaction matrix
  interaction_matrix <- mobility_data %>%
    filter(!is.na(activity_origin) & !is.na(activity_destination) & !is.na(distance)) %>%
    group_by(activity_pair, distance, activity_type) %>%
    summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      avg_trips = mean(n_trips, na.rm = TRUE),
      flow_count = n(),
      .groups = "drop"
    ) %>%
    filter(total_trips >= min_trips)
  
  # Calculate activity-specific distance preferences
  activity_distance_prefs <- interaction_matrix %>%
    group_by(activity_type) %>%
    summarise(
      total_trips = sum(total_trips),
      most_common_distance = distance[which.max(total_trips)],
      distance_diversity = length(unique(distance)),
      .groups = "drop"
    ) %>%
    arrange(desc(total_trips))
  
  # Calculate distance-specific activity preferences
  distance_activity_prefs <- interaction_matrix %>%
    group_by(distance) %>%
    summarise(
      total_trips = sum(total_trips),
      most_common_activity = activity_type[which.max(total_trips)],
      activity_diversity = length(unique(activity_type)),
      .groups = "drop"
    ) %>%
    arrange(desc(total_trips))
  
  # Calculate travel efficiency by activity
  if ("trips_total_length_km" %in% names(mobility_data)) {
    travel_efficiency <- mobility_data %>%
      filter(!is.na(activity_type) & n_trips >= min_trips) %>%
      group_by(activity_type) %>%
      summarise(
        total_distance_km = sum(trips_total_length_km, na.rm = TRUE),
        total_trips = sum(n_trips, na.rm = TRUE),
        avg_km_per_trip = total_distance_km / total_trips,
        .groups = "drop"
      )
    
    return(list(
      interaction_matrix = interaction_matrix,
      activity_distance_prefs = activity_distance_prefs,
      distance_activity_prefs = distance_activity_prefs,
      travel_efficiency = travel_efficiency,
      summary = list(
        total_activity_distance_flows = nrow(interaction_matrix),
        most_efficient_activity = travel_efficiency$activity_type[which.min(travel_efficiency$avg_km_per_trip)]
      )
    ))
  } else {
    return(list(
      interaction_matrix = interaction_matrix,
      activity_distance_prefs = activity_distance_prefs,
      distance_activity_prefs = distance_activity_prefs,
      summary = list(
        total_activity_distance_flows = nrow(interaction_matrix)
      )
    ))
  }
}

#' Calculate commuting pattern analysis
#'
#' Identifies and analyzes commuting patterns based on home-work flows
#'
#' @param mobility_data Data frame with activity and spatial columns
#' @param time_periods Vector of time periods to analyze (default: c("morning", "evening"))
#' @param min_commute_trips Minimum trips to consider as commuting (default: 5)
#' @return List with commuting analysis results
#' @export
#' @examples
#' \dontrun{
#' # Analyze commuting patterns
#' commute_analysis <- calculate_commuting_patterns(mobility_data)
#' print(commute_analysis$commute_zones)
#' 
#' # Focus on specific time periods
#' morning_commute <- calculate_commuting_patterns(
#'   mobility_data %>% filter(hour %in% 7:9),
#'   min_commute_trips = 10
#' )
#' }
calculate_commuting_patterns <- function(mobility_data, 
                                       time_periods = c("morning", "evening"),
                                       min_commute_trips = 5) {
  # Validate required columns
  required_cols <- c("id_origin", "id_destination", "activity_origin", "activity_destination", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Identify commuting flows (home <-> work)
  commute_flows <- mobility_data %>%
    filter(
      (activity_origin == "home" & activity_destination == "frequent_activity") |
      (activity_origin == "frequent_activity" & activity_destination == "home")
    ) %>%
    mutate(
      commute_direction = ifelse(
        activity_origin == "home",
        "outbound",
        "inbound"
      )
    )
  
  # Calculate commuting zones
  commute_zones <- commute_flows %>%
    group_by(id_origin, id_destination, commute_direction) %>%
    summarise(
      total_commute_trips = sum(n_trips, na.rm = TRUE),
      avg_commute_trips = mean(n_trips, na.rm = TRUE),
      commute_days = n(),
      .groups = "drop"
    ) %>%
    filter(total_commute_trips >= min_commute_trips)
  
  # Identify major employment centers
  employment_centers <- commute_zones %>%
    filter(commute_direction == "outbound") %>%
    group_by(employment_zone = id_destination) %>%
    summarise(
      total_workers = sum(total_commute_trips),
      residential_zones_served = length(unique(id_origin)),
      avg_commute_volume = mean(total_commute_trips),
      .groups = "drop"
    ) %>%
    arrange(desc(total_workers))
  
  # Identify major residential areas
  residential_areas <- commute_zones %>%
    filter(commute_direction == "outbound") %>%
    group_by(residential_zone = id_origin) %>%
    summarise(
      total_commuters = sum(total_commute_trips),
      employment_zones_accessed = length(unique(id_destination)),
      avg_commute_volume = mean(total_commute_trips),
      .groups = "drop"
    ) %>%
    arrange(desc(total_commuters))
  
  # Calculate commute balance (jobs-housing balance)
  commute_balance <- commute_zones %>%
    group_by(zone = id_origin) %>%
    summarise(
      outbound_commutes = sum(total_commute_trips[commute_direction == "outbound"], na.rm = TRUE),
      inbound_commutes = sum(total_commute_trips[commute_direction == "inbound"], na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      commute_balance = inbound_commutes - outbound_commutes,
      balance_ratio = ifelse(outbound_commutes > 0, inbound_commutes / outbound_commutes, NA),
      zone_type = case_when(
        commute_balance > 100 ~ "Employment Center",
        commute_balance < -100 ~ "Residential Area",
        TRUE ~ "Mixed Use"
      )
    )
  
  # Calculate commute distance analysis if available
  if ("distance" %in% names(mobility_data) | "trips_total_length_km" %in% names(mobility_data)) {
    commute_distance <- commute_flows %>%
      group_by(commute_direction) %>%
      summarise(
        avg_distance_category = names(sort(table(distance), decreasing = TRUE))[1],
        total_commute_km = sum(trips_total_length_km, na.rm = TRUE),
        avg_km_per_commute = mean(trips_total_length_km / n_trips, na.rm = TRUE),
        .groups = "drop"
      )
    
    return(list(
      commute_zones = commute_zones,
      employment_centers = employment_centers,
      residential_areas = residential_areas,
      commute_balance = commute_balance,
      commute_distance = commute_distance,
      summary = list(
        total_commute_flows = nrow(commute_zones),
        largest_employment_center = employment_centers$employment_zone[1],
        largest_residential_area = residential_areas$residential_zone[1],
        total_commute_trips = sum(commute_zones$total_commute_trips)
      )
    ))
  } else {
    return(list(
      commute_zones = commute_zones,
      employment_centers = employment_centers,
      residential_areas = residential_areas,
      commute_balance = commute_balance,
      summary = list(
        total_commute_flows = nrow(commute_zones),
        largest_employment_center = employment_centers$employment_zone[1],
        largest_residential_area = residential_areas$residential_zone[1],
        total_commute_trips = sum(commute_zones$total_commute_trips)
      )
    ))
  }
}

#' Analyze mobility network structure and connectivity
#'
#' Creates network analysis of mobility flows including centrality measures,
#' community detection, and network efficiency metrics
#'
#' @param mobility_data Data frame with mobility flows
#' @param spatial_zones Spatial zones data frame (optional)
#' @param min_trips Minimum trips threshold for network edges (default: 10)
#' @param include_centrality Whether to calculate centrality measures (default: TRUE)
#' @param detect_communities Whether to detect communities in the network (default: TRUE)
#' @return List with network analysis results
#' @export
#' @examples
#' \dontrun{
#' # Basic network analysis
#' network_analysis <- analyze_mobility_network(mobility_data)
#' print(network_analysis$centrality_measures)
#' 
#' # Network analysis with spatial zones
#' network_spatial <- analyze_mobility_network(
#'   mobility_data,
#'   spatial_zones = zones,
#'   min_trips = 20
#' )
#' 
#' # Network analysis with community detection
#' network_communities <- analyze_mobility_network(
#'   mobility_data,
#'   detect_communities = TRUE
#' )
#' }
analyze_mobility_network <- function(mobility_data, 
                                    spatial_zones = NULL,
                                    min_trips = 10,
                                    include_centrality = TRUE,
                                    detect_communities = TRUE) {
  # Validate required columns
  required_cols <- c("id_origin", "id_destination", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Create edge list for network analysis
  edge_list <- mobility_data %>%
    filter(id_origin != id_destination) %>%  # Remove self-loops
    group_by(id_origin, id_destination) %>%
    summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      flow_frequency = n(),
      .groups = "drop"
    ) %>%
    filter(total_trips >= min_trips) %>%
    arrange(desc(total_trips))
  
  # Basic network statistics
  network_stats <- list(
    total_nodes = length(unique(c(edge_list$id_origin, edge_list$id_destination))),
    total_edges = nrow(edge_list),
    total_trips = sum(edge_list$total_trips),
    avg_trips_per_edge = mean(edge_list$total_trips),
    median_trips_per_edge = median(edge_list$total_trips),
    network_density = nrow(edge_list) / (length(unique(c(edge_list$id_origin, edge_list$id_destination)))^2)
  )
  
  # Calculate node-level statistics
  node_stats <- bind_rows(
    edge_list %>% 
      group_by(node = id_origin) %>% 
      summarise(
        out_degree = n(),
        out_strength = sum(total_trips),
        .groups = "drop"
      ) %>%
      mutate(direction = "outbound"),
    edge_list %>% 
      group_by(node = id_destination) %>% 
      summarise(
        in_degree = n(),
        in_strength = sum(total_trips),
        .groups = "drop"
      ) %>%
      mutate(direction = "inbound")
  ) %>%
    group_by(node) %>%
    summarise(
      total_degree = sum(c(out_degree, in_degree), na.rm = TRUE),
      total_strength = sum(c(out_strength, in_strength), na.rm = TRUE),
      out_degree = max(out_degree, na.rm = TRUE),
      in_degree = max(in_degree, na.rm = TRUE),
      out_strength = max(out_strength, na.rm = TRUE),
      in_strength = max(in_strength, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      degree_centrality = total_degree / (network_stats$total_nodes - 1),
      strength_centrality = total_strength / network_stats$total_trips
    ) %>%
    arrange(desc(total_strength))
  
  # Calculate network efficiency and connectivity
  connectivity_analysis <- edge_list %>%
    group_by(id_origin) %>%
    summarise(
      reachable_zones = n(),
      total_outbound_trips = sum(total_trips),
      avg_trip_strength = mean(total_trips),
      connectivity_diversity = length(unique(id_destination)) / network_stats$total_nodes,
      .groups = "drop"
    ) %>%
    left_join(
      edge_list %>%
        group_by(id_destination) %>%
        summarise(
          accessible_from = n(),
          total_inbound_trips = sum(total_trips),
          .groups = "drop"
        ),
      by = c("id_origin" = "id_destination")
    ) %>%
    mutate(
      connectivity_balance = total_inbound_trips / total_outbound_trips,
      network_efficiency = reachable_zones / (network_stats$total_nodes - 1)
    )
  
  # Advanced centrality measures (if requested)
  centrality_measures <- NULL
  if (include_centrality) {
    # Calculate betweenness centrality approximation
    centrality_measures <- node_stats %>%
      mutate(
        betweenness_approx = total_degree * total_strength / network_stats$total_trips,
        closeness_approx = 1 / (1 + (network_stats$total_nodes - total_degree)),
        eigenvector_approx = total_strength / max(total_strength, na.rm = TRUE)
      ) %>%
      select(node, degree_centrality, strength_centrality, betweenness_approx, 
             closeness_approx, eigenvector_approx)
  }
  
  # Community detection (simplified approach)
  communities <- NULL
  if (detect_communities) {
    # Use modularity-based community detection (simplified)
    # Group zones based on strong bilateral flows
    bilateral_flows <- edge_list %>%
      left_join(
        edge_list %>% select(origin = id_destination, destination = id_origin, return_trips = total_trips),
        by = c("id_origin" = "origin", "id_destination" = "destination")
      ) %>%
      mutate(
        return_trips = ifelse(is.na(return_trips), 0, return_trips),
        bilateral_strength = total_trips + return_trips,
        flow_symmetry = pmin(as.numeric(total_trips), as.numeric(return_trips)) / pmax(as.numeric(total_trips), as.numeric(return_trips))
      ) %>%
      filter(bilateral_strength > quantile(bilateral_strength, 0.75, na.rm = TRUE)) %>%
      arrange(desc(bilateral_strength))
    
    # Create community assignments based on strongest connections
    communities <- bilateral_flows %>%
      slice_head(n = min(50, nrow(bilateral_flows))) %>%
      select(id_origin, id_destination, bilateral_strength) %>%
      mutate(community_pair = paste(pmin(as.character(id_origin), as.character(id_destination)), 
                                   pmax(as.character(id_origin), as.character(id_destination)), sep = "_"))
    
    community_summary <- communities %>%
      group_by(community_pair) %>%
      summarise(
        community_strength = sum(bilateral_strength),
        community_size = length(unique(c(id_origin, id_destination))),
        .groups = "drop"
      ) %>%
      arrange(desc(community_strength))
  }
  
  # Integrate spatial information if available
  if (!is.null(spatial_zones)) {
    # Flexible column detection for spatial zones
    id_cols <- c("id", "zone_id", "district_id", "area_id")
    name_cols <- c("name", "zone_name", "district_name", "area_name", "district_names_in_v2")
    area_cols <- c("area_km2", "area", "surface_km2")
    
    # Find available columns
    id_col <- intersect(id_cols, names(spatial_zones))[1]
    name_col <- intersect(name_cols, names(spatial_zones))[1]
    area_col <- intersect(area_cols, names(spatial_zones))[1]
    
    # Create join data with available columns
    join_data <- spatial_zones %>%
      select(node = !!rlang::sym(id_col))
    
    # Add name column if available
    if (!is.na(name_col)) {
      join_data <- join_data %>%
        mutate(zone_name = spatial_zones[[name_col]])
    }
    
    # Add area column if available
    if (!is.na(area_col)) {
      join_data <- join_data %>%
        mutate(area_km2 = spatial_zones[[area_col]])
    }
    
    # Add spatial context to network analysis
    spatial_network <- node_stats %>%
      left_join(join_data, by = "node")
    
    # Calculate spatial metrics only if area is available
    if (!is.na(area_col)) {
      spatial_network <- spatial_network %>%
        mutate(
          trips_per_km2 = total_strength / area_km2,
          spatial_efficiency = degree_centrality / log(area_km2 + 1)
        )
      
      network_stats$spatial_integration <- TRUE
      network_stats$avg_area_km2 <- mean(spatial_network$area_km2, na.rm = TRUE)
      network_stats$trips_per_km2 <- sum(spatial_network$total_strength, na.rm = TRUE) / 
                                     sum(spatial_network$area_km2, na.rm = TRUE)
    } else {
      network_stats$spatial_integration <- "partial"
    }
  } else {
    spatial_network <- node_stats
    network_stats$spatial_integration <- FALSE
  }
  
  # Summary insights
  summary_insights <- list(
    network_type = case_when(
      network_stats$network_density > 0.5 ~ "Dense Network",
      network_stats$network_density > 0.1 ~ "Moderately Connected",
      TRUE ~ "Sparse Network"
    ),
    most_central_zone = centrality_measures$node[1] %||% node_stats$node[1],
    largest_community = if(!is.null(communities)) community_summary$community_pair[1] else NA,
    network_efficiency = mean(connectivity_analysis$network_efficiency, na.rm = TRUE),
    connectivity_balance = mean(connectivity_analysis$connectivity_balance, na.rm = TRUE)
  )
  
  return(list(
    network_statistics = network_stats,
    node_statistics = spatial_network,
    connectivity_analysis = connectivity_analysis,
    centrality_measures = centrality_measures,
    communities = communities,
    community_summary = community_summary,
    summary_insights = summary_insights
  ))
}

#' Analyze mobility flows by trip purpose and distance
#'
#' Examines the relationship between trip purposes, distances, and mobility patterns
#' leveraging activity and distance information
#'
#' @param mobility_data Data frame with activity and distance columns
#' @param distance_bands Vector of distance thresholds (default: c(2, 10, 50, 200))
#' @param min_trips Minimum trips threshold (default: 10)
#' @param include_temporal Whether to include temporal analysis (default: TRUE)
#' @return List with trip purpose-distance analysis results
#' @export
#' @examples
#' \dontrun{
#' # Analyze trip purposes by distance
#' purpose_distance <- analyze_trip_purpose_distance(mobility_data)
#' print(purpose_distance$purpose_distance_matrix)
#' 
#' # Custom distance bands for urban analysis
#' urban_purpose <- analyze_trip_purpose_distance(
#'   mobility_data,
#'   distance_bands = c(1, 5, 15, 30)
#' )
#' 
#' # Include temporal patterns
#' temporal_purpose <- analyze_trip_purpose_distance(
#'   mobility_data,
#'   include_temporal = TRUE
#' )
#' }
analyze_trip_purpose_distance <- function(mobility_data, 
                                        distance_bands = c(2, 10, 50, 200),
                                        min_trips = 10,
                                        include_temporal = TRUE) {
  # Validate required columns
  required_cols <- c("activity_origin", "activity_destination", "distance", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Create trip purpose categories
  mobility_data <- mobility_data %>%
    mutate(
      trip_purpose = case_when(
        activity_origin == "home" & activity_destination == "frequent_activity" ~ "Home to Work",
        activity_origin == "frequent_activity" & activity_destination == "home" ~ "Work to Home",
        activity_origin == "home" & activity_destination == "other_activity" ~ "Home to Other",
        activity_origin == "other_activity" & activity_destination == "home" ~ "Other to Home",
        activity_origin == "home" & activity_destination == "home" ~ "Home-based Loop",
        activity_origin == "frequent_activity" & activity_destination == "frequent_activity" ~ "Work-based",
        activity_origin == "other_activity" & activity_destination == "other_activity" ~ "Other-based",
        TRUE ~ "Mixed Activities"
      )
    )
  
  # Process distance information
  if (is.factor(mobility_data$distance)) {
    # Handle categorical distance data
    distance_mapping <- c(
      "0.5-2" = 1.25,
      "2-10" = 6,
      "10-50" = 30,
      "50+" = 100
    )
    mobility_data$distance_km <- distance_mapping[as.character(mobility_data$distance)]
    mobility_data$distance_category <- as.character(mobility_data$distance)
  } else {
    # Handle numeric distance data
    mobility_data$distance_km <- as.numeric(mobility_data$distance)
    mobility_data$distance_category <- cut(
      mobility_data$distance_km,
      breaks = c(0, distance_bands, Inf),
      labels = c(
        paste0("0-", distance_bands[1], "km"),
        paste0(distance_bands[-length(distance_bands)], "-", distance_bands[-1], "km"),
        paste0(">", distance_bands[length(distance_bands)], "km")
      ),
      include.lowest = TRUE
    )
  }
  
  # Create trip purpose-distance matrix
  purpose_distance_matrix <- mobility_data %>%
    filter(!is.na(trip_purpose) & !is.na(distance_category)) %>%
    group_by(trip_purpose, distance_category) %>%
    summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      unique_flows = n(),
      avg_trips_per_flow = mean(n_trips, na.rm = TRUE),
      avg_distance_km = mean(distance_km, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(total_trips >= min_trips)
  
  # Calculate purpose-specific distance preferences
  purpose_distance_prefs <- purpose_distance_matrix %>%
    group_by(trip_purpose) %>%
    summarise(
      total_trips = sum(total_trips),
      preferred_distance = distance_category[which.max(total_trips)],
      distance_diversity = length(unique(distance_category)),
      avg_distance_km = weighted.mean(avg_distance_km, total_trips, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(total_trips))
  
  # Calculate distance-specific purpose preferences
  distance_purpose_prefs <- purpose_distance_matrix %>%
    group_by(distance_category) %>%
    summarise(
      total_trips = sum(total_trips),
      dominant_purpose = trip_purpose[which.max(total_trips)],
      purpose_diversity = length(unique(trip_purpose)),
      avg_trips_per_purpose = mean(total_trips),
      .groups = "drop"
    ) %>%
    arrange(desc(total_trips))
  
  # Calculate trip efficiency by purpose and distance
  if ("trips_total_length_km" %in% names(mobility_data)) {
    trip_efficiency <- mobility_data %>%
      filter(!is.na(trip_purpose) & !is.na(distance_category)) %>%
      group_by(trip_purpose, distance_category) %>%
      summarise(
        total_distance_km = sum(trips_total_length_km, na.rm = TRUE),
        total_trips = sum(n_trips, na.rm = TRUE),
        avg_km_per_trip = total_distance_km / total_trips,
        distance_efficiency = total_trips / total_distance_km,
        .groups = "drop"
      ) %>%
      mutate(
        efficiency_rank = rank(desc(distance_efficiency))
      )
  } else {
    trip_efficiency <- NULL
  }
  
  # Temporal analysis (if requested and hour column available)
  temporal_analysis <- NULL
  if (include_temporal && "hour" %in% names(mobility_data)) {
    temporal_analysis <- mobility_data %>%
      filter(!is.na(trip_purpose) & !is.na(hour)) %>%
      mutate(
        time_period = case_when(
          hour %in% 6:9 ~ "Morning Rush",
          hour %in% 10:15 ~ "Midday",
          hour %in% 16:19 ~ "Evening Rush",
          hour %in% 20:23 ~ "Evening",
          TRUE ~ "Night/Early Morning"
        )
      ) %>%
      group_by(trip_purpose, time_period) %>%
      summarise(
        total_trips = sum(n_trips, na.rm = TRUE),
        avg_distance_km = mean(distance_km, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      filter(total_trips >= min_trips)
    
    # Find peak hours for each purpose
    peak_hours <- temporal_analysis %>%
      group_by(trip_purpose) %>%
      summarise(
        peak_period = time_period[which.max(total_trips)],
        peak_trips = max(total_trips),
        .groups = "drop"
      )
    
    temporal_analysis <- list(
      hourly_patterns = temporal_analysis,
      peak_hours = peak_hours
    )
  }
  
  # Summary statistics
  summary_stats <- list(
    total_trip_purposes = length(unique(purpose_distance_matrix$trip_purpose)),
    total_distance_categories = length(unique(purpose_distance_matrix$distance_category)),
    most_common_purpose = purpose_distance_prefs$trip_purpose[1],
    most_common_distance = distance_purpose_prefs$distance_category[1],
    total_trips_analyzed = sum(purpose_distance_matrix$total_trips),
    avg_trip_distance = weighted.mean(purpose_distance_prefs$avg_distance_km, 
                                     purpose_distance_prefs$total_trips, na.rm = TRUE)
  )
  
  return(list(
    purpose_distance_matrix = purpose_distance_matrix,
    purpose_distance_preferences = purpose_distance_prefs,
    distance_purpose_preferences = distance_purpose_prefs,
    trip_efficiency = trip_efficiency,
    temporal_analysis = temporal_analysis,
    summary = summary_stats
  ))
}
