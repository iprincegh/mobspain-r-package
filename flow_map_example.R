# Flow Map Example - Handling Origin-Destination Data Properly
# This script shows how to create effective flow maps with the mobspain data

library(mobspain)
library(dplyr)

cat("=== Flow Map Configuration Guide ===\n\n")

# 1. Load data
zones <- get_spatial_zones("dist")
mobility <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-02"), level = "dist")

cat("Data loaded:\n")
cat("• Zones:", nrow(zones), "\n")
cat("• Mobility records:", nrow(mobility), "\n\n")

# 2. Analyze flow patterns
cat("Analyzing flow patterns...\n")

# Check internal vs external flows
internal_flows <- mobility %>% filter(id_origin == id_destination)
external_flows <- mobility %>% filter(id_origin != id_destination)

cat("• Internal flows (same zone):", nrow(internal_flows), "\n")
cat("• External flows (between zones):", nrow(external_flows), "\n\n")

# 3. Prepare different flow datasets for visualization

# Option A: Daily aggregated flows (recommended for flow maps)
daily_flows <- mobility %>%
  group_by(id_origin, id_destination, date) %>%
  summarise(n_trips = sum(n_trips, na.rm = TRUE), .groups = "drop") %>%
  filter(n_trips > 0)

# Option B: Inter-zone flows only (shows connections between areas)
inter_zone_flows <- daily_flows %>%
  filter(id_origin != id_destination) %>%
  filter(n_trips >= 10)  # Minimum threshold for visibility

# Option C: Top flows (most significant movements)
top_flows <- daily_flows %>%
  arrange(desc(n_trips)) %>%
  head(100)  # Top 100 flows

cat("Flow datasets prepared:\n")
cat("• Daily flows:", nrow(daily_flows), "\n")
cat("• Inter-zone flows:", nrow(inter_zone_flows), "\n")
cat("• Top flows:", nrow(top_flows), "\n\n")

# 4. Create different types of flow maps
cat("Creating flow maps...\n")

# Flow Map 1: Inter-zone connections
if(nrow(inter_zone_flows) > 0) {
  flow_map_connections <- create_flow_map(
    zones, 
    inter_zone_flows, 
    min_flow = 20,
    map_style = "osm"
  )
  cat("✓ Inter-zone connections map created\n")
} else {
  cat("⚠ No inter-zone flows found with current threshold\n")
}

# Flow Map 2: Top flows only
if(nrow(top_flows) > 0) {
  flow_map_top <- create_flow_map(
    zones,
    top_flows,
    min_flow = 1,  # Low threshold since we already filtered top flows
    map_style = "carto"
  )
  cat("✓ Top flows map created\n")
}

# Flow Map 3: All flows with higher threshold
flow_map_all <- create_flow_map(
  zones,
  daily_flows,
  min_flow = 50,
  map_style = "osm"
)
cat("✓ All flows map created\n\n")

# 5. Additional analysis for better understanding
cat("Flow analysis summary:\n")

# Top origin zones (most outgoing trips)
top_origins <- daily_flows %>%
  group_by(id_origin) %>%
  summarise(total_outflow = sum(n_trips), .groups = "drop") %>%
  arrange(desc(total_outflow)) %>%
  head(10)

cat("Top origin zones:\n")
print(top_origins)

# Top destination zones (most incoming trips)
top_destinations <- daily_flows %>%
  group_by(id_destination) %>%
  summarise(total_inflow = sum(n_trips), .groups = "drop") %>%
  arrange(desc(total_inflow)) %>%
  head(10)

cat("\nTop destination zones:\n")
print(top_destinations)

cat("\n=== Flow Maps Ready! ===\n")
cat("Available maps:\n")
if(exists("flow_map_connections")) cat("• flow_map_connections - Inter-zone connections\n")
if(exists("flow_map_top")) cat("• flow_map_top         - Top flows only\n")
cat("• flow_map_all         - All flows (filtered)\n")

cat("\nTips for better flow maps:\n")
cat("• Use inter-zone flows to see connections between areas\n")
cat("• Aggregate by day/hour to reduce data size\n")
cat("• Apply minimum flow thresholds to show significant movements\n")
cat("• Try different map styles: 'osm', 'carto', 'stamen'\n")
