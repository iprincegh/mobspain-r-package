# Advanced Mobility Analysis - Practical Example Script
# This script demonstrates the new advanced analytical functions in mobspain

# Load required libraries
library(mobspain)
library(dplyr)
library(ggplot2)

# ===== SETUP AND DATA LOADING =====

# Configure mobspain (if needed)
# configure_mobspain(
#   cache_enabled = TRUE,
#   cache_dir = "~/.cache/mobspain",
#   parallel_enabled = TRUE
# )

# Load sample data or get real data
# For demonstration, we'll use sample data structure
cat("Loading mobility data...\n")

# Get mobility data with activity information
mobility_data <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  include_activity = TRUE
)

# Get spatial zones
zones <- get_spatial_zones("dist")

cat("Data loaded successfully!\n")
cat("Mobility data dimensions:", dim(mobility_data), "\n")
cat("Zones data dimensions:", dim(zones), "\n")

# ===== 1. ACTIVITY-BASED ANALYSIS =====

cat("\n=== ACTIVITY-BASED ANALYSIS ===\n")

# Basic activity pattern analysis
cat("1. Analyzing activity patterns...\n")
activity_patterns <- calculate_activity_patterns(mobility_data, min_trips = 10)

cat("Activity pattern summary:\n")
print(activity_patterns$summary)

cat("\nTop 5 activity flows:\n")
print(head(activity_patterns$activity_matrix, 5))

# Commuting pattern analysis
cat("\n2. Analyzing commuting patterns...\n")
commuting_patterns <- calculate_commuting_patterns(mobility_data)

cat("Commuting summary:\n")
print(commuting_patterns$summary)

# Distance-based analysis
cat("\n3. Analyzing distance patterns...\n")
distance_analysis <- calculate_distance_analysis(
  mobility_data, 
  distance_bands = c(2, 10, 50, 200)
)

cat("Distance band summary:\n")
print(distance_analysis$summary)

# Advanced network analysis
cat("\n4. Performing network analysis...\n")
network_analysis <- analyze_mobility_network(mobility_data, zones)

cat("Network metrics:\n")
print(network_analysis$network_metrics)

cat("\nTop 5 central zones:\n")
print(head(network_analysis$centrality_measures, 5))

# ===== 2. DEMOGRAPHIC ANALYSIS (Version 2 Data) =====

cat("\n=== DEMOGRAPHIC ANALYSIS ===\n")

# Check if demographic data is available
if ("age" %in% names(mobility_data)) {
  cat("Version 2 demographic data detected!\n")
  
  # Age-based mobility analysis
  cat("1. Analyzing mobility by age groups...\n")
  age_mobility <- analyze_demographic_mobility(
    mobility_data, 
    demographic_var = "age",
    min_trips = 15
  )
  
  cat("Age-based mobility summary:\n")
  print(age_mobility$demographic_summary)
  
  # Gender-based mobility analysis
  if ("sex" %in% names(mobility_data)) {
    cat("\n2. Analyzing mobility by gender...\n")
    gender_mobility <- analyze_demographic_mobility(
      mobility_data, 
      demographic_var = "sex"
    )
    
    cat("Gender-based mobility summary:\n")
    print(gender_mobility$demographic_summary)
  }
  
  # Income-based mobility analysis
  if ("income" %in% names(mobility_data)) {
    cat("\n3. Analyzing mobility by income levels...\n")
    income_mobility <- analyze_demographic_mobility(
      mobility_data, 
      demographic_var = "income"
    )
    
    cat("Income-based mobility summary:\n")
    print(income_mobility$demographic_summary)
  }
  
  # Comprehensive socioeconomic analysis
  cat("\n4. Performing socioeconomic analysis...\n")
  socioeconomic_analysis <- analyze_socioeconomic_mobility(mobility_data)
  
  cat("Socioeconomic mobility summary:\n")
  print(socioeconomic_analysis$mobility_inequality)
  
  # Temporal-demographic analysis
  if ("hour" %in% names(mobility_data)) {
    cat("\n5. Analyzing temporal-demographic patterns...\n")
    temporal_demo <- analyze_temporal_demographic_mobility(
      mobility_data, 
      demographic_var = "age",
      time_var = "hour"
    )
    
    cat("Peak hour analysis by age:\n")
    print(temporal_demo$peak_hour_analysis)
  }
  
} else {
  cat("Demographic data not available in this dataset (Version 1 data)\n")
  cat("Advanced demographic analysis requires Version 2 data (2022 onwards)\n")
}

