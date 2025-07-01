## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE  # Prevent actual data downloads during package build
)


## ----library------------------------------------------------------------------
library(mobspain)


## ----setup_data---------------------------------------------------------------
# Set up data directory
init_data_dir("~/spanish_mobility_data")

# Check package status
mobspain_status()


## ----sample_data--------------------------------------------------------------
# Load sample zones
data(sample_zones)
print(sample_zones)

# Create spatial index
zone_index <- create_zone_index(sample_zones)


## ----spatial_zones------------------------------------------------------------
# Get districts (around 3,909 zones)
districts <- get_spatial_zones("dist")

# Get municipalities
municipalities <- get_spatial_zones("muni")


## ----mobility_data------------------------------------------------------------
# Get mobility data for a week
mobility_data <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist"
)

# Get morning commute data
commute_data <- get_mobility_matrix(
  dates = c("2023-03-01", "2023-03-07"), 
  level = "dist",
  time_window = c(7, 9)  # 7-9 AM
)


## ----containment--------------------------------------------------------------
containment <- calculate_containment(mobility_data)
head(containment[order(-containment$containment), ])


## ----indicators---------------------------------------------------------------
indicators <- calculate_mobility_indicators(mobility_data, districts)
print(indicators)


## ----anomalies----------------------------------------------------------------
anomalies <- detect_mobility_anomalies(mobility_data, method = "zscore")


## ----distance_decay-----------------------------------------------------------
decay_model <- calculate_distance_decay(mobility_data, districts)


## ----daily_mobility-----------------------------------------------------------
daily_plot <- plot_daily_mobility(mobility_data)
print(daily_plot)


## ----flow_maps----------------------------------------------------------------
# Create flow map with minimum flow threshold
flow_map <- create_flow_map(districts, mobility_data, min_flow = 500)
flow_map


## ----choropleth---------------------------------------------------------------
choropleth <- create_choropleth_map(
  districts, 
  indicators, 
  variable = "containment",
  title = "Self-Containment by District"
)
choropleth


## ----heatmaps-----------------------------------------------------------------
heatmap <- plot_mobility_heatmap(mobility_data, top_n = 20)
print(heatmap)


## ----distance_plots-----------------------------------------------------------
decay_plot <- plot_distance_decay(decay_model)
print(decay_plot)


## ----config-------------------------------------------------------------------
# Enable parallel processing
configure_mobspain(parallel = TRUE, n_cores = 4)

# Check configuration
mobspain_status()

