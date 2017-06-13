-- FIND TABLE WITHOUT CLUSTERED INDEX (HEAPS)
SELECT	OBJECT_SCHEMA_NAME(i.object_id) AS SchemaName,
		o.name AS TableName,
		p.rows AS RecordCount,
		o.is_published AS Published,
		i.type_desc AS TableTypeDesc,
		o.type_desc AS SystemOrUserTable,
		o.create_date AS CreateDate
FROM	sys.indexes AS i
	INNER JOIN sys.objects AS o
		ON i.object_id = o.object_id
	INNER JOIN sys.partitions AS P
		ON p.object_id = o.object_id
WHERE	o.type_desc = 'USER_TABLE'
AND		i.type_desc = 'HEAP'
AND		o.is_ms_shipped = 0  -- Return only user created objects
AND		p.index_id = 0
ORDER BY OBJECT_SCHEMA_NAME(i.object_id),o.name
GO