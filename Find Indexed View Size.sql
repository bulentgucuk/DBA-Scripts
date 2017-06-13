SELECT
	  OBJECT_SCHEMA_NAME(v.object_id) AS 'SchemaName'
	, v.NAME AS 'ViewName'
	, i.index_id
	, i.name AS 'IndexName'
	, p.rows AS 'RowCounts'
	, SUM(a.total_pages) * 8 AS 'TotalSpaceKB'
	, SUM(a.used_pages) * 8 AS 'UsedSpaceKB'
	, SUM(a.data_pages) * 8 AS 'DataSpaceKB'
FROM	sys.views AS v
	INNER JOIN sys.indexes AS i ON v.OBJECT_ID = i.object_id
	INNER JOIN sys.partitions AS p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
	INNER JOIN sys.allocation_units AS a ON p.partition_id = a.container_id
GROUP BY v.object_id, v.NAME, i.object_id, i.index_id, i.name, p.Rows;
