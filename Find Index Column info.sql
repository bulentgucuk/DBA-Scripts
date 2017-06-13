SELECT	OBJECT_NAME(i.[object_id]) TableName ,
		i.[name] IndexName ,
		c.[name] ColumnName ,
		ic.is_included_column ,
		i.index_id ,
		i.type_desc ,
		i.is_unique ,
		i.data_space_id ,
		i.ignore_dup_key ,
		i.is_primary_key ,
		i.is_unique_constraint 
FROM	sys.indexes i
	JOIN sys.index_columns ic
		ON ic.object_id = i.object_id
		AND i.index_id = ic.index_id 
	JOIN sys.columns c
		ON ic.object_id = c.object_id
		AND ic.column_id = c.column_id
--WHERE	I.NAME = 'INDEX NAME'
ORDER BY tableName ,
ic.index_id ,
ic.index_column_id