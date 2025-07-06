#' Economic and socioeconomic mobility analysis functions
#'
#' Advanced analytical functions for economic impact and socioeconomic patterns
#' using rich MITMA data with demographic and activity information.

#' Analyze economic mobility flows and trip costs
#'
#' Estimates economic impact of mobility flows including trip costs,
#' time values, and economic accessibility
#'
#' @param mobility_data Data frame with mobility flows and distance information
#' @param spatial_zones Spatial zones data frame with economic indicators (optional)
#' @param cost_per_km Cost per kilometer for travel (default: 0.35 EUR/km)
#' @param time_value Value of time per hour (default: 15 EUR/hour)
#' @param avg_speed Average travel speed in km/h (default: 40 km/h)
#' @param min_trips Minimum trips threshold (default: 10)
#' @return List with economic mobility analysis results
#' @export
#' @examples
#' \dontrun{
#' # Basic economic analysis
#' economic_analysis <- analyze_economic_mobility(mobility_data)
#' print(economic_analysis$economic_summary)
#' 
#' # Custom cost parameters
#' high_cost_analysis <- analyze_economic_mobility(
#'   mobility_data,
#'   cost_per_km = 0.50,
#'   time_value = 20
#' )
#' 
#' # Include spatial economic indicators
#' spatial_economic <- analyze_economic_mobility(
#'   mobility_data,
#'   spatial_zones = zones
#' )
#' }
analyze_economic_mobility <- function(mobility_data,
                                    spatial_zones = NULL,
                                    cost_per_km = 0.35,
                                    time_value = 15,
                                    avg_speed = 40,
                                    min_trips = 10) {
  # Validate required columns
  required_cols <- c("id_origin", "id_destination", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Process distance information
  if ("distance" %in% names(mobility_data)) {
    if (is.factor(mobility_data$distance)) {
      # Map categorical distances to numeric values
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
  } else if ("trips_total_length_km" %in% names(mobility_data)) {
    # Use total trip length if available
    mobility_data$distance_km <- mobility_data$trips_total_length_km / mobility_data$n_trips
  } else {
    warning("No distance information available. Using default distance of 10 km.")
    mobility_data$distance_km <- 10
  }
  
  # Calculate economic indicators
  economic_flows <- mobility_data %>%
    filter(n_trips >= min_trips) %>%
    mutate(
      travel_cost_per_trip = distance_km * cost_per_km,
      travel_time_hours = distance_km / avg_speed,
      time_cost_per_trip = travel_time_hours * time_value,
      total_cost_per_trip = travel_cost_per_trip + time_cost_per_trip,
      total_travel_cost = total_cost_per_trip * n_trips,
      total_time_cost = time_cost_per_trip * n_trips,
      total_economic_impact = total_travel_cost + total_time_cost
    ) %>%
    group_by(id_origin, id_destination) %>%
    summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      avg_distance_km = weighted.mean(distance_km, n_trips, na.rm = TRUE),
      total_economic_impact = sum(total_economic_impact, na.rm = TRUE),
      avg_cost_per_trip = total_economic_impact / total_trips,
      total_travel_time_hours = sum(travel_time_hours * n_trips, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(total_economic_impact))
  
  # Calculate zone-level economic indicators
  origin_economics <- economic_flows %>%
    group_by(id_origin) %>%
    summarise(
      outbound_trips = sum(total_trips),
      outbound_economic_impact = sum(total_economic_impact),
      avg_outbound_cost = mean(avg_cost_per_trip),
      outbound_destinations = n(),
      total_outbound_time = sum(total_travel_time_hours),
      .groups = "drop"
    )
  
  destination_economics <- economic_flows %>%
    group_by(id_destination) %>%
    summarise(
      inbound_trips = sum(total_trips),
      inbound_economic_impact = sum(total_economic_impact),
      avg_inbound_cost = mean(avg_cost_per_trip),
      inbound_origins = n(),
      total_inbound_time = sum(total_travel_time_hours),
      .groups = "drop"
    )
  
  zone_economics <- origin_economics %>%
    full_join(destination_economics, by = c("id_origin" = "id_destination")) %>%
    rename(zone_id = id_origin) %>%
    mutate(
      total_economic_impact = (outbound_economic_impact %||% 0) + (inbound_economic_impact %||% 0),
      economic_balance = (inbound_economic_impact %||% 0) - (outbound_economic_impact %||% 0),
      accessibility_index = (outbound_destinations %||% 0) + (inbound_origins %||% 0),
      time_burden = (total_outbound_time %||% 0) + (total_inbound_time %||% 0)
    ) %>%
    arrange(desc(total_economic_impact))
  
  # Calculate economic accessibility by activity type
  if ("activity_origin" %in% names(mobility_data) && "activity_destination" %in% names(mobility_data)) {
    activity_economics <- mobility_data %>%
      filter(n_trips >= min_trips) %>%
      mutate(
        travel_cost_per_trip = distance_km * cost_per_km,
        time_cost_per_trip = (distance_km / avg_speed) * time_value,
        total_cost_per_trip = travel_cost_per_trip + time_cost_per_trip,
        activity_pair = paste(activity_origin, "->", activity_destination)
      ) %>%
      group_by(activity_pair) %>%
      summarise(
        total_trips = sum(n_trips, na.rm = TRUE),
        avg_cost_per_trip = weighted.mean(total_cost_per_trip, n_trips, na.rm = TRUE),
        total_economic_impact = sum(total_cost_per_trip * n_trips, na.rm = TRUE),
        avg_distance_km = weighted.mean(distance_km, n_trips, na.rm = TRUE),
        cost_efficiency = total_trips / total_economic_impact,
        .groups = "drop"
      ) %>%
      arrange(desc(total_economic_impact))
  } else {
    activity_economics <- NULL
  }
  
  # Integrate spatial economic indicators if available
  if (!is.null(spatial_zones)) {
    # Check for economic indicators in spatial data
    economic_cols <- intersect(names(spatial_zones), 
                              c("population", "gdp", "income", "employment", "area_km2"))
    
    if (length(economic_cols) > 0) {
      spatial_economics <- zone_economics %>%
        left_join(
          spatial_zones %>% 
            select(zone_id = id, all_of(economic_cols)),
          by = "zone_id"
        )
      
      # Calculate economic efficiency indicators
      if ("population" %in% economic_cols) {
        spatial_economics <- spatial_economics %>%
          mutate(
            economic_impact_per_capita = total_economic_impact / population,
            trips_per_capita = ((outbound_trips %||% 0) + (inbound_trips %||% 0)) / population
          )
      }
      
      if ("area_km2" %in% economic_cols) {
        spatial_economics <- spatial_economics %>%
          mutate(
            economic_density = total_economic_impact / area_km2,
            trip_density = ((outbound_trips %||% 0) + (inbound_trips %||% 0)) / area_km2
          )
      }
    } else {
      spatial_economics <- zone_economics
      warning("No economic indicators found in spatial data")
    }
  } else {
    spatial_economics <- zone_economics
  }
  
  # Economic mobility patterns by demographic groups (if available)
  demographic_economics <- NULL
  if (any(c("age", "sex", "income") %in% names(mobility_data))) {
    demo_vars <- intersect(c("age", "sex", "income"), names(mobility_data))
    
    for (demo_var in demo_vars) {
      demo_economic <- mobility_data %>%
        filter(!is.na(!!sym(demo_var)) & n_trips >= min_trips) %>%
        mutate(
          total_cost_per_trip = (distance_km * cost_per_km) + ((distance_km / avg_speed) * time_value)
        ) %>%
        group_by(demographic_group = !!sym(demo_var)) %>%
        summarise(
          total_trips = sum(n_trips, na.rm = TRUE),
          avg_cost_per_trip = weighted.mean(total_cost_per_trip, n_trips, na.rm = TRUE),
          total_economic_impact = sum(total_cost_per_trip * n_trips, na.rm = TRUE),
          avg_distance = weighted.mean(distance_km, n_trips, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        mutate(demographic_variable = demo_var) %>%
        arrange(desc(total_economic_impact))
      
      if (is.null(demographic_economics)) {
        demographic_economics <- demo_economic
      } else {
        demographic_economics <- bind_rows(demographic_economics, demo_economic)
      }
    }
  }
  
  # Economic summary statistics
  economic_summary <- list(
    total_economic_impact = sum(economic_flows$total_economic_impact, na.rm = TRUE),
    total_trips_analyzed = sum(economic_flows$total_trips, na.rm = TRUE),
    avg_cost_per_trip = weighted.mean(economic_flows$avg_cost_per_trip, economic_flows$total_trips, na.rm = TRUE),
    total_travel_time_hours = sum(economic_flows$total_travel_time_hours, na.rm = TRUE),
    avg_travel_time_minutes = (sum(economic_flows$total_travel_time_hours, na.rm = TRUE) * 60) / 
                              sum(economic_flows$total_trips, na.rm = TRUE),
    most_expensive_corridor = paste(economic_flows$id_origin[1], "->", economic_flows$id_destination[1]),
    highest_impact_zone = spatial_economics$zone_id[1],
    cost_parameters = list(
      cost_per_km = cost_per_km,
      time_value = time_value,
      avg_speed = avg_speed
    )
  )
  
  return(list(
    economic_flows = economic_flows,
    zone_economics = spatial_economics,
    activity_economics = activity_economics,
    demographic_economics = demographic_economics,
    economic_summary = economic_summary
  ))
}

#' Analyze job accessibility and commuting economics
#'
#' Examines job accessibility, commuting costs, and employment-residence relationships
#' using activity-based mobility data
#'
#' @param mobility_data Data frame with activity and demographic information
#' @param spatial_zones Spatial zones data frame (optional)
#' @param job_activities Vector of activity types representing jobs (default: "frequent_activity")
#' @param home_activities Vector of activity types representing home (default: "home")
#' @param cost_per_km Travel cost per kilometer (default: 0.35)
#' @param min_commute_trips Minimum trips to consider as commuting (default: 5)
#' @return List with job accessibility analysis results
#' @export
#' @examples
#' \dontrun{
#' # Analyze job accessibility
#' job_analysis <- analyze_job_accessibility(mobility_data)
#' print(job_analysis$accessibility_summary)
#' 
#' # Custom job activity definition
#' custom_job_analysis <- analyze_job_accessibility(
#'   mobility_data,
#'   job_activities = c("frequent_activity", "work", "office")
#' )
#' 
#' # Include spatial context
#' spatial_job_analysis <- analyze_job_accessibility(
#'   mobility_data,
#'   spatial_zones = zones
#' )
#' }
analyze_job_accessibility <- function(mobility_data,
                                    spatial_zones = NULL,
                                    job_activities = "frequent_activity",
                                    home_activities = "home",
                                    cost_per_km = 0.35,
                                    min_commute_trips = 5) {
  # Validate required columns
  required_cols <- c("activity_origin", "activity_destination", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Process distance information
  if ("distance" %in% names(mobility_data)) {
    if (is.factor(mobility_data$distance)) {
      distance_mapping <- c("0.5-2" = 1.25, "2-10" = 6, "10-50" = 30, "50+" = 100)
      mobility_data$distance_km <- distance_mapping[as.character(mobility_data$distance)]
    } else {
      mobility_data$distance_km <- as.numeric(mobility_data$distance)
    }
  } else {
    mobility_data$distance_km <- 10  # Default distance
  }
  
  # Identify commuting flows (home <-> job)
  commuting_flows <- mobility_data %>%
    filter(
      (activity_origin %in% home_activities & activity_destination %in% job_activities) |
      (activity_origin %in% job_activities & activity_destination %in% home_activities)
    ) %>%
    mutate(
      commute_direction = case_when(
        activity_origin %in% home_activities ~ "home_to_work",
        activity_destination %in% home_activities ~ "work_to_home",
        TRUE ~ "other"
      ),
      commute_cost = distance_km * cost_per_km
    ) %>%
    filter(n_trips >= min_commute_trips)
  
  # Calculate job accessibility from each residential zone
  job_accessibility <- commuting_flows %>%
    filter(commute_direction == "home_to_work") %>%
    group_by(residential_zone = id_origin) %>%
    summarise(
      accessible_job_zones = n(),
      total_job_trips = sum(n_trips, na.rm = TRUE),
      avg_commute_distance = weighted.mean(distance_km, n_trips, na.rm = TRUE),
      avg_commute_cost = weighted.mean(commute_cost, n_trips, na.rm = TRUE),
      max_commute_distance = max(distance_km, na.rm = TRUE),
      min_commute_cost = min(commute_cost, na.rm = TRUE),
      accessibility_index = sum(n_trips / (distance_km + 1), na.rm = TRUE),  # Gravity-based accessibility
      .groups = "drop"
    ) %>%
    arrange(desc(accessibility_index))
  
  # Calculate employment attraction for each job zone
  employment_attraction <- commuting_flows %>%
    filter(commute_direction == "home_to_work") %>%
    group_by(job_zone = id_destination) %>%
    summarise(
      catchment_residential_zones = n(),
      total_workers = sum(n_trips, na.rm = TRUE),
      avg_worker_distance = weighted.mean(distance_km, n_trips, na.rm = TRUE),
      avg_worker_cost = weighted.mean(commute_cost, n_trips, na.rm = TRUE),
      max_catchment_distance = max(distance_km, na.rm = TRUE),
      employment_centrality = sum(n_trips / (distance_km + 1), na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(employment_centrality))
  
  # Calculate commuting burden and efficiency
  commuting_burden <- commuting_flows %>%
    group_by(id_origin, id_destination) %>%
    summarise(
      total_commute_trips = sum(n_trips, na.rm = TRUE),
      avg_commute_distance = weighted.mean(distance_km, n_trips, na.rm = TRUE),
      total_commute_cost = sum(commute_cost * n_trips, na.rm = TRUE),
      commute_directions = length(unique(commute_direction)),
      .groups = "drop"
    ) %>%
    mutate(
      cost_per_trip = total_commute_cost / total_commute_trips,
      commute_efficiency = total_commute_trips / avg_commute_distance,
      is_bidirectional = commute_directions > 1
    ) %>%
    arrange(desc(total_commute_cost))
  
  # Jobs-housing balance analysis
  jobs_housing_balance <- full_join(
    job_accessibility %>% 
      select(zone_id = residential_zone, residents_job_access = accessibility_index, 
             total_outbound_commuters = total_job_trips),
    employment_attraction %>%
      select(zone_id = job_zone, jobs_attraction = employment_centrality,
             total_inbound_workers = total_workers),
    by = "zone_id"
  ) %>%
    mutate(
      residents_job_access = ifelse(is.na(residents_job_access), 0, residents_job_access),
      jobs_attraction = ifelse(is.na(jobs_attraction), 0, jobs_attraction),
      total_outbound_commuters = ifelse(is.na(total_outbound_commuters), 0, total_outbound_commuters),
      total_inbound_workers = ifelse(is.na(total_inbound_workers), 0, total_inbound_workers),
      jobs_housing_ratio = total_inbound_workers / (total_outbound_commuters + 1),
      balance_index = (residents_job_access + jobs_attraction) / 2,
      zone_type = case_when(
        jobs_housing_ratio > 1.5 ~ "Employment Center",
        jobs_housing_ratio < 0.5 ~ "Residential Area", 
        TRUE ~ "Mixed Use"
      )
    ) %>%
    arrange(desc(balance_index))
  
  # Demographic commuting patterns (if available)
  demographic_commuting <- NULL
  if (any(c("age", "sex", "income") %in% names(mobility_data))) {
    demo_vars <- intersect(c("age", "sex", "income"), names(mobility_data))
    
    for (demo_var in demo_vars) {
      demo_commute <- commuting_flows %>%
        filter(!is.na(!!sym(demo_var))) %>%
        group_by(demographic_group = !!sym(demo_var), commute_direction) %>%
        summarise(
          total_trips = sum(n_trips, na.rm = TRUE),
          avg_distance = weighted.mean(distance_km, n_trips, na.rm = TRUE),
          avg_cost = weighted.mean(commute_cost, n_trips, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        mutate(demographic_variable = demo_var)
      
      if (is.null(demographic_commuting)) {
        demographic_commuting <- demo_commute
      } else {
        demographic_commuting <- bind_rows(demographic_commuting, demo_commute)
      }
    }
  }
  
  # Integrate spatial data if available
  if (!is.null(spatial_zones)) {
    spatial_accessibility <- jobs_housing_balance %>%
      left_join(
        spatial_zones %>% select(zone_id = id, zone_name = name, area_km2, population),
        by = "zone_id"
      ) %>%
      mutate(
        accessibility_density = residents_job_access / (area_km2 + 1),
        employment_density = jobs_attraction / (area_km2 + 1),
        commuter_per_capita = total_outbound_commuters / (population + 1),
        worker_per_capita = total_inbound_workers / (population + 1)
      )
  } else {
    spatial_accessibility <- jobs_housing_balance
  }
  
  # Summary statistics
  accessibility_summary <- list(
    total_commuting_trips = sum(commuting_flows$n_trips, na.rm = TRUE),
    total_residential_zones = nrow(job_accessibility),
    total_employment_zones = nrow(employment_attraction),
    avg_job_accessibility = mean(job_accessibility$accessibility_index, na.rm = TRUE),
    avg_employment_attraction = mean(employment_attraction$employment_centrality, na.rm = TRUE),
    avg_commute_distance = weighted.mean(commuting_flows$distance_km, commuting_flows$n_trips, na.rm = TRUE),
    avg_commute_cost = weighted.mean(commuting_flows$commute_cost, commuting_flows$n_trips, na.rm = TRUE),
    most_accessible_residential = job_accessibility$residential_zone[1],
    strongest_employment_center = employment_attraction$job_zone[1],
    balanced_zones = sum(jobs_housing_balance$zone_type == "Mixed Use", na.rm = TRUE),
    employment_centers = sum(jobs_housing_balance$zone_type == "Employment Center", na.rm = TRUE),
    residential_areas = sum(jobs_housing_balance$zone_type == "Residential Area", na.rm = TRUE)
  )
  
  return(list(
    job_accessibility = job_accessibility,
    employment_attraction = employment_attraction,
    commuting_burden = commuting_burden,
    jobs_housing_balance = spatial_accessibility,
    demographic_commuting = demographic_commuting,
    accessibility_summary = accessibility_summary
  ))
}

#' Analyze income-based mobility patterns
#'
#' Analyzes mobility patterns based on income levels and socioeconomic indicators
#' when available in the mobility data
#'
#' @param mobility_data Data frame with mobility flows and socioeconomic indicators
#' @param spatial_zones Spatial zones data frame with economic indicators (optional)
#' @param income_col Column name for income data (default: "income_level")
#' @param min_trips Minimum trips threshold (default: 10)
#' @return List with income-based mobility analysis results
#' @export
#' @examples
#' \dontrun{
#' # Analyze income mobility patterns
#' income_analysis <- analyze_income_mobility(mobility_data)
#' print(income_analysis$income_summary)
#' 
#' # Use custom income column
#' custom_income <- analyze_income_mobility(
#'   mobility_data,
#'   income_col = "socioeconomic_status"
#' )
#' 
#' # Include spatial economic zones
#' spatial_income <- analyze_income_mobility(
#'   mobility_data,
#'   spatial_zones = zones
#' )
#' }
analyze_income_mobility <- function(mobility_data,
                                   spatial_zones = NULL,
                                   income_col = "income_level",
                                   min_trips = 10) {
  # Validate required columns
  required_cols <- c("id_origin", "id_destination", "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Check for income-related columns
  income_cols <- c(income_col, "income_origin", "income_destination", 
                   "income_level", "socioeconomic_status", "economic_level")
  available_income_cols <- intersect(income_cols, names(mobility_data))
  
  if(length(available_income_cols) == 0) {
    warning("No income-related columns found in mobility data. Available columns: ", 
            paste(names(mobility_data), collapse = ", "))
    return(NULL)
  }
  
  # Use the first available income column
  income_var <- available_income_cols[1]
  
  # Filter data with income information
  income_mobility <- mobility_data %>%
    filter(!is.na(!!sym(income_var)) & n_trips >= min_trips)
  
  if(nrow(income_mobility) == 0) {
    warning("No mobility data with income information after filtering")
    return(NULL)
  }
  
  # Calculate income-based mobility patterns
  income_patterns <- income_mobility %>%
    group_by(income_level = !!sym(income_var)) %>%
    summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      avg_trips_per_flow = mean(n_trips, na.rm = TRUE),
      unique_flows = n(),
      total_origins = n_distinct(id_origin),
      total_destinations = n_distinct(id_destination),
      .groups = "drop"
    ) %>%
    mutate(
      trips_proportion = total_trips / sum(total_trips),
      mobility_index = (total_origins + total_destinations) / 2,
      flow_efficiency = unique_flows / (total_origins * total_destinations)
    ) %>%
    arrange(desc(total_trips))
  
  # Calculate income-based accessibility
  income_accessibility <- income_mobility %>%
    group_by(id_origin, income_level = !!sym(income_var)) %>%
    summarise(
      accessible_destinations = n_distinct(id_destination),
      total_outbound_trips = sum(n_trips, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    group_by(income_level) %>%
    summarise(
      avg_accessibility = mean(accessible_destinations, na.rm = TRUE),
      avg_outbound_trips = mean(total_outbound_trips, na.rm = TRUE),
      accessibility_dispersion = sd(accessible_destinations, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Calculate income mobility matrix
  if("income_origin" %in% names(mobility_data) && "income_destination" %in% names(mobility_data)) {
    income_matrix <- mobility_data %>%
      filter(!is.na(income_origin) & !is.na(income_destination)) %>%
      group_by(income_origin, income_destination) %>%
      summarise(
        total_trips = sum(n_trips, na.rm = TRUE),
        flow_count = n(),
        .groups = "drop"
      ) %>%
      mutate(
        flow_proportion = total_trips / sum(total_trips),
        is_same_income = income_origin == income_destination
      )
    
    # Calculate income mobility rates
    income_mobility_rates <- income_matrix %>%
      group_by(income_origin) %>%
      summarise(
        total_outbound = sum(total_trips),
        same_income_trips = sum(total_trips[is_same_income]),
        income_retention_rate = same_income_trips / total_outbound,
        .groups = "drop"
      )
  } else {
    income_matrix <- NULL
    income_mobility_rates <- NULL
  }
  
  # Summary statistics
  income_summary <- list(
    total_income_levels = nrow(income_patterns),
    most_mobile_income = income_patterns$income_level[1],
    least_mobile_income = income_patterns$income_level[nrow(income_patterns)],
    income_mobility_inequality = sd(income_patterns$trips_proportion, na.rm = TRUE),
    avg_accessibility_by_income = mean(income_accessibility$avg_accessibility, na.rm = TRUE)
  )
  
  return(list(
    income_patterns = income_patterns,
    income_accessibility = income_accessibility,
    income_matrix = income_matrix,
    income_mobility_rates = income_mobility_rates,
    income_summary = income_summary,
    analysis_column = income_var
  ))
}
