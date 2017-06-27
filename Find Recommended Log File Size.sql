--https://www.brentozar.com/archive/2016/02/no-but-really-how-big-should-my-log-file-be/
;
WITH    [log_size]
          AS ( SELECT TOP 1
                        SCHEMA_NAME([t].[schema_id]) AS [schema_name] ,
                        [t].[name] AS [table_name] ,
                        [i].[name] ,
                        [p].[rows] AS [row_count] ,
                        CAST(( SUM([a].[total_pages]) * 8. ) / 1024. / 1024. AS DECIMAL(18,
                                                              2)) AS [index_total_space_gb] ,
                        ( SUM([a].[total_pages]) * 8 ) / 1024 / 1024 * 2 AS [largest_index_times_two_(gb)] ,
                        ( SELECT    ( SUM([mf].[size]) * 8 ) / 1024 / 1024
                          FROM      [sys].[master_files] AS [mf]
                          WHERE     [mf].[database_id] = DB_ID() ) AS [database_size_(gb)] ,
                        ( SELECT    CAST(( SUM([mf].[size]) * 8 ) / 1024
                                    / 1024 AS INT)
                          FROM      [sys].[master_files] AS [mf]
                          WHERE     [mf].[database_id] = DB_ID()
                                    AND [mf].[type_desc] = 'LOG' ) AS [current_log_size_(gb)] ,
                        ( SELECT    CAST(( SUM([mf].[size]) * 8 ) / 1024
                                    / 1024 * .25 AS INT)
                          FROM      [sys].[master_files] AS [mf]
                          WHERE     [mf].[database_id] = DB_ID()
                                    AND [mf].[type_desc] = 'ROWS' ) AS [25%_of_database_(gb)]
               FROM     [sys].[tables] [t]
               INNER JOIN [sys].[indexes] [i]
               ON       [t].[object_id] = [i].[object_id]
               INNER JOIN [sys].[partitions] [p]
               ON       [i].[object_id] = [p].[object_id]
                        AND [i].[index_id] = [p].[index_id]
               INNER JOIN [sys].[allocation_units] [a]
               ON       [p].[partition_id] = [a].[container_id]
               WHERE    [t].[is_ms_shipped] = 0
               GROUP BY SCHEMA_NAME([t].[schema_id]) ,
                        [t].[name] ,
                        [i].[name] ,
                        [p].[rows]
               ORDER BY [index_total_space_gb] DESC)
     SELECT * ,
            CASE WHEN [ls].[largest_index_times_two_(gb)] > [ls].[25%_of_database_(gb)]
                 THEN [ls].[largest_index_times_two_(gb)]
                 ELSE [ls].[25%_of_database_(gb)]
            END AS [maybe_this_is_a_good_log_size(gb)]
     FROM   [log_size] AS [ls]
OPTION  ( RECOMPILE );