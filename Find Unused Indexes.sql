DECLARE @dbid INT
    , @dbName VARCHAR(100);
 
SELECT @dbid = DB_ID()
    , @dbName = DB_NAME();
 
WITH partitionCTE (OBJECT_ID, index_id, row_count, partition_count) 
AS
(
    SELECT [OBJECT_ID]
        , index_id
        , SUM([ROWS]) AS 'row_count'
        , COUNT(partition_id) AS 'partition_count'
    FROM sys.partitions
    GROUP BY [OBJECT_ID]
        , index_id
) 
 
SELECT	OBJECT_SCHEMA_NAME(i.[OBJECT_ID]) AS SchemaName
		, OBJECT_NAME(i.[OBJECT_ID]) AS ObjectName
        , i.name AS IndexName
        , CASE 
            WHEN i.is_unique = 1 
                THEN 'UNIQUE ' 
            ELSE '' 
          END + i.type_desc AS 'IndexType'
        , ddius.user_seeks
        , ddius.user_scans
        , ddius.user_lookups
        , ddius.user_updates
        , cte.row_count
        , CASE WHEN partition_count > 1 THEN 'yes' 
            ELSE 'no' END AS 'partitioned?'
        , CASE 
            WHEN i.type = 2 And i.is_unique = 0
                THEN 'Drop Index ' + i.name 
                    + ' On ' + @dbName 
                    + '.dbo.' + OBJECT_NAME(ddius.[OBJECT_ID]) + ';'
            WHEN i.type = 2 And i.is_unique = 1
                THEN 'Alter Table ' + @dbName 
                    + '.dbo.' + OBJECT_NAME(ddius.[OBJECT_ID]) 
                    + ' Drop Constraint ' + i.name + ';'
            ELSE '' 
          END AS 'SQL_DropStatement'
FROM sys.indexes AS i
INNER Join sys.dm_db_index_usage_stats ddius
    ON i.OBJECT_ID = ddius.OBJECT_ID
        And i.index_id = ddius.index_id
INNER Join partitionCTE AS cte
    ON i.OBJECT_ID = cte.OBJECT_ID
        And i.index_id = cte.index_id
WHERE ddius.database_id = @dbid
ORDER BY 
    (ddius.user_seeks + ddius.user_scans + ddius.user_lookups) ASC
    , user_updates DESC;