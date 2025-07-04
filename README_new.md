# mobspain: Spanish Mobility Data Analysis

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Token-Free](https://img.shields.io/badge/Token--Free-✅-brightgreen)](https://github.com/iprincegh/mobspain-r-package)

R package for analyzing Spanish mobility patterns using official MITMA data. **100% token-free** - no API keys or payments required.

## Quick Start

```r
# Install
devtools::install_github("iprincegh/mobspain-r-package")

# Setup
library(mobspain)
init_data_dir()  # Creates ~/spanish_mobility_data/

# Get data
zones <- get_spatial_zones("dist")         # ~3,909 districts
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"), 
  level = "dist"
)

# Analyze
containment <- calculate_containment(mobility)
anomalies <- detect_mobility_anomalies(mobility)

# Visualize
flow_map <- create_flow_map(zones, mobility, min_flow = 500)
plot_daily_mobility(mobility)
```

## Data Versions

| Feature | Version 1 (2020-2021) | Version 2 (2022+) |
|---------|------------------------|-------------------|
| **Period** | COVID-19 pandemic | Current (recommended) |
| **Countries** | Spain only | Spain + Portugal + France |
| **Sociodemographic** | Basic | Income, age, sex |

```r
# Choose version based on research needs
init_data_dir(version = 2)  # Enhanced current data (default)
init_data_dir(version = 1)  # COVID-19 studies
```

## Key Functions

### Data Access
```r
# Initialize data directory
init_data_dir(version = 2)

# Get spatial zones
zones <- get_spatial_zones("dist")  # Districts (~3,909)
zones <- get_spatial_zones("muni")  # Municipalities (~8,131)

# Get mobility data
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist"
)
```

### Analytics
```r
# Self-containment analysis
containment <- calculate_containment(mobility)
head(containment[order(-containment$containment), ])

# Anomaly detection
anomalies <- detect_mobility_anomalies(mobility, method = "zscore")
plot(anomalies$anomaly_score)

# Mobility indicators
indicators <- calculate_mobility_indicators(mobility, zones)
summary(indicators)

# Distance decay modeling
decay <- calculate_distance_decay(mobility, zones)
cat("Distance decay R²:", decay$r_squared)
```

### Visualization
```r
# Interactive flow map
flow_map <- create_flow_map(zones, mobility, min_flow = 500)
flow_map

# Daily mobility trends
plot_daily_mobility(mobility)

# Choropleth map
create_choropleth_map(zones, indicators, variable = "containment")

# Mobility heatmap
plot_mobility_heatmap(mobility)
```

## Complete Example

```r
library(mobspain)

# Setup
init_data_dir()
configure_mobspain(parallel = TRUE, cache_enabled = TRUE)

# Data
zones <- get_spatial_zones("dist")
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist"
)

# Validate data quality
quality <- validate_mitma_data(mobility)
print(quality$summary)

# Analysis
containment <- calculate_containment(mobility)
anomalies <- detect_mobility_anomalies(mobility)
decay_model <- calculate_distance_decay(mobility, zones)

# Top self-contained districts
top_contained <- head(containment[order(-containment$containment), ], 10)
print(top_contained)

# Visualizations
flow_map <- create_flow_map(zones, mobility, min_flow = 1000)
daily_plot <- plot_daily_mobility(mobility)
choropleth <- create_choropleth_map(zones, containment, variable = "containment")
```

## Configuration

```r
# Package setup
configure_mobspain(
  parallel = TRUE,
  n_cores = 4,
  cache_enabled = TRUE,
  cache_max_size = 1000  # MB
)

# Check status
mobspain_status()

# Get optimal parameters
params <- get_optimal_parameters("exploratory", "medium")
```

## Documentation

- **Help**: `?mobspain`, `?get_mobility_matrix`
- **Vignette**: `vignette("introduction", package = "mobspain")`
- **GitHub**: https://github.com/iprincegh/mobspain-r-package

Built on [spanishoddata](https://github.com/rOpenSpain/spanishoddata). MIT License.
