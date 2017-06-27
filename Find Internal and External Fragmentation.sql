-- Find Both Internal and External Fragmentation
SELECT
	  QUOTENAME(OBJECT_SCHEMA_NAME(ix.object_id)) + '.' + QUOTENAME(o.name) AS 'TableName'
	, ix.index_id
	, IX.name AS 'IndexName'
	, PS.index_level AS 'IndexLevel'
	, PS.page_count AS 'PageCount'
	, PS.avg_page_space_used_in_percent AS 'Page Fullness (%)'
	, PS.avg_fragmentation_in_percent AS 'External Fragmentation (%)'
	, PS.fragment_count AS 'Fragments'
	, PS.avg_fragment_size_in_pages AS 'Avg Fragment Size'
FROM sys.dm_db_index_physical_stats( DB_ID()
									, null -- REPLACE NULL WITH OBJECT_ID
									, DEFAULT
									, DEFAULT
									, 'DETAILED') AS PS
	INNER JOIN sys.indexes IX ON IX.OBJECT_ID = PS.OBJECT_ID AND IX.index_id = PS.index_id
	INNER JOIN sys.objects as o on o.object_id = ix.object_id
ORDER BY TableName, IX.INDEX_ID
GO