
-- Find read and write operation for all the tables

SELECT  OBJECT_SCHEMA_NAME(ddius.object_id) + '.' + OBJECT_NAME(ddius.object_id) AS [Object Name] ,
       CASE
        WHEN ( SUM(user_updates + user_seeks + user_scans + user_lookups) = 0 )
        THEN NULL
        ELSE CONVERT(DECIMAL(38,2), CAST(SUM(user_seeks + user_scans + user_lookups) AS DECIMAL)
                                    / CAST(SUM(user_updates + user_seeks + user_scans
                                               + user_lookups) AS DECIMAL) )
        END AS [Proportion of Reads] ,
       CASE
        WHEN ( SUM(user_updates + user_seeks + user_scans + user_lookups) = 0 )
        THEN NULL
        ELSE CONVERT(DECIMAL(38,2), CAST(SUM(user_updates) AS DECIMAL)
                                    / CAST(SUM(user_updates + user_seeks + user_scans
                                               + user_lookups) AS DECIMAL) )
        END AS [Proportion of Writes] ,
        SUM(user_seeks + user_scans + user_lookups) AS [Total Read Operations] ,
        SUM(user_updates) AS [Total Write Operations]
FROM    sys.dm_db_index_usage_stats AS ddius
        JOIN sys.indexes AS i ON ddius.object_id = i.object_id
                                 AND ddius.index_id = i.index_id
WHERE   i.type_desc IN ( 'CLUSTERED', 'HEAP' ) --only works in Current db
GROUP BY ddius.object_id
ORDER BY OBJECT_SCHEMA_NAME(ddius.object_id) + '.' + OBJECT_NAME(ddius.object_id)