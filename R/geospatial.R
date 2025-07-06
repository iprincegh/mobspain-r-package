#' Advanced Geospatial Analysis for Spanish Mobility Data
#'
#' This module provides sophisticated geospatial analysis capabilities
#' including spatial autocorrelation, hotspot detection, and accessibility analysis.

#' Analyze spatial patterns in mobility data
#'
#' @param mobility_data Data frame with mobility data
#' @param spatial_zones SF object with spatial zones
#' @param analysis_type Type of analysis ("autocorrelation", "hotspots", "accessibility")
#' @param value_column Column name for values to analyze
#' @param weight_matrix Spatial weight matrix (optional)
#' @param distance_threshold Distance threshold for spatial relationships
#' @return List with spatial analysis results
#' @export
#' @examples
#' \dontrun{
#' # Get mobility data and spatial zones
#' mobility_data <- get_mobility_matrix(dates = c("2022-01-01", "2022-01-07"))
#' districts <- get_spatial_zones("districts", version = 2)
#' 
#' # Analyze spatial autocorrelation
#' spatial_analysis <- analyze_spatial_patterns(
#'   mobility_data,
#'   districts,
#'   analysis_type = "autocorrelation"
#' )
#' 
#' # Detect hotspots
#' hotspot_analysis <- analyze_spatial_patterns(
#'   mobility_data,
#'   districts,
#'   analysis_type = "hotspots"
#' )
#' }
analyze_spatial_patterns <- function(mobility_data,
                                   spatial_zones,
                                   analysis_type = "autocorrelation",
                                   value_column = "n_trips",
                                   weight_matrix = NULL,
                                   distance_threshold = 50000) {
  
  # Validate inputs
  if(!inherits(spatial_zones, "sf")) {
    stop("spatial_zones must be an sf object")
  }
  
  if(!value_column %in% names(mobility_data)) {
    stop(sprintf("Column '%s' not found in mobility_data", value_column))
  }
  
  # Aggregate mobility data by spatial zone
  spatial_data <- aggregate_mobility_by_zone(mobility_data, spatial_zones, value_column)
  
  # Create or use provided weight matrix
  if(is.null(weight_matrix)) {
    weight_matrix <- create_spatial_weights(spatial_zones, distance_threshold)
  }
  
  # Perform spatial analysis
  results <- switch(analysis_type,
    "autocorrelation" = analyze_spatial_autocorrelation(spatial_data, weight_matrix),
    "hotspots" = detect_spatial_hotspots(spatial_data, weight_matrix),
    "accessibility" = analyze_spatial_accessibility(spatial_data, spatial_zones),
    stop("Invalid analysis_type. Must be 'autocorrelation', 'hotspots', or 'accessibility'")
  )
  
  # Add metadata
  results$metadata <- list(
    analysis_type = analysis_type,
    value_column = value_column,
    n_zones = nrow(spatial_data),
    date_range = if("date" %in% names(mobility_data)) range(mobility_data$date) else NULL,
    distance_threshold = distance_threshold
  )
  
  class(results) <- "mobspain_spatial_analysis"
  return(results)
}

