% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mobility.R
\name{calculate_distance_decay}
\alias{calculate_distance_decay}
\title{Calculate distance-decay parameters}
\usage{
calculate_distance_decay(od_data, zones, model = "power")
}
\arguments{
\item{od_data}{Mobility matrix}

\item{zones}{Spatial zones with geometry}

\item{model}{Model type: "power" or "exponential"}
}
\value{
List with model parameters and fit statistics
}
\description{
Calculate distance-decay parameters
}
\examples{
\dontrun{
# Load data
zones <- get_spatial_zones("dist")
mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))

# Calculate distance decay with power model
decay_power <- calculate_distance_decay(mobility_data, zones, model = "power")
print(decay_power$parameters)

# Calculate distance decay with exponential model
decay_exp <- calculate_distance_decay(mobility_data, zones, model = "exponential")
print(decay_exp$parameters)

# Plot the results
plot_distance_decay(decay_power)

# Compare model quality
cat("Power model R²:", decay_power$parameters$r_squared, "\n")
cat("Exponential model R²:", decay_exp$parameters$r_squared, "\n")
}
}
