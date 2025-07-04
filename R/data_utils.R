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

#' Get information about Spanish mobility data versions
#'
#' @return List with detailed information about both data versions
#' @export
#' @examples
#' # Get comprehensive version information
#' version_info <- get_data_version_info()
#' 
#' # View comparison table
#' print(version_info$comparison)
#' 
#' # Get recommendations
#' print(version_info$recommendations)
#' 
#' # Check current version
#' cat("Current version:", version_info$current_version, "\n")
#' 
#' # Get details for specific version
#' v1_info <- version_info$version_1
#' cat("Version 1 period:", v1_info$period, "\n")
#' cat("Version 1 characteristics:", paste(v1_info$characteristics, collapse = ", "), "\n")
#' 
#' v2_info <- version_info$version_2
#' cat("Version 2 period:", v2_info$period, "\n")
#' cat("Version 2 characteristics:", paste(v2_info$characteristics, collapse = ", "), "\n")
get_data_version_info <- function() {
  list(
    version_1 = list(
      period = "2020-2021",
      description = "COVID-19 pandemic period data",
      characteristics = c(
        "Trip numbers and distances by origin-destination",
        "Activity and residence province breakdown", 
        "Time interval and distance interval data",
        "Individual counts by location and trip frequency",
        "Focus on COVID-19 mobility changes"
      ),
      spatial_resolution = "Municipality and district level",
      temporal_resolution = "Daily and hourly",
      countries = "Spain only",
      use_cases = c(
        "COVID-19 mobility analysis",
        "Pandemic impact studies", 
        "Historical mobility comparison",
        "Emergency response planning"
      )
    ),
    version_2 = list(
      period = "2022 onwards", 
      description = "Enhanced mobility data with sociodemographic factors",
      characteristics = c(
        "Improved spatial resolution",
        "Trips to and from Portugal and France",
        "Sociodemographic factors: income, age, sex",
        "Study-related activities information",
        "Individual counts by overnight stay location",
        "Residence and date breakdown"
      ),
      spatial_resolution = "Enhanced municipality and district level",
      temporal_resolution = "Daily and hourly",
      countries = "Spain, Portugal, France",
      use_cases = c(
        "Current mobility analysis (recommended)",
        "Cross-border mobility studies",
        "Sociodemographic mobility patterns",
        "Urban planning and policy",
        "Transportation demand modeling"
      )
    ),
    comparison = data.frame(
      Feature = c(
        "Time Period", "Spatial Resolution", "Countries Covered", 
        "Sociodemographic Data", "Cross-border Trips", "Use Case",
        "Data Quality", "Recommendation"
      ),
      `Version 1 (2020-2021)` = c(
        "2020-2021 (COVID period)", "Standard", "Spain only",
        "Limited", "No", "Historical/COVID analysis", 
        "Good", "For COVID studies"
      ),
      `Version 2 (2022+)` = c(
        "2022 onwards (current)", "Enhanced", "Spain + Portugal + France",
        "Income, age, sex", "Yes", "Current analysis",
        "Enhanced", "Recommended for new projects"
      ),
      stringsAsFactors = FALSE
    ),
    current_version = getOption("mobspain.data_version", 2),
    recommendations = list(
      general = "Use Version 2 for new projects (enhanced data quality and features)",
      covid_studies = "Use Version 1 for COVID-19 specific analysis", 
      cross_border = "Use Version 2 for Spain-Portugal-France mobility studies",
      sociodemographic = "Use Version 2 for income/age/sex analysis"
    )
  )
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
