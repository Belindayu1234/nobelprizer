#' Fetch Nobel Prize laureates
#'
#' Queries the Nobel Prize API (v2) for laureates, optionally filtered by
#' category, year and gender. Returns one row per laureate-prize combination.
#'
#' @param category Optional character string, one of "Physics",
#'   "Chemistry", "Medicine", "Economics", "Literature" or "Peace".
#'   Default NULL returns all categories.
#' @param year Optional integer; a single award year.
#' @param gender Optional character string, one of "male" or "female".
#' @param limit Maximum number of laureates to fetch.
#'
#' @return A data.frame containing laureate and prize information.
#'
#' @examples
#' \dontrun{
#' get_nobel_laureates(category = "Physics")
#' get_nobel_laureates(category = "Chemistry", gender = "female")
#' }
#'
#' @references \url{https://www.nobelprize.org/about/developer-zone-2/}
#'
#' @export
get_nobel_laureates <- function(category = NULL, year = NULL,
                                gender = NULL, limit = 1050) {
  category <- validate_category(category)

  if (!is.null(year)) {
    stopifnot(is.numeric(year), length(year) == 1, year >= 1901)
  }

  if (!is.null(gender)) {
    stopifnot(gender %in% c("male", "female"))
  }

  raw <- nobel_request(
    "laureates",
    nobelPrizeYear = year,
    nobelPrizeCategory = category,
    gender = gender,
    limit = limit
  )

  nobel_parse_laureates(raw)
}
