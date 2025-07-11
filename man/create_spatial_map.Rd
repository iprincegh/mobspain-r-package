% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/viz.R
\name{create_spatial_map}
\alias{create_spatial_map}
\title{Spatial Visualization Functions for Analysis}
\usage{
create_spatial_map(
  analysis_result,
  spatial_zones,
  map_type = c("auto", "choropleth", "flow", "points"),
  color_palette = "viridis",
  title = NULL
)
}
\arguments{
\item{analysis_result}{Result from any mobspain analysis function}

\item{spatial_zones}{Spatial zones sf object with geometries}

\item{map_type}{Type of map to create ("choropleth", "flow", "points", "auto")}

\item{color_palette}{Color palette for the map}

\item{title}{Map title}
}
\value{
ggplot2 map object
}
\description{
This file contains spatial visualization functions optimized for spatial analysis
and spatial data science education, using sf package for spatial operations.
Create spatial map of mobility analysis results
}
\details{
A comprehensive function that creates spatial maps for any mobility analysis
result, automatically detecting the type of analysis and creating appropriate
spatial visualizations using sf geometries.
}
\examples{
\dontrun{
# Create spatial map for containment analysis
containment <- calculate_containment_spatial(mobility_data)
map <- create_spatial_map(containment, zones, map_type = "choropleth")

# Create spatial map for anomaly detection
anomalies <- detect_simple_anomalies(mobility_data)
map <- create_spatial_map(anomalies, zones, map_type = "auto")
}
}
