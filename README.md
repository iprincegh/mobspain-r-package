# mobspain: Spanish Mobility Data Analysis Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Token-Free](https://img.shields.io/badge/Token--Free-✅-brightgreen)](https://github.com/iprincegh/mobspain-r-package)
[![Open Source](https://img.shields.io/badge/Open%20Source-❤️-red)](https://github.com/iprincegh/mobspain-r-package)

A comprehensive R package for analyzing Spanish mobility patterns using MITMA (Ministry of Transport, Mobility and Urban Agenda) data. Built on `spanishoddata` with enhanced analytics, visualization, and performance features.

## 🌟 **100% Token-Free & Open Access**

**No API keys, no tokens, no payment required!** This package is designed for maximum accessibility:

- ✅ **Free forever** - No hidden costs or subscription fees
- ✅ **No API tokens** - Works immediately after installation
- ✅ **Open source maps** - OpenStreetMap, CartoDB, Stamen
- ✅ **Offline capable** - Core functionality works without internet
- ✅ **Student friendly** - Perfect for educational use
- ✅ **Research ready** - Reproducible and transparent

## ✨ Key Features

- **Data Access**: Real Spanish mobility data from MITMA (~3,909 districts, ~8,131 municipalities)
- **Dual Data Versions**: Version 1 (2020-2021 COVID) and Version 2 (2022+ enhanced data)
- **Advanced Analytics**: Containment analysis, anomaly detection, distance-decay modeling, mobility indicators
- **District Analysis**: Detailed analysis of specific districts with heatmaps and flow visualization
- **Visualizations**: Interactive flow maps, choropleth maps, heatmaps, time series plots
- **Production Ready**: 22+ tested functions with data validation and quality tools
- **Smart Caching**: Automatic data management with configurable parallel processing

## 📊 Data Versions

The package supports **two versions** of Spanish mobility data:

| Feature | Version 1 (2020-2021) | Version 2 (2022 onwards) |
|---------|------------------------|---------------------------|
| **Period** | COVID-19 pandemic | Current data (recommended) |
| **Spatial Resolution** | Standard districts/municipalities | Enhanced resolution |
| **Countries** | Spain only | Spain + Portugal + France |
| **Sociodemographic** | Basic | Income, age, sex |
| **Use Cases** | COVID impact studies | Current mobility analysis |

```r
# Choose your version based on research needs
init_data_dir(version = 2)  # Recommended: Enhanced current data
init_data_dir(version = 1)  # For COVID-19 studies

# Get version information
get_data_version_info()$comparison
```

## 📦 Installation

```r
# Install from GitHub
devtools::install_github("iprincegh/mobspain-r-package")

# Core dependencies (automatically installed)
# spanishoddata, sf, dplyr, ggplot2, leaflet, duckdb
```

## 🚀 Quick Start

```r
library(mobspain)

# Setup with data version selection
init_data_dir(version = 2)  # Version 2 (2022+, recommended) or 1 (2020-2021 COVID)
data(sample_zones)

# Get Spanish zones and mobility data with version control
zones <- get_spatial_zones("dist", version = 2)  # ~3,909 districts
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  version = 2  # Enhanced data with sociodemographic factors
)

# Compare with COVID-period data
covid_mobility <- get_mobility_matrix(
  dates = c("2020-03-15", "2020-03-21"),
  version = 1  # COVID-19 pandemic period data
)

# Get detailed version information
version_info <- get_data_version_info()
print(version_info$comparison)

# Analytics with version-aware data
containment <- calculate_containment(mobility)
anomalies <- detect_mobility_anomalies(mobility, by_weekday = TRUE)
indicators <- calculate_mobility_indicators(mobility, zones)

# Visualizations (completely token-free)
flow_map <- create_flow_map(zones, mobility, min_flow = 500)
daily_plot <- plot_daily_mobility(mobility)

# District-specific analysis
madrid_analysis <- analyze_district_mobility(
  district_id = "28079", 
  dates = c("2023-01-01", "2023-01-07"),
  time_range = c(7, 9),  # Morning rush hour
  plot_type = "all"
)
madrid_analysis$heatmap
madrid_analysis$flow_plot
```

## 📊 Functions Overview

**22+ Production-Ready Functions** ✅

### Core Functions (10)
| Function | Description |
|----------|-------------|
| `get_spatial_zones()` | Download Spanish administrative zones |
| `get_mobility_matrix()` | Retrieve MITMA mobility data |
| `calculate_containment()` | Self-containment analysis |
| `create_flow_map()` | Interactive flow visualization |
| `plot_daily_mobility()` | Time series plotting |
| `init_data_dir()` / `connect_mobility_db()` | Data setup |
| `create_zone_index()` / `sample_zones` | Spatial utilities |
| `standardize_od_columns()` | Data standardization |

### Advanced Analytics (7)
| Function | Description |
|----------|-------------|
| `calculate_mobility_indicators()` | Comprehensive mobility metrics |
| `detect_mobility_anomalies()` | Statistical anomaly detection |
| `calculate_distance_decay()` | Distance-decay modeling |
| `analyze_district_mobility()` | **NEW!** District-specific analysis with heatmaps |
| `validate_mitma_data()` | Data quality validation |
| `check_spanish_holidays()` | Holiday detection |
| `get_optimal_parameters()` | Parameter recommendations |

### Visualization & Config (5)
| Function | Description |
|----------|-------------|
| `create_choropleth_map()` / `plot_mobility_heatmap()` | Spatial mapping |
| `plot_distance_decay()` | Distance visualization |
| `configure_mobspain()` / `mobspain_status()` | Package management |

## � Complete Analysis Example

```r
library(mobspain)

# Setup and configuration
init_data_dir()
optimal_params <- get_optimal_parameters("exploratory", "medium")

# Data retrieval
zones <- get_spatial_zones("dist")
mobility <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"), level = "dist")

# Data validation
quality_report <- validate_mitma_data(mobility)
holidays <- check_spanish_holidays(unique(mobility$date))

# Analytics
containment <- calculate_containment(mobility)
indicators <- calculate_mobility_indicators(mobility, zones)
anomalies <- detect_mobility_anomalies(mobility, method = "zscore", by_weekday = TRUE)
decay_model <- calculate_distance_decay(mobility, zones)

# Visualizations
flow_map <- create_flow_map(zones, mobility, min_flow = 500)
daily_plot <- plot_daily_mobility(mobility)
choropleth <- create_choropleth_map(zones, indicators, variable = "containment")

# Results
print(head(containment[order(-containment$containment), ], 10))
print(paste("Distance decay R²:", round(decay_model$r_squared, 3)))
```

## ⚙️ Configuration & Data

```r
# Package configuration
configure_mobspain(parallel = TRUE, n_cores = 4, cache_enabled = TRUE)
mobspain_status()  # Check package status

# Data validation and optimization
quality_report <- validate_mitma_data(your_data)
holidays <- check_spanish_holidays(c("2023-01-01", "2023-12-25"))
optimal_params <- get_optimal_parameters("exploratory", "medium")
```

**Data Sources:**
- **MITMA**: Official Spanish mobility data (Feb 2020+)
- **Spatial Coverage**: Districts (~3,909), municipalities (~8,131), LUAs (~85)
- **Methodology**: [MITMA official standards v8](https://www.transportes.gob.es/recursos_mfom/paginabasica/recursos/a3_informe_metodologico_estudio_movilidad_mitms_v8.pdf)
- **Storage**: `~/spanish_mobility_data/` with smart caching

## 📚 Resources

- **Documentation**: `?mobspain`, `vignette("introduction", package = "mobspain")`
- **Examples**: `complete_working_example.R`, `simple_mobspain_example.R`
- **GitHub**: https://github.com/iprincegh/mobspain-r-package
- **Issues**: https://github.com/iprincegh/mobspain-r-package/issues

Built on [spanishoddata](https://github.com/rOpenSpain/spanishoddata). MIT License.

---
**Ready to analyze Spanish mobility patterns? Install mobspain and start exploring!** 🇪🇸📊


