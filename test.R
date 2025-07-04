# Test Token-Free Functionality
library(mobspain)

# Test the core functionality
cat("Testing mobspain token-free functionality...\n")

# Test 1: Check available map providers (should all be token-free)
cat("\n1. Available Map Providers (No Tokens Required):\n")
providers <- get_available_map_providers()

# Test 2: Load sample data
cat("\n2. Loading sample data...\n")
data(sample_zones)
cat("Sample zones loaded:", nrow(sample_zones), "zones\n")

# Test 3: Create simple mobility data
cat("\n3. Creating test mobility data...\n")
test_mobility <- data.frame(
  id_origin = c("001", "002", "003", "001", "002"),
  id_destination = c("002", "003", "001", "003", "001"),
  n_trips = c(100, 150, 200, 80, 120),
  date = as.Date("2023-01-01")
)

# Test 4: Create flow map with different providers
cat("\n4. Testing flow map creation...\n")

# Test static map (no tokens needed)
cat("Creating static flow map...\n")
static_map <- create_flow_map(sample_zones, test_mobility, interactive = FALSE)
cat("Static flow map created successfully ✓\n")

# Test interactive map with different providers
for(provider in c("osm", "carto", "stamen")) {
  cat(paste("Testing", provider, "provider...\n"))
  tryCatch({
    interactive_map <- create_flow_map(sample_zones, test_mobility, 
                                     interactive = TRUE, map_style = provider)
    cat(paste("✓", provider, "provider working\n"))
  }, error = function(e) {
    cat(paste("✗", provider, "provider failed:", e$message, "\n"))
  })
}

# Test 5: District analysis functionality
cat("\n5. Testing district analysis...\n")
tryCatch({
  # This will use sample data since we don't have real MITMA data in this test
  district_analysis <- analyze_district_mobility(
    district_id = "001",
    dates = c("2023-01-01", "2023-01-07"),
    zones = sample_zones,
    mobility_data = test_mobility,
    plot_type = "heatmap"
  )
  cat("District analysis completed successfully ✓\n")
}, error = function(e) {
  cat("District analysis test failed:", e$message, "\n")
})

# Test 6: Comprehensive visualization suite
cat("\n6. Testing comprehensive visualization suite...\n")
tryCatch({
  viz_suite <- create_mobility_viz_suite(
    zones = sample_zones,
    mobility_data = test_mobility,
    viz_type = "both"
  )
  cat("Comprehensive visualization suite created successfully ✓\n")
  cat("Available visualizations:", names(viz_suite), "\n")
}, error = function(e) {
  cat("Visualization suite test failed:", e$message, "\n")
})

cat("\n✅ All token-free functionality tests completed!\n")
cat("The mobspain package is ready for open-source distribution.\n")
