#' Sample mobility zones for testing
#'
#' A dataset containing sample geographical zones with mobility-related attributes
#' for testing and demonstration purposes.
#'
#' @format A data frame with 3 rows and 5 variables:
#' \describe{
#'   \item{id}{Character vector of zone identifiers}
#'   \item{name}{Character vector of zone names}
#'   \item{population}{Numeric vector of population counts}
#'   \item{geometry}{Simple feature geometry column (POINT)}
#'   \item{area_km2}{Numeric vector of zone areas in square kilometers}
#' }
#' @source Generated for package testing and demonstration
"sample_zones"

#' Initialize data directory for MITMA data
#'
#' Sets up storage for MITMA data and configures spanishoddata
#'
#' @param path Path to store MITMA data (default: ~/spanish_mobility_data)
#' @param version Data version to use: 1 (2020-2021) or 2 (2022 onwards, default)
#' @export
#' @details
#' The Spanish mobility data comes in two versions:
#' \itemize{
#'   \item \strong{Version 1 (2020-2021):} COVID-19 pandemic period data with trip numbers 
#'         and distances by origin, destination, activity, residence province, time, and date.
#'   \item \strong{Version 2 (2022 onwards):} Enhanced data with improved spatial resolution,
#'         trips to/from Portugal and France, and sociodemographic factors (income, age, sex).
#' }
#' @examples
#' \dontrun{
#' # Use default version 2 (2022 onwards - recommended)
#' init_data_dir()
#' 
#' # Use version 1 (2020-2021 COVID period)
#' init_data_dir(version = 1)
#' 
#' # Specify custom path and version
#' init_data_dir("~/my_mobility_data", version = 2)
#' }
init_data_dir <- function(path = "~/spanish_mobility_data", version = 2) {
  # Validate version
  if (!version %in% c(1, 2)) {
    stop("version must be 1 (2020-2021) or 2 (2022 onwards)", call. = FALSE)
  }
  
  if(!dir.exists(path)) dir.create(path, recursive = TRUE)
  spanishoddata::spod_set_data_dir(path)
  options(mobspain.data_dir = path)
  options(mobspain.data_version = version)
  
  # Provide informative message about the chosen version
  version_info <- if(version == 1) {
    "Version 1 (2020-2021): COVID-19 pandemic period data"
  } else {
    "Version 2 (2022 onwards): Enhanced data with sociodemographic factors (recommended)"
  }
  
  message("Data directory set to: ", normalizePath(path))
  message("Using data ", version_info)
  message("For version details, see: ?init_data_dir or get_data_version_info()")
}

#' Connect to mobility database
#'
#' Establishes connection to DuckDB database with processed mobility data
#'
#' @return DuckDB connection object
#' @export
#' @examples
#' \dontrun{
#' # First initialize data directory
#' init_data_dir()
#' 
#' # Connect to the database
#' con <- connect_mobility_db()
#' 
#' # Use the connection for custom queries
#' result <- DBI::dbGetQuery(con, "SELECT * FROM mobility_data LIMIT 10")
#' 
#' # Don't forget to close the connection
#' DBI::dbDisconnect(con)
#' }
connect_mobility_db <- function() {
  data_dir <- getOption("mobspain.data_dir")
  if(is.null(data_dir)) stop("Run init_data_dir() first")
  
  # Try to connect to existing database first
  db_path <- file.path(data_dir, "spanishoddata.duckdb")
  
  if(file.exists(db_path)) {
    return(DBI::dbConnect(duckdb::duckdb(), db_path))
  }
  
  # If database doesn't exist, try to create it
  message("No existing database found. Creating new connection...")
  
  # Create a simple DuckDB connection for now
  # Users should manually run spod_convert outside if they need data conversion
  warning("No pre-converted database found. Use spanishoddata::spod_convert() manually to convert your data first.")
  
  DBI::dbConnect(duckdb::duckdb(), db_path)
}

