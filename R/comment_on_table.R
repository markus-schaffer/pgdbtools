#' Add Comment to Database Table
#'
#' Adds a comment to a database table using SQL COMMENT statement.
#'
#' @param conn A database connection object (DBI connection)
#' @param table Character string specifying the table name
#' @param comment Character string with the comment text to add
#'
#' @return Number of rows affected (typically 0 for DDL statements)
#'
#' @examples
#' \dontrun{
#' library(DBI)
#' conn <- dbConnect(...)
#' comment_on_table(conn, "my_table", "This table contains user data")
#' }
#'
#' @export
comment_on_table <- function(conn, table, comment) {
  stopifnot(is.character(table), length(table) == 1, !is.na(table), nzchar(table))
  stopifnot(is.character(comment), length(comment) == 1, !is.na(comment), nzchar(comment))

  table_id <- DBI::dbQuoteIdentifier(conn, table)
  comment_str <- DBI::dbQuoteString(conn, comment)

  sql <- paste0("COMMENT ON TABLE ", table_id, " IS ", comment_str, ";")
  DBI::dbExecute(conn, sql)
}
