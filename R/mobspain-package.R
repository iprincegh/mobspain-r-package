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
#' \subsection{Enhanced Data Access}{
#' \itemize{
#'   \item Intelligent data version detection and caching
#'   \item Seamless integration with spanishoddata package
#'   \item Robust fallback mechanisms (database -> CSV -> download)
#'   \item Demographic filtering for v2 data
#'   \item Comprehensive metadata and data summaries
#' }
#' }
#'
#' \subsection{Advanced Analytics}{
#' \itemize{
#'   \item Mobility indicators (containment, connectivity, flow analysis)
#'   \item Anomaly detection using statistical methods
#'   \item Distance decay modeling (power law, exponential)
#'   \item Time series analysis with seasonal decomposition
#'   \item Machine learning integration for predictive analytics
#' }
#' }
#'
#' \subsection{Geospatial Analysis}{
#' \itemize{
#'   \item Spatial autocorrelation analysis (Moran's I, Geary's C)
#'   \item Hotspot detection with LISA indicators
#'   \item Accessibility analysis (gravity-based, cumulative)
#'   \item Spatial clustering and pattern detection
#' }
#' }
#'
#' \subsection{Rich Visualizations}{
#' \itemize{
#'   \item Interactive flow maps with Leaflet
#'   \item Choropleth maps with custom palettes
#'   \item Time series plots with anomaly highlighting
#'   \item Comprehensive dashboard creation
#'   \item Origin-destination heatmaps
#' }
#' }
#'
#' \subsection{Data Quality & Validation}{
#' \itemize{
#'   \item Comprehensive data validation and quality assessment
#'   \item Metadata consistency checking
#'   \item Anomaly detection and flagging
#'   \item Data completeness analysis
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
#' ## Data Versions
#'
#' The package supports both versions of Spanish mobility data:
#' 
#' \itemize{
#'   \item \strong{Version 1 (2020-2021):} COVID-19 pandemic period data
#'   \item \strong{Version 2 (2022 onwards):} Enhanced data with demographics (recommended)
#' }
#'
#' ## Quick Start
#'
#' \preformatted{
#' # Load the package
#' library(mobspain)
#' 
#' # Configure data directory (recommended)
#' init_data_dir("~/spanish_mobility_data", version = 2)
#' 
#' # Get mobility data with intelligent caching
#' mobility_data <- get_enhanced_mobility_data(
#'   dates = c("2022-01-01", "2022-01-07"),
#'   data_type = "od",
#'   zone_level = "districts"
#' )
#' 
#' # Analyze temporal patterns
#' ts_analysis <- analyze_mobility_time_series(
#'   mobility_data,
#'   temporal_resolution = "daily",
#'   detect_anomalies = TRUE
#' )
#' 
#' # Create interactive dashboard
#' dashboard <- create_mobility_dashboard(
#'   mobility_data,
#'   dashboard_type = "overview",
#'   title = "Spanish Mobility Analysis"
#' )
#' 
#' # Analyze spatial patterns
#' districts <- get_enhanced_spatial_zones("districts", version = 2)
#' spatial_analysis <- analyze_spatial_patterns(
#'   mobility_data,
#'   districts,
#'   analysis_type = "hotspots"
#' )
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
