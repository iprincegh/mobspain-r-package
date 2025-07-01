# Simple Example Script for mobspain Package
# This script demonstrates basic usage of the mobspain package

# Load the package
library(mobspain)

# Print package information
cat("=== mobspain Package Example ===\n")
cat("Package version:", as.character(packageVersion("mobspain")), "\n\n")

# 1. Load and explore sample data
cat("1. Loading sample zones data...\n")
data(sample_zones)
print(sample_zones)
cat("\nSample zones structure:\n")
str(sample_zones)

# 2. Check available functions
cat("\n2. Available functions in mobspain package:\n")
exported_functions <- ls('package:mobspain')
cat(paste(exported_functions, collapse = ", "), "\n")

# 3. Initialize data directory
cat("\n3. Initializing data directory...\n")
tryCatch({
  data_dir <- init_data_dir()
  cat("Data directory initialized at:", data_dir, "\n")
}, error = function(e) {
  cat("Error initializing data directory:", e$message, "\n")
})

# 4. Create zone index
cat("\n4. Creating zone index...\n")
tryCatch({
  zone_index <- create_zone_index(sample_zones)
  print("Zone index created:")
  print(zone_index)
}, error = function(e) {
  cat("Error creating zone index:", e$message, "\n")
})

# 5. Try to connect to mobility database (will likely fail without real credentials)
cat("\n5. Attempting to connect to mobility database...\n")
tryCatch({
  connection <- connect_mobility_db()
  cat("Database connection successful!\n")
}, error = function(e) {
  cat("Expected error (no real database credentials):", e$message, "\n")
})

# 6. Try to get spatial zones
cat("\n6. Attempting to get spatial zones...\n")
tryCatch({
  spatial_zones <- get_spatial_zones(region = "madrid")
  print("Spatial zones retrieved:")
  print(head(spatial_zones))
}, error = function(e) {
  cat("Expected error (no database connection):", e$message, "\n")
})

# 7. Try to get mobility matrix with fallback
cat("\n7. Attempting to get mobility matrix...\n")
tryCatch({
  mobility_data <- get_mobility_matrix(
    origin_zones = sample_zones$id[1:2],
    destination_zones = sample_zones$id[2:3],
    date_range = c("2023-01-01", "2023-01-07")
  )
  print("Mobility data retrieved:")
  print(mobility_data)
}, error = function(e) {
  cat("Expected error (no real database connection):", e$message, "\n")
})

# 8. Calculate containment if we have mobility data
cat("\n8. Creating sample mobility data and calculating containment...\n")
# Create sample mobility matrix for demonstration
sample_mobility <- data.frame(
  origin = rep(sample_zones$id[1:2], each = 2),
  destination = rep(sample_zones$id[1:2], 2),
  flow = c(100, 50, 30, 80),
  stringsAsFactors = FALSE
)

print("Sample mobility matrix:")
print(sample_mobility)

tryCatch({
  containment <- calculate_containment(sample_mobility)
  print("Containment calculated:")
  print(containment)
}, error = function(e) {
  cat("Error calculating containment:", e$message, "\n")
})

# 9. Create visualizations if possible
cat("\n9. Creating visualizations...\n")

# Try to create a flow map
tryCatch({
  if (require(ggplot2, quietly = TRUE) && require(sf, quietly = TRUE)) {
    flow_map <- create_flow_map(sample_zones, sample_mobility)
    print("Flow map created successfully!")
    print(flow_map)
  } else {
    cat("Required packages (ggplot2, sf) not available for visualization\n")
  }
}, error = function(e) {
  cat("Error creating flow map:", e$message, "\n")
})

# Try to plot daily mobility
tryCatch({
  # Create sample daily data
  daily_data <- data.frame(
    date = seq.Date(as.Date("2023-01-01"), as.Date("2023-01-07"), by = "day"),
    mobility = c(100, 120, 110, 95, 105, 130, 125)
  )
  
  if (require(ggplot2, quietly = TRUE)) {
    mobility_plot <- plot_daily_mobility(daily_data)
    print("Daily mobility plot created successfully!")
    print(mobility_plot)
  } else {
    cat("ggplot2 not available for daily mobility plot\n")
  }
}, error = function(e) {
  cat("Error creating daily mobility plot:", e$message, "\n")
})

cat("\n=== Example completed successfully! ===\n")
cat("The mobspain package is ready to use for mobility analysis in Spain.\n")
cat("For more information, check the package documentation with ?mobspain or help(package='mobspain')\n")
