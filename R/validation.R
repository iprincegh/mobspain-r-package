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
