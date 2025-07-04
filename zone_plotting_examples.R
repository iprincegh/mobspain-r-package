#!/usr/bin/env Rscript
# ==========================================
# Zone Plotting Examples for mobspain Package
# ==========================================

# Load required libraries
library(mobspain)
library(sf)
library(ggplot2)
library(leaflet)

# Initialize data directory
init_data_dir("~/spanish_mobility_data", version = 2)

# Configure package
configure_mobspain(parallel = TRUE, n_cores = 2)

# Get spatial zones (districts)
cat("Loading Spanish districts...\n")
districts <- get_spatial_zones(level = "dist", version = 2)
cat("Loaded", nrow(districts), "districts\n")

# ======================
# BASIC SF PLOTTING
# ======================

cat("\n=== Basic sf plotting examples ===\n")

# 1. Simple boundary plot
cat("Creating basic boundary plot...\n")
plot(st_geometry(districts), main = "Spanish Districts", 
     col = "lightblue", border = "darkblue")

# 2. Plot with area data
cat("Creating area visualization...\n")
plot(districts["area_km2"], main = "District Areas (km²)")

# 3. Plot with population density (if available)
if("population" %in% names(districts) && "area_km2" %in% names(districts)) {
  cat("Creating population density plot...\n")
  districts$pop_density <- districts$population / districts$area_km2
  plot(districts["pop_density"], main = "Population Density (per km²)")
}

# ======================
# GGPLOT2 VISUALIZATION
# ======================

cat("\n=== ggplot2 visualization examples ===\n")

# 1. Advanced area visualization
cat("Creating ggplot2 area visualization...\n")
zone_plot <- ggplot(districts) +
  geom_sf(aes(fill = area_km2), color = "white", size = 0.1) +
  scale_fill_viridis_c(name = "Area\n(km²)", trans = "log10") +
  labs(title = "Spanish Districts by Area", 
       subtitle = "Administrative boundaries for mobility analysis") +
  theme_void() +
  theme(legend.position = "bottom")

print(zone_plot)

# Save the plot
ggsave("spanish_districts_area.png", zone_plot, width = 12, height = 8, dpi = 300)
cat("Saved plot as 'spanish_districts_area.png'\n")

# 2. Focus on specific regions (Madrid area)
cat("Creating Madrid region plot...\n")
madrid_zones <- districts[grepl("Madrid", districts$name, ignore.case = TRUE), ]
if(nrow(madrid_zones) > 0) {
  madrid_plot <- ggplot(madrid_zones) +
    geom_sf(aes(fill = area_km2), color = "white") +
    scale_fill_viridis_c(name = "Area (km²)") +
    labs(title = "Madrid Districts") +
    theme_void()
  
  print(madrid_plot)
  ggsave("madrid_districts.png", madrid_plot, width = 8, height = 6, dpi = 300)
  cat("Saved Madrid plot as 'madrid_districts.png'\n")
}

# ======================
# INTERACTIVE LEAFLET MAP
# ======================

cat("\n=== Interactive leaflet map ===\n")

# Create interactive map with first 100 zones for performance
cat("Creating interactive leaflet map...\n")
sample_zones <- districts[1:100, ]

interactive_map <- leaflet(sample_zones) %>%
  addTiles() %>%
  addPolygons(
    fillColor = ~colorQuantile("YlOrRd", area_km2)(area_km2),
    weight = 1,
    opacity = 1,
    color = "white",
    dashArray = "3",
    fillOpacity = 0.7,
    popup = ~paste("Zone:", name, "<br>Area:", round(area_km2, 1), "km²")
  ) %>%
  addLegend(
    position = "bottomright",
    pal = colorQuantile("YlOrRd", sample_zones$area_km2),
    values = ~area_km2,
    title = "Area (km²)",
    opacity = 1
  )

print(interactive_map)

# Save interactive map
library(htmlwidgets)
saveWidget(interactive_map, "spanish_districts_interactive.html")
cat("Saved interactive map as 'spanish_districts_interactive.html'\n")

# ======================
# SUMMARY STATISTICS
# ======================

cat("\n=== Zone statistics ===\n")
cat("Total districts:", nrow(districts), "\n")
cat("Total area:", round(sum(districts$area_km2, na.rm = TRUE)), "km²\n")
cat("Average area:", round(mean(districts$area_km2, na.rm = TRUE), 1), "km²\n")
cat("Median area:", round(median(districts$area_km2, na.rm = TRUE), 1), "km²\n")
cat("Largest district:", districts$name[which.max(districts$area_km2)], 
    "(" , round(max(districts$area_km2, na.rm = TRUE), 1), "km²)\n")
cat("Smallest district:", districts$name[which.min(districts$area_km2)], 
    "(" , round(min(districts$area_km2, na.rm = TRUE), 1), "km²)\n")

if("population" %in% names(districts)) {
  cat("Total population:", format(sum(districts$population, na.rm = TRUE), big.mark = ","), "\n")
  cat("Average population:", round(mean(districts$population, na.rm = TRUE)), "\n")
}

cat("\n=== Zone plotting examples completed successfully! ===\n")
cat("Files created:\n")
cat("- spanish_districts_area.png\n")
cat("- madrid_districts.png (if Madrid zones found)\n")
cat("- spanish_districts_interactive.html\n")
