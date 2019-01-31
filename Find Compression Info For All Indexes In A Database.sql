-- Find Compression Info for all indexes in a Database
SELECT	
		SCHEMA_NAME(st.schema_id) AS SchemaName,
		st.name AS TableName,
		CASE WHEN SI.index_id = 0 THEN 'HEAP'
			ELSE si.name 
			END AS IndexName,
		si.index_id,
		sp.partition_number,
		sp.data_compression,
		sp.data_compression_desc
FROM sys.partitions AS SP
	INNER JOIN sys.tables AS ST ON st.object_id = sp.object_id
	INNER JOIN sys.indexes AS si ON si.object_id = ST.object_id AND si.index_id = SP.index_id
ORDER BY SchemaName, TableName
OPTION(RECOMPILE);
