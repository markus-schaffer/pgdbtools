#' Add Comment to Database Column
#'
#' Adds a comment to a specific column in a database table using SQL COMMENT statement.
#'
#' @param conn A database connection object (DBI connection)
#' @param table Character string specifying the table name
#' @param column Character string specifying the column name
#' @param comment Character string with the comment text to add
#'
#' @return Number of rows affected (typically 0 for DDL statements)
#'
#' @examples
#' \dontrun{
#' library(DBI)
#' conn <- dbConnect(...)
#' comment_on_column(conn, "my_table", "my_column", "This is a description")
#' }
#'
#' @export
comment_on_column <- function(conn, table, column, comment) {
  stopifnot(is.character(table), length(table) == 1, !is.na(table), nzchar(table))
  stopifnot(is.character(column), length(column) == 1, !is.na(column), nzchar(column))
  stopifnot(is.character(comment), length(comment) == 1, !is.na(comment), nzchar(comment))

  sql <- paste0("COMMENT ON COLUMN ", table, ".", column, " IS '", comment, "';")
  DBI::dbExecute(conn, sql)
}
