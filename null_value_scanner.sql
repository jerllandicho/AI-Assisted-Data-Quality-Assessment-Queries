DO $$
DECLARE
    r RECORD;
    null_expressions TEXT;
BEGIN

    DROP TABLE IF EXISTS pg_temp.null_report;
    DROP TABLE IF EXISTS pg_temp.null_scan_errors;

    CREATE TEMP TABLE null_report (
        table_schema TEXT,
        table_name TEXT,
        column_name TEXT,
        total_rows BIGINT,
        null_count BIGINT,
        null_percentage NUMERIC(10,2)
    );

    CREATE TEMP TABLE null_scan_errors (
        table_schema TEXT,
        table_name TEXT,
        error_message TEXT
    );

    FOR r IN
        SELECT
            table_schema,
            table_name
        FROM information_schema.tables
        WHERE table_type = 'BASE TABLE'
          AND table_schema NOT IN (
              'information_schema',
              'pg_catalog'
          )
          AND table_schema NOT LIKE 'pg_temp_%' ESCAPE ''
          AND table_schema NOT LIKE 'pg_toast%'
        ORDER BY table_schema, table_name
    LOOP

        SELECT string_agg(
            format(
                '%L, COUNT(*) FILTER (WHERE %I IS NULL)',
                column_name,
                column_name
            ),
            ', ' ORDER BY ordinal_position
        )
        INTO null_expressions
        FROM information_schema.columns
        WHERE table_schema = r.table_schema
          AND table_name = r.table_name;

        IF null_expressions IS NOT NULL THEN
	BEGIN

                EXECUTE format(
                    'INSERT INTO pg_temp.null_report
                     SELECT
                         %L,
                         %L,
                         j.key,
                         t.total_rows,
                         j.value::BIGINT,
                         ROUND(
                             (j.value::NUMERIC /
                              NULLIF(t.total_rows, 0)) * 100,
                             2
                         )
                     FROM (
                         SELECT
                             COUNT(*) AS total_rows,
                             jsonb_build_object(%s) AS null_counts
                         FROM %I.%I
                     ) AS t
                     CROSS JOIN LATERAL
                         jsonb_each_text(t.null_counts) AS j
                     WHERE j.value::BIGINT > 0',
                    r.table_schema,
                    r.table_name,
                    null_expressions,
                    r.table_schema,
                    r.table_name
                );

            EXCEPTION WHEN OTHERS THEN

                INSERT INTO pg_temp.null_scan_errors
                VALUES (
                    r.table_schema,
                    r.table_name,
                    SQLERRM
                );

            END;

        END IF;

    END LOOP;

END $$;


-- NULL REPORT
SELECT *
FROM null_report
ORDER BY
    null_percentage DESC,
    table_schema,
    table_name,
    column_name;


-- TABLES THAT COULD NOT BE SCANNED
SELECT *
FROM null_scan_errors
ORDER BY table_schema, table_name;