--Find tables created for backup or temporarily which can be dropped
SELECT
	  DB_NAME() AS 'DatabaseName'
	, s.name AS 'SchemaName'
	, t.Name AS 'TableName'
	, t.create_date AS 'CreateDate'
	, CASE
		WHEN I.index_id = 0 THEN 'HEAP'
		ELSE i.Name
		END AS 'IndexName'
	, i.index_id AS 'IndexId'
	, MAX(ps.row_count) AS 'RowCount'
	, SUM(ps.reserved_page_count) * 8.0 / (1024) as 'SpaceInMB'
FROM	sys.dm_db_partition_stats AS ps
	INNER JOIN sys.indexes AS i ON ps.object_id = i.object_id and ps.index_id = i.index_id
	INNER JOIN sys.tables AS t ON i.object_id = t.object_id
	INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE	t.is_ms_shipped = 0
AND	(		t.name LIKE '%backup%'
	OR		t.name LIKE '%bck%'
	OR		t.name LIKE '%old%'
	OR		t.name LIKE '%2017%'
	OR		t.name LIKE '%2016%'
	OR		t.name LIKE '%2015%'
	OR		t.name LIKE '%tmp%' )
GROUP BY s.name, t.Name, i.Name, i.index_id, t.create_date
ORDER BY SchemaName, TableName, i.index_id, SpaceInMB DESC;
