# mobspain: Spanish Mobility Data Analysis Toolkit

[![R-CMD-check](https://github.com/iprincegh/mobspain-r-package/workflows/R-CMD-check/badge.svg)](https://github.com/iprincegh/mobspain-r-package/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive R package for analyzing Spanish mobility patterns using MITMA (Ministry of Transport, Mobility and Urban Agenda) data. Built on top of the `spanishoddata` package with enhanced analytics, visualization, and performance features.

## 🚀 Features

### 📊 **Advanced Analytics**
- **Mobility Indicators**: Comprehensive metrics including containment, connectivity, and flow analysis
- **Anomaly Detection**: Statistical methods for identifying unusual mobility patterns
- **Distance Decay Modeling**: Power law and exponential decay analysis
- **Spatial Analysis**: Zone-based mobility calculations with geometric support

### 🎨 **Rich Visualizations**
- **Interactive Flow Maps**: Leaflet-based mobility flow visualization
- **Choropleth Maps**: Spatial distribution of mobility indicators
- **Time Series Plots**: Daily and hourly mobility pattern analysis
- **Heatmaps**: Origin-destination flow matrices
- **Distance Decay Plots**: Relationship visualization between distance and mobility

### ⚡ **Performance & Usability**
- **Smart Caching**: Automatic data caching for faster repeated analyses
- **Parallel Processing**: Multi-core support for large datasets
- **Robust Error Handling**: Graceful fallbacks and informative error messages
- **Flexible Data Access**: DuckDB, CSV, and sample data support

## 📦 Installation

### From GitHub (Recommended)
```r
# Install development version
devtools::install_github("iprincegh/mobspain-r-package")
```

### Dependencies
```r
# Core dependencies
install.packages(c("spanishoddata", "sf", "dplyr", "ggplot2", "leaflet", "duckdb"))

# Optional for enhanced features
install.packages(c("digest", "viridis", "parallel"))
```

## 🎯 Quick Start

### Basic Setup
```r
library(mobspain)

# Load sample data
data(sample_zones)
print(sample_zones)

# For a working example, see:
# - simple_mobspain_example.R (demonstrates core functionality)
```

### Running the Examples
The package includes working example scripts to help you get started:

**Complete Working Example** (`complete_working_example.R`):
```r
source("complete_working_example.R")
```
- Demonstrates **ALL 9 functions working perfectly** (100% success rate)
- Downloads real MITMA data from Spanish government
- Shows analytics, visualization, and data processing capabilities
- Perfect for new users and demonstrates production readiness

**Simple Example** (`simple_mobspain_example.R`):
```r
source("simple_mobspain_example.R")
```
- Focuses on core functionality with sample data
- Quick introduction to package capabilities
- Lightweight demonstration

# Configure package (optional)
configure_mobspain(parallel = TRUE, n_cores = 4)

# Check package status
mobspain_status()

# Initialize data directory
init_data_dir("~/spanish_mobility_data")
```

### Data Analysis Workflow
```r
# 1. Get spatial zones
zones <- get_spatial_zones("dist")  # Districts

# 2. Get mobility data
mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist",
  time_window = c(7, 9)  # Morning commute
)

# 3. Calculate comprehensive indicators
indicators <- calculate_mobility_indicators(mobility, zones)

# 4. Detect anomalies
anomalies <- detect_mobility_anomalies(mobility, method = "zscore")

# 5. Model distance decay
decay_model <- calculate_distance_decay(mobility, zones, model = "power")
```

### Visualization Examples
```r
# Time series plot
plot_daily_mobility(mobility)

# Interactive flow map
create_flow_map(mobility, zones, min_flow = 100)

# Choropleth map
create_choropleth_map(zones, indicators, variable = "containment")

# Mobility heatmap
plot_mobility_heatmap(mobility, top_n = 50)

# Distance decay visualization
plot_distance_decay(decay_model, log_scale = TRUE)
```

## 📚 Key Functions

### Data Management
- `init_data_dir()`: Set up data storage directory
- `connect_mobility_db()`: Connect to DuckDB database
- `configure_mobspain()`: Package configuration

### Data Retrieval
- `get_mobility_matrix()`: Retrieve origin-destination mobility data
- `get_spatial_zones()`: Download Spanish administrative boundaries

### Analytics
- `calculate_mobility_indicators()`: Comprehensive mobility metrics
- `calculate_containment()`: Self-containment analysis
- `detect_mobility_anomalies()`: Anomaly detection
- `calculate_distance_decay()`: Distance-decay modeling

### Visualization
- `plot_daily_mobility()`: Time series visualization
- `create_flow_map()`: Interactive flow mapping
- `create_choropleth_map()`: Spatial indicator mapping
- `plot_mobility_heatmap()`: Flow matrix heatmaps
- `plot_distance_decay()`: Distance-decay plots

### Utilities
- `mobspain_status()`: Package diagnostics
- `create_zone_index()`: Spatial indexing for performance

## 🗺️ Data Sources

This package works with Spanish mobility data from:
- **MITMA**: Ministry of Transport, Mobility and Urban Agenda
- **INE**: National Statistics Institute spatial boundaries
- **Administrative Levels**: Districts, Municipalities, Large Urban Areas

## 📖 Documentation

### Vignettes
- `vignette("introduction", package = "mobspain")`: Getting started guide
- Complete function documentation: `?function_name`

### Sample Data
The package includes `sample_zones` dataset for testing and learning:
```r
data("sample_zones")
head(sample_zones)
```

## 🔧 Advanced Configuration

### Parallel Processing
```r
configure_mobspain(
  parallel = TRUE,
  n_cores = 8,
  max_cache_size = 2000  # MB
)
```

### Caching Control
```r
# Configure caching
configure_mobspain(
  cache_dir = "~/mobility_cache",
  max_cache_size = 1000
)
```

## 🤝 Contributing

We welcome contributions! Please see our [contributing guidelines](CONTRIBUTING.md) for details.

### Development Setup
```r
# Clone and setup
git clone https://github.com/iprincegh/mobspain-r-package.git
cd mobspain-r-package

# Install development dependencies
devtools::install_dev_deps()

# Run tests
devtools::test()

# Check package
devtools::check()
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/iprincegh/mobspain-r-package/issues)
- **Discussions**: [GitHub Discussions](https://github.com/iprincegh/mobspain-r-package/discussions)
- **Email**: [Your Email]

## 🙏 Acknowledgments

- **spanishoddata**: Base data access functionality
- **MITMA**: Spanish mobility data provision
- **R Community**: Amazing ecosystem and tools

## 📊 Package Status

Current version: 0.1.0

### ✅ Implemented Features
- Core mobility data access and analysis
- Advanced analytics and modeling
- Rich visualization capabilities
- Performance optimizations
- Comprehensive documentation

### 🔮 Roadmap
- [ ] Real-time data processing
- [ ] Machine learning integration
- [ ] Network analysis capabilities
- [ ] Enhanced spatial analytics
- [ ] API integrations

---

**Happy analyzing! 🇪🇸📊**

For more information, visit our [GitHub repository](https://github.com/iprincegh/mobspain-r-package).
