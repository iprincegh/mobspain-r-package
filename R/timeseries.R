#' Advanced Time Series Analysis for Spanish Mobility Data
#'
#' This module provides sophisticated time series analysis capabilities
#' for Spanish mobility data with seasonal decomposition, trend analysis,
#' and anomaly detection.

#' Analyze mobility time series with seasonal decomposition
#'
#' @param mobility_data Data frame with mobility data including date column
#' @param value_column Column name for values to analyze (default: "n_trips")
#' @param temporal_resolution Time resolution ("daily", "weekly", "monthly")
#' @param seasonal_method Method for seasonal decomposition ("stl", "classical", "x11")
#' @param detect_anomalies Whether to detect statistical anomalies
#' @param trend_analysis Whether to perform trend analysis
#' @return List with time series analysis results
#' @export
#' @examples
#' \dontrun{
#' # Analyze daily mobility patterns
#' mobility_data <- get_mobility_matrix(dates = c("2022-01-01", "2022-03-31"))
#' ts_analysis <- analyze_mobility_time_series(
#'   mobility_data,
#'   temporal_resolution = "daily",
#'   detect_anomalies = TRUE,
#'   trend_analysis = TRUE
#' )
#' 
#' # Plot results
#' plot(ts_analysis)
#' }
analyze_mobility_time_series <- function(mobility_data,
                                       value_column = "n_trips",
                                       temporal_resolution = "daily",
                                       seasonal_method = "stl",
                                       detect_anomalies = TRUE,
                                       trend_analysis = TRUE) {
  
  # Validate inputs
  if(!value_column %in% names(mobility_data)) {
    stop(sprintf("Column '%s' not found in mobility_data", value_column))
  }
  
  if(!"date" %in% names(mobility_data)) {
    stop("Date column not found in mobility_data")
  }
  
  # Aggregate data by temporal resolution
  ts_data <- aggregate_temporal_mobility(mobility_data, value_column, temporal_resolution)
  
  # Create time series object
  ts_object <- create_mobility_time_series(ts_data, temporal_resolution)
  
  # Perform seasonal decomposition
  decomposition <- perform_seasonal_decomposition(ts_object, seasonal_method)
  
  # Trend analysis
  trend_results <- NULL
  if(trend_analysis) {
    trend_results <- analyze_mobility_trends(ts_object, decomposition)
  }
  
  # Anomaly detection
  anomaly_results <- NULL
  if(detect_anomalies) {
    anomaly_results <- detect_time_series_anomalies(ts_object, decomposition)
  }
  
  # Create comprehensive results
  results <- list(
    data = ts_data,
    time_series = ts_object,
    decomposition = decomposition,
    trend_analysis = trend_results,
    anomaly_detection = anomaly_results,
    metadata = list(
      temporal_resolution = temporal_resolution,
      seasonal_method = seasonal_method,
      value_column = value_column,
      date_range = range(ts_data$date),
      n_observations = nrow(ts_data)
    )
  )
  
  class(results) <- "mobspain_time_series"
  return(results)
}

#' Aggregate mobility data by temporal resolution
#'
#' @param mobility_data Data frame with mobility data
#' @param value_column Column to aggregate
#' @param temporal_resolution Time resolution
#' @return Aggregated data frame
#' @keywords internal
aggregate_temporal_mobility <- function(mobility_data, value_column, temporal_resolution) {
  
  if(requireNamespace("dplyr", quietly = TRUE)) {
    
    # Create temporal grouping variable
    mobility_data <- mobility_data %>%
      dplyr::mutate(
        date = as.Date(date),
        temporal_group = case_when(
          temporal_resolution == "daily" ~ date,
          temporal_resolution == "weekly" ~ floor_date(date, "week"),
          temporal_resolution == "monthly" ~ floor_date(date, "month"),
          TRUE ~ date
        )
      )
    
    # Aggregate by temporal group
    ts_data <- mobility_data %>%
      dplyr::group_by(temporal_group) %>%
      dplyr::summarise(
        value = sum(!!sym(value_column), na.rm = TRUE),
        .groups = "drop"
      ) %>%
      dplyr::rename(date = temporal_group) %>%
      dplyr::arrange(date)
    
  } else {
    # Base R implementation
    mobility_data$date <- as.Date(mobility_data$date)
    
    if(temporal_resolution == "weekly") {
      mobility_data$temporal_group <- as.Date(cut(mobility_data$date, "week"))
    } else if(temporal_resolution == "monthly") {
      mobility_data$temporal_group <- as.Date(cut(mobility_data$date, "month"))
    } else {
      mobility_data$temporal_group <- mobility_data$date
    }
    
    ts_data <- aggregate(
      mobility_data[[value_column]],
      by = list(date = mobility_data$temporal_group),
      FUN = sum, na.rm = TRUE
    )
    names(ts_data)[2] <- "value"
    ts_data <- ts_data[order(ts_data$date), ]
  }
  
  return(ts_data)
}