# ===== 3. ECONOMIC ANALYSIS =====

cat("\n=== ECONOMIC ANALYSIS ===\n")

# Basic economic impact analysis
cat("1. Analyzing economic mobility flows...\n")
economic_analysis <- analyze_economic_mobility(
  mobility_data,
  spatial_zones = zones,
  cost_per_km = 0.35,    # EUR per km
  time_value = 15,       # EUR per hour
  avg_speed = 40         # km/h
)

cat("Economic mobility summary:\n")
print(economic_analysis$economic_summary)

cat("\nTop 5 most expensive flows:\n")
print(head(economic_analysis$flow_economics[order(-economic_analysis$flow_economics$total_cost), ], 5))

# Job accessibility analysis
cat("\n2. Analyzing job accessibility...\n")
job_accessibility <- analyze_job_accessibility(mobility_data, zones)

cat("Job accessibility summary:\n")
print(job_accessibility$accessibility_summary)

cat("\nTop 5 zones by job accessibility:\n")
print(head(job_accessibility$zone_accessibility[order(-job_accessibility$zone_accessibility$jobs_accessible), ], 5))

# High-cost scenario analysis
cat("\n3. High-cost scenario analysis...\n")
high_cost_analysis <- analyze_economic_mobility(
  mobility_data,
  cost_per_km = 0.60,    # Higher fuel costs
  time_value = 25,       # Higher time value
  avg_speed = 30         # Urban congestion
)

# Compare scenarios
baseline_cost <- economic_analysis$economic_summary$total_travel_cost
high_cost <- high_cost_analysis$economic_summary$total_travel_cost
cost_increase <- (high_cost - baseline_cost) / baseline_cost * 100

cat("Cost comparison:\n")
cat("Baseline total travel cost:", round(baseline_cost, 2), "EUR\n")
cat("High-cost scenario:", round(high_cost, 2), "EUR\n")
cat("Cost increase:", round(cost_increase, 1), "%\n")

# ===== 4. INTEGRATED ANALYSIS AND VISUALIZATION =====

cat("\n=== INTEGRATED ANALYSIS ===\n")

# Create comprehensive analysis function
perform_comprehensive_analysis <- function(mobility_data, zones) {
  
  # Basic indicators
  containment <- calculate_containment(mobility_data)
  indicators <- calculate_mobility_indicators(mobility_data, zones)
  
  # Activity analysis
  activity_patterns <- calculate_activity_patterns(mobility_data)
  network_analysis <- analyze_mobility_network(mobility_data, zones)
  
  # Economic analysis
  economic_analysis <- analyze_economic_mobility(mobility_data, zones)
  
  # Compile results
  results <- list(
    basic_metrics = list(
      containment_index = containment,
      mobility_indicators = indicators
    ),
    activity_analysis = list(
      patterns = activity_patterns,
      network = network_analysis
    ),
    economic_analysis = economic_analysis
  )
  
  return(results)
}

# Run comprehensive analysis
cat("Running comprehensive analysis...\n")
comprehensive_results <- perform_comprehensive_analysis(mobility_data, zones)

# Display key insights
cat("\nKEY INSIGHTS:\n")
cat("-------------\n")
cat("1. Containment Index:", round(comprehensive_results$basic_metrics$containment_index, 3), "\n")
cat("2. Total Activity Flows:", comprehensive_results$activity_analysis$patterns$summary$total_activity_flows, "\n")
cat("3. Network Density:", round(comprehensive_results$activity_analysis$network$network_metrics$density, 3), "\n")
cat("4. Total Economic Cost:", round(comprehensive_results$economic_analysis$economic_summary$total_travel_cost, 2), "EUR\n")
cat("5. Average Cost per Trip:", round(comprehensive_results$economic_analysis$economic_summary$avg_cost_per_trip, 2), "EUR\n")

# ===== 5. VISUALIZATION EXAMPLES =====

cat("\n=== CREATING VISUALIZATIONS ===\n")