#' Standardize OD data column names
#'
#' Converts various column naming conventions to standard format
#' @param od_data Mobility data with origin/destination/flow columns
#' @return Data frame with standardized column names
#' @keywords internal
standardize_od_columns <- function(od_data) {
  # Create a copy to avoid modifying original data
  result <- od_data
  
  # Standardize origin column
  if("origin" %in% names(result) && !"id_origin" %in% names(result)) {
    names(result)[names(result) == "origin"] <- "id_origin"
  }
  
  # Standardize destination column  
  if("destination" %in% names(result) && !"id_destination" %in% names(result)) {
    names(result)[names(result) == "destination"] <- "id_destination"
  }
  
  # Standardize flow column
  if("flow" %in% names(result) && !"n_trips" %in% names(result)) {
    names(result)[names(result) == "flow"] <- "n_trips"
  }
  
  # Validate required columns
  required_cols <- c("id_origin", "id_destination", "n_trips")
  missing_cols <- setdiff(required_cols, names(result))
  
  if(length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "), 
         ". Expected: origin/id_origin, destination/id_destination, flow/n_trips", 
         call. = FALSE)
  }
  
  return(result)
}

# Enhanced data version and metadata functions based on MITMA codebooks

#' Get comprehensive data version information
#'
#' @param version Data version (1 or 2). If NULL, detects from dates
#' @param dates Date range to help determine version
#' @return List with detailed metadata about data version capabilities
#' @export
#' @examples
#' \dontrun{
#' # Get v1 data info
#' v1_info <- get_data_version_info(version = 1)
#' print(v1_info$description)
#' print(v1_info$available_variables)
#' 
#' # Get v2 data info
#' v2_info <- get_data_version_info(version = 2)
#' print(v2_info$demographic_variables)
#' print(v2_info$use_cases)
#' }
get_data_version_info <- function(version = NULL, dates = NULL) {
  
  if(is.null(version) && !is.null(dates)) {
    version <- detect_data_version(dates)
  }
  
  if(is.null(version)) {
    version <- getOption("mobspain.data_version", 2)
  }
  
  if(version == 1) {
    return(list(
      version = 1,
      period = "2020-02-14 to 2021-05-09",
      description = "COVID-19 mobility study data from MITMA",
      producer = "Nommon Solutions using Orange Espana mobile data",
      methodology_url = "https://cdn.mitma.gob.es/portal-web-drupal/covid-19/bigdata/mitma_-_estudio_movilidad_covid-19_informe_metodologico_v3.pdf",
      
      spatial_levels = c("districts", "municipalities"),
      districts_count = 2850,
      municipalities_count = 2205,
      
      available_variables = c(
        "date", "id_origin", "id_destination", "activity_origin", 
        "activity_destination", "residence_province_ine_code", 
        "residence_province_name", "hour", "distance", "n_trips", 
        "trips_total_length_km", "year", "month", "day"
      ),
      
      data_types = c(
        "origin_destination" = "od",
        "number_of_trips" = "nt"
      ),
      
      temporal_resolution = "hourly",
      spatial_aggregation = "privacy_compliant",
      
      use_cases = c(
        "COVID-19 mobility impact analysis",
        "Containment policy evaluation", 
        "Regional mobility comparison",
        "Hourly mobility patterns",
        "Distance decay analysis"
      ),
      
      limitations = c(
        "Limited temporal coverage (COVID period only)",
        "No demographic variables (age, sex, income)",
        "Some spatial aggregation for privacy",
        "Single mobile operator data (reweighted)"
      ),
      
      recommended_for = c(
        "COVID-19 research",
        "Policy impact assessment",
        "Short-term mobility studies",
        "Baseline mobility analysis"
      )
    ))
    
  } else if(version == 2) {
    return(list(
      version = 2,
      period = "2022-01-01 onwards (continuous)",
      description = "Comprehensive mobility study data from MITMA",
      producer = "Nommon Solutions using Orange Espana mobile data",
      methodology_url = "https://www.transportes.gob.es/recursos_mfom/paginabasica/recursos/a3_informe_metodologico_estudio_movilidad_mitms_v8.pdf",
      
      spatial_levels = c("districts", "municipalities", "large_urban_areas"),
      districts_count = 3792,
      municipalities_count = 2618,
      luas_count = 2086,
      international_coverage = c("France (94 NUTS3)", "Portugal (23 NUTS3)"),
      
      available_variables = c(
        "date", "id_origin", "id_destination", "activity_origin", 
        "activity_destination", "study_possible_origin", "study_possible_destination",
        "residence_province_ine_code", "residence_province_name", 
        "income", "age", "sex", "hour", "distance", "n_trips", 
        "trips_total_length_km", "year", "month", "day"
      ),
      
      demographic_variables = list(
        age = c("0-25", "25-45", "45-65", "65-100", "NA"),
        sex = c("female", "male", "NA"),
        income = c("<10k EUR", "10-15k EUR", ">15k EUR")
      ),
      
      data_types = c(
        "origin_destination" = "od",
        "number_of_trips" = "nt", 
        "overnight_stays" = "os"
      ),
      
      study_types = c(
        "basic_studies" = "Daily hourly OD matrices (currently supported)",
        "complete_studies" = "Advanced datasets (future support)",
        "road_routes" = "Route-based analysis (future support)"
      ),
      
      temporal_resolution = "hourly",
      spatial_resolution = "enhanced_granularity",
      
      use_cases = c(
        "Long-term mobility trend analysis",
        "Demographic mobility patterns",
        "Income-based mobility inequality",
        "Age-specific mobility behavior",
        "Gender mobility differences", 
        "International mobility flows",
        "Urban planning and policy",
        "Transport demand modeling",
        "Accessibility analysis",
        "Tourism mobility patterns"
      ),
      
      advanced_features = c(
        "Demographic segmentation",
        "Income-based analysis",
        "Educational trip detection",
        "Continuous temporal coverage",
        "International zones",
        "Enhanced spatial resolution",
        "Study/work trip classification"
      ),
      
      limitations = c(
        "Demographic data partially imputed",
        "Some privacy-based spatial aggregation",
        "Single mobile operator (reweighted)",
        "Income based on census tract averages"
      ),
      
      recommended_for = c(
        "Academic research",
        "Urban planning",
        "Transport policy",
        "Demographic studies",
        "Economic mobility analysis",
        "Long-term trend analysis",
        "International comparisons"
      )
    ))
  }
  
  stop("Invalid version. Must be 1 or 2.")
}