#' Create time series object from mobility data
#'
#' @param ts_data Temporal data frame
#' @param temporal_resolution Time resolution
#' @return Time series object
#' @keywords internal
create_mobility_time_series <- function(ts_data, temporal_resolution) {
  
  # Determine frequency
  frequency <- switch(temporal_resolution,
    "daily" = 365.25,
    "weekly" = 52,
    "monthly" = 12,
    1
  )
  
  # Create time series
  ts_object <- ts(
    ts_data$value,
    start = c(as.numeric(format(min(ts_data$date), "%Y")), 1),
    frequency = frequency
  )
  
  # Add date information as attribute
  attr(ts_object, "dates") <- ts_data$date
  
  return(ts_object)
}

#' Perform seasonal decomposition
#'
#' @param ts_object Time series object
#' @param method Decomposition method
#' @return Decomposition results
#' @keywords internal
perform_seasonal_decomposition <- function(ts_object, method) {
  
  if(length(ts_object) < 2 * frequency(ts_object)) {
    warning("Time series too short for seasonal decomposition")
    return(NULL)
  }
  
  tryCatch({
    decomp <- switch(method,
      "stl" = {
        if(requireNamespace("stats", quietly = TRUE)) {
          stats::stl(ts_object, s.window = "periodic")
        } else {
          stop("stats package required for STL decomposition")
        }
      },
      "classical" = {
        stats::decompose(ts_object)
      },
      "x11" = {
        if(requireNamespace("seasonal", quietly = TRUE)) {
          seasonal::seas(ts_object)
        } else {
          warning("seasonal package not available, using classical decomposition")
          stats::decompose(ts_object)
        }
      },
      stats::decompose(ts_object)
    )
    
    return(decomp)
  }, error = function(e) {
    warning(sprintf("Seasonal decomposition failed: %s", e$message))
    return(NULL)
  })
}

#' Analyze mobility trends
#'
#' @param ts_object Time series object
#' @param decomposition Decomposition results
#' @return Trend analysis results
#' @keywords internal
analyze_mobility_trends <- function(ts_object, decomposition) {
  
  trend_results <- list()
  
  # Extract trend component
  if(!is.null(decomposition)) {
    if(inherits(decomposition, "stl")) {
      trend <- decomposition$time.series[, "trend"]
    } else if(inherits(decomposition, "decomposed.ts")) {
      trend <- decomposition$trend
    } else {
      trend <- ts_object
    }
  } else {
    trend <- ts_object
  }
  
  # Remove NAs
  trend <- trend[!is.na(trend)]
  
  if(length(trend) < 3) {
    warning("Insufficient data for trend analysis")
    return(NULL)
  }
  
  # Linear trend analysis
  time_index <- seq_along(trend)
  trend_model <- lm(trend ~ time_index)
  
  trend_results$linear_trend <- list(
    slope = coef(trend_model)[2],
    intercept = coef(trend_model)[1],
    r_squared = summary(trend_model)$r.squared,
    p_value = summary(trend_model)$coefficients[2, 4],
    is_significant = summary(trend_model)$coefficients[2, 4] < 0.05
  )
  
  # Trend direction
  trend_results$trend_direction <- if(trend_results$linear_trend$slope > 0) {
    "increasing"
  } else if(trend_results$linear_trend$slope < 0) {
    "decreasing"
  } else {
    "stable"
  }
  
  # Change point detection (simple method)
  trend_results$change_points <- detect_change_points(trend)
  
  # Seasonal strength (if decomposition available)
  if(!is.null(decomposition)) {
    trend_results$seasonal_strength <- calculate_seasonal_strength(decomposition)
  }
  
  return(trend_results)
}

