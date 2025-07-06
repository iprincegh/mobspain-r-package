#!/usr/bin/env Rscript

# Comprehensive Function Testing Script for mobspain Package
# This script tests all major functions to ensure they work correctly

# Load required libraries
library(devtools)
load_all()

# Helper function to safely test functions
test_function <- function(func_name, test_code, description = "") {
  cat(sprintf("Testing %s%s...\n", func_name, ifelse(description != "", paste0(" (", description, ")"), "")))
  
  tryCatch({
    result <- eval(parse(text = test_code))
    cat(sprintf("✓ %s works\n", func_name))
    return(TRUE)
  }, error = function(e) {
    cat(sprintf("✗ %s failed: %s\n", func_name, e$message))
    return(FALSE)
  })
}

# Create test data
create_test_data <- function() {
  # Sample mobility data
  mobility_data <- data.frame(
    id_origin = c(1, 2, 3, 1, 2, 3),
    id_destination = c(2, 3, 1, 3, 1, 2),
    n_trips = c(100, 150, 200, 80, 120, 90),
    trips_total_length_km = c(50, 75, 100, 40, 60, 45),
    date = as.Date(c(rep('2020-01-01', 3), rep('2020-01-02', 3))),
    hour = c(8, 9, 10, 8, 9, 10)
  )
  
  # Sample spatial zones (simplified)
  spatial_zones <- data.frame(
    id = c(1, 2, 3),
    name = c("Zone A", "Zone B", "Zone C"),
    lon = c(-3.7, -3.6, -3.5),
    lat = c(40.4, 40.5, 40.6),
    stringsAsFactors = FALSE
  )
  
  # Convert to sf object if sf is available
  if(requireNamespace("sf", quietly = TRUE)) {
    spatial_zones <- sf::st_as_sf(spatial_zones, 
                                coords = c("lon", "lat"), 
                                crs = 4326)
  }
  
  return(list(mobility_data = mobility_data, spatial_zones = spatial_zones))
}

# Initialize test results
test_results <- list()
test_data <- create_test_data()

cat("=== MOBSPAIN PACKAGE FUNCTION TESTING ===\n\n")

# 1. Core Package Functions
cat("1. CORE PACKAGE FUNCTIONS\n")
cat("========================\n")

test_results$mobspain_status <- test_function("mobspain_status", 
  "status <- mobspain_status(); status")

test_results$configure_mobspain <- test_function("configure_mobspain", 
  "configure_mobspain()")

test_results$sample_zones <- test_function("sample_zones", 
  "data('sample_zones'); nrow(sample_zones)")

# 2. Validation Functions
cat("\n2. VALIDATION FUNCTIONS\n")
cat("======================\n")

test_results$validate_dates <- test_function("validate_dates", 
  "validate_dates(c('2020-01-01', '2020-01-02'))")

test_results$validate_level <- test_function("validate_level", 
  "validate_level('district')")

test_results$validate_mitma_data <- test_function("validate_mitma_data", 
  "validate_mitma_data(test_data$mobility_data)")

# 3. Mobility Analysis Functions
cat("\n3. MOBILITY ANALYSIS FUNCTIONS\n")
cat("==============================\n")

test_results$calculate_containment <- test_function("calculate_containment", 
  "calculate_containment(test_data$mobility_data)")

test_results$calculate_mobility_indicators <- test_function("calculate_mobility_indicators", 
  "calculate_mobility_indicators(test_data$mobility_data)")

test_results$calculate_distance_decay <- test_function("calculate_distance_decay", 
  "calculate_distance_decay(test_data$mobility_data)")

# 4. Spatial Analysis Functions
cat("\n4. SPATIAL ANALYSIS FUNCTIONS\n")
cat("=============================\n")

test_results$analyze_spatial_patterns <- test_function("analyze_spatial_patterns", 
  "analyze_spatial_patterns(test_data$mobility_data)")

test_results$calculate_spatial_accessibility <- test_function("calculate_spatial_accessibility", 
  "calculate_spatial_accessibility(test_data$mobility_data)")

# 5. Temporal Analysis Functions
cat("\n5. TEMPORAL ANALYSIS FUNCTIONS\n")
cat("==============================\n")

test_results$analyze_mobility_time_series <- test_function("analyze_mobility_time_series", 
  "analyze_mobility_time_series(test_data$mobility_data)")

test_results$detect_time_series_anomalies <- test_function("detect_time_series_anomalies", 
  "detect_time_series_anomalies(test_data$mobility_data)")

# 6. Visualization Functions
cat("\n6. VISUALIZATION FUNCTIONS\n")
cat("==========================\n")

test_results$plot_daily_mobility <- test_function("plot_daily_mobility", 
  "plot_daily_mobility(test_data$mobility_data)")

test_results$plot_distance_decay <- test_function("plot_distance_decay", 
  "plot_distance_decay(test_data$mobility_data)")

test_results$create_flow_map <- test_function("create_flow_map", 
  "create_flow_map(test_data$mobility_data)")

# 7. Dashboard Functions
cat("\n7. DASHBOARD FUNCTIONS\n")
cat("======================\n")

test_results$create_mobility_dashboard <- test_function("create_mobility_dashboard", 
  "create_mobility_dashboard(test_data$mobility_data, dashboard_type = 'overview')")

test_results$prepare_dashboard_data <- test_function("prepare_dashboard_data", 
  "prepare_dashboard_data(test_data$mobility_data, test_data$spatial_zones)")

# 8. Cache Functions
cat("\n8. CACHE FUNCTIONS\n")
cat("==================\n")

test_results$check_cache <- test_function("check_cache", 
  "check_cache('test_key')")

test_results$save_to_cache <- test_function("save_to_cache", 
  "save_to_cache('test_data', test_data$mobility_data)")

# 9. Anomaly Detection Functions
cat("\n9. ANOMALY DETECTION FUNCTIONS\n")
cat("==============================\n")

test_results$detect_mobility_anomalies <- test_function("detect_mobility_anomalies", 
  "detect_mobility_anomalies(test_data$mobility_data)")

# 10. Machine Learning Functions
cat("\n10. MACHINE LEARNING FUNCTIONS\n")
cat("===============================\n")

test_results$predict_mobility_patterns <- test_function("predict_mobility_patterns", 
  "predict_mobility_patterns(test_data$mobility_data)")

# Summary
cat("\n=== TESTING SUMMARY ===\n")
passed <- sum(unlist(test_results))
total <- length(test_results)
cat(sprintf("Tests passed: %d/%d (%.1f%%)\n", passed, total, (passed/total)*100))

# List failed tests
failed_tests <- names(test_results)[!unlist(test_results)]
if(length(failed_tests) > 0) {
  cat("\nFailed tests:\n")
  for(test in failed_tests) {
    cat(sprintf("- %s\n", test))
  }
} else {
  cat("\n🎉 All tests passed!\n")
}

# Cleanup
rm(test_data)
cat("\nTesting complete.\n")
