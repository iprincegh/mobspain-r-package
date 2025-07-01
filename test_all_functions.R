# Function Testing Script for mobspain Package
# This script tests each exported function to determine which ones work

library(mobspain)
library(sf)

cat("=== Testing all mobspain functions ===\n\n")

# Load sample data
data(sample_zones)

# Test results storage
test_results <- list()

# 1. Test sample_zones (data)
cat("1. Testing sample_zones data...\n")
tryCatch({
  print(sample_zones)
  test_results$sample_zones <- "✅ WORKING"
  cat("✅ sample_zones: WORKING\n\n")
}, error = function(e) {
  test_results$sample_zones <- paste("❌ ERROR:", e$message)
  cat("❌ sample_zones: ERROR -", e$message, "\n\n")
})

# 2. Test init_data_dir()
cat("2. Testing init_data_dir()...\n")
tryCatch({
  result <- init_data_dir()
  test_results$init_data_dir <- "✅ WORKING"
  cat("✅ init_data_dir: WORKING\n\n")
}, error = function(e) {
  test_results$init_data_dir <- paste("❌ ERROR:", e$message)
  cat("❌ init_data_dir: ERROR -", e$message, "\n\n")
})

# 3. Test create_zone_index()
cat("3. Testing create_zone_index()...\n")
tryCatch({
  zone_index <- create_zone_index(sample_zones)
  test_results$create_zone_index <- "✅ WORKING"
  cat("✅ create_zone_index: WORKING\n\n")
}, error = function(e) {
  test_results$create_zone_index <- paste("❌ ERROR:", e$message)
  cat("❌ create_zone_index: ERROR -", e$message, "\n\n")
})

# 4. Test connect_mobility_db()
cat("4. Testing connect_mobility_db()...\n")
tryCatch({
  conn <- connect_mobility_db()
  test_results$connect_mobility_db <- "✅ WORKING"
  cat("✅ connect_mobility_db: WORKING\n\n")
}, error = function(e) {
  test_results$connect_mobility_db <- paste("❌ ERROR:", e$message)
  cat("❌ connect_mobility_db: ERROR -", e$message, "\n\n")
})

# 5. Test get_spatial_zones()
cat("5. Testing get_spatial_zones()...\n")
tryCatch({
  zones <- get_spatial_zones()
  test_results$get_spatial_zones <- "✅ WORKING"
  cat("✅ get_spatial_zones: WORKING\n\n")
}, error = function(e) {
  test_results$get_spatial_zones <- paste("❌ ERROR:", e$message)
  cat("❌ get_spatial_zones: ERROR -", e$message, "\n\n")
})

# 6. Test get_mobility_matrix()
cat("6. Testing get_mobility_matrix()...\n")
tryCatch({
  matrix <- get_mobility_matrix()
  test_results$get_mobility_matrix <- "✅ WORKING"
  cat("✅ get_mobility_matrix: WORKING\n\n")
}, error = function(e) {
  test_results$get_mobility_matrix <- paste("❌ ERROR:", e$message)
  cat("❌ get_mobility_matrix: ERROR -", e$message, "\n\n")
})

# 7. Test calculate_containment()
cat("7. Testing calculate_containment()...\n")
# Create sample mobility data
sample_mobility <- data.frame(
  origin = rep(sample_zones$id[1:2], each = 2),
  destination = rep(sample_zones$id[1:2], 2),
  flow = c(100, 50, 30, 80),
  stringsAsFactors = FALSE
)
tryCatch({
  containment <- calculate_containment(sample_mobility)
  test_results$calculate_containment <- "✅ WORKING"
  cat("✅ calculate_containment: WORKING\n\n")
}, error = function(e) {
  test_results$calculate_containment <- paste("❌ ERROR:", e$message)
  cat("❌ calculate_containment: ERROR -", e$message, "\n\n")
})

# 8. Test create_flow_map()
cat("8. Testing create_flow_map()...\n")
tryCatch({
  flow_map <- create_flow_map(sample_zones, sample_mobility)
  test_results$create_flow_map <- "✅ WORKING"
  cat("✅ create_flow_map: WORKING\n\n")
}, error = function(e) {
  test_results$create_flow_map <- paste("❌ ERROR:", e$message)
  cat("❌ create_flow_map: ERROR -", e$message, "\n\n")
})

# 9. Test plot_daily_mobility()
cat("9. Testing plot_daily_mobility()...\n")
# Create proper daily mobility data
daily_data <- data.frame(
  date = seq.Date(as.Date("2023-01-01"), as.Date("2023-01-07"), by = "day"),
  origin = rep("001", 7),
  destination = rep("002", 7), 
  flow = c(100, 120, 110, 95, 105, 130, 125)
)
tryCatch({
  plot <- plot_daily_mobility(daily_data)
  test_results$plot_daily_mobility <- "✅ WORKING"
  cat("✅ plot_daily_mobility: WORKING\n\n")
}, error = function(e) {
  test_results$plot_daily_mobility <- paste("❌ ERROR:", e$message)
  cat("❌ plot_daily_mobility: ERROR -", e$message, "\n\n")
})

# Summary
cat("=== SUMMARY OF FUNCTION TESTS ===\n")
for (func_name in names(test_results)) {
  cat(paste(func_name, ":", test_results[[func_name]], "\n"))
}

# Count working vs broken
working_count <- sum(grepl("✅ WORKING", test_results))
total_count <- length(test_results)
cat(sprintf("\nResult: %d/%d functions working (%.1f%%)\n", 
            working_count, total_count, (working_count/total_count)*100))
