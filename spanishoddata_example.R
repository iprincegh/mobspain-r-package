#!/usr/bin/env Rscript
# ==========================================
# Advanced mobspain + spanishoddata Integration
# ==========================================

# This script demonstrates how to use spanishoddata functions directly
# alongside mobspain for advanced mobility analysis workflows

# Load required libraries
library(mobspain)
library(spanishoddata)
library(sf)
library(ggplot2)
library(dplyr)
library(scales)
library(igraph)
library(ggspatial)

# ==========================================
# SETUP AND DATA RETRIEVAL
# ==========================================

cat("Setting up data access...\n")

# Initialize data directory
init_data_dir("~/spanish_mobility_data", version = 2)

# Configure mobspain
configure_mobspain(parallel = TRUE, n_cores = 2)

# ==========================================
# DIRECT SPANISHODDATA ACCESS
# ==========================================

cat("\n=== Using spanishoddata functions directly ===\n")

# Get data using spanishoddata functions for fine-grained control
cat("Downloading mobility data for April 7, 2021...\n")
od_20210407 <- spod_get("od", zones = "distr", dates = "2021-04-07")

cat("Getting district zones (version 1)...\n")
districts_v1 <- spod_get_zones("dist", ver = 1)

# ==========================================
# DATA PREPROCESSING
# ==========================================

cat("\n=== Data preprocessing ===\n")

# Preprocess data with dplyr
cat("Creating total flow matrix...\n")
od_20210407_total <- od_20210407 |>
  group_by(origin = id_origin, dest = id_destination) |>
  summarise(count = sum(n_trips, na.rm = TRUE), .groups = "drop") |> 
  collect()

# Time-series data with hourly resolution
cat("Creating time-series data...\n")
od_20210407_time <- od_20210407 |>
  mutate(time = as.POSIXct(paste0(date, "T", hour, ":00:00"))) |>
  group_by(origin = id_origin, dest = id_destination, time) |>
  summarise(count = sum(n_trips, na.rm = TRUE), .groups = "drop") |> 
  collect()

# Calculate centroids for all districts
cat("Calculating district centroids...\n")
districts_v1_centroids <- districts_v1 |>
  st_transform(4326) |> 
  st_centroid() |>
  st_coordinates() |>
  as.data.frame() |>
  mutate(id = districts_v1$id) |>
  rename(lon = X, lat = Y)

# ==========================================
# MADRID FUNCTIONAL URBAN AREA ANALYSIS
# ==========================================

cat("\n=== Madrid FUA Analysis ===\n")

# Filter Madrid districts
cat("Identifying Madrid districts...\n")
zones_madrid <- districts_v1 |>
  filter(grepl("Madrid", name, ignore.case = TRUE))

cat("Found", nrow(zones_madrid), "Madrid districts\n")

# Create functional urban area buffer around Madrid (10km)
cat("Creating Madrid Functional Urban Area (10km buffer)...\n")
zones_madrid_fua <- districts_v1[
  st_buffer(zones_madrid, dist = 10000),
]

cat("Madrid FUA includes", nrow(zones_madrid_fua), "districts\n")

# Centroids for Madrid FUA
zones_madrid_fua_coords <- zones_madrid_fua |>
  st_transform(crs = 4326) |>
  st_centroid() |>
  st_coordinates() |>
  as.data.frame() |>
  mutate(id = zones_madrid_fua$id) |>
  rename(lon = X, lat = Y)

# Filter flows for Madrid FUA
cat("Filtering flows for Madrid FUA...\n")
od_20210407_total_madrid <- od_20210407_total |>
  filter(origin %in% zones_madrid_fua$id & dest %in% zones_madrid_fua$id)

# Filter time-series flows for Madrid FUA
od_20210407_time_madrid <- od_20210407_time |>
  filter(origin %in% zones_madrid_fua$id & dest %in% zones_madrid_fua$id) |>
  filter(count > 50)  # Filter small flows for better visualization

cat("Madrid FUA flows:", nrow(od_20210407_total_madrid), "OD pairs\n")

# ==========================================
# MOBILITY HEATMAP VISUALIZATION
# ==========================================

cat("\n=== Creating mobility heatmap ===\n")

# Calculate flow totals for Madrid
flow_totals <- bind_rows(
  od_20210407_total_madrid |> 
    group_by(id = origin) |> 
    summarise(out_flows = sum(count, na.rm = TRUE)),
  od_20210407_total_madrid |> 
    group_by(id = dest) |> 
    summarise(in_flows = sum(count, na.rm = TRUE))
) |>
  group_by(id) |>
  summarise(
    out_flows = sum(out_flows, na.rm = TRUE),
    in_flows = sum(in_flows, na.rm = TRUE),
    total_flows = out_flows + in_flows,
    .groups = "drop"
  )

# Join with spatial data
madrid_activity <- zones_madrid_fua |>
  left_join(flow_totals, by = "id") |>
  st_as_sf()

# Create mobility heatmap
mobility_heatmap <- ggplot(madrid_activity) +
  geom_sf(aes(fill = total_flows), color = "white", linewidth = 0.3) +
  geom_sf(data = zones_madrid, fill = NA, color = "cyan", linewidth = 0.8) +
  scale_fill_viridis_c(
    option = "inferno", 
    name = "Total Trips", 
    trans = "log10", 
    breaks = c(100, 500, 2500, 10000, 50000),
    labels = label_comma(),
    na.value = "grey90"
  ) +
  labs(
    title = "Mobility Intensity in Madrid Functional Urban Area",
    subtitle = "Total trips (incoming + outgoing) on April 7, 2021",
    caption = "Data: Spanish Ministry of Transport | Cyan outline: Madrid city districts"
  ) +
  theme_void() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 16, hjust = 0.5),
    plot.subtitle = element_text(color = "grey30", size = 12, hjust = 0.5),
    plot.caption = element_text(color = "grey50", size = 9),
    panel.background = element_rect(fill = "white", color = NA)
  ) +
  annotation_scale(location = "br", width_hint = 0.25) +
  annotation_north_arrow(location = "tr", style = north_arrow_minimal())