#' Aggregate mobility data by spatial zone
#'
#' @param mobility_data Data frame with mobility data
#' @param spatial_zones SF object with spatial zones
#' @param value_column Column to aggregate
#' @return Data frame with aggregated values by zone
#' @keywords internal
aggregate_mobility_by_zone <- function(mobility_data, spatial_zones, value_column) {
  
  # Check if we have origin-destination data or node-level data
  if(all(c("id_origin", "id_destination") %in% names(mobility_data))) {
    # Origin-destination data - aggregate by origin
    if(requireNamespace("dplyr", quietly = TRUE)) {
      zone_data <- mobility_data %>%
        dplyr::group_by(id_origin) %>%
        dplyr::summarise(
          value = sum(!!sym(value_column), na.rm = TRUE),
          .groups = "drop"
        ) %>%
        dplyr::rename(id = id_origin)
    } else {
      # Base R aggregation
      zone_data <- aggregate(
        mobility_data[[value_column]],
        by = list(id = mobility_data$id_origin),
        FUN = sum, na.rm = TRUE
      )
      names(zone_data)[2] <- "value"
    }
  } else if("id" %in% names(mobility_data)) {
    # Node-level data
    if(requireNamespace("dplyr", quietly = TRUE)) {
      zone_data <- mobility_data %>%
        dplyr::group_by(id) %>%
        dplyr::summarise(
          value = sum(!!sym(value_column), na.rm = TRUE),
          .groups = "drop"
        )
    } else {
      # Base R aggregation
      zone_data <- aggregate(
        mobility_data[[value_column]],
        by = list(id = mobility_data$id),
        FUN = sum, na.rm = TRUE
      )
      names(zone_data)[2] <- "value"
    }
  } else {
    stop("Cannot identify spatial identifiers in mobility_data")
  }
  
  # Join with spatial zones
  spatial_data <- merge(spatial_zones, zone_data, by = "id", all.x = TRUE)
  spatial_data$value[is.na(spatial_data$value)] <- 0
  
  return(spatial_data)
}

#' Create spatial weight matrix
#'
#' @param spatial_zones SF object with spatial zones
#' @param distance_threshold Distance threshold for neighbors
#' @return Spatial weight matrix
#' @keywords internal
create_spatial_weights <- function(spatial_zones, distance_threshold) {
  
  if(!requireNamespace("sf", quietly = TRUE)) {
    stop("sf package required for spatial operations")
  }
  
  # Calculate centroids
  centroids <- sf::st_centroid(spatial_zones)
  
  # Calculate distances
  distances <- sf::st_distance(centroids)
  
  # Create weight matrix based on distance threshold
  weight_matrix <- matrix(0, nrow = nrow(spatial_zones), ncol = nrow(spatial_zones))
  
  # Set weights for neighbors within threshold
  for(i in seq_len(nrow(spatial_zones))) {
    for(j in seq_len(nrow(spatial_zones))) {
      if(i != j && distances[i, j] <= distance_threshold) {
        weight_matrix[i, j] <- 1 / as.numeric(distances[i, j])
      }
    }
  }
  
  # Row standardize
  row_sums <- rowSums(weight_matrix)
  weight_matrix[row_sums > 0, ] <- weight_matrix[row_sums > 0, ] / row_sums[row_sums > 0]
  
  return(weight_matrix)
}

#' Analyze spatial autocorrelation
#'
#' @param spatial_data SF object with aggregated mobility data
#' @param weight_matrix Spatial weight matrix
#' @return List with autocorrelation results
#' @keywords internal
analyze_spatial_autocorrelation <- function(spatial_data, weight_matrix) {
  
  values <- spatial_data$value
  n <- length(values)
  
  if(n != nrow(weight_matrix)) {
    stop("Dimension mismatch between spatial data and weight matrix")
  }
  
  # Calculate Moran's I
  moran_i <- calculate_morans_i(values, weight_matrix)
  
  # Calculate Geary's C
  geary_c <- calculate_gearys_c(values, weight_matrix)
  
  # Local indicators of spatial association (LISA)
  lisa <- calculate_lisa(values, weight_matrix)
  
  # Interpretation
  interpretation <- interpret_spatial_autocorrelation(moran_i, geary_c)
  
  results <- list(
    global_autocorrelation = list(
      morans_i = moran_i,
      gearys_c = geary_c,
      interpretation = interpretation
    ),
    local_autocorrelation = lisa,
    spatial_data = spatial_data
  )
  
  return(results)
}

