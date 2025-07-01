library(sf)
library(dplyr)
library(usethis)

# Create sample data with area
sample_zones <- data.frame(
  id = c("001", "002", "003"),
  name = c("Zone 1", "Zone 2", "Zone 3"),
  population = c(10000, 20000, 15000),
  geometry = st_sfc(
    st_point(c(0,0)),
    st_point(c(1,1)),
    st_point(c(2,2))
  )
) %>%
  st_as_sf() %>%
  st_set_crs(4326) %>%
  mutate(area_km2 = as.numeric(st_area(geometry)) / 1e6)

# Save to package data
usethis::use_data(sample_zones, overwrite = TRUE)
