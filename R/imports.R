#' @import glue
#' @import lubridate
#' @import leaflet
#' @importFrom dplyr %>% mutate summarise group_by filter select
#' @importFrom sf st_area st_as_sf st_set_crs st_sfc st_point
#' @importFrom ggplot2 ggplot aes geom_line labs theme_minimal
#' @importFrom utils globalVariables
#' @importFrom stats coef lm quantile reorder sd
#' @importFrom rlang .data
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
  "daily_trips", "avg_daily_trips", "max_daily_trips", "min_daily_trips"
))
