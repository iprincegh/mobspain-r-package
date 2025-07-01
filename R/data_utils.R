#' Initialize data directory for MITMA data
#'
#' Sets up storage for MITMA data and configures spanishoddata
#'
#' @param path Path to store MITMA data (default: ~/spanish_mobility_data)
#' @export
init_data_dir <- function(path = "~/spanish_mobility_data") {
  if(!dir.exists(path)) dir.create(path, recursive = TRUE)
  spanishoddata::spod_set_data_dir(path)
  options(mobspain.data_dir = path)
  message("Data directory set to: ", normalizePath(path))
}

#' Connect to mobility database
#'
#' Establishes connection to DuckDB database with processed mobility data
#'
#' @return DuckDB connection object
#' @export
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