#' Calculate Moran's I statistic
#'
#' @param values Vector of values
#' @param weight_matrix Spatial weight matrix
#' @return List with Moran's I statistics
#' @keywords internal
calculate_morans_i <- function(values, weight_matrix) {
  
  n <- length(values)
  mean_val <- mean(values, na.rm = TRUE)
  
  # Calculate numerator and denominator
  numerator <- 0
  denominator <- 0
  
  for(i in 1:n) {
    for(j in 1:n) {
      numerator <- numerator + weight_matrix[i, j] * (values[i] - mean_val) * (values[j] - mean_val)
    }
    denominator <- denominator + (values[i] - mean_val)^2
  }
  
  # Sum of weights
  w_sum <- sum(weight_matrix)
  
  # Calculate Moran's I
  morans_i <- (n / w_sum) * (numerator / denominator)
  
  # Calculate expected value and variance
  expected_i <- -1 / (n - 1)
  variance_i <- calculate_morans_i_variance(n, weight_matrix)
  
  # Z-score and p-value
  z_score <- (morans_i - expected_i) / sqrt(variance_i)
  p_value <- 2 * (1 - pnorm(abs(z_score)))
  
  return(list(
    statistic = morans_i,
    expected = expected_i,
    variance = variance_i,
    z_score = z_score,
    p_value = p_value,
    significant = p_value < 0.05
  ))
}

#' Calculate Geary's C statistic
#'
#' @param values Vector of values
#' @param weight_matrix Spatial weight matrix
#' @return List with Geary's C statistics
#' @keywords internal
calculate_gearys_c <- function(values, weight_matrix) {
  
  n <- length(values)
  mean_val <- mean(values, na.rm = TRUE)
  
  # Calculate numerator and denominator
  numerator <- 0
  denominator <- 0
  
  for(i in 1:n) {
    for(j in 1:n) {
      numerator <- numerator + weight_matrix[i, j] * (values[i] - values[j])^2
    }
    denominator <- denominator + (values[i] - mean_val)^2
  }
  
  # Sum of weights
  w_sum <- sum(weight_matrix)
  
  # Calculate Geary's C
  gearys_c <- ((n - 1) / (2 * w_sum)) * (numerator / denominator)
  
  # Expected value
  expected_c <- 1.0
  
  return(list(
    statistic = gearys_c,
    expected = expected_c,
    interpretation = if(gearys_c < 1) "positive autocorrelation" else if(gearys_c > 1) "negative autocorrelation" else "no autocorrelation"
  ))
}

#' Calculate Local Indicators of Spatial Association (LISA)
#'
#' @param values Vector of values
#' @param weight_matrix Spatial weight matrix
#' @return Vector of local Moran's I values
#' @keywords internal
calculate_lisa <- function(values, weight_matrix) {
  
  n <- length(values)
  mean_val <- mean(values, na.rm = TRUE)
  var_val <- var(values, na.rm = TRUE)
  
  lisa_values <- numeric(n)
  
  for(i in 1:n) {
    local_sum <- 0
    for(j in 1:n) {
      local_sum <- local_sum + weight_matrix[i, j] * (values[j] - mean_val)
    }
    lisa_values[i] <- ((values[i] - mean_val) / var_val) * local_sum
  }
  
  return(lisa_values)
}

#' Calculate variance for Moran's I
#'
#' @param n Number of observations
#' @param weight_matrix Spatial weight matrix
#' @return Variance value
#' @keywords internal
calculate_morans_i_variance <- function(n, weight_matrix) {
  
  w_sum <- sum(weight_matrix)
  s1 <- sum(weight_matrix^2)
  s2 <- sum(colSums(weight_matrix)^2)
  
  b2 <- n * sum((rowSums(weight_matrix))^2) / w_sum^2
  
  variance <- (n * ((n^2 - 3 * n + 3) * s1 - n * s2 + 3 * w_sum^2) - 
              b2 * ((n^2 - n) * s1 - 2 * n * s2 + 6 * w_sum^2)) / 
             ((n - 1) * (n - 2) * (n - 3) * w_sum^2)
  
  return(variance)
}

