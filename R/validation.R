#' Enhanced validation utilities
#' @name validation
#' @keywords internal
NULL

#' Validate date inputs
#' @param dates Date vector to validate
#' @return Validated date vector
#' @keywords internal
validate_dates <- function(dates) {
  if(is.null(dates) || length(dates) == 0) {
    stop("Dates cannot be NULL or empty", call. = FALSE)
  }
  
  if(length(dates) == 1) {
    dates <- rep(dates, 2)
  } else if(length(dates) > 2) {
    warning("Only first two dates will be used")
    dates <- dates[1:2]
  }
  
  # Try to convert to Date
  tryCatch({
    date_objects <- as.Date(dates)
    if(any(is.na(date_objects))) {
      stop("Invalid date format. Use 'YYYY-MM-DD' format", call. = FALSE)
    }
    if(date_objects[2] < date_objects[1]) {
      stop("End date must be after start date", call. = FALSE)
    }
    
    # MITMA data availability check
    mitma_start <- as.Date("2020-02-14")
    if(any(date_objects < mitma_start)) {
      warning("MITMA data is only available from 2020-02-14 onwards. Earlier dates may return no data.", 
              call. = FALSE)
    }
    
    # Future date check
    if(any(date_objects > Sys.Date())) {
      warning("Future dates requested. Data may not be available.", call. = FALSE)
    }
    
    return(as.character(date_objects))
  }, error = function(e) {
    stop("Date parsing failed: ", e$message, call. = FALSE)
  })
}

#' Validate spatial level
#' @param level Spatial level to validate
#' @return Standardized level name
#' @keywords internal
validate_level <- function(level) {
  valid_levels <- c("dist", "districts", "muni", "municipalities", "lua", "large_urban_areas")
  if(!level %in% valid_levels) {
    stop("Level must be one of: ", paste(valid_levels, collapse = ", "), call. = FALSE)
  }
  
  # Standardize level names
  level_map <- c(
    "districts" = "dist",
    "municipalities" = "muni", 
    "large_urban_areas" = "lua"
  )
  
  return(ifelse(level %in% names(level_map), level_map[level], level))
}

#' Validate time window
#' @param time_window Time window to validate
#' @return Validated time window
#' @keywords internal
validate_time_window <- function(time_window) {
  if(is.null(time_window)) return(NULL)
  
  if(length(time_window) != 2) {
    stop("time_window must be a vector of length 2", call. = FALSE)
  }
  
  if(!is.numeric(time_window) || any(time_window < 0) || any(time_window > 23)) {
    stop("time_window must contain hours between 0 and 23", call. = FALSE)
  }
  
  if(time_window[2] < time_window[1]) {
    stop("End hour must be after start hour", call. = FALSE)
  }
  
  return(as.integer(time_window))
}

