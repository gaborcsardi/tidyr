check_spec <- function(spec) {
  # Eventually should just be vec_assert() on partial_frame()
  # Waiting for https://github.com/r-lib/vctrs/issues/198

  if (!is.data.frame(spec)) {
    stop("`spec` must be a data frame", call. = FALSE)
  }

  if (!has_name(spec, ".name") || !has_name(spec, ".value")) {
    stop("`spec` must have `.name` and `.value` columns", call. = FALSE)
  }

  if (!is.character(spec$.name)) {
    abort("The `.name` column must be a character vector.")
  }
  if (vec_duplicate_any(spec$.name)) {
    abort("The `.name` column must be unique.")
  }

  if (!is.character(spec$.value)) {
    abort("The `.value` column must be a character vector.")
  }

  # Ensure .name and .value come first
  vars <- union(c(".name", ".value"), names(spec))
  spec[vars]
}

wrap_error_names <- function(code) {
  withCallingHandlers(
    code,
    vctrs_error_names = function(cnd) {
      cnd$arg <- "names_repair"
      cnd_signal(cnd)
    }
  )
}
