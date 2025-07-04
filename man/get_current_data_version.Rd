% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\name{get_current_data_version}
\alias{get_current_data_version}
\title{Get current data version}
\usage{
get_current_data_version()
}
\value{
Current data version (1 or 2)
}
\description{
Get current data version
}
\examples{
\dontrun{
# Check current data version
current_version <- get_current_data_version()
cat("Current data version:", current_version, "\n")

# Set up data directory and check version
init_data_dir(version = 2)
version <- get_current_data_version()
cat("Using version:", version, "\n")

# Use in conditional logic
if (get_current_data_version() == 1) {
  cat("Using COVID-19 period data\n")
} else {
  cat("Using enhanced current data\n")
}
}
}
