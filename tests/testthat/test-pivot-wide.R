test_that("can pivot all cols to wide", {
  df <- tibble(key = c("x", "y", "z"), val = 1:3)
  pv <- pivot_wider(df, names_from = key, values_from = val)

  expect_named(pv, c("x", "y", "z"))
  expect_equal(nrow(pv), 1)
})

test_that("non-pivoted cols are preserved", {
  df <- tibble(a = 1, key = c("x", "y"), val = 1:2)
  pv <- pivot_wider(df, names_from = key, values_from = val)

  expect_named(pv, c("a", "x", "y"))
  expect_equal(nrow(pv), 1)
})

test_that("implicit missings turn into explicit missings", {
  df <- tibble(a = 1:2, key = c("x", "y"), val = 1:2)
  pv <- pivot_wider(df, names_from = key, values_from = val)

  expect_equal(pv$a, c(1, 2))
  expect_equal(pv$x, c(1, NA))
  expect_equal(pv$y, c(NA, 2))
})

test_that("error when overwriting existing column", {
  df <- tibble(
    a = c(1, 1),
    key = c("a", "b"),
    val = c(1, 2)
  )

  expect_snapshot(
    (expect_error(pivot_wider(df, names_from = key, values_from = val)))
  )

  expect_snapshot(
    out <- pivot_wider(df, names_from = key, values_from = val, names_repair = "unique")
  )
  expect_named(out, c("a...1", "a...2", "b"))
})

test_that("`names_repair` happens after spec column reorganization (#1107)", {
  df <- tibble(
    test = c("a", "b"),
    name = c("test", "test2"),
    value = c(1, 2)
  )

  out <- pivot_wider(df, names_repair = ~make.unique(.x))

  expect_identical(out$test, c("a", "b"))
  expect_identical(out$test.1, c(1, NA))
  expect_identical(out$test2, c(NA, 2))
})

test_that("minimal `names_repair` doesn't overwrite a value column that collides with key column (#1107)", {
  df <- tibble(
    test = c("a", "b"),
    name = c("test", "test2"),
    value = c(1, 2)
  )

  out <- pivot_wider(df, names_repair = "minimal")

  expect_identical(out[[1]], c("a", "b"))
  expect_identical(out[[2]], c(1, NA))
  expect_identical(out[[3]], c(NA, 2))
})

test_that("grouping is preserved", {
  df <- tibble(g = 1, k = "x", v = 2)
  out <- df %>%
    dplyr::group_by(g) %>%
    pivot_wider(names_from = k, values_from = v)
  expect_equal(dplyr::group_vars(out), "g")
})

# https://github.com/tidyverse/tidyr/issues/804
test_that("column with `...j` name can be used as `names_from`", {
  df <- tibble(...8 = c("x", "y", "z"), val = 1:3)
  pv <- pivot_wider(df, names_from = ...8, values_from = val)
  expect_named(pv, c("x", "y", "z"))
  expect_equal(nrow(pv), 1)
})

test_that("data frame columns pivot correctly", {
  df <- tibble(
    i = c(1, 2, 1, 2),
    g = c("a", "a", "b", "b"),
    d = tibble(x = 1:4, y = 5:8)
  )

  out <- pivot_wider(df, names_from = g, values_from = d)
  expect_equal(out$a$x, 1:2)
  expect_equal(out$b$y, 7:8)
})

test_that("works with data.table and empty key_vars", {
  dt <- data.table::data.table(n = "a", v = 1)
  expect_equal(
    pivot_wider(dt, names_from = n, values_from = v),
    tibble(a = 1)
  )
})

test_that("`names_from` must be supplied if `name` isn't in `data` (#1240)", {
  df <- tibble(key = "x", val = 1)
  expect_snapshot((expect_error(pivot_wider(df, values_from = val))))
})

test_that("`values_from` must be supplied if `value` isn't in `data` (#1240)", {
  df <- tibble(key = "x", val = 1)
  expect_snapshot((expect_error(pivot_wider(df, names_from = key))))
})

