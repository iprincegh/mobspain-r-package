% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/district.R
\name{analyze_district_mobility}
\alias{analyze_district_mobility}
\title{Analyze and visualize mobility patterns for a specific district}
\usage{
analyze_district_mobility(
  district_id,
  dates,
  zones = NULL,
  mobility_data = NULL,
  time_range = NULL,
  plot_type = "all",
  top_n = 10
)
}
\arguments{
\item{district_id}{Character or numeric ID of the district to analyze}

\item{dates}{Date range for analysis (character vector)}

\item{zones}{Spatial zones data (sf object). If NULL, will load automatically}

\item{mobility_data}{Mobility data. If NULL, will load automatically}

\item{time_range}{Hour range to analyze (e.g., c(7, 9) for morning rush)}

\item{plot_type}{Type of visualization: "all", "heatmap", "flows", "timeseries"}

\item{top_n}{Number of top flows to show (default: 10)}
}
\value{
List containing plots and summary statistics
}
\description{
Analyze and visualize mobility patterns for a specific district
}
\examples{
\dontrun{
# Analyze district mobility patterns
result <- analyze_district_mobility(
  district_id = "28079",
  dates = c("2023-01-01", "2023-01-07"),
  time_range = c(7, 9),
  plot_type = "all"
)

# View the plots
result$heatmap
result$flow_plot
result$timeseries_plot
}
}
