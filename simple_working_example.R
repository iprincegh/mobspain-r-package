# Simple Working Example - Fixed mobspain Functions
# Run this script in R Studio to test all the fixes

library(mobspain)
library(dplyr)

cat("=== mobspain Package - Fixed Functions Test ===\n\n")

# 1. CONFIGURATION (FIXED: now accepts cache_enabled parameter)
cat("1. Configuration (FIXED)...\n")
configure_mobspain(
  parallel = TRUE,
  cache_enabled = TRUE,  # This parameter now works!
  cache_max_size = 500,
  n_cores = 2
)
cat("✓ Configuration successful\n\n")

# 2. DATA SETUP
cat("2. Setting up data...\n")
init_data_dir("~/spanish_mobility_data", version = 2)

# Get zones
zones <- get_spatial_zones("dist")
cat("✓ Loaded", nrow(zones), "zones\n")

# Get mobility data (small sample for testing)
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-02"),
  level = "dist"
)
cat("✓ Loaded", nrow(mobility), "mobility records\n")

# Check data structure
cat("✓ Data columns:", paste(names(mobility), collapse = ", "), "\n")
cat("✓ Sample of first few trips:\n")
print(head(mobility[, c("date", "hour", "id_origin", "id_destination", "n_trips")]))

# Filter for inter-zone flows (origin != destination) for better flow map
inter_zone_flows <- mobility %>%
  filter(id_origin != id_destination) %>%
  group_by(id_origin, id_destination, date) %>%
  summarise(n_trips = sum(n_trips, na.rm = TRUE), .groups = "drop")

cat("✓ Inter-zone flows:", nrow(inter_zone_flows), "records\n")
cat("✓ Total daily flows available for visualization\n\n")

# 3. VALIDATION (FIXED: now returns proper summary)
cat("3. Data validation (FIXED)...\n")
quality <- validate_mitma_data(mobility)
cat("✓ Validation completed\n")
print(quality$summary)  # This now works!
cat("\n")

# 4. ANALYTICS
cat("4. Analytics...\n")
containment <- calculate_containment(mobility)
cat("✓ Containment analysis:", nrow(containment), "zones\n\n")

# 5. VISUALIZATIONS (FIXED: all issues resolved)
cat("5. Creating visualizations (FIXED)...\n")

# Daily plot (FIXED: no more grouping error)
daily_plot <- plot_daily_mobility(mobility)
cat("✓ Daily plot created\n")

# Flow map (FIXED: coordinate system warnings resolved)
# Use inter-zone flows for better visualization
if(nrow(inter_zone_flows) > 0) {
  flow_map <- create_flow_map(zones, inter_zone_flows, min_flow = 10)
  cat("✓ Flow map created with", nrow(inter_zone_flows), "flows\n")
} else {
  # Fallback: use all data but with higher threshold
  flow_map <- create_flow_map(zones, mobility, min_flow = 50)
  cat("✓ Flow map created (including internal flows)\n")
}

# Choropleth map (FIXED: coordinate system warnings resolved)
choropleth <- create_choropleth_map(zones, containment, variable = "containment")
cat("✓ Choropleth map created\n\n")

cat("=== ALL FIXES VERIFIED! ===\n")
cat("Data Summary:\n")
cat("• Total mobility records:", format(nrow(mobility), big.mark = ","), "\n")
cat("• Unique zones:", length(unique(c(mobility$id_origin, mobility$id_destination))), "\n")
cat("• Date range:", min(mobility$date), "to", max(mobility$date), "\n")
cat("• Total trips:", format(sum(mobility$n_trips, na.rm = TRUE), big.mark = ","), "\n\n")

cat("Available visualizations:\n")
cat("• daily_plot      - Shows daily mobility trends\n")
cat("• flow_map        - Interactive flow map\n") 
cat("• choropleth      - Containment index map\n\n")

cat("To view maps in RStudio:\n")
cat("• Click on 'flow_map' or 'choropleth' in Environment panel\n")
cat("• Or run: flow_map or choropleth in Console\n\n")

cat("Sample high-containment zones:\n")
top_contained <- head(containment[order(-containment$containment), ], 5)
print(top_contained[, c("id_origin", "containment", "total_trips")])
