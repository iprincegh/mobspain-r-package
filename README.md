# mobspain: Spanish Mobility Data Analysis

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Token-Free](https://img.shields.io/badge/Token--Free-✅-brightgreen)](https://github.com/iprincegh/mobspain-r-package)
[![CRAN Ready](https://img.shields.io/badge/CRAN--Ready-✅-blue)](https://github.com/iprincegh/mobspain-r-package)
[![R CMD Check](https://img.shields.io/badge/R%20CMD%20Check-PASS-green)](https://github.com/iprincegh/mobspain-r-package)

**Professional R package for analyzing Spanish mobility patterns using official MITMA data.** 37+ functions covering data retrieval, advanced analytics, and visualization. **Token-free** access to comprehensive mobility insights.

## Features

- **37+ Functions**: Complete mobility analysis toolkit from basic to advanced analytics
- **Advanced Analytics**: Activity-based, demographic, and economic mobility analysis  
- **Multiple Data Versions**: COVID-19 era (v1) and current enhanced data (v2)
- **Interactive Visualizations**: Flow maps, heatmaps, time series, and spatial plots
- **CRAN-Ready**: Zero errors/warnings, comprehensive documentation, follows best practices
- **Token-Free**: No API keys or payments required

## Installation

```r
devtools::install_github("iprincegh/mobspain-r-package")
```

## Quick Start

```r
library(mobspain)

# Setup
init_data_dir(version = 2)  # Latest data with demographics
zones <- get_spatial_zones("dist")  # ~3,909 districts

# Get mobility data
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"), 
  level = "dist"
)

# Core analysis
containment <- calculate_containment(mobility)
anomalies <- detect_mobility_anomalies(mobility)
indicators <- calculate_mobility_indicators(mobility, zones)

# Advanced analytics
activity_patterns <- calculate_activity_patterns(mobility)
demographic_analysis <- analyze_demographic_mobility(mobility)
economic_impact <- analyze_economic_mobility(mobility, zones)

# Visualization
flow_map <- create_flow_map(zones, mobility, min_flow = 500)
plot_daily_mobility(mobility, group_by = "weekday")
```

## Data Versions

| Feature | Version 1 (2020-2021) | Version 2 (2022+) |
|---------|------------------------|-------------------|
| **Period** | COVID-19 pandemic | Current (recommended) |
| **Coverage** | Spain only | Spain + Portugal + France |
| **Demographics** | Basic | Income, age, sex, residence |

```r
init_data_dir(version = 2)  # Enhanced current data (default)
init_data_dir(version = 1)  # COVID-19 studies
```

## Core Functions

### Data Access
```r
# Spatial zones: ~3,909 districts, ~8,131 municipalities, ~85 large urban areas
zones <- get_spatial_zones("dist")  # "dist", "muni", "lua"

# Mobility matrices with temporal filtering
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist",
  time_window = c(7, 9)  # Morning commute hours
)
```

### Analysis
```r
# Core mobility metrics
containment <- calculate_containment(mobility, min_trips = 10)
anomalies <- detect_mobility_anomalies(mobility, method = "zscore")
indicators <- calculate_mobility_indicators(mobility, zones)
decay <- calculate_distance_decay(mobility, zones)

# Advanced analytics
activity_patterns <- calculate_activity_patterns(mobility)
network_analysis <- analyze_mobility_network(mobility, zones)
demographic_mobility <- analyze_demographic_mobility(mobility, demographic_var = "age")
economic_impact <- analyze_economic_mobility(mobility, zones)
```

### Visualization
```r
# Interactive maps and statistical plots
create_flow_map(zones, mobility, min_flow = 500)
create_choropleth_map(zones, indicators, variable = "containment")
plot_daily_mobility(mobility, group_by = "weekday")
plot_mobility_heatmap(mobility, cluster_rows = TRUE)
```
## Complete Workflow Example

```r
library(mobspain)

# 1. Setup and Configuration
init_data_dir(version = 2)  # Use latest data version
configure_mobspain(parallel = TRUE, cache_enabled = TRUE)

# 2. Data Retrieval
zones <- get_spatial_zones("dist")  # Get districts
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist"
)

# 3. Core Analysis
containment <- calculate_containment(mobility, min_trips = 10)
anomalies <- detect_mobility_anomalies(mobility, method = "zscore")
indicators <- calculate_mobility_indicators(mobility, zones)

# 4. Advanced Analytics
activity_patterns <- calculate_activity_patterns(mobility)
network_metrics <- analyze_mobility_network(mobility, zones)
economic_impact <- analyze_economic_mobility(mobility, zones)

# 5. Visualization
flow_map <- create_flow_map(zones, mobility, min_flow = 1000)
plot_daily_mobility(mobility, group_by = "weekday")

# 6. Results Summary
head(containment[order(-containment$containment), ])
cat("Mobility anomalies detected:", sum(anomalies$is_anomaly))
```

## Advanced Features

### Activity-Based Analysis
```r
# Trip purpose, commuting patterns, network analysis
activity_patterns <- calculate_activity_patterns(mobility)
commute_analysis <- analyze_commute_patterns(mobility, zones)
network_metrics <- analyze_mobility_network(mobility, zones)
```

### Demographic Analysis
```r
# Age, gender, income-based mobility patterns
demographic_analysis <- analyze_demographic_mobility(mobility, demographic_var = "age")
income_patterns <- analyze_income_mobility(mobility, zones)
```

### Spatial Integration
```r
# Full sf compatibility for mapping and visualization
library(sf)
library(ggplot2)

# ggplot2 integration
ggplot(zones) +
  geom_sf(aes(fill = area_km2)) +
  scale_fill_viridis_c() +
  theme_void()

# Interactive maps
library(leaflet)
leaflet(zones[1:100, ]) %>%
  addTiles() %>%
  addPolygons(popup = ~name)
```

## Configuration Options

```r
# Package setup with all options
configure_mobspain(
  parallel = TRUE,              # Enable parallel processing
  n_cores = 4,                  # Number of cores
  cache_enabled = TRUE,         # Enable caching
  cache_max_size = 1000,        # Cache size in MB
  data_source = "csv",          # "csv" or "duckdb"
  validate_data = TRUE          # Validate data on load
)

# Check current status
status <- mobspain_status()
```

## Package Quality

### ✅ **CRAN-Ready Package**
- **R CMD Check**: 0 errors, 0 warnings, 0 notes
- **Test Coverage**: All 4 tests passing
- **Documentation**: 59 comprehensive .Rd files
- **Examples**: Practical @examples for all 37 functions

### 📊 **Package Statistics**
- **37 exported functions** (vs. 5-20 typical for CRAN packages)
- **15 R source files** with advanced analytics
- **3 comprehensive example scripts**
- **Complete vignette** with practical examples
- **Professional organization** following R package best practices

## Documentation & Help

- **📖 Complete Tutorial**: `vignette("introduction", package = "mobspain")`
- **📚 Function Documentation**: `?function_name` (e.g., `?get_mobility_matrix`)
- **📋 Package Overview**: `?mobspain`
- **🔧 Configuration Guide**: `?configure_mobspain`
- **📊 Advanced Functions**: See `ADVANCED_SUMMARY.md` in package repository
- **🌐 GitHub Repository**: https://github.com/iprincegh/mobspain-r-package

### Quick Reference
**Common Parameter Values:**
- **Spatial Levels**: `"dist"` (districts), `"muni"` (municipalities), `"lua"` (large urban areas)
- **Analysis Methods**: `"zscore"`, `"iqr"`, `"isolation"` (anomaly detection)
- **Color Palettes**: `"viridis"`, `"plasma"`, `"blues"`, `"reds"`
- **Map Providers**: `"osm"`, `"cartodb"`, `"stamen"`

### System Requirements
- R ≥ 4.0.0
- Internet connection (for data download)
- Sufficient disk space (data can be large)

---

Built on [spanishoddata](https://github.com/rOpenSpain/spanishoddata). MIT License.
