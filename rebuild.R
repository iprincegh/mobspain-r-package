#!/usr/bin/env Rscript
# rebuild.R
setwd("~/mobspain")

# Clean environment
rm(list = ls())

# Remove existing installation
if ("mobspain" %in% installed.packages()) {
  remove.packages("mobspain")
}

# Clear caches
cache_dirs <- c(
  "~/Library/Caches/org.R-project.R/R/pkgcache",
  "~/Library/R/",
  file.path(tempdir(), "Rtmp*")
)

for (cache in cache_dirs) {
  unlink(cache, recursive = TRUE, force = TRUE)
}

# Install dependencies
install.packages(c("devtools", "spanishoddata", "duckdb", "sf", "dplyr", "testthat"))

# Rebuild package
devtools::document()
devtools::install(
  build = TRUE,
  build_vignettes = TRUE,
  dependencies = TRUE,
  INSTALL_opts = c("--no-multiarch", "--no-byte-compile")
)
