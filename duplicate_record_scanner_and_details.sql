---------------------------- DUPLICATE RECORD SCANNER ----------------------------

DO $$
DECLARE
    r RECORD;
    col_list TEXT;
BEGIN

    DROP TABLE IF EXISTS pg_temp.duplicate_report;

    CREATE TEMP TABLE duplicate_report (
        table_schema TEXT,
        table_name TEXT,
        duplicate_groups BIGINT,
        duplicate_rows BIGINT
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
          AND table_schema NOT LIKE 'pg_temp_%'
          AND table_schema NOT LIKE 'pg_toast%'
    LOOP

        SELECT string_agg(
            format('%I', column_name),
            ', ' ORDER BY ordinal_position
        )
        INTO col_list
        FROM information_schema.columns
        WHERE table_schema = r.table_schema
          AND table_name = r.table_name;

        IF col_list IS NOT NULL THEN

            EXECUTE format(
                'INSERT INTO pg_temp.duplicate_report
                 SELECT
                     %L,
                     %L,
                     COUNT(*),
                     COALESCE(SUM(cnt - 1), 0)
                 FROM (
                     SELECT COUNT(*) AS cnt
                     FROM %I.%I
                     GROUP BY %s
                     HAVING COUNT(*) > 1
                 ) AS duplicates',
                r.table_schema,
                r.table_name,
                r.table_schema,
                r.table_name,
                col_list
            );

        END IF;

    END LOOP;

END $$;

SELECT *
FROM duplicate_report
WHERE duplicate_groups > 0
ORDER BY table_schema, table_name;

---------------------------- DUPLICATE RECORD DETAILS ----------------------------

DROP TABLE IF EXISTS pg_temp.duplicate_records;

DO $$
DECLARE
    col_list TEXT;
BEGIN
    SELECT string_agg(
        format('%I', column_name),
        ', ' ORDER BY ordinal_position
    )
    INTO col_list
    FROM information_schema.columns
    WHERE table_schema = 'public'         -- CHANGE 1: Schema name
      AND table_name = 'duplicate_test';  -- CHANGE 2: Table name

    EXECUTE format(
        'CREATE TEMP TABLE duplicate_records AS
         SELECT *
         FROM (
             SELECT *,
                    COUNT(*) OVER (
                        PARTITION BY %s
                    ) AS duplicate_count
             FROM %I.%I
         ) AS duplicates
         WHERE duplicate_count > 1',
        col_list,
        'public',                          -- CHANGE 3: Schema name
        'duplicate_test'                   -- CHANGE 4: Table name
    );
END $$;

SELECT *
FROM duplicate_records; 