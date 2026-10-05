# Internal infrastructure for nobelprizer -------------------------------
# URL building, in-memory caching, HTTP handling and JSON parsing.
# None of these functions are exported; users only see get_nobel_prizes()
# and get_nobel_laureates() (defined in R/nobel_api.R).

.nobel_cache <- new.env(parent = emptyenv())

nobel_cache_get <- function(key) {
  if (exists(key, envir = .nobel_cache, inherits = FALSE)) {
    get(key, envir = .nobel_cache, inherits = FALSE)
  } else {
    NULL
  }
}

nobel_cache_set <- function(key, value) {
  assign(key, value, envir = .nobel_cache)
  invisible(value)
}

# Build a Nobel API v2 URL, dropping NULL query parameters.
nobel_url <- function(endpoint, ...) {
  base <- paste0("https://api.nobelprize.org/2.1/", endpoint)
  qs <- list(...)
  qs <- qs[!vapply(qs, is.null, logical(1))]
  if (length(qs) == 0) {
    return(base)
  }
  parts <- vapply(names(qs), function(nm) {
    paste0(nm, "=", utils::URLencode(as.character(qs[[nm]]), reserved = TRUE))
  }, character(1))
  paste0(base, "?", paste(parts, collapse = "&"))
}

# Core request handler: cached GET against the Nobel API v2.
nobel_request <- function(endpoint, ...) {
  url <- nobel_url(endpoint, ...)
  cached <- nobel_cache_get(url)
  if (!is.null(cached)) {
    return(cached)
  }
  resp <- httr::GET(url, httr::user_agent("nobelprizer (https://github.com/yourname/nobelprizer)"))
  if (httr::http_error(resp)) {
    stop("Nobel API request failed [", resp$status_code, "]: ", url, call. = FALSE)
  }
  txt <- httr::content(resp, as = "text", encoding = "UTF-8")
  data <- jsonlite::fromJSON(txt, simplifyVector = FALSE)
  nobel_cache_set(url, data)
  data
}

# Validate the category argument (NULL means "all categories").
validate_category <- function(category) {
  valid <- c("Physics", "Chemistry", "Medicine", "Economics",
             "Literature", "Peace")
  if (is.null(category)) {
    return(NULL)
  }
  stopifnot(is.character(category), length(category) == 1)
  category <- trimws(category)
  if (!category %in% valid) {
    stop("category must be one of: ",
         paste(valid, collapse = ", "), call. = FALSE)
  }
  category
}


# Parse one raw "laureates" response into a tidy data.frame.
# Each row is one laureate-prize combination, so a person who won twice
# appears in two rows. Age can be derived later as award_year - birth year.
nobel_parse_laureates <- function(raw) {
  rows <- lapply(raw$laureates, function(l) {
    prizes <- l$nobelPrizes %||% list()
    if (length(prizes) == 0) {
      prizes <- list(list())
    }
    lapply(prizes, function(p) {
      #
      aff <- p$affiliations[[1]] %||% list()
      data.frame(
        id              = l$id,
        name            = l$knownName$en %||% (l$fullName$en %||% NA_character_),
        gender          = l$gender %||% NA_character_,
        birth_date      = l$birth$date %||% NA_character_,
        death_date      = l$death$date %||% NA_character_,
        birth_city      = l$birth$place$city$en %||% NA_character_,
        birth_country   = l$birth$place$country$en %||% NA_character_,
        affiliation     = aff$name$en %||% NA_character_,
        aff_city        = aff$city$en %||% NA_character_,
        aff_country     = aff$country$en %||% NA_character_,
        award_year      = as.integer(p$awardYear %||% NA_integer_),
        category        = p$category$en %||% NA_character_,
        prize_amount    = as.numeric(p$prizeAmount %||% NA_real_),
        motivation      = p$motivation$en %||% NA_character_,
        profile_url = l$links[[2]]$href %||% NA_character_,
        stringsAsFactors = FALSE
      )
    })
  })
  if (length(rows) == 0) {
    return(data.frame())
  }
  do.call(rbind, unlist(rows, recursive = FALSE))
}

