#' @import glue
#' @import lubridate
#' @import leaflet
#' @import dplyr
#' @importFrom sf st_area st_as_sf st_set_crs st_sfc st_point st_centroid st_distance
#' @importFrom ggplot2 ggplot aes geom_line labs theme_minimal geom_point geom_smooth
#' @importFrom utils globalVariables head tail
#' @importFrom stats coef lm quantile reorder sd median weighted.mean aggregate as.formula complete.cases fitted frequency pnorm predict ts var
#' @importFrom rlang .data sym
#' @importFrom methods is
NULL

# Declare global variables to avoid R CMD check warnings
globalVariables(c(
  "id_origin", "n_trips", "id_destination", "internal_trips", 
  "total_trips", "containment", ".", "id", "lon", "lat", 
  "geometry", "sample_zones", "weekday", "date", "total_outflow",
  "total_inflow", "external_trips", "n_destinations", "net_flow",
  "connectivity_index", "area_km2", "trip_density", "internal_density",
  "z_score", "is_anomaly", "distance_km", "hour", "flow_type",
  "destination_name", "datetime", "name", "avg_outbound", "avg_inbound",
  "avg_internal", "unique_destinations", "unique_origins", "connected_zone",
  "daily_trips", "avg_daily_trips", "max_daily_trips", "min_daily_trips",
  # New demographic analysis variables
  "demo_group", "age", "sex", "income", "unique_flows", "spatial_coverage",
  "flow_trips", "distance", "activity_origin", "temporal_group", 
  "residence_province", "interaction_group", "migration_trips", 
  "external_flows", "internal_flows", "flow_concentration", "flow_entropy",
  "trip_share", "flow_share", "spatial_share", "avg_distance_pref",
  "most_common_activity", "weekend_ratio", "migration_ratio", 
  "provinces_connected", "avg_connectivity", "avg_trips_per_flow", 
  "median_trips", "mobility_concentration", "temporal_diversity",
  "peak_period", "peak_trips", "off_peak_ratio",
  # New network analysis variables
  "node", "out_degree", "in_degree", "out_strength", "in_strength",
  "total_degree", "total_strength", "degree_centrality", "strength_centrality",
  "flow_frequency", "reachable_zones", "total_outbound_trips", "avg_trip_strength",
  "connectivity_diversity", "accessible_from", "total_inbound_trips",
  "connectivity_balance", "network_efficiency", "betweenness_approx",
  "closeness_approx", "eigenvector_approx", "bilateral_strength", "flow_symmetry",
  "return_trips", "community_pair", "community_strength", "community_size",
  "zone_name", "trips_per_km2", "spatial_efficiency", "direction",
  # New trip purpose analysis variables
  "trip_purpose", "distance_category", "activity_destination", "time_period",
  "preferred_distance", "distance_diversity", "dominant_purpose", 
  "purpose_diversity", "avg_trips_per_purpose", "trips_total_length_km",
  "total_distance_km", "avg_km_per_trip", "distance_efficiency", "efficiency_rank",
  # New economic analysis variables
  "travel_cost_per_trip", "travel_time_hours", "time_cost_per_trip", 
  "total_cost_per_trip", "total_travel_cost", "total_time_cost", 
  "total_economic_impact", "avg_cost_per_trip", "total_travel_time_hours",
  "outbound_economic_impact", "avg_outbound_cost", "outbound_destinations",
  "total_outbound_time", "inbound_economic_impact", "avg_inbound_cost",
  "inbound_origins", "total_inbound_time", "zone_id", "economic_balance",
  "accessibility_index", "time_burden", "activity_pair", "cost_efficiency",
  "population", "gdp", "employment", "economic_impact_per_capita",
  "trips_per_capita", "economic_density", "trip_density", "demographic_group",
  "demographic_variable", "commute_direction", "commute_cost", "residential_zone",
  "accessible_job_zones", "total_job_trips", "avg_commute_distance",
  "avg_commute_cost", "max_commute_distance", "min_commute_cost",
  "job_zone", "catchment_residential_zones", "total_workers", 
  "avg_worker_distance", "avg_worker_cost", "max_catchment_distance",
  "employment_centrality", "total_commute_trips", "total_commute_cost",
  "commute_directions", "cost_per_trip", "commute_efficiency", "is_bidirectional",
  "residents_job_access", "total_outbound_commuters", "jobs_attraction",
  "total_inbound_workers", "jobs_housing_ratio", "balance_index", "zone_type",
  "accessibility_density", "employment_density", "commuter_per_capita",
  "worker_per_capita",
  # Additional missing variables from R CMD check
  "activity_type", "avg_distance", "avg_distance_km", "coverage", "dest_total",
  "distance_band", "flow_count", "from", "inbound_commutes", "inbound_trips",
  "origin_total", "outbound_commutes", "outbound_trips", "to", "total_commuters",
  "total_groups", "trips", "income_level", "income_origin", "income_destination",
  "accessible_destinations", "total_outbound_trips", "avg_accessibility",
  "avg_outbound_trips", "accessibility_dispersion", "flow_proportion",
  "is_same_income", "total_outbound", "same_income_trips", "income_retention_rate",
  "trips_proportion", "mobility_index", "flow_efficiency"
))
