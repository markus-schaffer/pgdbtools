# pgdbtools

<!-- badges: start -->
[![R-CMD-check](https://github.com/markus-schaffer/pgdbtools/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/markus-schaffer/pgdbtools/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->


PostgreSQL database utility functions for R.

## Scope and Dependencies

- **PostgreSQL-only**: this package generates PostgreSQL-specific SQL (including triggers and PL/pgSQL trigger functions).
- **DB interface**: requires the `DBI` package.
- **Database backend**: use a PostgreSQL DBI backend such as `RPostgres`.

## Installation

```r
# Install remotes if needed
install.packages("remotes")

# Install from GitHub
remotes::install_github("markus-schaffer/pgdbtools")
```

## Functions

### Table and Column Comments

- `comment_on_table(conn, table, comment)` — Add a SQL comment to a database table
- `comment_on_column(conn, table, column, comment)` — Add a SQL comment to a specific column

### Lookup Tables

- `generic_lookup(conn)` — Install the PostgreSQL `sync_lookup_generic` trigger function
- `create_lookup_table(conn, lookup_table, source_table, column_name, column_type)` — Create an auto-synchronising lookup table backed by a trigger

## Workflow for Lookup Setup

1. Call `generic_lookup(conn)` once per database (or after replacing the trigger function).
2. Call `create_lookup_table(...)` for each source table/column pair.

## Example

```r
library(DBI)
library(RPostgres)
library(pgdbtools)

conn <- dbConnect(...)

# Add comments
comment_on_table(conn, "my_table", "Contains raw smart meter readings")
comment_on_column(conn, "my_table", "meter_id", "Unique meter identifier")

# Create a lookup table that stays in sync with the source table
generic_lookup(conn)
create_lookup_table(conn, "status_lookup", "readings", "status")
```
