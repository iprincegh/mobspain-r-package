% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/flows.R
\name{get_flow_map_recommendations}
\alias{get_flow_map_recommendations}
\title{Get flow map configuration recommendations}
\usage{
get_flow_map_recommendations(mobility_data)
}
\arguments{
\item{mobility_data}{Mobility data to analyze}
}
\value{
List with recommended configuration settings
}
\description{
Get flow map configuration recommendations
}
\examples{
\dontrun{
# Get recommendations for flow map configuration
recommendations <- get_flow_map_recommendations(mobility_data)
print(recommendations)
}
}
