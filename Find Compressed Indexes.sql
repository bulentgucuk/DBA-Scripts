-- Find compressed indexes in SQL 2008 and above
SELECT
	  SCHEMA_NAME(ST.schema_id) AS 'SchemaName'
	, st.name AS 'TableName'
	, si.name AS 'IndexName'
	, si.index_id
	, si.type_desc AS 'IndexType'
	, sp.data_compression
	, sp.data_compression_desc
FROM sys.partitions AS SP
	INNER JOIN sys.tables AS ST ON st.object_id = sp.object_id
	INNER JOIN sys.indexes AS SI ON si.object_id = st.object_id
WHERE data_compression <> 0
ORDER BY ST.name, SI.index_id;