test_that("`names_from` must identify at least 1 column (#1240)", {
  df <- tibble(key = "x", val = 1)
  expect_snapshot(
    (expect_error(pivot_wider(df, names_from = starts_with("foo"), values_from = val)))
  )
})

test_that("`values_from` must identify at least 1 column (#1240)", {
  df <- tibble(key = "x", val = 1)
  expect_snapshot(
    (expect_error(pivot_wider(df, names_from = key, values_from = starts_with("foo"))))
  )
})

test_that("`values_fn` emits an informative error when it doesn't result in unique values (#1238)", {
  df <- tibble(name = c("a", "a"), value = c(1, 2))
  expect_snapshot(
    (expect_error(pivot_wider(df, values_fn = list(value = ~.x))))
  )
})

test_that("can pivot a manual spec with spec columns that don't identify any rows (#1250)", {
  # Looking for `x = 1L`
  spec <- tibble(.name = "name", .value = "value", x = 1L)

  # But that doesn't exist here...
  df <- tibble(key = "a", value = 1L, x = 2L)
  expect_identical(
    pivot_wider_spec(df, spec, id_cols = key),
    tibble(key = "a", name = NA_integer_)
  )

  # ...or here
  df <- tibble(key = character(), value = integer(), x = integer())
  expect_identical(
    pivot_wider_spec(df, spec, id_cols = key),
    tibble(key = character(), name = integer())
  )
})

test_that("pivoting with a manual spec and zero rows results in zero rows (#1252)", {
  spec <- tibble(.name = "name", .value = "value", x = 1L)

  df <- tibble(value = integer(), x = integer())
  expect_identical(pivot_wider_spec(df, spec), tibble(name = integer()))
})

# column names -------------------------------------------------------------

test_that("names_glue affects output names", {
  df <- tibble(
    x = c("X", "Y"),
    y = 1:2,
    a = 1:2,
    b = 1:2
  )

  spec <- build_wider_spec(df, x:y, a:b, names_glue = '{x}{y}_{.value}')
  expect_equal(spec$.name, c("X1_a", "Y2_a", "X1_b", "Y2_b"))
})

test_that("can sort column names", {
  df <- tibble(
    int = c(1, 3, 2),
    fac = factor(int, levels = 1:3, labels = c("Mon", "Tue", "Wed")),
  )
  spec <- build_wider_spec(df,
    names_from = fac,
    values_from = int,
    names_sort = TRUE
  )
  expect_equal(spec$.name, levels(df$fac))
})

# keys ---------------------------------------------------------

test_that("can override default keys", {
  df <- tribble(
    ~row, ~name, ~var, ~value,
    1,    "Sam", "age", 10,
    2,    "Sam", "height", 1.5,
    3,    "Bob", "age", 20,
  )

  pv <- df %>% pivot_wider(id_cols = name, names_from = var, values_from = value)
  expect_equal(nrow(pv), 2)
})


# non-unique keys ---------------------------------------------------------

test_that("duplicated keys produce list column with warning", {
  df <- tibble(a = c(1, 1, 2), key = c("x", "x", "x"), val = 1:3)

  expect_snapshot(pv <- pivot_wider(df, names_from = key, values_from = val))

  expect_equal(pv$a, c(1, 2))
  expect_equal(as.list(pv$x), list(c(1L, 2L), 3L))
})

test_that("duplicated key warning occurs for each applicable column", {
  df <- tibble(
    key = c("x", "x"),
    a = c(1, 2),
    b = c(3, 4),
    c = c(5, 6)
  )

  expect_snapshot(
    pivot_wider(
      df,
      names_from = key,
      values_from = c(a, b, c),
      values_fn = list(b = sum)
    )
  )
})

