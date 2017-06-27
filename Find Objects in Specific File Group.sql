
SELECT	FileGroup = FILEGROUP_NAME(a.data_space_id),
		SchemaName = OBJECT_SCHEMA_NAME(p.object_id),
		TableName = OBJECT_NAME(p.object_id),
		IndexName = i.name
FROM	sys.allocation_units a
	INNER JOIN sys.partitions p ON a.container_id = CASE WHEN a.type in(1,3) THEN p.hobt_id ELSE p.partition_id END AND p.object_id > 1024
	LEFT JOIN sys.indexes i ON i.object_id = p.object_id AND i.index_id = p.index_id

WHERE	FILEGROUP_NAME(a.data_space_id) = 'PRIMARY'
AND		OBJECT_SCHEMA_NAME(p.object_id) != 'sys'
ORDER BY	FileGroup,
			OBJECT_SCHEMA_NAME(p.object_id),
			OBJECT_NAME(p.object_id)



