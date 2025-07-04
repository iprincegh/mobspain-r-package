# Workflow Examples

Complete, practical examples of how to use the mobspain package functions for different analysis scenarios.

## Table of Contents

1. [Basic Setup and Data Loading](#basic-setup-and-data-loading)
2. [Exploratory Data Analysis](#exploratory-data-analysis)
3. [Advanced Mobility Analysis](#advanced-mobility-analysis)
4. [Comprehensive Visualization](#comprehensive-visualization)
5. [District-Specific Analysis](#district-specific-analysis)
6. [Data Quality and Validation](#data-quality-and-validation)
7. [Version Selection and Comparison](#version-selection-and-comparison)

## Basic Setup and Data Loading

```r
# Load the mobspain package
library(mobspain)

# 1. Initialize data directory (choose version)
# Version 2 (recommended): Enhanced data with sociodemographic factors
init_data_dir("~/spanish_mobility_data", version = 2)

# Check package status
status <- mobspain_status()
print(status)

# 2. Load spatial zones
zones <- get_spatial_zones("dist")  # District level
print(head(zones))

# 3. Load mobility data for a specific date range
mobility_data <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist"
)
print(head(mobility_data))
```

## Exploratory Data Analysis

```r
# 1. Get version information
version_info <- get_data_version_info()
print(version_info$comparison)

# 2. Validate data quality
quality_report <- validate_mitma_data(mobility_data)
print(quality_report)

# 3. Check for holidays in your data
unique_dates <- unique(mobility_data$date)
holiday_check <- check_spanish_holidays(unique_dates)
print(holiday_check[holiday_check$is_likely_holiday, ])

# 4. Calculate basic mobility indicators
indicators <- calculate_mobility_indicators(mobility_data, zones)
print(head(indicators))

# 5. Identify zones with highest mobility
top_outflow <- indicators[order(-indicators$total_outflow), ][1:10, ]
print(top_outflow)

# 6. Calculate containment (self-containment index)
containment <- calculate_containment(mobility_data)
print(head(containment))
```

## Advanced Mobility Analysis

```r
# 1. Distance-decay analysis
decay_analysis <- calculate_distance_decay(mobility_data, zones, model = "power")
print(decay_analysis$parameters)

# 2. Detect mobility anomalies
anomalies <- detect_mobility_anomalies(mobility_data, method = "zscore")
print(anomalies[anomalies$anomaly, ])

# 3. Morning rush hour analysis
morning_rush <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist",
  time_window = c(7, 9)
)

rush_indicators <- calculate_mobility_indicators(morning_rush, zones)
print(head(rush_indicators))

# 4. Weekend vs weekday comparison
weekend_data <- get_mobility_matrix(
  dates = c("2023-01-07", "2023-01-08"),  # Weekend
  level = "dist"
)

weekday_data <- get_mobility_matrix(
  dates = c("2023-01-09", "2023-01-13"),  # Weekdays
  level = "dist"
)

weekend_indicators <- calculate_mobility_indicators(weekend_data)
weekday_indicators <- calculate_mobility_indicators(weekday_data)

# Compare average flows
cat("Weekend average flow:", mean(weekend_indicators$total_outflow), "\n")
cat("Weekday average flow:", mean(weekday_indicators$total_outflow), "\n")
```

## Comprehensive Visualization

```r
# 1. Create individual plots
# Daily mobility pattern
daily_plot <- plot_daily_mobility(mobility_data)
print(daily_plot)
ggsave("daily_mobility.png", daily_plot, width = 10, height = 6)

# Mobility heatmap
heatmap_plot <- plot_mobility_heatmap(mobility_data, top_n = 30)
print(heatmap_plot)
ggsave("mobility_heatmap.png", heatmap_plot, width = 12, height = 8)

# Distance decay plot
decay_plot <- plot_distance_decay(decay_analysis)
print(decay_plot)
ggsave("distance_decay.png", decay_plot, width = 10, height = 6)

# 2. Interactive flow map
flow_map <- create_flow_map(zones, mobility_data, min_flow = 500, interactive = TRUE)
print(flow_map)

# 3. Choropleth map
choropleth_map <- create_choropleth_map(zones, indicators, "total_outflow")
print(choropleth_map)

# 4. Comprehensive visualization suite
viz_suite <- create_mobility_viz_suite(
  zones = zones,
  mobility_data = mobility_data,
  viz_type = "both",
  output_format = "all"
)

# Export all visualizations
export_visualizations(viz_suite, 
                     output_dir = "mobility_analysis_plots",
                     formats = c("png", "pdf", "html"))
```

## District-Specific Analysis

```r
# Analyze mobility patterns for Madrid (district 28079)
madrid_analysis <- analyze_district_mobility(
  district_id = "28079",
  dates = c("2023-01-01", "2023-01-07"),
  time_range = c(7, 9),  # Morning rush hour
  plot_type = "all"
)

# View results
print(madrid_analysis$summary_stats)
print(madrid_analysis$heatmap)
print(madrid_analysis$flow_plot)
print(madrid_analysis$timeseries_plot)

# Analyze multiple districts
districts_to_analyze <- c("28079", "08019", "41091")  # Madrid, Barcelona, Sevilla
district_results <- list()

for(district in districts_to_analyze) {
  district_results[[district]] <- analyze_district_mobility(
    district_id = district,
    dates = c("2023-01-01", "2023-01-07"),
    plot_type = "all"
  )
}

# Compare district mobility patterns
for(district in names(district_results)) {
  cat("District", district, ":\n")
  print(district_results[[district]]$summary_stats)
  cat("\n")
}
```

## Data Quality and Validation

```r
# 1. Comprehensive data validation
quality_report <- validate_mitma_data(mobility_data)
print(quality_report)

# 2. Check for missing data patterns
missing_summary <- mobility_data %>%
  group_by(date) %>%
  summarise(
    total_records = n(),
    missing_flows = sum(is.na(n_trips)),
    zero_flows = sum(n_trips == 0, na.rm = TRUE),
    .groups = "drop"
  )
print(missing_summary)

# 3. Validate zone coverage
zone_coverage <- mobility_data %>%
  summarise(
    unique_origins = n_distinct(id_origin),
    unique_destinations = n_distinct(id_destination),
    total_zones_expected = nrow(zones)
  )
print(zone_coverage)

# 4. Temporal coverage check
temporal_coverage <- mobility_data %>%
  group_by(date) %>%
  summarise(records = n(), .groups = "drop") %>%
  mutate(
    weekday = lubridate::wday(date, label = TRUE),
    is_complete = records > quantile(records, 0.25)
  )
print(temporal_coverage)
```

## Version Selection and Comparison

```r
# 1. Get version information
version_info <- get_data_version_info()
print(version_info$comparison)

# 2. Compare data from different versions
# COVID-19 period data (Version 1)
init_data_dir("~/covid_mobility_data", version = 1)
covid_data <- get_mobility_matrix(
  dates = c("2020-03-15", "2020-03-21"),
  level = "dist"
)

# Current data (Version 2)
init_data_dir("~/current_mobility_data", version = 2)
current_data <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist"
)

# Compare indicators
covid_indicators <- calculate_mobility_indicators(covid_data)
current_indicators <- calculate_mobility_indicators(current_data)

# Summary comparison
covid_summary <- summary(covid_indicators$total_outflow)
current_summary <- summary(current_indicators$total_outflow)

cat("COVID-19 period mobility summary:\n")
print(covid_summary)
cat("\nCurrent period mobility summary:\n")
print(current_summary)

# 3. Use optimal parameters for different scenarios
optimal_params <- get_optimal_parameters("detailed", "large")
print(optimal_params)

# Apply optimal parameters
detailed_data <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-31"),
  level = optimal_params$spatial_level,
  aggregate_by = optimal_params$temporal_aggregation
)
```

## Advanced Configuration and Optimization

```r
# 1. Configure package for better performance
configure_mobspain(
  cache_dir = "~/mobspain_cache",
  max_cache_size = 1000,  # 1GB cache
  parallel = TRUE,
  n_cores = 4
)

# 2. Check available map providers
providers <- get_available_map_providers()

# 3. Create maps with different providers
osm_map <- create_flow_map(zones, mobility_data, map_style = "osm")
carto_map <- create_flow_map(zones, mobility_data, map_style = "carto")

# 4. Database connection for advanced queries
con <- connect_mobility_db()
custom_query <- "SELECT * FROM mobility_data WHERE date = '2023-01-01' LIMIT 100"
custom_result <- DBI::dbGetQuery(con, custom_query)
DBI::dbDisconnect(con)

# 5. Monitor package status
status <- mobspain_status()
print(status)
```

## Complete Analysis Pipeline

```r
# Complete mobility analysis pipeline
complete_analysis <- function(dates, district_id = NULL, output_dir = "mobility_analysis") {
  
  # 1. Setup
  cat("Setting up analysis...\n")
  configure_mobspain(cache_dir = "~/mobspain_cache")
  
  # 2. Data loading
  cat("Loading data...\n")
  zones <- get_spatial_zones("dist")
  mobility_data <- get_mobility_matrix(dates = dates, level = "dist")
  
  # 3. Data validation
  cat("Validating data...\n")
  quality_report <- validate_mitma_data(mobility_data)
  if (quality_report$has_issues) {
    warning("Data quality issues detected")
  }
  
  # 4. Analysis
  cat("Performing analysis...\n")
  indicators <- calculate_mobility_indicators(mobility_data, zones)
  containment <- calculate_containment(mobility_data)
  decay_analysis <- calculate_distance_decay(mobility_data, zones)
  anomalies <- detect_mobility_anomalies(mobility_data)
  
  # 5. Visualization
  cat("Creating visualizations...\n")
  viz_suite <- create_mobility_viz_suite(zones, mobility_data, viz_type = "both")
  
  # 6. District-specific analysis (if specified)
  district_analysis <- NULL
  if (!is.null(district_id)) {
    cat("Analyzing district", district_id, "...\n")
    district_analysis <- analyze_district_mobility(district_id, dates)
  }
  
  # 7. Export results
  cat("Exporting results...\n")
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  
  export_visualizations(viz_suite, output_dir = output_dir)
  
  # Save data
  saveRDS(list(
    indicators = indicators,
    containment = containment,
    decay_analysis = decay_analysis,
    anomalies = anomalies,
    district_analysis = district_analysis,
    quality_report = quality_report
  ), file.path(output_dir, "analysis_results.rds"))
  
  cat("Analysis complete! Results saved to:", output_dir, "\n")
  
  return(list(
    indicators = indicators,
    containment = containment,
    decay_analysis = decay_analysis,
    anomalies = anomalies,
    district_analysis = district_analysis,
    viz_suite = viz_suite
  ))
}

# Run complete analysis
results <- complete_analysis(
  dates = c("2023-01-01", "2023-01-07"),
  district_id = "28079",
  output_dir = "madrid_mobility_analysis"
)
```

This comprehensive guide demonstrates how to use all the major functions in the mobspain package for a complete mobility analysis workflow. Each function includes practical examples showing how to implement them in real-world scenarios.
