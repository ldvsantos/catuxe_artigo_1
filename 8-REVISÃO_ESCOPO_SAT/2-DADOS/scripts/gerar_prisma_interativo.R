#!/usr/bin/env Rscript
# PRISMA 2020 FLOWCHART GENERATOR - OFFICIAL R VERSION
# Script to generate professional PRISMA 2020 diagrams using the official R package
# PRISMA2020 based on repository: https://github.com/prisma-flowdiagram/PRISMA2020
# Author: Adapted for English
# Date: 2025

# Suppress warnings
options(warn = -1)

# Configure CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com"))

# Check and install required packages
required_packages <- c("devtools", "htmlwidgets", "DiagrammeR")

# Force reinstall magrittr
install.packages("magrittr", quiet = TRUE)

for (package in required_packages) {
  if (!require(package, character.only = TRUE)) {
    cat(sprintf("📦 Installing package: %s\n", package))
    install.packages(package, quiet = TRUE)
  }
}

# Force reinstall PRISMA2020
if (!require("PRISMA2020", character.only = TRUE)) {
    cat("📦 Installing PRISMA2020 from GitHub...\n")
    devtools::install_github("prisma-flowdiagram/PRISMA2020", quiet = TRUE, force = TRUE)
}


library(PRISMA2020, quietly = TRUE)
library(htmlwidgets, quietly = TRUE)
library(DiagrammeR, quietly = TRUE)

# Set working directory to script location
script_dir <- dirname(normalizePath(commandArgs(trailingOnly = FALSE)[4]))
setwd(script_dir)

csv_file <- "PRISMA.csv"

if (!file.exists(csv_file)) {
  cat(sprintf("❌ File %s not found!\n", csv_file))
  quit(status = 1)
}

cat(sprintf("📂 Loading data from: %s\n", csv_file))

# Read the data (official PRISMA2020 template)
data <- read.csv(csv_file, sep = ",", stringsAsFactors = FALSE, check.names = FALSE)

cat("✅ Data loaded successfully\n\n")

# Process data to correct format
cat("📊 Processing PRISMA data...\n")
prisma_data <- PRISMA_data(data)

# Generate PRISMA 2020 flowchart
cat("🎨 Generating PRISMA 2020 flowchart...\n")

plot <- PRISMA_flowdiagram(
  prisma_data,
  fontsize = 12,
  font = "Helvetica",
  title_colour = "Goldenrod1",
  greybox_colour = "Gainsboro",
  main_colour = "Black",
  arrow_colour = "Black",
  arrow_head = "normal",
  arrow_tail = "none",
  interactive = FALSE,
  previous = FALSE,
  other = TRUE,
  detail_databases = TRUE,
  detail_registers = FALSE,
  meta_analysis = FALSE,
  side_boxes = TRUE
)

# Save in different formats
output_html <- "prisma_flowdiagram_interativo.html"
output_pdf <- "prisma_flowdiagram.pdf"
output_png <- "prisma_flowdiagram.png"
output_svg <- "prisma_flowdiagram.svg"

cat("\n📥 Saving files...\n")

# HTML (with interactivity)
tryCatch({
  PRISMA_save(plot, filename = output_html, filetype = "HTML", overwrite = TRUE)
  cat(sprintf("✅ HTML: %s\n", output_html))
}, error = function(e) {
  cat(sprintf("❌ Error saving HTML: %s\n", e$message))
})

# PDF
tryCatch({
  PRISMA_save(plot, filename = output_pdf, filetype = "PDF", overwrite = TRUE)
  cat(sprintf("✅ PDF: %s\n", output_pdf))
}, error = function(e) {
  cat(sprintf("⚠️  Warning saving PDF: %s\n", e$message))
})

# PNG
tryCatch({
  PRISMA_save(plot, filename = output_png, filetype = "PNG", overwrite = TRUE)
  cat(sprintf("✅ PNG: %s\n", output_png))
}, error = function(e) {
  cat(sprintf("⚠️  Warning saving PNG: %s\n", e$message))
})

# Copy the updated PNG to the manuscript figures folder (EN)
tryCatch({
  target_png <- file.path("..", "..", "2-FIGURAS", "2-EN", "prisma_flowdiagram.png")
  file.copy(output_png, target_png, overwrite = TRUE)
  cat(sprintf("✅ Copied to: %s\n", normalizePath(target_png, winslash = "/", mustWork = FALSE)))
}, error = function(e) {
  cat(sprintf("⚠️  Warning copying PNG: %s\n", e$message))
})

# SVG
tryCatch({
  PRISMA_save(plot, filename = output_svg, filetype = "SVG", overwrite = TRUE)
  cat(sprintf("✅ SVG: %s\n", output_svg))
}, error = function(e) {
  cat(sprintf("⚠️  Warning saving SVG: %s\n", e$message))
})

cat("\n======================================================================\n")
cat("✨ PRISMA 2020 FLOWCHART GENERATED SUCCESSFULLY!\n")
cat("======================================================================\n")
cat(sprintf("📁 Output files available in current directory\n"))
cat(sprintf("🌐 Interactive HTML file: %s\n", output_html))
cat("📖 To view, open the HTML file in your browser\n\n")
