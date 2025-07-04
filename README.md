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
# Initialize data directory with version options
init_data_dir(
  path = "~/spanish_mobility_data",  # Custom path
  version = 2                        # 1 (2020-2021) or 2 (2022+)
)

# Get spatial zones - level options: "dist", "muni", "ccaa"
zones <- get_spatial_zones("dist")  # Districts (~3,909)
zones <- get_spatial_zones("muni")  # Municipalities (~8,131)
zones <- get_spatial_zones("ccaa")  # Autonomous communities (~17)

# Get mobility data with parameters
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),  # Date range
  level = "dist",                          # "dist", "muni", "ccaa"
  time_range = c(6, 10),                   # Hour range (optional)
  filter_weekends = FALSE                   # Include/exclude weekends
)
```

### Analytics
```r
# Self-containment analysis
containment <- calculate_containment(
  mobility,
  min_trips = 10        # Minimum trips threshold
)
# Access results: containment$containment, containment$total_trips
head(containment[order(-containment$containment), ])

# Anomaly detection with method options
anomalies <- detect_mobility_anomalies(
  mobility, 
  method = "zscore",     # "zscore", "iqr", "isolation"
  threshold = 2.5,       # Z-score threshold
  by_weekday = TRUE      # Separate analysis by weekday
)
# Access results: anomalies$anomaly_score, anomalies$is_anomaly
plot(anomalies$anomaly_score)

# Mobility indicators with custom parameters
indicators <- calculate_mobility_indicators(
  mobility, 
  zones,
  include_distance = TRUE,    # Include distance calculations
  normalize = TRUE            # Normalize by population
)
# Results: indicators$total_inflow, indicators$total_outflow, indicators$containment
summary(indicators)

# Distance decay modeling
decay <- calculate_distance_decay(
  mobility, 
  zones,
  max_distance = 500,    # Maximum distance in km
  bin_size = 25          # Distance bins in km
)
# Access results: decay$r_squared, decay$coefficients, decay$model
cat("Distance decay R²:", decay$r_squared)
```

### Visualization
```r
# Interactive flow map with styling options
flow_map <- create_flow_map(
  zones, 
  mobility, 
  min_flow = 500,              # Minimum flow to display
  line_color = "blue",         # Flow line color
  line_width_scale = 1.5,      # Line width scaling
  background_map = "cartodb"   # "osm", "cartodb", "stamen"
)
flow_map

# Daily mobility trends with grouping
plot_daily_mobility(
  mobility,
  group_by = "weekday",        # "weekday", "date", "none"
  smooth = TRUE,               # Add trend line
  color_by = "day_type"        # Color by weekend/weekday
)

# Choropleth map with variable options
create_choropleth_map(
  zones, 
  indicators, 
  variable = "containment",     # Column name to visualize
  color_palette = "viridis",    # "viridis", "plasma", "blues"
  legend_title = "Self-containment %"
)

# Mobility heatmap with time options
plot_mobility_heatmap(
  mobility,
  time_unit = "hour",          # "hour", "day", "week"
  cluster_rows = TRUE,         # Cluster similar patterns
  color_scale = "log10"        # "linear", "log10", "sqrt"
)
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
# Package setup with all options
configure_mobspain(
  parallel = TRUE,              # Enable parallel processing
  n_cores = 4,                  # Number of cores (default: detectCores()-1)
  cache_enabled = TRUE,         # Enable caching
  cache_max_size = 1000,        # Cache size in MB
  cache_max_age_days = 7,       # Cache expiration in days
  data_source = "csv",          # "csv" or "duckdb"
  validate_data = TRUE          # Validate data on load
)

# Check current configuration
status <- mobspain_status()
# Access: status$parallel, status$cache_size, status$data_dir

# Get optimal parameters for different scenarios
params <- get_optimal_parameters(
  analysis_type = "exploratory",  # "exploratory", "production", "research"
  data_size = "medium"            # "small", "medium", "large"
)
# Returns: params$cache_size, params$parallel, params$batch_size
```

## Documentation

- **Function Help**: `?function_name` - Get detailed parameter information
  - `?get_mobility_matrix` - Data retrieval options
  - `?calculate_containment` - Containment analysis parameters  
  - `?create_flow_map` - Visualization styling options
  - `?detect_mobility_anomalies` - Anomaly detection methods
- **Package Overview**: `?mobspain` - Main package documentation
- **Vignette**: `vignette("introduction", package = "mobspain")` - Complete tutorial
- **GitHub**: https://github.com/iprincegh/mobspain-r-package

**Common Parameter Values:**
- **Levels**: `"dist"` (districts), `"muni"` (municipalities), `"ccaa"` (regions)
- **Methods**: `"zscore"`, `"iqr"`, `"isolation"` (anomaly detection)
- **Color Palettes**: `"viridis"`, `"plasma"`, `"blues"`, `"reds"`
- **Background Maps**: `"osm"`, `"cartodb"`, `"stamen"`

Built on [spanishoddata](https://github.com/rOpenSpain/spanishoddata). MIT License.
