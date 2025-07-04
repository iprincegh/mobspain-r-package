#' Demographic-based mobility analysis functions
#'
#' Advanced analytical functions for demographic and socioeconomic mobility patterns
#' using MITMA Version 2 data (2022 onwards) with sociodemographic factors.

#' Analyze mobility patterns by demographic characteristics
#'
#' Examines mobility flows by age groups, gender, and income levels
#' Available in Version 2 data (2022 onwards)
#'
#' @param mobility_data Data frame with demographic columns (age, sex, income)
#' @param demographic_var Demographic variable to analyze: "age", "sex", "income"
#' @param min_trips Minimum trips threshold for inclusion (default: 10)
#' @param normalize Whether to normalize by total trips (default: TRUE)
#' @return List with demographic mobility analysis results
#' @export
#' @examples
#' \dontrun{
#' # Analyze mobility by age groups
#' age_mobility <- analyze_demographic_mobility(
#'   mobility_data, 
#'   demographic_var = "age"
#' )
#' print(age_mobility$summary)
#' 
#' # Analyze mobility by gender
#' gender_mobility <- analyze_demographic_mobility(
#'   mobility_data, 
#'   demographic_var = "sex",
#'   min_trips = 20
#' )
#' 
#' # Analyze mobility by income levels
#' income_mobility <- analyze_demographic_mobility(
#'   mobility_data, 
#'   demographic_var = "income"
#' )
#' }
analyze_demographic_mobility <- function(mobility_data, 
                                       demographic_var = "age", 
                                       min_trips = 10,
                                       normalize = TRUE) {
  # Validate inputs
  if (!demographic_var %in% c("age", "sex", "income")) {
    stop("demographic_var must be one of: 'age', 'sex', 'income'")
  }
  
  required_cols <- c(demographic_var, "n_trips", "id_origin", "id_destination")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Check if demographic variable has data
  if (all(is.na(mobility_data[[demographic_var]]))) {
    stop("No data available for demographic variable: ", demographic_var, 
         ". This may require Version 2 data (2022 onwards).")
  }
  
  # Create demographic groups
  if (demographic_var == "age") {
    mobility_data <- mobility_data %>%
      mutate(
        demo_group = case_when(
          is.na(age) ~ "Unknown",
          age %in% c("16-24", "0-16", "16-24") ~ "Young (16-24)",
          age %in% c("25-34", "25-44") ~ "Young Adult (25-44)",
          age %in% c("35-44", "45-54") ~ "Middle Age (35-54)",
          age %in% c("55-64", "55+", "65+") ~ "Senior (55+)",
          TRUE ~ as.character(age)
        )
      )
  } else if (demographic_var == "sex") {
    mobility_data <- mobility_data %>%
      mutate(
        demo_group = case_when(
          is.na(sex) ~ "Unknown",
          sex %in% c("male", "M", "hombre") ~ "Male",
          sex %in% c("female", "F", "mujer") ~ "Female",
          TRUE ~ as.character(sex)
        )
      )
  } else if (demographic_var == "income") {
    mobility_data <- mobility_data %>%
      mutate(
        demo_group = case_when(
          is.na(income) ~ "Unknown",
          income %in% c("low", "bajo", "< 18k") ~ "Low Income",
          income %in% c("medium-low", "medio-bajo", "18-30k") ~ "Medium-Low Income",
          income %in% c("medium", "medio", "30-50k") ~ "Medium Income",
          income %in% c("medium-high", "medio-alto", "50-75k") ~ "Medium-High Income",
          income %in% c("high", "alto", "> 75k") ~ "High Income",
          TRUE ~ as.character(income)
        )
      )
  }
  
  # Calculate demographic mobility patterns
  demo_patterns <- mobility_data %>%
    filter(!is.na(demo_group) & demo_group != "Unknown") %>%
    group_by(demo_group) %>%
    summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      unique_flows = n(),
      avg_trips_per_flow = mean(n_trips, na.rm = TRUE),
      median_trips = median(n_trips, na.rm = TRUE),
      unique_origins = length(unique(id_origin)),
      unique_destinations = length(unique(id_destination)),
      spatial_coverage = length(unique(c(id_origin, id_destination))),
      .groups = "drop"
    ) %>%
    filter(total_trips >= min_trips) %>%
    arrange(desc(total_trips))
  
  # Calculate mobility diversity by demographic group
  mobility_diversity <- mobility_data %>%
    filter(!is.na(demo_group) & demo_group != "Unknown") %>%
    group_by(demo_group, id_origin, id_destination) %>%
    summarise(flow_trips = sum(n_trips, na.rm = TRUE), .groups = "drop") %>%
    group_by(demo_group) %>%
    summarise(
      flow_concentration = sum(flow_trips^2) / sum(flow_trips)^2,  # Herfindahl index
      flow_entropy = -sum((flow_trips/sum(flow_trips)) * log(flow_trips/sum(flow_trips)), na.rm = TRUE),
      .groups = "drop"
    )
  
  # Calculate demographic mobility inequality
  if (normalize) {
    demo_patterns <- demo_patterns %>%
      mutate(
        trip_share = total_trips / sum(total_trips),
        flow_share = unique_flows / sum(unique_flows),
        spatial_share = spatial_coverage / sum(spatial_coverage)
      )
  }
  
  # Cross-demographic comparison
  if (demographic_var == "age") {
    # Calculate age-specific mobility characteristics
    age_characteristics <- mobility_data %>%
      filter(!is.na(demo_group) & demo_group != "Unknown") %>%
      group_by(demo_group) %>%
      summarise(
        avg_distance_pref = names(sort(table(distance), decreasing = TRUE))[1],
        most_common_activity = names(sort(table(activity_origin), decreasing = TRUE))[1],
        weekend_ratio = mean(lubridate::wday(date) %in% c(1, 7), na.rm = TRUE),
        .groups = "drop"
      )
    
    demo_patterns <- demo_patterns %>%
      left_join(age_characteristics, by = "demo_group")
  }
  
  # Summary statistics
  summary_stats <- list(
    total_demographic_groups = nrow(demo_patterns),
    largest_group = demo_patterns$demo_group[1],
    total_trips_analyzed = sum(demo_patterns$total_trips),
    demographic_coverage = nrow(demo_patterns) / length(unique(mobility_data$demo_group[!is.na(mobility_data$demo_group)])),
    mobility_inequality = sd(demo_patterns$total_trips) / mean(demo_patterns$total_trips)  # Coefficient of variation
  )
  
  return(list(
    demographic_patterns = demo_patterns,
    mobility_diversity = mobility_diversity,
    summary = summary_stats,
    variable_analyzed = demographic_var
  ))
}

