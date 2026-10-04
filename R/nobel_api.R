#' Get Nobel Prize basic information
#'
#' Get Nobel prizes data from official Nobel Prize API.
#'
#' @param category character, optional. One of "Physics", "Chemistry", "Medicine", "Literature", "Peace", "Economics"
#' @param year integer, optional. Prize year.
#' @return tibble
#' @importFrom httr GET stop_for_status content
#' @importFrom jsonlite fromJSON
#' @importFrom tibble as_tibble
#' @export
get_nobel_prizes <- function(category = NULL, year = NULL){

  base_url <- "https://api.nobelprize.org/v1/prize.json"

  query_list <- list()
  if(!is.null(category)) query_list[["category"]] <- category
  if(!is.null(year)) query_list[["year"]] <- year

  resp <- httr::GET(base_url, query = query_list)
  httr::stop_for_status(resp)

  raw <- jsonlite::fromJSON(httr::content(resp, "text"), simplifyDataFrame = TRUE)
  out <- tibble::as_tibble(raw$prizes)

  return(out)
}

