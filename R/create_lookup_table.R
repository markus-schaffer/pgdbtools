#' Create Lookup Table with Auto-Sync Trigger
#'
#' Creates a lookup table that automatically synchronizes with a source table using
#' database triggers. The lookup table will contain distinct values from a specified
#' column and will be kept in sync via a trigger function.
#'
#' @param conn A database connection object (DBI connection)
#' @param lookup_table Character string specifying the name for the lookup table
#' @param source_table Character string specifying the source table name
#' @param column_name Character string specifying the column to create lookup for
#' @param column_type Character string specifying the SQL data type for the column.
#'   Default is "CHAR(64)"
#'
#' @return NULL (invisible). Function is called for its side effects (creating table and trigger)
#'
#' @details
#' This function performs three operations:
#' \enumerate{
#'   \item Creates the lookup table with the specified column as primary key
#'   \item Populates it with distinct non-NULL values from the source table
#'   \item Creates a trigger to keep the lookup table synchronized with changes
#' }
#'
#' The trigger uses the \code{sync_lookup_generic} function which must be created
#' first using \code{\link{generic_lookup}}.
#'
#' @examples
#' \dontrun{
#' library(DBI)
#' conn <- dbConnect(...)
#' generic_lookup(conn)
#' create_lookup_table(conn, "status_lookup", "events", "status")
#' }
#'
#' @seealso \code{\link{generic_lookup}}
#'
#' @export
create_lookup_table <- function(conn, lookup_table, source_table, column_name, column_type = "CHAR(64)") {
  stopifnot(is.character(lookup_table), length(lookup_table) == 1, !is.na(lookup_table), nzchar(lookup_table))
  stopifnot(is.character(source_table), length(source_table) == 1, !is.na(source_table), nzchar(source_table))
  stopifnot(is.character(column_name), length(column_name) == 1, !is.na(column_name), nzchar(column_name))
  stopifnot(is.character(column_type), length(column_type) == 1, !is.na(column_type), nzchar(column_type))

  create_sql <- paste0(
    "CREATE TABLE IF NOT EXISTS ", lookup_table, " (",
    column_name, " ", column_type, " PRIMARY KEY);"
  )
  DBI::dbExecute(conn, create_sql)

  insert_sql <- paste0(
    "INSERT INTO ", lookup_table, " (", column_name, ") ",
    "SELECT DISTINCT ", column_name, " FROM ", source_table, " ",
    "WHERE ", column_name, " IS NOT NULL;"
  )
  DBI::dbExecute(conn, insert_sql)

  trigger_name <- paste0(gsub("\\.", "_", source_table), "_", column_name, "_sync_lookup")
  trigger_exists_sql <- paste0(
    "SELECT EXISTS (",
    "SELECT 1 FROM pg_trigger t ",
    "JOIN pg_class c ON c.oid = t.tgrelid ",
    "JOIN pg_namespace n ON n.oid = c.relnamespace ",
    "WHERE t.tgname = ", trigger_name, " ",
    "AND c.relname = ", source_table, " ",
    "AND n.nspname = current_schema()",
    ");"
  )

  trigger_exists <- DBI::dbGetQuery(conn, trigger_exists_sql)[[1]]

  if (!isTRUE(trigger_exists)) {
    trigger_sql <- paste0(
      "CREATE TRIGGER ", trigger_name, " ",
      "AFTER INSERT OR DELETE OR UPDATE ON ", source_table, " ",
      "FOR EACH ROW EXECUTE FUNCTION sync_lookup_generic(",
      lookup_table, ", ", column_name, ");"
    )
    DBI::dbExecute(conn, trigger_sql)
  }

  invisible(NULL)
}

