% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ml.R
\name{detect_mobility_anomalies_ml}
\alias{detect_mobility_anomalies_ml}
\title{Detect anomalous mobility patterns using machine learning}
\usage{
detect_mobility_anomalies_ml(
  mobility_data,
  method = c("isolation_forest", "one_class_svm", "statistical"),
  contamination = 0.1
)
}
\arguments{
\item{mobility_data}{Mobility data to analyze}

\item{method}{Anomaly detection method}

\item{contamination}{Expected proportion of anomalies}
}
\value{
Data with anomaly flags and scores
}
\description{
Detect anomalous mobility patterns using machine learning
}
\examples{
\dontrun{
# Detect anomalies
anomalies <- detect_mobility_anomalies_ml(
  mobility_data = mobility,
  method = "isolation_forest",
  contamination = 0.1
)
}
}
