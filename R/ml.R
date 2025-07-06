#' Machine Learning and Predictive Analytics for Spanish Mobility Data
#'
#' This file contains machine learning functions for mobility prediction,
#' pattern recognition, and advanced analytics.

#' Predict mobility patterns using machine learning
#'
#' @param mobility_data Historical mobility data for training
#' @param prediction_dates Dates to predict mobility for
#' @param features Features to use for prediction
#' @param model_type Type of model to use
#' @param spatial_zones Spatial zones data for spatial features
#' @return Mobility predictions with confidence intervals
#' @export
#' @examples
#' \dontrun{
#' # Predict mobility patterns
#' predictions <- predict_mobility_patterns(
#'   mobility_data = historical_mobility,
#'   prediction_dates = c("2024-01-15", "2024-01-16"),
#'   model_type = "random_forest",
#'   features = c("hour", "weekday", "distance", "activity_origin")
#' )
#' }
predict_mobility_patterns <- function(mobility_data, prediction_dates,
                                    features = c("hour", "weekday", "distance"),
                                    model_type = c("random_forest", "linear_regression", "xgboost"),
                                    spatial_zones = NULL) {
  
  model_type <- match.arg(model_type)
  
  # Validate inputs
  if(!"date" %in% names(mobility_data)) {
    stop("mobility_data must contain 'date' column")
  }
  
  if(!"n_trips" %in% names(mobility_data)) {
    stop("mobility_data must contain 'n_trips' column for prediction target")
  }
  
  # Prepare training data
  training_data <- prepare_ml_training_data(mobility_data, features, spatial_zones)
  
  # Split into features and target
  feature_cols <- intersect(features, names(training_data))
  if(length(feature_cols) == 0) {
    stop("No valid features found in data. Available columns: ", paste(names(training_data), collapse = ", "))
  }
  
  X_train <- training_data[, feature_cols, drop = FALSE]
  y_train <- training_data$n_trips
  
  # Train model based on type
  model <- switch(model_type,
    "random_forest" = train_random_forest_model(X_train, y_train),
    "linear_regression" = train_linear_regression_model(X_train, y_train),
    "xgboost" = train_xgboost_model(X_train, y_train)
  )
  
  # Prepare prediction data
  prediction_data <- prepare_ml_prediction_data(mobility_data, prediction_dates, features, spatial_zones)
  X_predict <- prediction_data[, feature_cols, drop = FALSE]
  
  # Make predictions
  predictions <- make_model_predictions(model, X_predict, model_type)
  
  # Combine with prediction metadata
  result <- cbind(prediction_data[, c("date", "hour", "id_origin", "id_destination")], predictions)
  
  # Add model information
  attr(result, "model_type") <- model_type
  attr(result, "features_used") <- feature_cols
  attr(result, "training_period") <- range(mobility_data$date)
  
  class(result) <- c("mobility_predictions", "data.frame")
  
  return(result)
}

#' Prepare training data for machine learning
#' @param mobility_data Raw mobility data
#' @param features Features to extract
#' @param spatial_zones Spatial zones for spatial features
#' @return Prepared training data
#' @keywords internal
prepare_ml_training_data <- function(mobility_data, features, spatial_zones) {
  
  # Start with core data
  training_data <- mobility_data
  
  # Add temporal features
  if("hour" %in% features && !"hour" %in% names(training_data)) {
    training_data$hour <- lubridate::hour(training_data$date)
  }
  
  if("weekday" %in% features) {
    training_data$weekday <- lubridate::wday(training_data$date, label = TRUE)
    training_data$is_weekend <- lubridate::wday(training_data$date) %in% c(1, 7)
  }
  
  if("month" %in% features) {
    training_data$month <- lubridate::month(training_data$date)
  }
  
  if("quarter" %in% features) {
    training_data$quarter <- lubridate::quarter(training_data$date)
  }
  
  # Add lag features
  if("lag_1" %in% features) {
    training_data <- training_data %>%
      dplyr::arrange(.data$id_origin, .data$id_destination, .data$date, .data$hour) %>%
      dplyr::group_by(.data$id_origin, .data$id_destination) %>%
      dplyr::mutate(
        lag_1 = dplyr::lag(.data$n_trips, 1),
        lag_7 = dplyr::lag(.data$n_trips, 7),  # Weekly lag
        lag_24 = dplyr::lag(.data$n_trips, 24) # Daily lag (if hourly data)
      ) %>%
      dplyr::ungroup()
  }
  
  # Add spatial features if zones provided
  if(!is.null(spatial_zones)) {
    training_data <- add_spatial_features(training_data, spatial_zones)
  }
  
  # Add rolling statistics
  if("rolling_mean" %in% features) {
    training_data <- training_data %>%
      dplyr::arrange(.data$id_origin, .data$id_destination, .data$date, .data$hour) %>%
      dplyr::group_by(.data$id_origin, .data$id_destination) %>%
      dplyr::mutate(
        rolling_mean_7 = zoo::rollmean(.data$n_trips, k = 7, fill = NA, align = "right"),
        rolling_std_7 = zoo::rollapply(.data$n_trips, width = 7, FUN = sd, fill = NA, align = "right")
      ) %>%
      dplyr::ungroup()
  }
  
  # Convert factors to numeric for ML models
  factor_cols <- names(training_data)[sapply(training_data, is.factor)]
  for(col in factor_cols) {
    if(col %in% features) {
      training_data[[paste0(col, "_numeric")]] <- as.numeric(training_data[[col]])
    }
  }
  
  # Remove rows with missing target values
  training_data <- training_data[!is.na(training_data$n_trips), ]
  
  return(training_data)
}

