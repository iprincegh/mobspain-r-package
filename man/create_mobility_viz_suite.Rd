% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/visualization.R
\name{create_mobility_viz_suite}
\alias{create_mobility_viz_suite}
\title{Create comprehensive mobility visualization suite}
\usage{
create_mobility_viz_suite(
  zones,
  mobility_data,
  viz_type = "both",
  output_format = "html",
  min_flow = 100,
  color_palette = "viridis"
)
}
\arguments{
\item{zones}{Spatial zones data (sf object)}

\item{mobility_data}{Mobility OD data}

\item{viz_type}{Type of visualization: "interactive", "static", "both"}

\item{output_format}{Format: "html", "png", "pdf", "all"}

\item{min_flow}{Minimum flow threshold}

\item{color_palette}{Color palette for visualizations}
}
\value{
List of visualizations
}
\description{
Create comprehensive mobility visualization suite
}
\examples{
\dontrun{
zones <- get_spatial_zones("dist")
mobility <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))

# Create comprehensive visualization suite
viz_suite <- create_mobility_viz_suite(
  zones = zones,
  mobility_data = mobility,
  viz_type = "both",
  output_format = "all"
)

# Access different visualizations
viz_suite$flow_map_interactive
viz_suite$flow_map_static
viz_suite$heatmap
viz_suite$summary_stats
}
}
