-- Find all The Schemas, Tables, Columns, and Column DataTypes
SELECT	s.name AS SchemaName,
		t.name AS TableName,
		c.name AS ColumnName,
		t1.name AS DataType,
		CASE 
			WHEN c.system_type_id = 231 THEN c.max_length/2
			ELSE c.max_length
		END AS MaxLength,
		c.is_nullable AS IsNullable
		--,c.*
FROM	sys.tables AS t
	INNER JOIN sys.schemas AS S
		ON s.schema_id = t.schema_id
	INNER JOIN sys.columns AS c
		ON c.object_id = t.object_id
	INNER JOIN sys.types AS t1
		ON t1.system_type_id = c.system_type_id
WHERE	is_ms_shipped = 0
ORDER	BY s.name, t.name