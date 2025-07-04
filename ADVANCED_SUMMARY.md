# Advanced Mobility Analysis Functions - Summary

Based on the rich MITMA mobility data structure with columns like `id_origin`, `id_destination`, `distance`, `activity_origin`, `activity_destination`, `trips_total_length_km`, plus demographic data in Version 2 (age, sex, income, residence), I've created comprehensive analytical functions organized into several categories:

## 1. Activity-Based Analysis Functions (R/activity.R)

### Existing Functions:
- **`calculate_activity_patterns()`** - Analyzes mobility flows by activity types (home, work, other)
- **`calculate_distance_analysis()`** - Analyzes mobility patterns by distance bands
- **`calculate_activity_distance_patterns()`** - Examines activity-distance interactions
- **`calculate_commuting_patterns()`** - Identifies and analyzes commuting flows

### New Functions Added:
- **`analyze_mobility_network()`** - Network analysis of mobility flows including:
  - Centrality measures (degree, strength, betweenness approximation)
  - Community detection based on bilateral flows
  - Network efficiency and connectivity metrics
  - Spatial integration with zone attributes

- **`analyze_trip_purpose_distance()`** - Trip purpose and distance analysis:
  - Activity-distance interaction matrices
  - Trip efficiency by purpose and distance
  - Temporal patterns by trip purpose
  - Distance preferences by activity type

## 2. Demographic Analysis Functions (R/demographic.R) - NEW FILE

- **`analyze_demographic_mobility()`** - Mobility patterns by demographics:
  - Age group analysis (Young, Adult, Middle Age, Senior)
  - Gender-based mobility patterns
  - Income level mobility analysis
  - Mobility diversity and inequality metrics

- **`analyze_residence_mobility()`** - Residence-based mobility patterns:
  - Migration flows by residence province
  - Cross-regional mobility analysis
  - Residence-travel pattern relationships

- **`analyze_socioeconomic_mobility()`** - Comprehensive socioeconomic analysis:
  - Multi-factor demographic analysis
  - Factor interaction analysis (age×income, sex×income, etc.)
  - Cross-factor mobility comparison
  - Socioeconomic mobility inequality

- **`analyze_temporal_demographic_mobility()`** - Time-demographic interactions:
  - Hourly patterns by demographic groups
  - Peak hour analysis by age/income/gender
  - Temporal mobility equality metrics

## 3. Economic Analysis Functions (R/economic.R) - NEW FILE

- **`analyze_economic_mobility()`** - Economic impact analysis:
  - Travel cost estimation (distance-based costs)
  - Time value calculations
  - Economic accessibility indicators
  - Zone-level economic impact assessment
  - Activity-based cost analysis
  - Demographic economic patterns

- **`analyze_job_accessibility()`** - Employment and commuting economics:
  - Job accessibility from residential zones
  - Employment attraction analysis
  - Commuting cost and burden analysis
  - Jobs-housing balance metrics
  - Demographic commuting patterns
  - Spatial accessibility integration

## Key Data Utilization

### Core Columns Leveraged:
- **`id_origin`, `id_destination`** - Spatial flow analysis, network construction
- **`n_trips`** - Volume weighting, flow strength calculations
- **`distance`** - Distance decay modeling, cost calculations
- **`activity_origin`, `activity_destination`** - Purpose-based analysis, commuting identification
- **`trips_total_length_km`** - Economic cost estimation, efficiency metrics

### Version 2 Enhanced Columns:
- **`age`** - Age-based mobility patterns, life-cycle analysis
- **`sex`** - Gender mobility differences, safety implications
- **`income`** - Socioeconomic mobility analysis, accessibility equity
- **`residence_province_*`** - Migration patterns, cross-regional flows

### Temporal Columns:
- **`date`, `hour`** - Temporal patterns, peak hour analysis
- **`weekday`** - Weekend vs weekday mobility differences

## Advanced Analytical Capabilities

### 1. **Network Analysis**
- Node centrality and importance ranking
- Community detection in mobility networks
- Network efficiency and connectivity metrics
- Spatial network integration

### 2. **Economic Assessment**
- Travel cost estimation with customizable parameters
- Time value calculations for economic impact
- Economic accessibility and equity analysis
- Jobs-housing balance and commuting burden

### 3. **Demographic Insights**
- Multi-dimensional demographic analysis
- Factor interaction exploration
- Mobility inequality measurement
- Temporal-demographic pattern analysis

### 4. **Spatial Integration**
- Zone-based aggregation and analysis
- Spatial efficiency metrics
- Area-normalized indicators
- Population-weighted accessibility

### 5. **Activity-Based Modeling**
- Trip purpose classification and analysis
- Activity-distance relationship modeling
- Commuting pattern identification
- Purpose-specific mobility metrics

## Function Integration and Workflow

All functions are designed to work together and with existing mobspain functions:

```r
# Complete analytical workflow example
zones <- get_spatial_zones("dist")
mobility <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))

# Basic analysis
containment <- calculate_containment(mobility)
indicators <- calculate_mobility_indicators(mobility, zones)

# Advanced activity analysis
activity_patterns <- calculate_activity_patterns(mobility)
commuting <- calculate_commuting_patterns(mobility)
network <- analyze_mobility_network(mobility, zones)

# Demographic analysis (Version 2 data)
demo_age <- analyze_demographic_mobility(mobility, demographic_var = "age")
socioeconomic <- analyze_socioeconomic_mobility(mobility)
temporal_demo <- analyze_temporal_demographic_mobility(mobility, "income", "hour")

# Economic analysis
economic <- analyze_economic_mobility(mobility, zones)
job_access <- analyze_job_accessibility(mobility, zones)

# Trip purpose analysis
trip_purpose <- analyze_trip_purpose_distance(mobility)
```

## Output Structure

Each function returns comprehensive results with:
- **Main analysis data frames** with detailed metrics
- **Summary statistics** for quick insights
- **Metadata** about analysis parameters
- **Spatial integration** when zones provided
- **Temporal breakdowns** when time data available

This creates a complete analytical ecosystem for understanding Spanish mobility patterns from basic flows to complex socioeconomic and economic relationships.
