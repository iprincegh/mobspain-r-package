# Data Version Selection Examples

# Spanish mobility data comes in two versions
library(mobspain)

# ==============================================================================
# VERSION COMPARISON
# ==============================================================================

# Get detailed information about both data versions
version_info <- get_data_version_info()

# View comparison table
print(version_info$comparison)

# View recommendations
print(version_info$recommendations)

# ==============================================================================
# VERSION 1 EXAMPLES (2020-2021 COVID Period)
# ==============================================================================

# Setup for COVID-period analysis
init_data_dir("~/covid_mobility_data", version = 1)

# Get COVID-period zones
covid_zones <- get_spatial_zones("dist", version = 1)

# Get COVID-period mobility data
covid_mobility <- get_mobility_matrix(
  dates = c("2020-03-15", "2020-03-21"),  # During lockdown
  level = "dist",
  version = 1
)

# Analyze lockdown impact
containment_covid <- calculate_containment(covid_mobility)
print("COVID-period containment rates:")
print(summary(containment_covid$containment))

# ==============================================================================
# VERSION 2 EXAMPLES (2022 onwards - Enhanced Data)
# ==============================================================================

# Setup for current analysis (recommended)
init_data_dir("~/current_mobility_data", version = 2)

# Get current zones with enhanced resolution
current_zones <- get_spatial_zones("dist", version = 2)

# Get current mobility data with sociodemographic factors
current_mobility <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  level = "dist", 
  version = 2
)

# Analyze current patterns
containment_current <- calculate_containment(current_mobility)
print("Current containment rates:")
print(summary(containment_current$containment))

# ==============================================================================
# CROSS-BORDER ANALYSIS (Version 2 only)
# ==============================================================================

# Version 2 includes trips to/from Portugal and France
cross_border_mobility <- get_mobility_matrix(
  dates = c("2023-07-01", "2023-07-07"),  # Summer vacation period
  level = "dist",
  version = 2
)

# Filter for international flows (if available in the data)
# Note: This would require additional processing to identify cross-border zones

# ==============================================================================
# COMPARISON ANALYSIS
# ==============================================================================

# Compare mobility patterns between COVID and current periods
# Note: Use comparable date ranges (e.g., same month/season)

# COVID March 2020
covid_march <- get_mobility_matrix(
  dates = c("2020-03-01", "2020-03-07"),
  version = 1
)

# Normal March 2023  
normal_march <- get_mobility_matrix(
  dates = c("2023-03-01", "2023-03-07"),
  version = 2
)

# Calculate and compare mobility indicators
covid_indicators <- calculate_mobility_indicators(covid_march, covid_zones)
normal_indicators <- calculate_mobility_indicators(normal_march, current_zones)

print("COVID vs Normal Mobility Comparison:")
print(paste("COVID total outflow:", mean(covid_indicators$total_outflow, na.rm = TRUE)))
print(paste("Normal total outflow:", mean(normal_indicators$total_outflow, na.rm = TRUE)))

# ==============================================================================
# VISUALIZATION WITH VERSION SELECTION
# ==============================================================================

# Create flow maps for both periods
covid_flow_map <- create_flow_map(
  zones = covid_zones,
  od_data = covid_march,
  min_flow = 50,
  interactive = TRUE
)

normal_flow_map <- create_flow_map(
  zones = current_zones, 
  od_data = normal_march,
  min_flow = 50,
  interactive = TRUE
)

# District analysis for both periods
covid_madrid <- analyze_district_mobility(
  district_id = "28079",  # Madrid
  dates = c("2020-03-01", "2020-03-07"),
  zones = covid_zones,
  mobility_data = covid_march
)

normal_madrid <- analyze_district_mobility(
  district_id = "28079",  # Madrid
  dates = c("2023-03-01", "2023-03-07"), 
  zones = current_zones,
  mobility_data = normal_march
)

# ==============================================================================
# BEST PRACTICES
# ==============================================================================

# 1. For new projects: Use Version 2
init_data_dir(version = 2)  # Default and recommended

# 2. For COVID studies: Use Version 1
init_data_dir(version = 1)

# 3. Check current version
current_version <- get_current_data_version()
print(paste("Current version:", current_version))

# 4. Always specify version explicitly for reproducibility
mobility_v2 <- get_mobility_matrix(
  dates = c("2023-01-01", "2023-01-07"),
  version = 2  # Explicit version specification
)

# 5. Use appropriate date ranges for each version
# Version 1: 2020-2021 (COVID period)
# Version 2: 2022 onwards (current data)

print("Data version selection examples completed!")
print("Use get_data_version_info() for detailed version information.")
