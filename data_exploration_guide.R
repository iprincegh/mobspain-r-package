# Data Exploration Guide - Understanding MITMA Mobility Data Structure
# This script helps you understand and work with the rich MITMA dataset

library(mobspain)
library(dplyr)

cat("=== MITMA Data Structure Guide ===\n\n")

# 1. Load sample data
mobility <- get_mobility_matrix(dates = c("2023-01-01"), level = "dist")
zones <- get_spatial_zones("dist")

cat("Data loaded successfully!\n")
cat("• Mobility records:", format(nrow(mobility), big.mark = ","), "\n")
cat("• Spatial zones:", format(nrow(zones), big.mark = ","), "\n\n")

# 2. Explore data structure
cat("=== DATA STRUCTURE ANALYSIS ===\n\n")

cat("Mobility data columns:\n")
mobility_cols <- names(mobility)
for(i in seq_along(mobility_cols)) {
  cat(sprintf("%2d. %-25s", i, mobility_cols[i]))
  if(i %% 3 == 0) cat("\n")
}
if(length(mobility_cols) %% 3 != 0) cat("\n")

cat("\nKey columns explained:\n")
cat("• date, hour, time_slot     - Temporal dimensions\n")
cat("• id_origin, id_destination - Spatial flow pairs\n")
cat("• n_trips                   - Number of trips (main flow measure)\n")
cat("• trips_total_length_km     - Total distance traveled\n")
cat("• activity_origin/dest      - Trip purposes\n")
cat("• income, age, sex          - Demographics (Version 2 data)\n")
cat("• residence_province_*      - Home location info\n\n")

# 3. Data summary statistics
cat("=== DATA SUMMARY ===\n\n")

# Temporal coverage
date_range <- range(mobility$date)
hours <- unique(mobility$hour)
cat("Temporal coverage:\n")
cat("• Date range:", as.character(date_range[1]), "to", as.character(date_range[2]), "\n")
cat("• Hours available:", min(hours), "to", max(hours), "(", length(hours), "hours)\n")
cat("• Total time periods:", length(unique(paste(mobility$date, mobility$hour))), "\n\n")

# Spatial coverage
origins <- unique(mobility$id_origin)
destinations <- unique(mobility$id_destination)
zones_in_data <- unique(c(origins, destinations))
cat("Spatial coverage:\n")
cat("• Unique origins:", length(origins), "\n")
cat("• Unique destinations:", length(destinations), "\n")
cat("• Total zones with data:", length(zones_in_data), "\n")
cat("• Zones in shapefile:", nrow(zones), "\n\n")

# Trip patterns
total_trips <- sum(mobility$n_trips, na.rm = TRUE)
internal_trips <- sum(mobility$n_trips[mobility$id_origin == mobility$id_destination], na.rm = TRUE)
external_trips <- total_trips - internal_trips
cat("Trip patterns:\n")
cat("• Total trips:", format(total_trips, big.mark = ","), "\n")
cat("• Internal trips (same zone):", format(internal_trips, big.mark = ","), 
    sprintf("(%.1f%%)", 100 * internal_trips / total_trips), "\n")
cat("• External trips (between zones):", format(external_trips, big.mark = ","), 
    sprintf("(%.1f%%)", 100 * external_trips / total_trips), "\n\n")

# Activity analysis
if("activity_origin" %in% names(mobility)) {
  cat("Activity patterns:\n")
  activity_summary <- mobility %>%
    group_by(activity_origin) %>%
    summarise(trips = sum(n_trips, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(trips)) %>%
    mutate(percentage = round(100 * trips / sum(trips), 1))
  
  print(activity_summary)
  cat("\n")
}

# Demographics (if available)
if("age" %in% names(mobility)) {
  cat("Age distribution:\n")
  age_summary <- mobility %>%
    filter(!is.na(age)) %>%
    group_by(age) %>%
    summarise(trips = sum(n_trips, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(trips))
  print(age_summary)
  cat("\n")
}

if("sex" %in% names(mobility)) {
  cat("Gender distribution:\n")
  sex_summary <- mobility %>%
    filter(!is.na(sex)) %>%
    group_by(sex) %>%
    summarise(trips = sum(n_trips, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(trips))
  print(sex_summary)
  cat("\n")
}

# 4. Data preparation examples
cat("=== DATA PREPARATION EXAMPLES ===\n\n")

# Example 1: Daily aggregation for time series
cat("1. Daily aggregation:\n")
daily_mobility <- mobility %>%
  group_by(date, id_origin, id_destination) %>%
  summarise(
    n_trips = sum(n_trips, na.rm = TRUE),
    avg_distance = mean(trips_total_length_km / n_trips, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n_trips > 0)

cat("• Original records:", format(nrow(mobility), big.mark = ","), "\n")
cat("• Daily aggregated:", format(nrow(daily_mobility), big.mark = ","), "\n\n")

# Example 2: Inter-zone flows for network analysis
cat("2. Inter-zone flows (for flow maps):\n")
inter_zone <- daily_mobility %>%
  filter(id_origin != id_destination) %>%
  filter(n_trips >= 10)  # Minimum threshold

cat("• Inter-zone flows:", format(nrow(inter_zone), big.mark = ","), "\n")
cat("• Flow threshold: >= 10 trips\n\n")

# Example 3: Peak hour analysis
cat("3. Peak hour flows:\n")
hourly_totals <- mobility %>%
  group_by(hour) %>%
  summarise(total_trips = sum(n_trips, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(total_trips))

peak_hours <- head(hourly_totals, 3)
cat("Top 3 peak hours:\n")
print(peak_hours)
cat("\n")

# 5. Practical tips
cat("=== PRACTICAL TIPS ===\n\n")

cat("For better analysis and visualization:\n\n")

cat("1. Flow Maps:\n")
cat("   • Use inter-zone flows: filter(id_origin != id_destination)\n")
cat("   • Apply minimum thresholds: filter(n_trips >= threshold)\n")
cat("   • Aggregate by day/hour to reduce complexity\n\n")

cat("2. Time Series:\n")
cat("   • Aggregate by date for daily patterns\n")
cat("   • Consider weekdays vs weekends\n")
cat("   • Look for seasonal patterns\n\n")

cat("3. Spatial Analysis:\n")
cat("   • Internal flows show self-containment\n")
cat("   • External flows show connectivity\n")
cat("   • Consider activity types for trip purposes\n\n")

cat("4. Demographics (Version 2 data):\n")
cat("   • Age and sex provide population insights\n")
cat("   • Income levels show socioeconomic patterns\n")
cat("   • Activity types reveal land use patterns\n\n")

cat("=== EXAMPLE DATASETS CREATED ===\n")
cat("• daily_mobility  - Daily aggregated flows\n")
cat("• inter_zone      - Inter-zone connections\n")
cat("• hourly_totals   - Peak hour analysis\n")
cat("• activity_summary - Activity patterns\n\n")

cat("Ready for analysis! Use these datasets with mobspain functions.\n")
