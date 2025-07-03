# mobspain: Spanish Mobility Data Analysis Toolkit

[![R-CMD-check](https://github.com/iprincegh/mobspain-r-package/workflows/R-CMD-check/badge.svg)](https://github.com/iprincegh/mobspain-r-package/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive R package for analyzing Spanish mobility patterns using MITMA (Ministry of Transport, Mobility and Urban Agenda) data. Built on `spanishoddata` with enhanced analytics, visualization, and performance features.

## ✨ Key Features

- **Data Access**: Real Spanish mobility data from MITMA (~3,909 districts, ~8,131 municipalities)
- **Advanced Analytics**: Containment analysis, anomaly detection, distance-decay modeling, mobility indicators
- **Visualizations**: Interactive flow maps, choropleth maps, heatmaps, time series plots
- **Production Ready**: 21 tested functions with data validation and quality tools
- **Smart Caching**: Automatic data management with configurable parallel processing

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

# Setup
init_data_dir()
data(sample_zones)

# Get real Spanish zones and mobility data
zones <- get_spatial_zones("dist")  # ~3,909 districts
mobility <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))

# Analytics
containment <- calculate_containment(mobility)
anomalies <- detect_mobility_anomalies(mobility, by_weekday = TRUE)
indicators <- calculate_mobility_indicators(mobility, zones)

# Visualizations
flow_map <- create_flow_map(zones, mobility, min_flow = 500)
daily_plot <- plot_daily_mobility(mobility)
```

## 📊 Functions Overview

**21 Production-Ready Functions** ✅

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

### Advanced Analytics (6)
| Function | Description |
|----------|-------------|
| `calculate_mobility_indicators()` | Comprehensive mobility metrics |
| `detect_mobility_anomalies()` | Statistical anomaly detection |
| `calculate_distance_decay()` | Distance-decay modeling |
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