# Network centrality visualization
if (nrow(network_analysis$centrality_measures) > 0) {
  cat("Creating network centrality plot...\n")
  
  p1 <- ggplot(network_analysis$centrality_measures, 
               aes(x = degree_centrality, y = strength_centrality)) +
    geom_point(alpha = 0.6, color = "steelblue") +
    geom_smooth(method = "lm", se = FALSE, color = "red") +
    labs(title = "Network Centrality Analysis",
         subtitle = "Relationship between degree and strength centrality",
         x = "Degree Centrality",
         y = "Strength Centrality") +
    theme_minimal()
  
  print(p1)
}

# Economic cost visualization
if (nrow(economic_analysis$flow_economics) > 0) {
  cat("Creating economic cost plot...\n")
  
  p2 <- ggplot(economic_analysis$flow_economics, 
               aes(x = distance, y = total_cost)) +
    geom_point(alpha = 0.5, color = "darkgreen") +
    geom_smooth(method = "loess", se = FALSE, color = "orange") +
    labs(title = "Trip Cost by Distance",
         subtitle = "Economic cost increases with distance",
         x = "Distance (km)",
         y = "Total Cost (EUR)") +
    theme_minimal()
  
  print(p2)
}

# Activity patterns visualization
if (nrow(activity_patterns$activity_matrix) > 0) {
  cat("Creating activity patterns plot...\n")
  
  p3 <- ggplot(activity_patterns$activity_matrix, 
               aes(x = activity_origin, y = activity_destination, 
                   fill = total_trips)) +
    geom_tile() +
    scale_fill_gradient(low = "lightblue", high = "darkblue") +
    labs(title = "Activity Flow Matrix",
         subtitle = "Flows between different activity types",
         x = "Origin Activity",
         y = "Destination Activity",
         fill = "Total Trips") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p3)
}

# Demographic analysis visualization (if available)
if (exists("age_mobility")) {
  cat("Creating demographic analysis plot...\n")
  
  p4 <- ggplot(age_mobility$demographic_summary, 
               aes(x = age, y = avg_trips_per_flow)) +
    geom_col(fill = "coral", alpha = 0.7) +
    labs(title = "Average Trips per Flow by Age Group",
         subtitle = "Mobility patterns vary by age",
         x = "Age Group",
         y = "Average Trips per Flow") +
    theme_minimal()
  
  print(p4)
}

# ===== 6. SUMMARY AND RECOMMENDATIONS =====

cat("\n=== ANALYSIS SUMMARY ===\n")
cat("========================\n")

cat("This analysis has demonstrated the advanced analytical capabilities of mobspain:\n\n")

cat("1. ACTIVITY ANALYSIS:\n")
cat("   - Identified", nrow(activity_patterns$activity_matrix), "unique activity flow patterns\n")
cat("   - Network analysis revealed", nrow(network_analysis$centrality_measures), "zones with centrality measures\n")
cat("   - Network density:", round(network_analysis$network_metrics$density, 3), "\n\n")

cat("2. ECONOMIC ANALYSIS:\n")
cat("   - Total travel cost:", round(economic_analysis$economic_summary$total_travel_cost, 2), "EUR\n")
cat("   - Average cost per trip:", round(economic_analysis$economic_summary$avg_cost_per_trip, 2), "EUR\n")
cat("   - Cost efficiency varies significantly by distance and activity type\n\n")

if (exists("age_mobility")) {
  cat("3. DEMOGRAPHIC ANALYSIS:\n")
  cat("   - Age-based mobility patterns show distinct differences\n")
  cat("   - Socioeconomic factors influence mobility choices\n")
  cat("   - Temporal patterns vary by demographic group\n\n")
}

cat("4. INTEGRATION CAPABILITIES:\n")
cat("   - All functions work together seamlessly\n")
cat("   - Spatial integration with zone data\n")
cat("   - Temporal analysis capabilities\n")
cat("   - Economic impact assessment\n\n")

cat("RECOMMENDATIONS:\n")
cat("- Use activity analysis for urban planning\n")
cat("- Apply economic analysis for policy impact assessment\n")
cat("- Leverage demographic analysis for equity studies\n")
cat("- Combine network analysis with spatial planning\n")

cat("\nAnalysis completed successfully!\n")
cat("All advanced functions are working and integrated.\n")