#' Detect data version from dates
#'
#' @param dates Date vector or range
#' @return Integer version number (1 or 2)
#' @export
detect_data_version <- function(dates) {
  if(is.null(dates)) return(2)
  
  if(is.character(dates)) {
    dates <- as.Date(dates)
  }
  
  min_date <- min(dates, na.rm = TRUE)
  max_date <- max(dates, na.rm = TRUE)
  
  # V1 period: 2020-02-14 to 2021-05-09
  v1_start <- as.Date("2020-02-14")
  v1_end <- as.Date("2021-05-09")
  
  # V2 period: 2022-01-01 onwards
  v2_start <- as.Date("2022-01-01")
  
  if(max_date <= v1_end && min_date >= v1_start) {
    return(1)
  } else if(min_date >= v2_start) {
    return(2)
  } else {
    warning("Dates span multiple versions or unsupported period. Using version 2.")
    return(2)
  }
}

#' Get metadata for specific data type and version
#'
#' @param data_type Type of data ("od", "nt", "os")
#' @param version Data version (1 or 2)
#' @param zone_level Spatial level ("districts", "municipalities", "luas")
#' @return List with detailed metadata
#' @export
get_data_type_metadata <- function(data_type = "od", version = 2, zone_level = "districts") {
  
  base_info <- get_data_version_info(version)
  
  # Validate inputs
  if(!data_type %in% names(base_info$data_types)) {
    stop(sprintf("Invalid data_type. Available: %s", 
                 paste(names(base_info$data_types), collapse = ", ")))
  }
  
  if(version == 1 && data_type == "os") {
    stop("Overnight stays data not available in version 1")
  }
  
  metadata <- list(
    data_type = data_type,
    version = version,
    zone_level = zone_level,
    base_info = base_info
  )
  
  # Add specific metadata based on data type
  if(data_type == "od") {
    metadata$description <- "Origin-destination flow matrices"
    metadata$primary_variable <- "n_trips"
    metadata$spatial_nature <- "dyadic"
    metadata$analysis_capabilities <- c(
      "Flow analysis", "Network analysis", "Accessibility analysis",
      "Distance decay modeling", "Gravity modeling"
    )
  } else if(data_type == "nt") {
    metadata$description <- "Number of trips per zone"
    metadata$primary_variable <- "n_trips"
    metadata$spatial_nature <- "nodal"
    metadata$analysis_capabilities <- c(
      "Activity analysis", "Density analysis", "Temporal patterns",
      "Anomaly detection", "Containment analysis"
    )
  } else if(data_type == "os") {
    metadata$description <- "Overnight stays per zone"
    metadata$primary_variable <- "n_stays"
    metadata$spatial_nature <- "nodal"
    metadata$analysis_capabilities <- c(
      "Tourism analysis", "Temporary mobility", "Residential patterns",
      "Seasonal mobility", "Economic impact"
    )
  }
  
  return(metadata)
}

