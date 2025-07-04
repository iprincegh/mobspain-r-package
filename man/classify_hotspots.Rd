% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geospatial.R
\name{classify_hotspots}
\alias{classify_hotspots}
\title{Classify hotspots based on local indicators}
\usage{
classify_hotspots(standardized_values, spatial_lag, lisa_values)
}
\arguments{
\item{standardized_values}{Standardized values}

\item{spatial_lag}{Spatial lag values}

\item{lisa_values}{Local Moran's I values}
}
\value{
Character vector of hotspot classifications
}
\description{
Classify hotspots based on local indicators
}
\keyword{internal}