#' Add spatial features to mobility data
#' @param mobility_data Mobility data
#' @param spatial_zones Spatial zones
#' @return Data with spatial features added
#' @keywords internal
add_spatial_features <- function(mobility_data, spatial_zones) {
  
  # Calculate zone centroids for distance calculations
  if(inherits(spatial_zones, "sf")) {
    zones_centroids <- spatial_zones %>%
      sf::st_centroid() %>%
      sf::st_coordinates() %>%
      as.data.frame() %>%
      dplyr::mutate(id = spatial_zones$id) %>%
      dplyr::rename(lon = .data$X, lat = .data$Y)
    
    # Add origin coordinates
    mobility_data <- mobility_data %>%
      dplyr::left_join(zones_centroids, by = c("id_origin" = "id"), suffix = c("", "_origin")) %>%
      dplyr::rename(origin_lon = .data$lon, origin_lat = .data$lat)
    
    # Add destination coordinates
    mobility_data <- mobility_data %>%
      dplyr::left_join(zones_centroids, by = c("id_destination" = "id"), suffix = c("", "_dest")) %>%
      dplyr::rename(dest_lon = .data$lon, dest_lat = .data$lat)
    
    # Calculate euclidean distance
    mobility_data$euclidean_distance <- sqrt(
      (mobility_data$origin_lon - mobility_data$dest_lon)^2 + 
      (mobility_data$origin_lat - mobility_data$dest_lat)^2
    )
  }
  
  # Add population if available
  if("population" %in% names(spatial_zones)) {
    pop_data <- spatial_zones %>%
      sf::st_drop_geometry() %>%
      dplyr::select(.data$id, .data$population)
    
    # Add origin population
    mobility_data <- mobility_data %>%
      dplyr::left_join(pop_data, by = c("id_origin" = "id"), suffix = c("", "_origin")) %>%
      dplyr::rename(origin_population = .data$population)
    
    # Add destination population
    mobility_data <- mobility_data %>%
      dplyr::left_join(pop_data, by = c("id_destination" = "id"), suffix = c("", "_dest")) %>%
      dplyr::rename(dest_population = .data$population)
  }
  
  return(mobility_data)
}

#' Prepare prediction data
#' @param mobility_data Historical mobility data
#' @param prediction_dates Dates to predict
#' @param features Features to use
#' @param spatial_zones Spatial zones
#' @return Prepared prediction data
#' @keywords internal
prepare_ml_prediction_data <- function(mobility_data, prediction_dates, features, spatial_zones) {
  
  # Create prediction grid
  unique_origins <- unique(mobility_data$id_origin)
  unique_destinations <- unique(mobility_data$id_destination)
  
  prediction_grid <- expand.grid(
    date = as.Date(prediction_dates),
    hour = 0:23,
    id_origin = unique_origins,
    id_destination = unique_destinations,
    stringsAsFactors = FALSE
  )
  
  # Add features using the same function as training data
  prediction_data <- prepare_ml_training_data(prediction_grid, features, spatial_zones)
  
  # Remove the target variable (n_trips) as we're predicting it
  if("n_trips" %in% names(prediction_data)) {
    prediction_data$n_trips <- NULL
  }
  
  return(prediction_data)
}

#' Train random forest model
#' @param X_train Training features
#' @param y_train Training target
#' @return Trained random forest model
#' @keywords internal
train_random_forest_model <- function(X_train, y_train) {
  
  if(!requireNamespace("randomForest", quietly = TRUE)) {
    stop("randomForest package required. Install with: install.packages('randomForest')")
  }
  
  # Handle missing values
  X_train <- X_train[complete.cases(X_train), ]
  y_train <- y_train[complete.cases(X_train)]
  
  # Train model
  model <- randomForest::randomForest(
    x = X_train,
    y = y_train,
    ntree = 100,
    importance = TRUE
  )
  
  return(model)
}

