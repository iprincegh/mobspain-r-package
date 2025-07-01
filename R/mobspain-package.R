#' mobspain: Spanish Mobility Data Analysis Toolkit
#'
#' @description
#' A comprehensive R package for analyzing Spanish mobility patterns using MITMA 
#' (Ministry of Transport, Mobility and Urban Agenda) data. Built on top of the 
#' \code{spanishoddata} package with enhanced analytics, visualization, and 
#' performance features.
#'
#' @details
#' The mobspain package provides a complete toolkit for Spanish mobility analysis,
#' offering advanced analytics, interactive visualizations, and performance 
#' optimizations for researchers, urban planners, and data scientists.
#'
#' ## Key Features
#'
#' \subsection{Advanced Analytics}{
#' \itemize{
#'   \item Mobility indicators (containment, connectivity, flow analysis)
#'   \item Anomaly detection using statistical methods
#'   \item Distance decay modeling (power law, exponential)
#'   \item Spatial analysis with geometric support
#' }
#' }
#'
#' \subsection{Rich Visualizations}{
#' \itemize{
#'   \item Interactive flow maps with Leaflet
#'   \item Choropleth maps with custom palettes
#'   \item Time series plots for mobility patterns
#'   \item Origin-destination heatmaps
#'   \item Distance-decay relationship plots
#' }
#' }
#'
#' \subsection{Performance & Usability}{
#' \itemize{
#'   \item Smart caching for faster repeated analyses
#'   \item Parallel processing support for large datasets
#'   \item Robust error handling with graceful fallbacks
#'   \item Comprehensive input validation
#' }
#' }
#'
#' ## Quick Start
#'
#' \preformatted{
#' # Load the package
#' library(mobspain)
#' 
#' # Configure package (optional)
#' configure_mobspain(parallel = TRUE, n_cores = 4)
#' 
#' # Check package status
#' mobspain_status()
#' 
#' # Initialize data directory
#' init_data_dir("~/spanish_mobility_data")
#' 
#' # Get spatial zones
#' zones <- get_spatial_zones("dist")  # Districts
#' 
#' # Get mobility data
#' mobility <- get_mobility_matrix(
#'   dates = c("2023-01-01", "2023-01-07"),
#'   level = "dist",
#'   time_window = c(7, 9)  # Morning commute
#' )
#' 
#' # Calculate comprehensive indicators
#' indicators <- calculate_mobility_indicators(mobility, zones)
#' 
#' # Create visualizations
#' plot_daily_mobility(mobility)
#' create_flow_map(mobility, zones, min_flow = 100)
#' }
#'
#' ## Main Function Categories
#'
#' \subsection{Data Management}{
#' \itemize{
#'   \item \code{\link{init_data_dir}}: Set up data storage directory
#'   \item \code{\link{connect_mobility_db}}: Connect to DuckDB database
#'   \item \code{\link{configure_mobspain}}: Package configuration
#'   \item \code{\link{mobspain_status}}: Package diagnostics
#' }
#' }
#'
#' \subsection{Data Retrieval}{
#' \itemize{
#'   \item \code{\link{get_mobility_matrix}}: Retrieve origin-destination mobility data
#'   \item \code{\link{get_spatial_zones}}: Download Spanish administrative boundaries
#' }
#' }
#'
#' \subsection{Analytics}{
#' \itemize{
#'   \item \code{\link{calculate_mobility_indicators}}: Comprehensive mobility metrics
#'   \item \code{\link{calculate_containment}}: Self-containment analysis
#'   \item \code{\link{detect_mobility_anomalies}}: Anomaly detection
#'   \item \code{\link{calculate_distance_decay}}: Distance-decay modeling
#' }
#' }
#'
#' \subsection{Visualization}{
#' \itemize{
#'   \item \code{\link{plot_daily_mobility}}: Time series visualization
#'   \item \code{\link{create_flow_map}}: Interactive flow mapping
#'   \item \code{\link{create_choropleth_map}}: Spatial indicator mapping
#'   \item \code{\link{plot_mobility_heatmap}}: Flow matrix heatmaps
#'   \item \code{\link{plot_distance_decay}}: Distance-decay plots
#' }
#' }
#'
#' \subsection{Utilities}{
#' \itemize{
#'   \item \code{\link{create_zone_index}}: Spatial indexing for performance
#' }
#' }
#'
#' ## Data Sources
#'
#' This package works with Spanish mobility data from:
#' \itemize{
#'   \item MITMA: Ministry of Transport, Mobility and Urban Agenda
#'   \item INE: National Statistics Institute spatial boundaries
#'   \item Administrative Levels: Districts, Municipalities, Large Urban Areas
#' }
#'
#' ## Sample Data
#'
#' The package includes \code{\link{sample_zones}} dataset for testing and learning.
#'
#' @author Prince Oppong Boakye <prynx44@gmail.com>
#' @keywords package spatial mobility spain
#' @seealso 
#' \itemize{
#'   \item Package repository: \url{https://github.com/iprincegh/mobspain-r-package}
#'   \item spanishoddata package: \url{https://cran.r-project.org/package=spanishoddata}
#' }
#'
#' @examples
#' \dontrun{
#' # Basic workflow example
#' library(mobspain)
#' 
#' # Setup
#' init_data_dir("~/mobility_data")
#' 
#' # Get data
#' zones <- get_spatial_zones("dist")
#' mobility <- get_mobility_matrix(
#'   dates = c("2023-01-01", "2023-01-07"),
#'   level = "dist"
#' )
#' 
#' # Analyze
#' indicators <- calculate_mobility_indicators(mobility, zones)
#' anomalies <- detect_mobility_anomalies(mobility)
#' 
#' # Visualize
#' plot_daily_mobility(mobility)
#' create_choropleth_map(zones, indicators, variable = "containment")
#' }
#'
#' @docType package
#' @name mobspain
"_PACKAGE"
