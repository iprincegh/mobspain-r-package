#' Get spatial zones with parsed metadata
#'
#' @param level One of: "dist", "muni", "lua"
#' @param version Data version (default: 2)
#' @return sf object
#' @export
get_spatial_zones <- function(level = "dist", version = 2) {
  tryCatch({
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
    return(zones)
  }, error = function(e) {
    message("Failed to download spatial data: ", e$message)
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
