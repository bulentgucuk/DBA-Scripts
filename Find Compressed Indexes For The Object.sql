SELECT	OBJECT_NAME(i.object_id), i.name, i.index_id, i.type_desc, p.partition_number, p.rows, p.data_compression_desc, i.is_unique, i.is_primary_key, i.has_filter,i.filter_definition
FROM	sys.indexes AS i
	INNER JOIN sys.partitions AS p ON p.object_id = i.object_id AND p.index_id = i.index_id
WHERE	i.object_id = OBJECT_ID('ods.SGDW_FactItems')
ORDER BY i.index_id
