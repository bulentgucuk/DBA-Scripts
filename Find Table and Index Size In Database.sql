SELECT --'alter index all on ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.Name) + ' rebuild with (sort_in_tempdb = on, data_compression = page)' as 'Tsql',
	--'alter table ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.Name) + ' rebuild with (data_compression = page)' AS 'TsqlForHeaps' ,
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
	, (SUM(ps.reserved_page_count) * 8.0 / (1024))/ 1024 as 'SpaceInGB'
	, CASE
		WHEN MAX(ps.row_count) = 0 THEN 0
		ELSE (8 * 1024* SUM(ps.reserved_page_count)) / NULLIF(MAX(ps.row_count), 0)
		END AS 'Bytes/Row'
	, p.Data_compression_desc
FROM	sys.dm_db_partition_stats AS ps
	INNER JOIN sys.indexes AS i ON ps.object_id = i.object_id and ps.index_id = i.index_id
	INNER JOIN sys.tables AS t ON i.object_id = t.object_id
	INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
	INNER JOIN sys.partitions as p ON p.index_id = i.index_id and p.object_id = t.object_id
WHERE	t.is_ms_shipped = 0
--and		s.name = 'stg'
--and		p.data_compression_desc = 'none'
GROUP BY s.name, t.Name, i.Name, i.index_id, t.create_date, p.Data_compression_desc
ORDER BY SpaceInMB DESC
OPTION(RECOMPILE);