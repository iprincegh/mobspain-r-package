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


