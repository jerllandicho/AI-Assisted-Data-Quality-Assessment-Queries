
# Database-Wide NULL Value Scanner (PostgreSQL)

## Description
A PostgreSQL script that dynamically scans database base tables and identifies columns containing NULL values. It calculates NULL counts and percentages to help assess database completeness and data quality.

## Features
- Automatically identifies base tables across accessible schemas.
- Scans individual columns for NULL values.
- Calculates NULL counts and percentages.
- Records scanning errors separately.
- Sorts results by NULL percentage in descending order.

## How It Works
1. Retrieves base tables from `information_schema`.
2. Identifies the columns of each table.
3. Dynamically generates SQL expressions to count NULL values.
4. Calculates NULL percentages based on each table's total row count.
5. Stores results in temporary tables.
6. Records tables that encounter scanning errors.

**Formula:**

`NULL Percentage = (NULL Count / Total Rows) × 100`

## Instructions
1. Connect to the target PostgreSQL database.
2. Open `null_value_scanner.sql` in your SQL client.
3. Execute the script from the beginning up to and including the first SELECT query (**NULL REPORT**).
4. Review the results.
5. The second SELECT query (**TABLES THAT COULD NOT BE SCANNED**) is optional and can be executed separately to view scanning errors.

**Important:** Execute the scanning block and result queries within the same database session because the temporary tables are session-specific.

## Output

### 1. NULL REPORT
- `table_schema` – Schema name.
- `table_name` – Table name.
- `column_name` – Column containing NULL values.
- `total_rows` – Total number of table rows.
- `null_count` – Number of NULL values.
- `null_percentage` – Percentage of NULL values.

<img width="686" height="412" alt="image" src="https://github.com/user-attachments/assets/1f3aa543-fa8f-426e-86b9-cca34ac97fe6" />

### 2. TABLES THAT COULD NOT BE SCANNED
- `table_schema` – Schema name.
- `table_name` – Affected table.
- `error_message` – Scanning error returned by PostgreSQL.

## Compatibility
Originally written for PostgreSQL, this query can be adapted to other SQL dialects and database systems.

Simply ask an AI tool of your choice to modify the query to make it compatible with your preferred SQL dialect or database system. Always review and test the adapted version before execution.

*As proof that this works, I attached a MySQL version of the query below*
<img width="524" height="531" alt="image" src="https://github.com/user-attachments/assets/7d24f510-0a2d-4bcf-bea8-704b349f18a9" />

## Limitations & Notes
- Scans base tables only; views are excluded.
- Excludes specified system, temporary, and TOAST schemas.
- Columns without NULL values are omitted from the report.
- Requires sufficient database access privileges.
- Large databases may require considerable execution time and resources.
- Empty tables produce no NULL report entries.
- Scanning errors do not necessarily mean a table contains no NULL values.
- Uses temporary tables that disappear when the database session ends.
- Does not modify, delete, or clean existing database records.
- Results reflect the data visible during the scanning transaction.

## Disclaimer
This script is intended for database inspection, profiling, and NULL value detection. It does not automatically correct or remove NULL values.