print(mobility_heatmap)

# Save the plot
ggsave("madrid_mobility_heatmap.png", mobility_heatmap, width = 12, height = 8, dpi = 300)
cat("Saved mobility heatmap as 'madrid_mobility_heatmap.png'\n")

# ==========================================
# TEMPORAL ANALYSIS
# ==========================================

cat("\n=== Temporal analysis ===\n")

# Hourly mobility patterns for Madrid FUA
hourly_patterns <- od_20210407_time_madrid |>
  mutate(hour = as.numeric(format(time, "%H"))) |>
  group_by(hour) |>
  summarise(
    total_trips = sum(count, na.rm = TRUE),
    unique_flows = n(),
    avg_flow_size = mean(count, na.rm = TRUE),
    .groups = "drop"
  )

# Create hourly pattern plot
hourly_plot <- ggplot(hourly_patterns, aes(x = hour, y = total_trips)) +
  geom_line(color = "steelblue", size = 1.2) +
  geom_point(color = "darkblue", size = 2) +
  scale_x_continuous(breaks = seq(0, 23, 2), labels = paste0(seq(0, 23, 2), ":00")) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "Hourly Mobility Patterns in Madrid FUA",
    subtitle = "April 7, 2021 (Wednesday)",
    x = "Hour of Day",
    y = "Total Trips",
    caption = "Data: Spanish Ministry of Transport"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "grey30", size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank()
  )

print(hourly_plot)

# Save temporal plot
ggsave("madrid_hourly_patterns.png", hourly_plot, width = 10, height = 6, dpi = 300)
cat("Saved hourly patterns plot as 'madrid_hourly_patterns.png'\n")

# Identify peak hours
peak_hours <- hourly_patterns |>
  arrange(desc(total_trips)) |>
  head(3)

cat("Peak mobility hours:\n")
print(peak_hours)

# ==========================================
# NETWORK ANALYSIS
# ==========================================

cat("\n=== Network analysis ===\n")

# Create network metrics for Madrid FUA
cat("Building mobility network...\n")

# Prepare edge list for network analysis
edge_list <- od_20210407_total_madrid |>
  filter(count > 100) |>  # Focus on significant flows
  select(from = origin, to = dest, weight = count)

cat("Network edges (>100 trips):", nrow(edge_list), "\n")

# Create igraph object
mobility_network <- graph_from_data_frame(edge_list, directed = TRUE)

# Calculate network metrics
cat("Calculating network centrality measures...\n")
network_metrics <- data.frame(
  node = V(mobility_network)$name,
  degree = degree(mobility_network),
  in_degree = degree(mobility_network, mode = "in"),
  out_degree = degree(mobility_network, mode = "out"),
  betweenness = betweenness(mobility_network),
  closeness = closeness(mobility_network),
  page_rank = page_rank(mobility_network)$vector
) |>
  arrange(desc(page_rank))

# Join with spatial data for visualization
network_zones <- zones_madrid_fua |>
  left_join(network_metrics, by = c("id" = "node"))

# Create network centrality map
centrality_map <- ggplot(network_zones) +
  geom_sf(aes(fill = page_rank), color = "white", linewidth = 0.2) +
  geom_sf(data = zones_madrid, fill = NA, color = "red", linewidth = 0.8) +
  scale_fill_viridis_c(
    name = "PageRank\nCentrality",
    option = "plasma",
    na.value = "grey90"
  ) +
  labs(
    title = "Mobility Network Centrality in Madrid FUA",
    subtitle = "PageRank centrality based on mobility flows",
    caption = "Higher values indicate more central zones in mobility network"
  ) +
  theme_void() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(color = "grey30", size = 11, hjust = 0.5)
  )

print(centrality_map)

# Save centrality map
ggsave("madrid_network_centrality.png", centrality_map, width = 10, height = 8, dpi = 300)
cat("Saved network centrality map as 'madrid_network_centrality.png'\n")

# ==========================================
# SUMMARY STATISTICS
# ==========================================

cat("\n=== Summary statistics ===\n")

# Madrid FUA mobility statistics
madrid_stats <- madrid_activity |>
  st_drop_geometry() |>
  summarise(
    zones = n(),
    total_trips = sum(total_flows, na.rm = TRUE),
    avg_trips_per_zone = mean(total_flows, na.rm = TRUE),
    median_trips = median(total_flows, na.rm = TRUE),
    max_trips = max(total_flows, na.rm = TRUE),
    .groups = "drop"
  )

cat("Madrid FUA Mobility Statistics:\n")
print(madrid_stats)

# Network statistics
network_stats <- data.frame(
  nodes = vcount(mobility_network),
  edges = ecount(mobility_network),
  density = edge_density(mobility_network),
  avg_degree = mean(degree(mobility_network)),
  max_pagerank = max(network_metrics$page_rank)
)

cat("\nNetwork Statistics:\n")
print(network_stats)

# Top central zones
cat("\nTop 10 most central zones by PageRank:\n")
print(head(network_metrics[, c("node", "page_rank", "degree")], 10))

cat("\n=== Advanced analysis completed successfully! ===\n")
cat("Files created:\n")
cat("- madrid_mobility_heatmap.png\n")
cat("- madrid_hourly_patterns.png\n")
cat("- madrid_network_centrality.png\n")

cat("\nThis demonstrates the full power of combining mobspain convenience\n")
cat("functions with direct spanishoddata access for advanced analysis!\n")
