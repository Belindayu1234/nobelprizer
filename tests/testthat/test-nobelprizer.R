test_that("nobel_url correctly drop NULL query params and encode url", {
  u1 <- nobel_url("laureates", category = "Physics", year = NULL)
  expect_match(u1, "category=Physics")
  expect_no_match(u1, "year=")

  u2 <- nobel_url("laureates")
  expect_match(u2, "https://api.nobelprize.org/2.1/laureates")
})

test_that("validate_category rejects invalid category values", {
  expect_null(validate_category(NULL))
  expect_equal(validate_category("Chemistry"), "Chemistry")
  expect_error(validate_category("MarsScience"), "category must be one of")
  expect_error(validate_category(c("Physics","Peace")), "length")
})

test_that("in‑memory cache environment getter/setter work", {
  key <- "test‑url‑123"
  nobel_cache_set(key, list(test=123))
  res <- nobel_cache_get(key)
  expect_equal(res$test,123)
  expect_null(nobel_cache_get("nonexist‑key‑999"))
})

test_that("nobel_parse_laureates handle empty input gracefully", {
  empty_input <- list(laureates = list())
  df_out <- nobel_parse_laureates(empty_input)
  expect_s3_class(df_out, "data.frame")
  expect_equal(nrow(df_out),0)
})

test_that("nobel_parse_laureates expand multiple prizes per laureate to multiple rows", {
  mock_raw <- list(
    laureates = list(
      list(
        id = "1001",
        knownName = list(en = "Sample Person"),
        gender = "male",
        birth = list(place = list(country = list(en = "Sweden"))),
        nobelPrizes = list(
          list(awardYear = "2000", category = list(en="Physics")),
          list(awardYear = "2010", category = list(en="Chemistry"))
        )
      )
    )
  )
  df <- nobel_parse_laureates(mock_raw)
  expect_equal(nrow(df),2)
  expect_equal(sort(df$category), c("Chemistry","Physics"))
})



# FIX 1: Test the exported get_nobel_laureates() function
test_that("get_nobel_laureates filters Physics correctly", {

  mock_raw <- list(
    laureates = list(
      list(
        id = "1001",
        knownName = list(en = "Sample Person"),
        gender = "male",
        nobelPrizes = list(
          list(
            awardYear = "2000",
            category = list(en = "Physics")
          ),
          list(
            awardYear = "2010",
            category = list(en = "Chemistry")
          )
        )
      )
    )
  )

  local_mocked_bindings(
    nobel_request = function(...) mock_raw
  )

  df <- get_nobel_laureates(category = "Physics")

  expect_equal(nrow(df), 1)
  expect_equal(df$category, "Physics")
  expect_equal(df$award_year, 2000)
})


# FIX 2: Test filtering by award year
test_that("get_nobel_laureates filters year correctly", {

  mock_raw <- list(
    laureates = list(
      list(
        id = "1001",
        knownName = list(en = "Sample Person"),
        gender = "male",
        nobelPrizes = list(
          list(
            awardYear = "2000",
            category = list(en = "Physics")
          ),
          list(
            awardYear = "2010",
            category = list(en = "Chemistry")
          )
        )
      )
    )
  )

  local_mocked_bindings(
    nobel_request = function(...) mock_raw
  )

  df <- get_nobel_laureates(year = 2000)

  expect_equal(nrow(df), 1)
  expect_equal(df$award_year, 2000)
  expect_equal(df$category, "Physics")
})


# FIX 3: Test organisation names
test_that("get_nobel_laureates includes organisation names", {

  mock_raw <- list(
    laureates = list(
      list(
        id = "1002",
        orgName = list(
          en = "International Committee of the Red Cross"
        ),
        nobelPrizes = list(
          list(
            awardYear = "1963",
            category = list(en = "Peace")
          )
        )
      )
    )
  )

  local_mocked_bindings(
    nobel_request = function(...) mock_raw
  )

  df <- get_nobel_laureates(category = "Peace")

  expect_equal(nrow(df), 1)
  expect_equal(
    df$name,
    "International Committee of the Red Cross"
  )
  expect_equal(df$category, "Peace")
  expect_equal(df$award_year, 1963)
})

# FIX4 test the API code
test_that("get_nobel_laureates sends Nobel API category codes", {

  mock_raw <- list(laureates = list())

  local_mocked_bindings(
    nobel_request = function(endpoint, ...) {
      params <- list(...)

      expect_equal(endpoint, "laureates")
      expect_equal(params$nobelPrizeCategory, "phy")

      mock_raw
    }
  )

  get_nobel_laureates(category = "Physics")
})







