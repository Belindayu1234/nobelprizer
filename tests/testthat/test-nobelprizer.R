# test-nobelprizer.R
# 1. Test whether the function returns a data.frame
test_that("returns a data.frame", {
  x <- get_nobel_laureates(limit = 5)
  expect_s3_class(x, "data.frame")
})


# 2. Test whether the returned data contains the main expected columns
test_that("important columns exist", {
  x <- get_nobel_laureates(limit = 5)

  expect_true(all(c(
    "name",
    "gender",
    "award_year",
    "category"
  ) %in% names(x)))
})


# 3. Test whether invalid inputs are correctly rejected
test_that("invalid input gives an error", {
  expect_error(get_nobel_laureates(year = 1800))
  expect_error(get_nobel_laureates(gender = "unknown"))
})


# 4. Test whether a known Nobel laureate can be found for known inputs
test_that("known result can be found", {
  x <- get_nobel_laureates(
    year = 1921,
    category = "Physics",
    limit = 10
  )

  expect_true(any(grepl("Einstein", x$name, ignore.case = TRUE)))
})