#' Detect time series anomalies
#'
#' @param ts_object Time series object
#' @param decomposition Decomposition results
#' @return Anomaly detection results
#' @keywords internal
detect_time_series_anomalies <- function(ts_object, decomposition) {
  
  anomaly_results <- list()
  
  # Calculate residuals
  if(!is.null(decomposition)) {
    if(inherits(decomposition, "stl")) {
      residuals <- decomposition$time.series[, "remainder"]
    } else if(inherits(decomposition, "decomposed.ts")) {
      residuals <- decomposition$random
    } else {
      residuals <- ts_object - fitted(decomposition)
    }
  } else {
    # Use detrended values
    time_index <- seq_along(ts_object)
    linear_fit <- lm(as.numeric(ts_object) ~ time_index)
    residuals <- residuals(linear_fit)
  }
  
  # Remove NAs
  residuals <- residuals[!is.na(residuals)]
  
  if(length(residuals) < 3) {
    warning("Insufficient data for anomaly detection")
    return(NULL)
  }
  
  # Statistical anomaly detection
  anomaly_results$statistical <- detect_statistical_anomalies_iqr(residuals)
  
  # Seasonal anomaly detection
  if(!is.null(decomposition)) {
    # Simple seasonal anomaly detection based on seasonal component
    if(inherits(decomposition, "stl")) {
      seasonal <- decomposition$time.series[, "seasonal"]
    } else if(inherits(decomposition, "decomposed.ts")) {
      seasonal <- decomposition$seasonal
    } else {
      seasonal <- NULL
    }
    
    if(!is.null(seasonal)) {
      seasonal_anomalies <- detect_statistical_anomalies_iqr(seasonal)
      anomaly_results$seasonal <- seasonal_anomalies
    }
  }
  
  # Combine results
  dates <- attr(ts_object, "dates")
  if(!is.null(dates)) {
    anomaly_results$anomaly_dates <- dates[anomaly_results$statistical$indices]
  }
  
  return(anomaly_results)
}

