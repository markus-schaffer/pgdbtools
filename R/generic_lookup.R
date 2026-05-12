#' Generic Lookup Synchronization SQL Function
#'
#' Installs a PostgreSQL trigger function that maintains lookup tables
#' by automatically syncing them with source tables on INSERT, UPDATE, and DELETE
#' operations.
#'
#' @param conn A database connection object (DBI connection)
#'
#' @details
#' This creates a PL/pgSQL function named \code{sync_lookup_generic} that:
#' \itemize{
#'   \item Inserts new values into the lookup table when rows are inserted
#'   \item Updates the lookup table when values change
#'   \item Removes values from lookup table only if they are no longer used anywhere
#'   \item Handles NULL values appropriately
#' }
#'
#' The function expects two arguments when called from a trigger:
#' \enumerate{
#'   \item TG_ARGV[0]: The lookup table name
#'   \item TG_ARGV[1]: The column name to sync
#' }
#'
#' Execute this function before using \code{\link{create_lookup_table}}.
#'
#' @examples
#' \dontrun{
#' library(DBI)
#' conn <- dbConnect(...)
#' generic_lookup(conn)
#' }
#'
#' @seealso \code{\link{create_lookup_table}}
#'
#' @export
generic_lookup <- function(conn) {
  sql <- "CREATE OR REPLACE FUNCTION sync_lookup_generic()
  RETURNS TRIGGER AS $$
  DECLARE
      lookup_table TEXT := TG_ARGV[0];
      column_name TEXT := TG_ARGV[1];
      new_value TEXT;
      old_value TEXT;
  BEGIN
      IF TG_OP IN ('INSERT', 'UPDATE') THEN
          EXECUTE format('SELECT ($1).%I::text', column_name) INTO new_value USING NEW;
      END IF;
      IF TG_OP IN ('DELETE', 'UPDATE') THEN
          EXECUTE format('SELECT ($1).%I::text', column_name) INTO old_value USING OLD;
      END IF;
      IF TG_OP = 'INSERT' THEN
          EXECUTE format(
              'INSERT INTO %I (%I) VALUES ($1) ON CONFLICT (%I) DO NOTHING',
              lookup_table, column_name, column_name
          ) USING new_value;
      END IF;
      IF TG_OP = 'DELETE' THEN
          EXECUTE format(
              'DELETE FROM %I WHERE %I = $1 AND NOT EXISTS (SELECT 1 FROM %I WHERE %I = $1)',
              lookup_table, column_name, TG_TABLE_NAME, column_name
          ) USING old_value;
      END IF;
      IF TG_OP = 'UPDATE' AND old_value IS DISTINCT FROM new_value THEN
          EXECUTE format(
              'INSERT INTO %I (%I) VALUES ($1) ON CONFLICT (%I) DO NOTHING',
              lookup_table, column_name, column_name
          ) USING new_value;
          EXECUTE format(
              'DELETE FROM %I WHERE %I = $1 AND NOT EXISTS (SELECT 1 FROM %I WHERE %I = $1)',
              lookup_table, column_name, TG_TABLE_NAME, column_name
          ) USING old_value;
      END IF;
      RETURN NULL;
  END;
  $$ LANGUAGE plpgsql;
  "
  DBI::dbExecute(conn, sql)
}