#' Train linear regression model
#' @param X_train Training features
#' @param y_train Training target
#' @return Trained linear regression model
#' @keywords internal
train_linear_regression_model <- function(X_train, y_train) {
  
  # Combine features and target
  training_df <- data.frame(X_train, y = y_train)
  
  # Handle missing values
  training_df <- training_df[complete.cases(training_df), ]
  
  # Create formula
  feature_names <- names(X_train)
  formula_str <- paste("y ~", paste(feature_names, collapse = " + "))
  formula_obj <- as.formula(formula_str)
  
  # Train model
  model <- lm(formula_obj, data = training_df)
  
  return(model)
}

#' Train XGBoost model
#' @param X_train Training features
#' @param y_train Training target
#' @return Trained XGBoost model
#' @keywords internal
train_xgboost_model <- function(X_train, y_train) {
  
  if(!requireNamespace("xgboost", quietly = TRUE)) {
    stop("xgboost package required. Install with: install.packages('xgboost')")
  }
  
  # Handle missing values
  complete_indices <- complete.cases(X_train)
  X_train <- X_train[complete_indices, ]
  y_train <- y_train[complete_indices]
  
  # Convert to matrix
  X_matrix <- as.matrix(X_train)
  
  # Train model
  model <- xgboost::xgboost(
    data = X_matrix,
    label = y_train,
    nrounds = 100,
    objective = "reg:squarederror",
    verbose = 0
  )
  
  return(model)
}

#' Make predictions with trained model
#' @param model Trained model object
#' @param X_predict Features for prediction
#' @param model_type Type of model
#' @return Predictions with confidence intervals
#' @keywords internal
make_model_predictions <- function(model, X_predict, model_type) {
  
  # Handle missing values
  X_predict_clean <- X_predict[complete.cases(X_predict), ]
  
  predictions_result <- switch(model_type,
    "random_forest" = {
      pred <- predict(model, X_predict_clean)
      data.frame(
        predicted_trips = pred,
        lower_ci = pred * 0.8,  # Simplified CI
        upper_ci = pred * 1.2
      )
    },
    "linear_regression" = {
      pred <- predict(model, X_predict_clean, interval = "prediction")
      data.frame(
        predicted_trips = pred[, "fit"],
        lower_ci = pred[, "lwr"],
        upper_ci = pred[, "upr"]
      )
    },
    "xgboost" = {
      X_matrix <- as.matrix(X_predict_clean)
      pred <- predict(model, X_matrix)
      data.frame(
        predicted_trips = pred,
        lower_ci = pred * 0.8,  # Simplified CI
        upper_ci = pred * 1.2
      )
    }
  )
  
  # Handle rows that were removed due to missing values
  if(nrow(X_predict) > nrow(X_predict_clean)) {
    full_result <- data.frame(
      predicted_trips = NA,
      lower_ci = NA,
      upper_ci = NA
    )[rep(1, nrow(X_predict)), ]
    
    complete_indices <- complete.cases(X_predict)
    full_result[complete_indices, ] <- predictions_result
    predictions_result <- full_result
  }
  
  return(predictions_result)
}

#' Detect anomalous mobility patterns using machine learning
#'
#' @param mobility_data Mobility data to analyze
#' @param method Anomaly detection method
#' @param contamination Expected proportion of anomalies
#' @return Data with anomaly flags and scores
#' @export
#' @examples
#' \dontrun{
#' # Detect anomalies
#' anomalies <- detect_mobility_anomalies_ml(
#'   mobility_data = mobility,
#'   method = "isolation_forest",
#'   contamination = 0.1
#' )
#' }
detect_mobility_anomalies_ml <- function(mobility_data, 
                                        method = c("isolation_forest", "one_class_svm", "statistical"),
                                        contamination = 0.1) {
  
  method <- match.arg(method)
  
  # Prepare features for anomaly detection
  features <- prepare_anomaly_features(mobility_data)
  
  # Detect anomalies based on method
  anomaly_results <- switch(method,
    "isolation_forest" = detect_isolation_forest_anomalies(features, contamination),
    "one_class_svm" = detect_svm_anomalies(features, contamination),
    "statistical" = detect_statistical_anomalies(features, contamination)
  )
  
  # Combine with original data
  result <- cbind(mobility_data, anomaly_results)
  
  class(result) <- c("mobility_anomalies", "data.frame")
  return(result)
}

#' Prepare features for anomaly detection
#' @param mobility_data Mobility data
#' @return Feature matrix for anomaly detection
#' @keywords internal
prepare_anomaly_features <- function(mobility_data) {
  
  features <- mobility_data %>%
    dplyr::mutate(
      hour = lubridate::hour(.data$date),
      weekday = as.numeric(lubridate::wday(.data$date)),
      is_weekend = lubridate::wday(.data$date) %in% c(1, 7)
    ) %>%
    dplyr::select(.data$n_trips, .data$hour, .data$weekday, .data$is_weekend) %>%
    dplyr::filter(complete.cases(.))
  
  return(features)
}