#' Detect statistical anomalies using IQR method
#'
#' @param residuals Residual values
#' @return List with anomaly indices and statistics
#' @keywords internal
detect_statistical_anomalies_iqr <- function(residuals) {
  
  # IQR method
  q1 <- quantile(residuals, 0.25, na.rm = TRUE)
  q3 <- quantile(residuals, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  
  lower_bound <- q1 - 1.5 * iqr
  upper_bound <- q3 + 1.5 * iqr
  
  anomaly_indices <- which(residuals < lower_bound | residuals > upper_bound)
  
  # Z-score method
  z_scores <- abs(scale(residuals))
  z_anomalies <- which(z_scores > 3)
  
  return(list(
    iqr_method = list(
      indices = anomaly_indices,
      lower_bound = lower_bound,
      upper_bound = upper_bound,
      n_anomalies = length(anomaly_indices)
    ),
    z_score_method = list(
      indices = z_anomalies,
      threshold = 3,
      n_anomalies = length(z_anomalies)
    ),
    indices = unique(c(anomaly_indices, z_anomalies))
  ))
}

#' Detect change points in time series
#'
#' @param trend Trend values
#' @return List with change point information
#' @keywords internal
detect_change_points <- function(trend) {
  
  if(length(trend) < 10) {
    return(list(n_change_points = 0, change_points = integer(0)))
  }
  
  # Simple change point detection using rolling statistics
  window_size <- max(3, floor(length(trend) / 10))
  
  # Calculate rolling means
  rolling_means <- rep(NA, length(trend))
  for(i in (window_size + 1):(length(trend) - window_size)) {
    rolling_means[i] <- mean(trend[(i - window_size):(i + window_size)])
  }
  
  # Find significant changes
  mean_diff <- diff(rolling_means, na.rm = TRUE)
  threshold <- 2 * sd(mean_diff, na.rm = TRUE)
  
  change_points <- which(abs(mean_diff) > threshold)
  
  return(list(
    n_change_points = length(change_points),
    change_points = change_points,
    threshold = threshold
  ))
}

#' Calculate seasonal strength
#'
#' @param decomposition Decomposition object
#' @return Seasonal strength value
#' @keywords internal
calculate_seasonal_strength <- function(decomposition) {
  
  if(inherits(decomposition, "stl")) {
    seasonal <- decomposition$time.series[, "seasonal"]
    remainder <- decomposition$time.series[, "remainder"]
  } else if(inherits(decomposition, "decomposed.ts")) {
    seasonal <- decomposition$seasonal
    remainder <- decomposition$random
  } else {
    return(NA)
  }
  
  # Calculate seasonal strength
  var_seasonal <- var(seasonal, na.rm = TRUE)
  var_remainder <- var(remainder, na.rm = TRUE)
  
  seasonal_strength <- var_seasonal / (var_seasonal + var_remainder)
  
  return(seasonal_strength)
}

#' Plot method for mobspain time series analysis
#'
#' @param x mobspain_time_series object
#' @param ... Additional plotting parameters
#' @return ggplot object
#' @export
#' @method plot mobspain_time_series
plot.mobspain_time_series <- function(x, ...) {
  
  if(!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 package required for plotting")
  }
  
  # Create main time series plot
  p1 <- ggplot2::ggplot(x$data, ggplot2::aes(x = .data$date, y = .data$value)) +
    ggplot2::geom_line(color = "steelblue", size = 1) +
    ggplot2::labs(
      title = "Mobility Time Series",
      x = "Date",
      y = "Mobility Count"
    ) +
    ggplot2::theme_minimal()
  
  # Add anomalies if detected
  if(!is.null(x$anomaly_detection) && !is.null(x$anomaly_detection$anomaly_dates)) {
    anomaly_data <- data.frame(
      date = x$anomaly_detection$anomaly_dates,
      value = x$data$value[x$data$date %in% x$anomaly_detection$anomaly_dates]
    )
    
    p1 <- p1 + ggplot2::geom_point(
      data = anomaly_data,
      ggplot2::aes(x = .data$date, y = .data$value),
      color = "red", size = 3, alpha = 0.7
    )
  }
  
  # Add trend line if available
  if(!is.null(x$trend_analysis) && !is.null(x$trend_analysis$linear_trend)) {
    p1 <- p1 + ggplot2::geom_smooth(
      method = "lm",
      se = TRUE,
      color = "darkred",
      linetype = "dashed"
    )
  }
  
  return(p1)
}

#' Print method for mobspain time series analysis
#'
#' @param x mobspain_time_series object
#' @param ... Additional parameters
#' @export
#' @method print mobspain_time_series
print.mobspain_time_series <- function(x, ...) {
  
  cat("Spanish Mobility Time Series Analysis\n")
  cat("=====================================\n\n")
  
  # Basic information
  cat("Data Summary:\n")
  cat(sprintf("  Temporal Resolution: %s\n", x$metadata$temporal_resolution))
  cat(sprintf("  Date Range: %s to %s\n", x$metadata$date_range[1], x$metadata$date_range[2]))
  cat(sprintf("  Number of Observations: %d\n", x$metadata$n_observations))
  cat(sprintf("  Value Column: %s\n", x$metadata$value_column))
  
  # Trend analysis
  if(!is.null(x$trend_analysis)) {
    cat("\nTrend Analysis:\n")
    cat(sprintf("  Trend Direction: %s\n", x$trend_analysis$trend_direction))
    if(!is.null(x$trend_analysis$linear_trend)) {
      cat(sprintf("  Linear Trend Slope: %.6f\n", x$trend_analysis$linear_trend$slope))
      cat(sprintf("  R-squared: %.4f\n", x$trend_analysis$linear_trend$r_squared))
      cat(sprintf("  Significant: %s\n", x$trend_analysis$linear_trend$is_significant))
    }
    if(!is.null(x$trend_analysis$change_points)) {
      cat(sprintf("  Change Points: %d\n", x$trend_analysis$change_points$n_change_points))
    }
  }
  
  # Anomaly detection
  if(!is.null(x$anomaly_detection)) {
    cat("\nAnomaly Detection:\n")
    if(!is.null(x$anomaly_detection$statistical)) {
      cat(sprintf("  Statistical Anomalies: %d\n", length(x$anomaly_detection$indices)))
    }
  }
  
  # Seasonal analysis
  if(!is.null(x$decomposition)) {
    cat("\nSeasonal Analysis:\n")
    cat(sprintf("  Decomposition Method: %s\n", x$metadata$seasonal_method))
    if(!is.null(x$trend_analysis$seasonal_strength)) {
      cat(sprintf("  Seasonal Strength: %.4f\n", x$trend_analysis$seasonal_strength))
    }
  }
  
  cat("\nUse plot() to visualize the time series analysis.\n")
}
