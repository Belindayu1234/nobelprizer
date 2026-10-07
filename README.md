# nobelprizer
<!-- badges: start -->
[![R-CMD-check](https://github.com/Belindayu1234/nobelprizer/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Belindayu1234/nobelprizer/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of nobelprizer is to retrieve Nobel Prize data from the public Nobel Prize API.

## Installation
You can install the development version of nobelprizer from GitHub:

```r
# install.packages("pak")
pak::pak("Belindayu1234/nobelprizer")
```

## Launch Shiny application
```
app_location <- system.file("app", package = "nobelprizer")
shiny::runApp(app_location)
```

## Project structure
```
nobelprizer/
├── .github/
│   └── workflows/          # GitHub‑Actions CI workflow files
├── R/
│   ├─ nobel_request.R      # Internal infrastructure: URL‑build, cache, HTTP, JSON parsing
│   └─ nobel_api.R          # Exported public user‑facing functions
├── inst/
│   └─ app/
│       └─ app.R            # Shiny interactive explorer (* master exercise)
├── tests/
│   ├─ testthat.R           # testthat runner
│   └─ testthat/
│       └─ test‑nobelprizer.R  # Unit test cases
├── vignettes/
│   └─ nobelprizer_intro.Rmd   # Package usage vignette
├── man/                     # Auto‑generated function help pages (roxygen2)
├── DESCRIPTION
├── NAMESPACE
├── .Rbuildignore
├── .gitignore
├── LICENSE
├── LICENSE.md
├── nobelprizer.Rproj
└── README.md
```

## Example
This basic example shows how to fetch Nobel Prize data:

```r
library(nobelprizer)
# Get Nobel prize records
prizes <- get_nobel_prizes()
head(prizes)
```

## Overview
This R package provides an easy-to-use interface to download Nobel laureate and prize information.
The main function `get_nobel_prizes()` returns a tidy data frame containing prize metadata.