#' Validate MITMA data quality
#' @param od_data Origin-destination mobility data
#' @return List with quality indicators and warnings
#' @export
#' @examples
#' \dontrun{
#' # Load mobility data
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' 
#' # Validate data quality
#' quality_report <- validate_mitma_data(mobility_data)
#' print(quality_report)
#' 
#' # Check for issues
#' if (quality_report$has_issues) {
#'   cat("Data quality issues found:\n")
#'   print(quality_report$issues)
#' } else {
#'   cat("Data quality is good\n")
#' }
#' 
#' # View quality metrics
#' cat("Missing values:", quality_report$missing_values, "\n")
#' cat("Zero flows:", quality_report$zero_flows, "\n")
#' cat("Date range:", quality_report$date_range, "\n")
#' }
validate_mitma_data <- function(od_data) {
  quality_report <- list()
  
  # Check required columns
  required_cols <- c("id_origin", "id_destination", "n_trips", "date")
  missing_cols <- setdiff(required_cols, names(od_data))
  if(length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  
  # Check for negative trip counts
  negative_trips <- sum(od_data$n_trips < 0, na.rm = TRUE)
  quality_report$negative_trips <- negative_trips
  if(negative_trips > 0) {
    warning("Found ", negative_trips, " negative trip counts. This may indicate data quality issues.", call. = FALSE)
  }
  
  # Check for missing data patterns
  total_na <- sum(is.na(od_data$n_trips))
  quality_report$missing_trips <- total_na
  quality_report$missing_percentage <- (total_na / nrow(od_data)) * 100
  
  # Check date continuity
  dates <- unique(od_data$date)
  date_gaps <- length(seq(min(dates), max(dates), by = "day")) - length(dates)
  quality_report$date_gaps <- date_gaps
  
  # Check for extremely high values (potential outliers)
  trip_threshold <- quantile(od_data$n_trips, 0.99, na.rm = TRUE) * 10
  extreme_values <- sum(od_data$n_trips > trip_threshold, na.rm = TRUE)
  quality_report$extreme_values <- extreme_values
  
  # Weekend vs weekday data availability
  od_data$is_weekend <- lubridate::wday(od_data$date) %in% c(1, 7)
  weekend_coverage <- mean(od_data$is_weekend, na.rm = TRUE)
  quality_report$weekend_coverage <- weekend_coverage
  
  if(weekend_coverage < 0.1 || weekend_coverage > 0.5) {
    warning("Unusual weekend/weekday data distribution. Expected ~28% weekend data.", call. = FALSE)
  }
  
  return(quality_report)
}

#' Check for Spanish holidays that may affect mobility patterns
#' @param dates Vector of dates to check
#' @return Data frame with holiday information
#' @export
#' @examples
#' \dontrun{
#' # Check holidays for specific dates
#' dates <- c("2023-01-01", "2023-12-25", "2023-08-15", "2023-05-01")
#' holiday_info <- check_spanish_holidays(dates)
#' print(holiday_info)
#' 
#' # Check holidays for a date range
#' date_range <- seq(as.Date("2023-01-01"), as.Date("2023-12-31"), by = "day")
#' all_holidays <- check_spanish_holidays(date_range)
#' holidays_only <- all_holidays[all_holidays$is_likely_holiday, ]
#' print(holidays_only)
#' 
#' # Use in mobility analysis to flag potentially unusual dates
#' mobility_data <- get_mobility_matrix(dates = c("2023-01-01", "2023-01-07"))
#' unique_dates <- unique(mobility_data$date)
#' holiday_check <- check_spanish_holidays(unique_dates)
#' cat("Holidays in the data:", 
#'     sum(holiday_check$is_likely_holiday), "\n")
#' }
check_spanish_holidays <- function(dates) {
  # Common Spanish national holidays (approximate - varies by year)
  holiday_patterns <- data.frame(
    date_pattern = c("01-01", "01-06", "05-01", "08-15", "10-12", "11-01", "12-06", "12-08", "12-25"),
    holiday_name = c("New Year", "Epiphany", "Labour Day", "Assumption", "National Day", 
                     "All Saints", "Constitution", "Immaculate Conception", "Christmas"),
    stringsAsFactors = FALSE
  )
  
  date_strings <- format(as.Date(dates), "%m-%d")
  
  holiday_check <- data.frame(
    date = as.Date(dates),
    is_likely_holiday = date_strings %in% holiday_patterns$date_pattern,
    stringsAsFactors = FALSE
  )
  
  # Add holiday names
  holiday_check$holiday_name <- NA
  if(nrow(holiday_patterns) > 0) {
    for(i in seq_len(nrow(holiday_patterns))) {
      matches <- date_strings == holiday_patterns$date_pattern[i]
      holiday_check$holiday_name[matches] <- holiday_patterns$holiday_name[i]
    }
  }
  
  # Check for Easter (varies by year - simplified check)
  # Note: This is a simplified implementation
  easter_months <- format(as.Date(dates), "%m") %in% c("03", "04")
  holiday_check$is_easter_period <- easter_months
  
  return(holiday_check)
}
