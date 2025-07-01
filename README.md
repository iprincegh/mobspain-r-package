# mobspain: Spanish Mobility Data Analysis Toolkit

[![R-CMD-check](https://github.com/iprincegh/mobspain-r-package/workflows/R-CMD-check/badge.svg)](https://github.com/iprincegh/mobspain-r-package/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive R package for analyzing Spanish mobility patterns using MITMA (Ministry of Transport, Mobility and Urban Agenda) data. Built on top of the `spanishoddata` package with enhanced analytics, visualization, and performance features.

## 🚀 Features

- **📊 Complete Data Access**: Download and process real Spanish mobility data from MITMA
- **🎯 Advanced Analytics**: Containment indices, anomaly detection with weekday/weekend context, distance-decay modeling, comprehensive mobility indicators
- **🗺️ Rich Visualizations**: Interactive flow maps, choropleth maps, heatmaps, time series plots, and distance-decay plots  
- **💾 Smart Data Management**: Automatic caching, data directory setup, and efficient processing
- **🔧 Production Ready**: All 21 functions tested and working with real data
- **⚙️ Flexible Configuration**: Customizable settings for parallel processing, caching, and advanced features
- **🛡️ Data Quality Tools**: MITMA-specific validation, holiday detection, and optimal parameter recommendations

## 📦 Installation

### From GitHub
```r
# Install from GitHub
devtools::install_github("iprincegh/mobspain-r-package")
```

### Dependencies
```r
# Core dependencies (automatically installed)
install.packages(c("spanishoddata", "sf", "dplyr", "ggplot2", "leaflet", "duckdb"))
```

## 🎯 Quick Start

### Basic Usage
```r
library(mobspain)

# Set up data directory
init_data_dir()

# Load sample zones
data(sample_zones)
print(sample_zones)

# Download real Spanish spatial zones (3,909 zones)
zones <- get_spatial_zones()

# Get mobility matrix (downloads real MITMA data)
mobility_data <- get_mobility_matrix()

# Calculate mobility indicators
containment <- calculate_containment(mobility_data)

# Create interactive flow map
flow_map <- create_flow_map(zones, mobility_data)
```

### Complete Working Examples

**Full Demonstration** (`complete_working_example.R`):
```r
source("complete_working_example.R")
```
- Demonstrates all 9 functions working with real data
- Downloads actual MITMA mobility data
- Creates visualizations and analytics
- Perfect for understanding full package capabilities

**Quick Introduction** (`simple_mobspain_example.R`):
```r
source("simple_mobspain_example.R")
```
- Basic functionality with sample data
- Quick package overview
- Ideal for first-time users

## 📊 Core Functions

| Function | Description | Status |
|----------|-------------|---------|
| `get_spatial_zones()` | Download Spanish administrative zones | ✅ Working |
| `get_mobility_matrix()` | Retrieve mobility flow data | ✅ Working |
| `calculate_containment()` | Compute self-containment indices | ✅ Working |
| `create_flow_map()` | Interactive/static flow visualization | ✅ Working |
| `plot_daily_mobility()` | Time series mobility plotting | ✅ Working |
| `init_data_dir()` | Set up data directory | ✅ Working |
| `create_zone_index()` | Spatial zone indexing | ✅ Working |
| `connect_mobility_db()` | Database connection management | ✅ Working |
| `sample_zones` | Sample data for testing | ✅ Working |
| `standardize_od_columns()` | Flexible data input handling | ✅ Working |

### 🚀 Advanced Analytics & Validation

| Function | Description | Status |
|----------|-------------|---------|
| `calculate_mobility_indicators()` | Comprehensive mobility metrics | ✅ Working |
| `detect_mobility_anomalies()` | Statistical anomaly detection (weekday/weekend aware) | ✅ Working |
| `calculate_distance_decay()` | Distance-decay relationship modeling | ✅ Working |
| `validate_mitma_data()` | Data quality validation | ✅ Working |
| `check_spanish_holidays()` | Holiday detection | ✅ Working |
| `get_optimal_parameters()` | Parameter recommendations | ✅ Working |

### 🎨 Visualization Functions

| Function | Description | Status |
|----------|-------------|---------|
| `create_choropleth_map()` | Spatial indicator mapping | ✅ Working |
| `plot_mobility_heatmap()` | Flow matrix heatmaps | ✅ Working |
| `plot_distance_decay()` | Distance-decay visualization | ✅ Working |

### ⚙️ Configuration & Utilities

| Function | Description | Status |
|----------|-------------|---------|
| `configure_mobspain()` | Package configuration | ✅ Working |
| `mobspain_status()` | Package diagnostics | ✅ Working |

**Total: 21 Working Functions** ✅

## 🗺️ Data Sources

- **MITMA (Ministry of Transport)**: Official Spanish mobility data from mobile phone analytics
- **Administrative Boundaries**: Districts (~3,909), municipalities (~8,131), and large urban areas (~85)
- **Real-time Downloads**: Automatic data retrieval and caching from February 2020 onwards
- **Comprehensive Coverage**: All Spanish territories with hourly and daily temporal resolution
- **Methodology**: Based on [MITMA official standards v8](https://www.transportes.gob.es/recursos_mfom/paginabasica/recursos/a3_informe_metodologico_estudio_movilidad_mitms_v8.pdf)

## 📈 Example Analysis

```r
# Complete mobility analysis workflow
library(mobspain)

# 1. Setup and validation
init_data_dir()
mobspain_status()

# Get optimal parameters for your analysis
optimal_params <- get_optimal_parameters("exploratory", "medium")

# 2. Get spatial data
zones <- get_spatial_zones("dist")  # Districts level
cat("Downloaded", nrow(zones), "spatial zones")

# 3. Get mobility data 
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist"
)

# 4. Data validation and quality checks
quality_report <- validate_mitma_data(mobility)
holidays <- check_spanish_holidays(unique(mobility$date))

# 5. Calculate comprehensive metrics
containment <- calculate_containment(mobility)
indicators <- calculate_mobility_indicators(mobility, zones)
anomalies <- detect_mobility_anomalies(mobility, method = "zscore", by_weekday = TRUE)

# 6. Advanced analytics
decay_model <- calculate_distance_decay(mobility, zones)
print(paste("Distance decay R²:", round(decay_model$r_squared, 3)))

# 7. Visualizations
flow_map <- create_flow_map(zones, mobility, min_flow = 500)
daily_plot <- plot_daily_mobility(mobility)
heatmap <- plot_mobility_heatmap(mobility, top_n = 20)
choropleth <- create_choropleth_map(zones, indicators, variable = "containment")

# 8. Results
print("Top 10 most self-contained zones:")
print(head(containment[order(-containment$containment), ], 10))

flow_map      # Interactive flow map
daily_plot    # Time series plot
heatmap       # Flow matrix heatmap
choropleth    # Choropleth map
```

## 🔧 Configuration

The package supports flexible configuration and intelligent data management:

```r
# Configure package settings
configure_mobspain(
  parallel = TRUE,         # Enable parallel processing
  n_cores = 4,            # Number of cores to use
  cache_enabled = TRUE,   # Enable intelligent caching
  data_dir = "~/spanish_mobility_data/"  # Custom data directory
)

# Check configuration and package status
mobspain_status()

# Get optimal parameters for your analysis type
optimal_params <- get_optimal_parameters(
  analysis_type = "exploratory",  # or "detailed", "quick"
  computational_resources = "medium"  # or "low", "high"
)

# Data validation and quality checks
quality_report <- validate_mitma_data(your_mobility_data)
holidays <- check_spanish_holidays(c("2023-01-01", "2023-12-25"))
```

### Data Storage
- **Default location**: `~/spanish_mobility_data/`
- **Automatic caching**: Smart caching for faster subsequent access
- **Configurable**: Custom data directories and cache settings
- **Efficient**: Optimized storage and retrieval using DuckDB

## 📚 Documentation

- **Package Help**: `?mobspain` or `help(package = "mobspain")`
- **Function Documentation**: `?function_name` (e.g., `?get_mobility_matrix`)
- **Vignette**: `vignette("introduction", package = "mobspain")`
- **Examples**: See `complete_working_example.R` and `simple_mobspain_example.R`

## 🤝 Contributing

This package builds on the excellent [spanishoddata](https://github.com/rOpenSpain/spanishoddata) package. Contributions, issues, and feature requests are welcome!

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

## 🔗 Links

- **GitHub Repository**: https://github.com/iprincegh/mobspain-r-package
- **Issue Tracker**: https://github.com/iprincegh/mobspain-r-package/issues
- **MITMA Data Source**: [Spanish Ministry of Transport](https://www.mitma.gob.es/)

## 🙏 Acknowledgments

- **spanishoddata**: Base data access functionality
- **MITMA**: Spanish mobility data provision
- **R Community**: Amazing ecosystem and tools

---

**Ready to analyze Spanish mobility patterns? Install mobspain and start exploring!** 🇪🇸📊


