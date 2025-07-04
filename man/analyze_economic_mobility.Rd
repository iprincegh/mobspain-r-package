% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/economic.R
\name{analyze_economic_mobility}
\alias{analyze_economic_mobility}
\title{Economic and socioeconomic mobility analysis functions}
\usage{
analyze_economic_mobility(
  mobility_data,
  spatial_zones = NULL,
  cost_per_km = 0.35,
  time_value = 15,
  avg_speed = 40,
  min_trips = 10
)
}
\arguments{
\item{mobility_data}{Data frame with mobility flows and distance information}

\item{spatial_zones}{Spatial zones data frame with economic indicators (optional)}

\item{cost_per_km}{Cost per kilometer for travel (default: 0.35 EUR/km)}

\item{time_value}{Value of time per hour (default: 15 EUR/hour)}

\item{avg_speed}{Average travel speed in km/h (default: 40 km/h)}

\item{min_trips}{Minimum trips threshold (default: 10)}
}
\value{
List with economic mobility analysis results
}
\description{
Advanced analytical functions for economic impact and socioeconomic patterns
using rich MITMA data with demographic and activity information.
Analyze economic mobility flows and trip costs
}
\details{
Estimates economic impact of mobility flows including trip costs,
time values, and economic accessibility
}
\examples{
\dontrun{
# Basic economic analysis
economic_analysis <- analyze_economic_mobility(mobility_data)
print(economic_analysis$economic_summary)

# Custom cost parameters
high_cost_analysis <- analyze_economic_mobility(
  mobility_data,
  cost_per_km = 0.50,
  time_value = 20
)

# Include spatial economic indicators
spatial_economic <- analyze_economic_mobility(
  mobility_data,
  spatial_zones = zones
)
}
}