#' Detect anomalies using Isolation Forest
#' @param features Feature matrix
#' @param contamination Contamination rate
#' @return Anomaly detection results
#' @keywords internal
detect_isolation_forest_anomalies <- function(features, contamination) {
  
  if(!requireNamespace("isotree", quietly = TRUE)) {
    warning("isotree package not available. Using statistical method instead.")
    return(detect_statistical_anomalies(features, contamination))
  }
  
  # Train isolation forest
  iso_forest <- isotree::isolation.forest(features, ntree = 100)
  
  # Get anomaly scores
  scores <- predict(iso_forest, features)
  
  # Determine threshold based on contamination rate
  threshold <- quantile(scores, 1 - contamination)
  
  return(data.frame(
    anomaly_score = scores,
    is_anomaly = scores > threshold,
    method = "isolation_forest"
  ))
}

#' Detect anomalies using One-Class SVM
#' @param features Feature matrix
#' @param contamination Contamination rate
#' @return Anomaly detection results
#' @keywords internal
detect_svm_anomalies <- function(features, contamination) {
  
  if(!requireNamespace("e1071", quietly = TRUE)) {
    warning("e1071 package not available. Using statistical method instead.")
    return(detect_statistical_anomalies(features, contamination))
  }
  
  # Train one-class SVM
  svm_model <- e1071::svm(features, type = "one-classification", nu = contamination)
  
  # Get predictions
  predictions <- predict(svm_model, features)
  
  return(data.frame(
    anomaly_score = as.numeric(!predictions),
    is_anomaly = !predictions,
    method = "one_class_svm"
  ))
}

#' Detect anomalies using statistical methods
#' @param features Feature matrix
#' @param contamination Contamination rate
#' @return Anomaly detection results
#' @keywords internal
detect_statistical_anomalies <- function(features, contamination) {
  
  # Use z-score based anomaly detection
  z_scores <- abs(scale(features$n_trips))
  threshold <- quantile(z_scores, 1 - contamination, na.rm = TRUE)
  
  return(data.frame(
    anomaly_score = as.vector(z_scores),
    is_anomaly = z_scores > threshold,
    method = "statistical"
  ))
}

#' Print method for mobility predictions
#' @param x Mobility predictions object
#' @param ... Additional arguments
#' @export
print.mobility_predictions <- function(x, ...) {
  cat("Mobility Pattern Predictions\n")
  cat("===========================\n\n")
  
  cat("Model Information:\n")
  cat("- Model type:", attr(x, "model_type"), "\n")
  cat("- Features used:", paste(attr(x, "features_used"), collapse = ", "), "\n")
  cat("- Training period:", paste(attr(x, "training_period"), collapse = " to "), "\n\n")
  
  cat("Predictions Summary:\n")
  cat("- Total predictions:", nrow(x), "\n")
  cat("- Unique dates:", length(unique(x$date)), "\n")
  cat("- Predicted trips range:", round(range(x$predicted_trips, na.rm = TRUE), 2), "\n\n")
  
  # Show first few predictions
  cat("First 10 predictions:\n")
  print(head(x[, c("date", "hour", "id_origin", "id_destination", "predicted_trips")], 10))
  
  invisible(x)
}

#' Print method for mobility anomalies
#' @param x Mobility anomalies object
#' @param ... Additional arguments
#' @export
print.mobility_anomalies <- function(x, ...) {
  cat("Mobility Anomaly Detection Results\n")
  cat("=================================\n\n")
  
  anomaly_count <- sum(x$is_anomaly, na.rm = TRUE)
  anomaly_rate <- round(mean(x$is_anomaly, na.rm = TRUE) * 100, 2)
  
  cat("Detection Summary:\n")
  cat("- Method used:", x$method[1], "\n")
  cat("- Total records:", nrow(x), "\n")
  cat("- Anomalies detected:", anomaly_count, "\n")
  cat("- Anomaly rate:", anomaly_rate, "%\n\n")
  
  if(anomaly_count > 0) {
    cat("Top 5 anomalies (highest scores):\n")
    top_anomalies <- x[x$is_anomaly, ] %>%
      dplyr::arrange(dplyr::desc(.data$anomaly_score)) %>%
      head(5) %>%
      dplyr::select(.data$date, .data$hour, .data$id_origin, .data$id_destination, 
                   .data$n_trips, .data$anomaly_score)
    print(top_anomalies)
  }
  
  invisible(x)
}
