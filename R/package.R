#' mobspain: Spatial Mobility Analysis for Spanish Transportation Data
#'
#' A comprehensive R package for spatial analysis of Spanish mobility patterns 
#' using MITMA (Ministry of Transportation) data.
#'
#' @description
#' This package provides easy access to Spanish mobility data from MITMA 
#' (Ministry of Transportation) with automatic spatial visualization using 
#' sf package geometries. Ideal for spatial data science applications 
#' with real-world mobility data.
#'
#' @section Key Features:
#' \itemize{
#'   \item Automatic spatial mapping of all analysis results using sf geometries
#'   \item Streamlined workflow with clear step-by-step messaging
#'   \item Memory-optimized processing with automatic data sampling
#'   \item Complete spatial analysis with choropleth maps, flow maps, and anomaly detection
#'   \item Real government data from Spanish Ministry of Transportation
#'   \item Efficient functions focusing on essential spatial analysis capabilities
#'   \item Advanced filtering capabilities to reduce data download size
#' }
#'
#' @section Main Functions and Parameters:
#' 
#' \subsection{Data Access Functions:}{
#' \describe{
#'   \item{\code{\link{get_zones}}}{Get administrative boundaries with optional filtering
#'     \itemize{
#'       \item \code{level = "dist"} - Spatial level: "dist" (districts), "prov" (provinces), or "muni" (municipalities)
#'       \item \code{year = 2023} - Year for boundaries
#'       \item \code{zones_filter = NULL} - Vector of specific zone IDs to filter
#'       \item \code{region_filter = NULL} - Region name or province code for filtering
#'     }
#'   }
#'   \item{\code{\link{get_mobility}}}{Get mobility data with filtering to reduce download size
#'     \itemize{
#'       \item \code{dates = "2023-01-01"} - Date or date range
#'       \item \code{level = "dist"} - Spatial level
#'       \item \code{max_rows = 10000} - Maximum rows for memory management
#'       \item \code{zones_filter = NULL} - Vector of specific zone IDs to filter
#'       \item \code{region_filter = NULL} - Region name or province code for filtering
#'     }
#'   }
#'   \item{\code{\link{get_region_mobility}}}{Quick regional analysis (both data and zones)
#'     \itemize{
#'       \item \code{region} - Region name or province code
#'       \item \code{dates = "2023-01-01"} - Date or date range  
#'       \item \code{level = "dist"} - Spatial level
#'       \item \code{max_rows = 10000} - Maximum rows for memory management
#'     }
#'   }
#' }
#' }
#' 
#' \subsection{Spatial Analysis Functions:}{
#' \describe{
#'   \item{\code{\link{calculate_containment}}}{Containment analysis with spatial mapping
#'     \itemize{
#'       \item \code{mobility_data} - Data frame with mobility data
#'       \item \code{spatial_zones = NULL} - sf object with spatial zones
#'       \item \code{create_map = TRUE} - Whether to create spatial maps
#'     }
#'   }
#'   \item{\code{\link{detect_anomalies}}}{Anomaly detection with spatial mapping
#'     \itemize{
#'       \item \code{mobility_data} - Data frame with mobility data
#'       \item \code{threshold = 2.5} - Z-score threshold for anomaly detection
#'       \item \code{spatial_zones = NULL} - sf object with spatial zones
#'       \item \code{create_map = TRUE} - Whether to create spatial maps
#'     }
#'   }
#'   \item{\code{\link{calc_indicators}}}{Calculate basic mobility indicators with mapping
#'     \itemize{
#'       \item \code{mobility_data} - Data frame with mobility data
#'       \item \code{spatial_zones = NULL} - sf object with spatial zones
#'     }
#'   }
#'   \item{\code{\link{calc_stats}}}{Calculate spatial statistics for zones
#'     \itemize{
#'       \item \code{mobility_data} - Data frame with mobility data
#'       \item \code{spatial_zones} - sf object with spatial zones (required)
#'     }
#'   }
#' }
#' }
#' 
#' \subsection{Visualization Functions:}{
#' \describe{
#'   \item{\code{\link{create_flows}}}{Flow visualization with sf geometries
#'     \itemize{
#'       \item \code{mobility_data} - Data frame with mobility data
#'       \item \code{spatial_zones} - sf object with spatial zones
#'       \item \code{top_flows = 20} - Number of top flows to visualize
#'     }
#'   }
#'   \item{\code{\link{create_spatial_map}}}{Create choropleth maps
#'     \itemize{
#'       \item \code{data} - Data frame with values to map
#'       \item \code{spatial_zones} - sf object with spatial zones
#'       \item \code{value_column} - Column name containing values to map
#'       \item \code{title} - Map title
#'     }
#'   }
#' }
#' }
#' 
#' \subsection{Machine Learning Functions:}{
#' \describe{
#'   \item{\code{\link{predict_patterns}}}{ML predictions with spatial mapping
#'     \itemize{
#'       \item \code{mobility_data} - Data frame with mobility data
#'       \item \code{prediction_dates} - Dates to predict
#'       \item \code{model_type = "linear_regression"} - Model type: "linear_regression" or "random_forest"
#'       \item \code{max_rows = 3000} - Maximum rows for model training
#'       \item \code{spatial_zones = NULL} - sf object with spatial zones
#'       \item \code{create_map = TRUE} - Whether to create spatial maps
#'     }
#'   }
#'   \item{\code{\link{detect_outliers}}}{Simple anomaly detection
#'     \itemize{
#'       \item \code{mobility_data} - Data frame with mobility data
#'       \item \code{threshold = 2.5} - Z-score threshold for outlier detection
#'       \item \code{spatial_zones = NULL} - sf object with spatial zones
#'       \item \code{create_map = TRUE} - Whether to create spatial maps
#'     }
#'   }
#' }
#' }
#' 
#' \subsection{Complete Workflow Functions:}{
#' \describe{
#'   \item{\code{\link{quick_analysis}}}{Complete workflow in one function
#'     \itemize{
#'       \item \code{dates = "2023-01-01"} - Date or date range
#'       \item \code{level = "dist"} - Spatial level
#'     }
#'   }
#'   \item{\code{\link{analyze_complete}}}{Multiple analyses with all maps
#'     \itemize{
#'       \item \code{mobility_data} - Data frame with mobility data
#'       \item \code{spatial_zones} - sf object with spatial zones
#'       \item \code{analyses = c("containment", "anomalies", "predictions")} - Analyses to run
#'     }
#'   }
#' }
#' }
#' 
#' \subsection{Advanced Spatial Analysis Functions:}{
#' \describe{
#'   \item{\code{\link{get_zones_buffer}}}{Buffer-based zone selection
#'     \itemize{
#'       \item \code{zones} - sf object with zone geometries
#'       \item \code{center_points} - Data frame with center coordinates
#'       \item \code{buffer_km = 10} - Buffer distance in kilometers
#'       \item \code{crs_proj = 25830} - Projected CRS for calculations
#'     }
#'   }
#'   \item{\code{\link{calculate_accessibility_matrix}}}{Spatial accessibility analysis
#'     \itemize{
#'       \item \code{zones} - sf object with zone geometries
#'       \item \code{decay_function = "exponential"} - Distance decay function
#'       \item \code{max_distance_km = 50} - Maximum distance for calculations
#'       \item \code{decay_parameter = 0.1} - Decay parameter
#'     }
#'   }
#'   \item{\code{\link{calculate_spatial_lag}}}{Spatial lag variable calculation
#'     \itemize{
#'       \item \code{zones} - sf object with zone geometries and attributes
#'       \item \code{variable} - Name of variable to calculate lag for
#'       \item \code{method = "contiguity"} - Spatial weights method
#'       \item \code{k = 5} - Number of neighbors for knn method
#'     }
#'   }
#' }
#' }
#'
#' @section Parameter Details:
#' 
#' \subsection{Common Parameters:}{
#' \itemize{
#'   \item \code{mobility_data} - Data frame with mobility data (must have 'origin', 'dest', 'n_trips', 'date' columns)
#'   \item \code{spatial_zones} - sf object with spatial zones and geometries (use \code{get_zones()} to obtain)
#'   \item \code{dates} - Character vector of dates (e.g., "2023-01-01" or c("2023-01-01", "2023-01-07"))
#'   \item \code{level} - Spatial level: "dist" (districts), "prov" (provinces), or "muni" (municipalities)
#'   \item \code{create_map} - Logical, whether to create spatial maps (default: TRUE)
#'   \item \code{max_rows} - Maximum number of rows for memory-efficient processing (default varies by function)
#'   \item \code{threshold} - Threshold for anomaly detection (default: 2.5 for z-score)
#' }
#' }
#' 
#' \subsection{Filtering Parameters (New!):}{
#' \itemize{
#'   \item \code{zones_filter} - Character vector of specific zone IDs (e.g., c("28079", "08019") for Madrid and Barcelona)
#'   \item \code{region_filter} - Region name or province code (e.g., "Madrid", "Barcelona", "46" for Valencia)
#'   \item \code{region} - Region identifier for \code{get_region_mobility()} function
#' }
#' }
#' 
#' \subsection{Model Parameters:}{
#' \itemize{
#'   \item \code{model_type} - Machine learning model: "linear_regression" (default) or "random_forest"
#'   \item \code{prediction_dates} - Dates to predict (character vector)
#'   \item \code{top_flows} - Number of top flows to show in flow maps (default: 20)
#'   \item \code{year} - Year for spatial boundaries (default: 2023)
#' }
#' }
#'
#' @section Getting Started:
#' \preformatted{
#' # Quick start - complete analysis in one function
#' results <- quick_analysis(dates = "2023-01-01", level = "dist")
#' print(results$maps$indicators)
#' print(results$maps$containment)
#' print(results$maps$flows)
#' 
#' # Regional analysis (recommended for users)
#' madrid_data <- get_region_mobility("Madrid", dates = "2023-01-01")
#' madrid_indicators <- calc_indicators(madrid_data$mobility, madrid_data$zones)
#' print(madrid_indicators$map)
#' 
#' # Step-by-step workflow with filtering
#' # 1. Get data with regional filtering
#' zones <- get_zones(level = "dist", region_filter = "Madrid")
#' mobility <- get_mobility(dates = "2023-01-01", level = "dist", region_filter = "Madrid")
#' 
#' # 2. Analyze containment
#' containment <- calculate_containment(mobility, zones, create_map = TRUE)
#' print(containment$map)
#' 
#' # 3. Detect anomalies
#' anomalies <- detect_anomalies(mobility, threshold = 2.5, spatial_zones = zones)
#' print(anomalies$map)
#' 
#' # 4. Create flow map
#' flows <- create_flows(mobility, zones, top_flows = 15)
#' print(flows)
#' 
#' # 5. Predict mobility patterns
#' predictions <- predict_patterns(
#'   mobility_data = mobility,
#'   prediction_dates = "2023-01-08",
#'   model_type = "linear_regression",
#'   spatial_zones = zones
#' )
#' print(predictions$spatial_map)
#' }
#'
#' @section Filtering Examples:
#' \preformatted{
#' # Filter by specific zones (Madrid and Barcelona districts)
#' madrid_barcelona_zones <- get_zones(level = "dist", zones_filter = c("28079", "08019"))
#' madrid_barcelona_mobility <- get_mobility(dates = "2023-01-01", zones_filter = c("28079", "08019"))
#' 
#' # Filter by region name
#' madrid_zones <- get_zones(level = "dist", region_filter = "Madrid")
#' madrid_mobility <- get_mobility(dates = "2023-01-01", region_filter = "Madrid")
#' 
#' # Filter by province code (faster)
#' valencia_zones <- get_zones(level = "dist", region_filter = "46")
#' valencia_mobility <- get_mobility(dates = "2023-01-01", region_filter = "46")
#' 
#' # Convenience function for regional analysis
#' barcelona_data <- get_region_mobility("Barcelona", dates = "2023-01-01")
#' # Access with: barcelona_data$mobility and barcelona_data$zones
#' }
#'
#' @section Province Codes:
#' \preformatted{
#' # Common province codes for filtering:
#' "28"  # Madrid
#' "08"  # Barcelona
#' "46"  # Valencia
#' "41"  # Sevilla
#' "29"  # Málaga
#' "03"  # Alicante
#' "48"  # Bizkaia (Bilbao)
#' "50"  # Zaragoza
#' "35"  # Las Palmas
#' "38"  # Santa Cruz de Tenerife
#' }
#'
#' @name mobspain
#' @import dplyr
#' @import sf
#' @import ggplot2
#' @import glue
#' @import lubridate
"_PACKAGE"