#' Detect spatial hotspots
#'
#' @param spatial_data SF object with aggregated mobility data
#' @param weight_matrix Spatial weight matrix
#' @return List with hotspot detection results
#' @keywords internal
detect_spatial_hotspots <- function(spatial_data, weight_matrix) {
  
  values <- spatial_data$value
  
  # Calculate local Moran's I
  lisa_values <- calculate_lisa(values, weight_matrix)
  
  # Standardize values
  standardized_values <- scale(values)[, 1]
  
  # Calculate local spatial lag
  spatial_lag <- numeric(length(values))
  for(i in seq_along(values)) {
    spatial_lag[i] <- sum(weight_matrix[i, ] * standardized_values)
  }
  
  # Classify hotspots
  hotspot_types <- classify_hotspots(standardized_values, spatial_lag, lisa_values)
  
  # Add to spatial data
  spatial_data$lisa <- lisa_values
  spatial_data$hotspot_type <- hotspot_types
  
  # Summary statistics
  hotspot_summary <- table(hotspot_types)
  
  results <- list(
    hotspot_data = spatial_data,
    hotspot_summary = hotspot_summary,
    lisa_values = lisa_values,
    classification = hotspot_types
  )
  
  return(results)
}

#' Classify hotspots based on local indicators
#'
#' @param standardized_values Standardized values
#' @param spatial_lag Spatial lag values
#' @param lisa_values Local Moran's I values
#' @return Character vector of hotspot classifications
#' @keywords internal
classify_hotspots <- function(standardized_values, spatial_lag, lisa_values) {
  
  # Threshold for significance (simplified)
  significance_threshold <- 1.96  # Roughly 95% confidence
  
  hotspot_types <- character(length(standardized_values))
  
  for(i in seq_along(standardized_values)) {
    if(abs(lisa_values[i]) > significance_threshold) {
      if(standardized_values[i] > 0 && spatial_lag[i] > 0) {
        hotspot_types[i] <- "High-High"
      } else if(standardized_values[i] < 0 && spatial_lag[i] < 0) {
        hotspot_types[i] <- "Low-Low"
      } else if(standardized_values[i] > 0 && spatial_lag[i] < 0) {
        hotspot_types[i] <- "High-Low"
      } else if(standardized_values[i] < 0 && spatial_lag[i] > 0) {
        hotspot_types[i] <- "Low-High"
      } else {
        hotspot_types[i] <- "Not Significant"
      }
    } else {
      hotspot_types[i] <- "Not Significant"
    }
  }
  
  return(hotspot_types)
}

#' Analyze spatial accessibility
#'
#' @param spatial_data SF object with aggregated mobility data
#' @param spatial_zones SF object with spatial zones
#' @return List with accessibility analysis results
#' @keywords internal
analyze_spatial_accessibility <- function(spatial_data, spatial_zones) {
  
  if(!requireNamespace("sf", quietly = TRUE)) {
    stop("sf package required for accessibility analysis")
  }
  
  # Calculate centroids
  centroids <- sf::st_centroid(spatial_zones)
  
  # Calculate distance matrix
  distances <- sf::st_distance(centroids)
  
  # Calculate accessibility measures
  accessibility_results <- list()
  
  # Gravity-based accessibility
  accessibility_results$gravity <- calculate_gravity_accessibility(
    spatial_data$value, 
    distances
  )
  
  # Cumulative accessibility (within 30km)
  accessibility_results$cumulative <- calculate_cumulative_accessibility(
    spatial_data$value, 
    distances, 
    threshold = 30000
  )
  
  # Add results to spatial data
  spatial_data$gravity_accessibility <- accessibility_results$gravity
  spatial_data$cumulative_accessibility <- accessibility_results$cumulative
  
  results <- list(
    accessibility_data = spatial_data,
    gravity_accessibility = accessibility_results$gravity,
    cumulative_accessibility = accessibility_results$cumulative,
    distance_matrix = distances
  )
  
  return(results)
}

