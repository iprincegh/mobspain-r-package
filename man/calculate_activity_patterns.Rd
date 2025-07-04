% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/activity.R
\name{calculate_activity_patterns}
\alias{calculate_activity_patterns}
\title{Calculate activity-based mobility patterns}
\usage{
calculate_activity_patterns(mobility_data, min_trips = 10, normalize = TRUE)
}
\arguments{
\item{mobility_data}{Data frame with mobility data including activity_origin and activity_destination}

\item{min_trips}{Minimum trips threshold for inclusion (default: 10)}

\item{normalize}{Whether to normalize by total trips (default: TRUE)}
}
\value{
Data frame with activity-based mobility metrics
}
\description{
Analyzes mobility flows by activity types (home, work, frequent_activity, other_activity)
}
\examples{
\dontrun{
# Analyze activity patterns
activity_patterns <- calculate_activity_patterns(mobility_data)
print(activity_patterns)

# Focus on work commuting patterns
work_patterns <- calculate_activity_patterns(
  mobility_data,
  activity_filter = c("home", "frequent_activity"),
  min_trips = 20
)
}
}