#' Get recommended analysis approaches for data characteristics
#'
#' @param data_characteristics List with data properties
#' @return List with recommended analysis methods
#' @export
get_analysis_recommendations <- function(data_characteristics) {
  
  recommendations <- list()
  
  # Basic recommendations based on data type
  if(data_characteristics$data_type == "od") {
    recommendations$primary_methods <- c(
      "Flow mapping", "Network analysis", "Gravity modeling"
    )
    recommendations$visualization <- c(
      "Flow maps", "Chord diagrams", "Sankey diagrams"
    )
  } else if(data_characteristics$data_type == "nt") {
    recommendations$primary_methods <- c(
      "Choropleth mapping", "Time series analysis", "Anomaly detection"
    )
    recommendations$visualization <- c(
      "Heatmaps", "Time series plots", "Density maps"
    )
  }
  
  # Version-specific recommendations
  if(data_characteristics$version == 1) {
    recommendations$temporal_analysis <- c(
      "COVID impact analysis", "Policy evaluation", "Containment assessment"
    )
    recommendations$special_considerations <- c(
      "Account for COVID context", "Compare with pre-pandemic baselines",
      "Consider policy intervention dates"
    )
  } else if(data_characteristics$version == 2) {
    recommendations$demographic_analysis <- c(
      "Age-based segmentation", "Income inequality analysis", "Gender patterns"
    )
    recommendations$advanced_methods <- c(
      "Machine learning clustering", "Predictive modeling", "Causal inference"
    )
  }
  
  return(recommendations)
}

#' Get current data version
#' 
#' @return Current data version (1 or 2)
#' @export
#' @examples
#' \dontrun{
#' # Check current data version
#' current_version <- get_current_data_version()
#' cat("Current data version:", current_version, "\n")
#' 
#' # Set up data directory and check version
#' init_data_dir(version = 2)
#' version <- get_current_data_version()
#' cat("Using version:", version, "\n")
#' 
#' # Use in conditional logic
#' if (get_current_data_version() == 1) {
#'   cat("Using COVID-19 period data\n")
#' } else {
#'   cat("Using enhanced current data\n")
#' }
#' }
get_current_data_version <- function() {
  version <- getOption("mobspain.data_version", 2)
  if (is.null(version)) {
    message("No data version set. Run init_data_dir() first. Using default version 2.")
    return(2)
  }
  return(version)
}
