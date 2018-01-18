-- Find the Index Stats Date for All Table
SELECT
	  OBJECT_SCHEMA_NAME(t.object_id) AS SchemaName
	, t.name AS TableName
	, i.name AS IndexName
	, i.index_id
	, i.type_desc AS IndexType
	, STATS_DATE(i.[object_id], i.index_id) AS StatisticsDate
FROM	sys.indexes AS i
	INNER JOIN sys.tables as t ON i.[object_id] = t.[object_id]
WHERE	t.type = 'U'     --Only get indexes for User Created Tables
AND		i.name IS NOT NULL
ORDER BY	OBJECT_SCHEMA_NAME(t.object_id), t.name, i.type
OPTION(RECOMPILE)