#' Analyze mobility patterns by residence province
#'
#' Examines mobility flows by residence province information
#' Available in Version 2 data (2022 onwards)
#'
#' @param mobility_data Data frame with residence province columns
#' @param min_trips Minimum trips threshold for inclusion (default: 10)
#' @param focus_provinces Vector of province codes to focus on (optional)
#' @return List with residence-based mobility analysis results
#' @export
#' @examples
#' \dontrun{
#' # Analyze mobility by residence province
#' residence_mobility <- analyze_residence_mobility(mobility_data)
#' print(residence_mobility$migration_flows)
#' 
#' # Focus on specific provinces
#' madrid_mobility <- analyze_residence_mobility(
#'   mobility_data,
#'   focus_provinces = c("28", "Madrid")
#' )
#' }
analyze_residence_mobility <- function(mobility_data, 
                                     min_trips = 10,
                                     focus_provinces = NULL) {
  # Look for residence province columns
  residence_cols <- names(mobility_data)[grepl("residence.*province", names(mobility_data), ignore.case = TRUE)]
  
  if (length(residence_cols) == 0) {
    stop("No residence province columns found. This requires Version 2 data (2022 onwards).")
  }
  
  # Use the first residence province column found
  residence_col <- residence_cols[1]
  message("Using residence column: ", residence_col)
  
  # Check if residence variable has data
  if (all(is.na(mobility_data[[residence_col]]))) {
    stop("No data available for residence province. This may require Version 2 data (2022 onwards).")
  }
  
  # Filter by focus provinces if specified
  if (!is.null(focus_provinces)) {
    mobility_data <- mobility_data %>%
      filter(!!sym(residence_col) %in% focus_provinces)
  }
  
  # Calculate residence-based mobility patterns
  residence_patterns <- mobility_data %>%
    filter(!is.na(!!sym(residence_col))) %>%
    group_by(residence_province = !!sym(residence_col)) %>%
    summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      unique_flows = n(),
      avg_trips_per_flow = mean(n_trips, na.rm = TRUE),
      unique_origins = length(unique(id_origin)),
      unique_destinations = length(unique(id_destination)),
      spatial_coverage = length(unique(c(id_origin, id_destination))),
      .groups = "drop"
    ) %>%
    filter(total_trips >= min_trips) %>%
    arrange(desc(total_trips))
  
  # Calculate migration flows (residence vs travel patterns)
  # Identify trips where residence province differs from origin/destination
  if ("id_origin" %in% names(mobility_data) && "id_destination" %in% names(mobility_data)) {
    # This would require spatial matching between zone IDs and provinces
    # For now, we'll analyze residence-based patterns
    migration_flows <- mobility_data %>%
      filter(!is.na(!!sym(residence_col))) %>%
      group_by(
        residence_province = !!sym(residence_col),
        id_origin,
        id_destination
      ) %>%
      summarise(
        migration_trips = sum(n_trips, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      group_by(residence_province) %>%
      summarise(
        internal_flows = sum(migration_trips[id_origin == id_destination]),
        external_flows = sum(migration_trips[id_origin != id_destination]),
        migration_ratio = external_flows / (internal_flows + external_flows),
        .groups = "drop"
      )
  } else {
    migration_flows <- residence_patterns %>%
      mutate(
        migration_ratio = NA,
        note = "Migration analysis requires origin-destination data"
      )
  }
  
  # Calculate residence province connectivity
  connectivity <- mobility_data %>%
    filter(!is.na(!!sym(residence_col))) %>%
    group_by(residence_province = !!sym(residence_col)) %>%
    summarise(
      provinces_connected = length(unique(c(id_origin, id_destination))),
      avg_connectivity = mean(unique_flows, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Summary statistics
  summary_stats <- list(
    total_residence_provinces = nrow(residence_patterns),
    largest_residence_province = residence_patterns$residence_province[1],
    total_trips_analyzed = sum(residence_patterns$total_trips),
    avg_migration_ratio = mean(migration_flows$migration_ratio, na.rm = TRUE),
    residence_column_used = residence_col
  )
  
  return(list(
    residence_patterns = residence_patterns,
    migration_flows = migration_flows,
    connectivity = connectivity,
    summary = summary_stats
  ))
}

#' Analyze socioeconomic mobility patterns
#'
#' Comprehensive analysis combining demographic and socioeconomic factors
#' Available in Version 2 data (2022 onwards)
#'
#' @param mobility_data Data frame with demographic and socioeconomic columns
#' @param factors Vector of factors to analyze: "age", "sex", "income", "residence"
#' @param min_trips Minimum trips threshold for inclusion (default: 10)
#' @param interaction_analysis Whether to analyze factor interactions (default: TRUE)
#' @return List with comprehensive socioeconomic mobility analysis
#' @export
#' @examples
#' \dontrun{
#' # Comprehensive socioeconomic analysis
#' socio_mobility <- analyze_socioeconomic_mobility(mobility_data)
#' print(socio_mobility$factor_interactions)
#' 
#' # Focus on specific factors
#' gender_income_mobility <- analyze_socioeconomic_mobility(
#'   mobility_data,
#'   factors = c("sex", "income")
#' )
#' }
analyze_socioeconomic_mobility <- function(mobility_data, 
                                         factors = c("age", "sex", "income"),
                                         min_trips = 10,
                                         interaction_analysis = TRUE) {
  # Validate available factors
  available_factors <- intersect(factors, names(mobility_data))
  if (length(available_factors) == 0) {
    stop("None of the specified factors are available in the data. This may require Version 2 data (2022 onwards).")
  }
  
  if (length(available_factors) < length(factors)) {
    missing_factors <- setdiff(factors, available_factors)
    warning("Missing factors: ", paste(missing_factors, collapse = ", "))
  }
  
  # Individual factor analysis
  factor_results <- list()
  for (factor in available_factors) {
    factor_results[[factor]] <- analyze_demographic_mobility(
      mobility_data, 
      demographic_var = factor, 
      min_trips = min_trips
    )
  }
  
  # Factor interactions analysis
  if (interaction_analysis && length(available_factors) >= 2) {
    # Analyze interactions between factors
    interaction_results <- list()
    
    for (i in 1:(length(available_factors) - 1)) {
      for (j in (i + 1):length(available_factors)) {
        factor1 <- available_factors[i]
        factor2 <- available_factors[j]
        
        # Create interaction groups
        interaction_data <- mobility_data %>%
          filter(!is.na(!!sym(factor1)) & !is.na(!!sym(factor2))) %>%
          mutate(
            interaction_group = paste(!!sym(factor1), !!sym(factor2), sep = "_")
          )
        
        if (nrow(interaction_data) > 0) {
          interaction_analysis_result <- interaction_data %>%
            group_by(interaction_group) %>%
            summarise(
              total_trips = sum(n_trips, na.rm = TRUE),
              unique_flows = n(),
              avg_trips_per_flow = mean(n_trips, na.rm = TRUE),
              spatial_coverage = length(unique(c(id_origin, id_destination))),
              .groups = "drop"
            ) %>%
            filter(total_trips >= min_trips) %>%
            arrange(desc(total_trips))
          
          interaction_results[[paste(factor1, factor2, sep = "_")]] <- interaction_analysis_result
        }
      }
    }
  } else {
    interaction_results <- NULL
  }
  
  # Cross-factor comparison
  if (length(available_factors) >= 2) {
    # Compare mobility patterns across factors
    factor_comparison <- data.frame(
      factor = available_factors,
      total_groups = sapply(available_factors, function(f) {
        length(unique(mobility_data[[f]][!is.na(mobility_data[[f]])]))
      }),
      total_trips = sapply(available_factors, function(f) {
        sum(mobility_data$n_trips[!is.na(mobility_data[[f]])], na.rm = TRUE)
      }),
      coverage = sapply(available_factors, function(f) {
        mean(!is.na(mobility_data[[f]]))
      }),
      stringsAsFactors = FALSE
    )
    
    factor_comparison <- factor_comparison %>%
      mutate(
        trips_per_group = total_trips / total_groups,
        relative_coverage = coverage / max(coverage)
      ) %>%
      arrange(desc(total_trips))
  } else {
    factor_comparison <- NULL
  }
  
  # Summary statistics
  summary_stats <- list(
    factors_analyzed = available_factors,
    total_interactions = ifelse(is.null(interaction_results), 0, length(interaction_results)),
    most_important_factor = ifelse(is.null(factor_comparison), available_factors[1], factor_comparison$factor[1]),
    data_coverage = sapply(available_factors, function(f) mean(!is.na(mobility_data[[f]]))),
    total_trips_analyzed = sum(mobility_data$n_trips, na.rm = TRUE)
  )
  
  return(list(
    factor_results = factor_results,
    factor_interactions = interaction_results,
    factor_comparison = factor_comparison,
    summary = summary_stats
  ))
}

#' Analyze temporal mobility patterns by demographics
#'
#' Examines how mobility patterns vary by time of day, day of week, and demographic characteristics
#'
#' @param mobility_data Data frame with temporal and demographic columns
#' @param demographic_var Demographic variable to analyze: "age", "sex", "income"
#' @param temporal_var Temporal variable to analyze: "hour", "weekday", "date"
#' @param min_trips Minimum trips threshold for inclusion (default: 10)
#' @return List with temporal-demographic mobility analysis
#' @export
#' @examples
#' \dontrun{
#' # Analyze hourly patterns by age
#' temporal_age <- analyze_temporal_demographic_mobility(
#'   mobility_data,
#'   demographic_var = "age",
#'   temporal_var = "hour"
#' )
#' 
#' # Analyze weekday patterns by income
#' temporal_income <- analyze_temporal_demographic_mobility(
#'   mobility_data,
#'   demographic_var = "income",
#'   temporal_var = "weekday"
#' )
#' }
analyze_temporal_demographic_mobility <- function(mobility_data, 
                                                demographic_var = "age",
                                                temporal_var = "hour",
                                                min_trips = 10) {
  # Validate inputs
  required_cols <- c(demographic_var, temporal_var, "n_trips")
  missing_cols <- setdiff(required_cols, names(mobility_data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Check for data availability
  if (all(is.na(mobility_data[[demographic_var]]))) {
    stop("No data available for demographic variable: ", demographic_var)
  }
  
  # Create temporal groups
  if (temporal_var == "hour") {
    mobility_data <- mobility_data %>%
      mutate(
        temporal_group = case_when(
          hour %in% 6:9 ~ "Morning Rush (6-9)",
          hour %in% 10:15 ~ "Midday (10-15)",
          hour %in% 16:19 ~ "Evening Rush (16-19)",
          hour %in% 20:23 ~ "Evening (20-23)",
          hour %in% 0:5 ~ "Night (0-5)",
          TRUE ~ as.character(hour)
        )
      )
  } else if (temporal_var == "weekday") {
    mobility_data <- mobility_data %>%
      mutate(
        temporal_group = case_when(
          lubridate::wday(date) %in% 2:6 ~ "Weekday",
          lubridate::wday(date) %in% c(1, 7) ~ "Weekend",
          TRUE ~ "Unknown"
        )
      )
  } else if (temporal_var == "date") {
    mobility_data <- mobility_data %>%
      mutate(
        temporal_group = as.character(date)
      )
  }
  
  # Create demographic groups (simplified)
  mobility_data <- mobility_data %>%
    mutate(
      demo_group = case_when(
        is.na(!!sym(demographic_var)) ~ "Unknown",
        TRUE ~ as.character(!!sym(demographic_var))
      )
    )
  
  # Calculate temporal-demographic patterns
  temporal_demo_patterns <- mobility_data %>%
    filter(!is.na(demo_group) & demo_group != "Unknown") %>%
    group_by(demo_group, temporal_group) %>%
    summarise(
      total_trips = sum(n_trips, na.rm = TRUE),
      unique_flows = n(),
      avg_trips_per_flow = mean(n_trips, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(total_trips >= min_trips)
  
  # Calculate peak hours by demographic group
  if (temporal_var == "hour") {
    peak_analysis <- temporal_demo_patterns %>%
      group_by(demo_group) %>%
      summarise(
        peak_period = temporal_group[which.max(total_trips)],
        peak_trips = max(total_trips),
        off_peak_ratio = min(total_trips) / max(total_trips),
        .groups = "drop"
      )
  } else {
    peak_analysis <- temporal_demo_patterns %>%
      group_by(demo_group) %>%
      summarise(
        peak_period = temporal_group[which.max(total_trips)],
        peak_trips = max(total_trips),
        .groups = "drop"
      )
  }
  
  # Calculate temporal mobility equality
  temporal_equality <- temporal_demo_patterns %>%
    group_by(demo_group) %>%
    summarise(
      temporal_diversity = length(unique(temporal_group)),
      mobility_concentration = sum(total_trips^2) / sum(total_trips)^2,
      .groups = "drop"
    )
  
  # Summary statistics
  summary_stats <- list(
    demographic_variable = demographic_var,
    temporal_variable = temporal_var,
    total_demo_groups = length(unique(temporal_demo_patterns$demo_group)),
    total_temporal_periods = length(unique(temporal_demo_patterns$temporal_group)),
    total_trips_analyzed = sum(temporal_demo_patterns$total_trips),
    most_active_demo_group = temporal_demo_patterns$demo_group[which.max(temporal_demo_patterns$total_trips)],
    most_active_temporal_period = temporal_demo_patterns$temporal_group[which.max(temporal_demo_patterns$total_trips)]
  )
  
  return(list(
    temporal_demographic_patterns = temporal_demo_patterns,
    peak_analysis = peak_analysis,
    temporal_equality = temporal_equality,
    summary = summary_stats
  ))
}
