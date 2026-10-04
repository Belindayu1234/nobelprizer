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

## Project structure
```
nobelprizer/
├── .github/workflows/   # GitHub Actions CI workflow
├── R/                   # R source functions
├── man/                 # Function documentation
├── tests/               # Unit tests
├── vignettes/           # Package vignette (introduction.Rmd)
├── DESCRIPTION
├── NAMESPACE
├── .gitignore
├── .Rbuildignore
└── nobelprizer.Rproj
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
