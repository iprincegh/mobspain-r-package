% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/viz.R
\name{create_dashboard}
\alias{create_dashboard}
\title{Create comprehensive spatial analysis dashboard}
\usage{
create_dashboard(
  mobility_data,
  spatial_zones,
  analyses = c("containment", "anomalies", "predictions")
)
}
\arguments{
\item{mobility_data}{Mobility data}

\item{spatial_zones}{Spatial zones sf object}

\item{analyses}{List of analysis types to include}
}
\value{
List of ggplot2 maps
}
\description{
Creates a multi-panel spatial dashboard showing different aspects of mobility
analysis results on maps using sf geometries.
}
\examples{
\dontrun{
# Create comprehensive spatial dashboard
dashboard <- create_spatial_dashboard(
  mobility_data = mobility,
  spatial_zones = zones,
  analyses = c("containment", "anomalies", "predictions")
)
}
}
