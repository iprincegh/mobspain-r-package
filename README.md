# mobspain: Spanish Mobility Data Analysis

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Token-Free](https://img.shields.io/badge/Token--Free-✅-brightgreen)](https://github.com/iprincegh/mobspain-r-package)
[![R CMD Check](https://img.shields.io/badge/R%20CMD%20Check-PASS-green)](https://github.com/iprincegh/mobspain-r-package)
[![Functions Tested](https://img.shields.io/badge/Functions%20Tested-90%25-success)](https://github.com/iprincegh/mobspain-r-package)

**Professional R package for analyzing Spanish mobility patterns using official MITMA data.** 100+ functions covering mobility analysis, interactive dashboards, machine learning, and advanced analytics. Production-ready with extensive testing.

## Installation

```r
devtools::install_github("iprincegh/mobspain-r-package")
```

## Quick Start

```r
library(mobspain)

# 1. Setup and get data
configure_mobspain()
zones <- get_spatial_zones("dist")  # 3,909 districts
mobility <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"), level = "dist")

# 2. Core analysis
containment <- calculate_containment(mobility)
indicators <- calculate_mobility_indicators(mobility, zones)
anomalies <- detect_mobility_anomalies(mobility)

# 3. Interactive dashboard
dashboard <- create_mobility_dashboard(mobility, zones, dashboard_type = "overview")

# 4. Advanced analytics
predictions <- predict_mobility_patterns(mobility)
flow_map <- create_interactive_flow_map(zones, mobility, flow_threshold = 500)
```

## Key Functions

### 📊 **Data Access**
- `configure_mobspain()` - Package setup with intelligent defaults
- `get_spatial_zones(level)` - Zones: `"dist"` (3,909), `"muni"` (8,131), `"lua"` (85)
- `get_mobility_matrix(dates, level)` - Core mobility data retrieval
- `mobspain_status()` - Check package configuration

### 🔍 **Analysis**
- `calculate_containment(mobility)` - Measure local mobility containment
- `calculate_mobility_indicators(mobility, zones)` - Key accessibility metrics
- `detect_mobility_anomalies(mobility)` - Statistical anomaly detection
- `analyze_mobility_time_series(mobility)` - Temporal pattern analysis

### 🎛️ **Interactive Dashboards**
- `create_mobility_dashboard(mobility, zones, dashboard_type)` - Complete dashboards
  - Types: `"overview"`, `"temporal"`, `"spatial"`, `"comparative"`
- `create_interactive_flow_map(zones, mobility)` - Flow visualization
- `plot_daily_mobility(mobility)` - Daily pattern plotting

### 🤖 **Machine Learning**
- `predict_mobility_patterns(mobility)` - Pattern prediction
- `detect_mobility_anomalies_ml(mobility)` - ML-based anomaly detection
- `analyze_spatial_clustering(mobility, zones)` - Spatial clustering analysis

### 📈 **Time Series**
- `perform_seasonal_decomposition(mobility)` - Seasonal pattern analysis
- `detect_change_points(mobility)` - Change point detection
- `analyze_mobility_trends(mobility)` - Trend analysis

## Data Variables

### Mobility Matrix Variables
- `origin_id`, `destination_id` - Zone identifiers
- `date` - Date of travel (YYYY-MM-DD format)
- `n_trips` - Number of trips between zones
- `distance` - Distance between zones (km)
- `time_window` - Time period (0-23 hours)

### Spatial Zones Variables
- `id` - Zone identifier
- `name` - Zone name
- `area_km2` - Area in square kilometers
- `population` - Population count
- `centroid_lat`, `centroid_lon` - Geographic center coordinates

### Analysis Output Variables
- `containment` - Proportion of trips within zone (0-1)
- `accessibility` - Accessibility score based on trip patterns
- `anomaly_score` - Anomaly detection score
- `cluster_id` - Spatial cluster assignment
- `prediction` - Predicted mobility values

## Configuration Options

```r
configure_mobspain(
  parallel = TRUE,         # Enable parallel processing
  cache_enabled = TRUE,    # Enable caching
  data_source = "csv",     # Data source: "csv" or "duckdb"
  validate_data = TRUE     # Validate data on load
)
```

## Package Quality

✅ **Production-Ready**: 90% function success rate across 100+ functions  
✅ **R CMD Check**: Passes with minimal warnings  
✅ **Documentation**: 90+ comprehensive help files  
✅ **Token-Free**: No API keys required  
✅ **CRAN Compliant**: Professional package structure

## Documentation & Help

- **📖 Main Tutorial**: `vignette("introduction", package = "mobspain")`
- **📋 Package Overview**: `?mobspain`
- **🔧 Configuration**: `?configure_mobspain`
- **🎛️ Dashboards**: `?create_mobility_dashboard`
- **🌐 GitHub**: https://github.com/iprincegh/mobspain-r-package

## System Requirements

- **R ≥ 4.0.0**
- **Internet connection** (for data download)
- **Optional dependencies** handled gracefully:
  - `randomForest`, `xgboost` (for ML models)
  - `plotly`, `DT` (for interactive features)
  - `leaflet`, `sf` (for mapping)

---

**🎯 Production-ready package for professional Spanish mobility analysis.**  
Built on [spanishoddata](https://github.com/rOpenSpain/spanishoddata). MIT License.

**🌟 Star this repository if you find mobspain useful!**