test_that("warning suppressed by supplying values_fn", {
  df <- tibble(a = c(1, 1, 2), key = c("x", "x", "x"), val = 1:3)
  expect_warning(
    pv <- pivot_wider(df,
      names_from = key,
      values_from = val,
      values_fn = list(val = list)
    ),
    NA
  )
  expect_equal(pv$a, c(1, 2))
  expect_equal(as.list(pv$x), list(c(1L, 2L), 3L))
})

test_that("values_fn can be a single function", {
  df <- tibble(a = c(1, 1, 2), key = c("x", "x", "x"), val = c(1, 10, 100))
  pv <- pivot_wider(df, names_from = key, values_from = val, values_fn = sum)
  expect_equal(pv$x, c(11, 100))
})

test_that("values_fn can be an anonymous function (#1114)", {
  df <- tibble(a = c(1, 1, 2), key = c("x", "x", "x"), val = c(1, 10, 100))
  pv <- pivot_wider(df, names_from = key, values_from = val, values_fn = ~sum(.x))
  expect_equal(pv$x, c(11, 100))
})

test_that("values_fn applied even when no-duplicates", {
  df <- tibble(a = c(1, 2), key = c("x", "x"), val = 1:2)
  pv <- pivot_wider(df,
    names_from = key,
    values_from = val,
    values_fn = list(val = list)
  )

  expect_equal(pv$a, c(1, 2))
  expect_equal(as.list(pv$x), list(1L, 2L))
})

test_that("values_fn is validated", {
  df <- tibble(name = "x", value = 1L)
  expect_snapshot(
    (expect_error(pivot_wider(df, values_fn = 1)))
  )
})

# can fill missing cells --------------------------------------------------

test_that("can fill in missing cells", {
  df <- tibble(g = c(1, 2), var = c("x", "y"), val = c(1, 2))

  widen <- function(...) {
    df %>% pivot_wider(names_from = var, values_from = val, ...)
  }

  expect_equal(widen()$x, c(1, NA))
  expect_equal(widen(values_fill = 0)$x, c(1, 0))
  expect_equal(widen(values_fill = list(val = 0))$x, c(1, 0))
})

test_that("values_fill only affects missing cells", {
  df <- tibble(g = c(1, 2), names = c("x", "y"), value = c(1, NA))
  out <- pivot_wider(df, names_from = names, values_from = value, values_fill = 0 )
  expect_equal(out$y, c(0, NA))
})

# multiple values ----------------------------------------------------------

test_that("can pivot from multiple measure cols", {
  df <- tibble(row = 1, var = c("x", "y"), a = 1:2, b = 3:4)
  sp <- build_wider_spec(df, names_from = var, values_from = c(a, b))
  pv <- pivot_wider_spec(df, sp)

  expect_named(pv, c("row", "a_x", "a_y", "b_x", "b_y"))
  expect_equal(pv$a_x, 1)
  expect_equal(pv$b_y, 4)
})

test_that("can pivot from multiple measure cols using all keys", {
  df <- tibble(var = c("x", "y"), a = 1:2, b = 3:4)
  sp <- build_wider_spec(df, names_from = var, values_from = c(a, b))
  pv <- pivot_wider_spec(df, sp)

  expect_named(pv, c("a_x", "a_y", "b_x", "b_y"))
  expect_equal(pv$a_x, 1)
  expect_equal(pv$b_y, 4)
})

test_that("column order in output matches spec", {
  df <- tribble(
    ~hw,   ~name,  ~mark,   ~pr,
    "hw1", "anna",    95,  "ok",
    "hw2", "anna",    70, "meh",
  )

  # deliberately create weird order
  sp <- tribble(
    ~hw, ~.value,  ~.name,
    "hw1", "mark", "hw1_mark",
    "hw1", "pr",   "hw1_pr",
    "hw2", "pr",   "hw2_pr",
    "hw2", "mark", "hw2_mark",
  )

  pv <- pivot_wider_spec(df, sp)
  expect_named(pv, c("name", sp$.name))
})