#' Calculate gravity-based accessibility
#'
#' @param values Vector of values (opportunities)
#' @param distances Distance matrix
#' @param decay_parameter Distance decay parameter
#' @return Vector of accessibility values
#' @keywords internal
calculate_gravity_accessibility <- function(values, distances, decay_parameter = 1.5) {
  
  n <- length(values)
  accessibility <- numeric(n)
  
  for(i in 1:n) {
    accessibility[i] <- sum(values * exp(-decay_parameter * as.numeric(distances[i, ]) / 1000))
  }
  
  return(accessibility)
}

#' Calculate cumulative accessibility
#'
#' @param values Vector of values (opportunities)
#' @param distances Distance matrix
#' @param threshold Distance threshold
#' @return Vector of accessibility values
#' @keywords internal
calculate_cumulative_accessibility <- function(values, distances, threshold) {
  
  n <- length(values)
  accessibility <- numeric(n)
  
  for(i in 1:n) {
    within_threshold <- as.numeric(distances[i, ]) <= threshold
    accessibility[i] <- sum(values[within_threshold])
  }
  
  return(accessibility)
}

#' Interpret spatial autocorrelation results
#'
#' @param moran_i Moran's I results
#' @param geary_c Geary's C results
#' @return Character description of spatial pattern
#' @keywords internal
interpret_spatial_autocorrelation <- function(moran_i, geary_c) {
  
  if(moran_i$significant) {
    if(moran_i$statistic > moran_i$expected) {
      return("Significant positive spatial autocorrelation - similar values cluster together")
    } else {
      return("Significant negative spatial autocorrelation - dissimilar values are neighbors")
    }
  } else {
    return("No significant spatial autocorrelation - values are randomly distributed")
  }
}

#' Print method for spatial analysis results
#'
#' @param x mobspain_spatial_analysis object
#' @param ... Additional parameters
#' @export
#' @method print mobspain_spatial_analysis
print.mobspain_spatial_analysis <- function(x, ...) {
  
  cat("Spanish Mobility Spatial Analysis\n")
  cat("==================================\n\n")
  
  # Basic information
  cat("Analysis Summary:\n")
  cat(sprintf("  Analysis Type: %s\n", x$metadata$analysis_type))
  cat(sprintf("  Number of Zones: %d\n", x$metadata$n_zones))
  cat(sprintf("  Value Column: %s\n", x$metadata$value_column))
  
  if(!is.null(x$metadata$date_range)) {
    cat(sprintf("  Date Range: %s to %s\n", x$metadata$date_range[1], x$metadata$date_range[2]))
  }
  
  # Analysis-specific results
  if(x$metadata$analysis_type == "autocorrelation") {
    cat("\nSpatial Autocorrelation Results:\n")
    cat(sprintf("  Moran's I: %.4f\n", x$global_autocorrelation$morans_i$statistic))
    cat(sprintf("  Expected: %.4f\n", x$global_autocorrelation$morans_i$expected))
    cat(sprintf("  Z-score: %.4f\n", x$global_autocorrelation$morans_i$z_score))
    cat(sprintf("  P-value: %.4f\n", x$global_autocorrelation$morans_i$p_value))
    cat(sprintf("  Significant: %s\n", x$global_autocorrelation$morans_i$significant))
    cat(sprintf("  Interpretation: %s\n", x$global_autocorrelation$interpretation))
  } else if(x$metadata$analysis_type == "hotspots") {
    cat("\nHotspot Detection Results:\n")
    print(x$hotspot_summary)
  } else if(x$metadata$analysis_type == "accessibility") {
    cat("\nAccessibility Analysis Results:\n")
    cat(sprintf("  Mean Gravity Accessibility: %.2f\n", mean(x$gravity_accessibility, na.rm = TRUE)))
    cat(sprintf("  Mean Cumulative Accessibility: %.2f\n", mean(x$cumulative_accessibility, na.rm = TRUE)))
  }
  
  cat("\nUse the spatial data components for mapping and further analysis.\n")
}
