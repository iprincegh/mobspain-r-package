#' Get spatial zones with parsed metadata
#'
#' @param level Spatial level: "dist" (districts), "muni" (municipalities), "lua" (large urban areas)
#' @param version Data version: 1 (2020-2021) or 2 (2022 onwards, default)
#' @return sf object with spatial zones
#' @export
#' @details
#' Downloads Spanish administrative boundaries from the MITMA dataset. 
#' The version parameter determines which dataset version to use:
#' \itemize{
#'   \item \strong{Version 1 (2020-2021):} COVID-19 period boundaries
#'   \item \strong{Version 2 (2022 onwards):} Enhanced boundaries with better resolution
#' }
#' @examples
#' \dontrun{
#' # Get districts using default version 2
#' districts <- get_spatial_zones("dist")
#' 
#' # Get municipalities using version 1 (COVID period)
#' municipalities <- get_spatial_zones("muni", version = 1)
#' 
#' # Get large urban areas using version 2
#' urban_areas <- get_spatial_zones("lua", version = 2)
#' }
get_spatial_zones <- function(level = "dist", version = NULL) {
  # Use configured version if not specified
  if (is.null(version)) {
    version <- getOption("mobspain.data_version", 2)
  }
  
  # Validate version
  if (!version %in% c(1, 2)) {
    stop("version must be 1 (2020-2021) or 2 (2022 onwards)", call. = FALSE)
  }
  
  # Validate level
  valid_levels <- c("dist", "muni", "lua")
  if (!level %in% valid_levels) {
    stop("level must be one of: ", paste(valid_levels, collapse = ", "), call. = FALSE)
  }
  
  tryCatch({
    message("Downloading spatial zones (level: ", level, ", version: ", version, ")...")
    zones <- spanishoddata::spod_get_zones(level, ver = version)

    # Standardize column names - spanishoddata uses different column names
    if("id_dist" %in% names(zones)) {
      zones$id <- zones$id_dist
    } else if("id_muni" %in% names(zones)) {
      zones$id <- zones$id_muni
    } else if("id_lua" %in% names(zones)) {
      zones$id <- zones$id_lua
    }
    
    # Calculate area
    zones$area_km2 <- as.numeric(sf::st_area(zones)) / 1e6
    
    message("Successfully downloaded ", nrow(zones), " zones")
    return(zones)
  }, error = function(e) {
    warning("Failed to download spatial data (version ", version, "): ", e$message)
    message("Using built-in sample data instead")

    # Load sample spatial data
    utils::data("sample_zones", package = "mobspain", envir = environment())
    return(get("sample_zones", envir = environment()))
  })
}

#' Create spatial index for zones
#'
#' Prepares zones for efficient spatial operations by adding centroids
#'
#' @param zones sf object from get_spatial_zones()
#' @return Enhanced sf object with centroid column
#' @export
create_zone_index <- function(zones) {
  if (!inherits(zones, "sf")) {
    stop("Input must be an sf object", call. = FALSE)
  }

  zones %>%
    sf::st_make_valid() %>%
    dplyr::mutate(centroid = sf::st_centroid(.data$geometry))
}
