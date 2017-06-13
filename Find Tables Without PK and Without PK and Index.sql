-- Find Tables Without PK
SELECT	DB_name() AS 'DatabaseName',
		SCHEMA_NAME(schema_id) AS 'SchemaName',
		[Name] AS 'TableName'
FROM	sys.tables
WHERE OBJECTPROPERTY(OBJECT_ID,'TableHasPrimaryKey') = 0
ORDER BY SchemaName, TableName

-- Find Tables Without PK Without Index
;WITH	UniqueObjects AS (
		SELECT	OBJECT_ID
			, DB_NAME() AS 'DatabaseName'
		FROM	SYS.indexes
		GROUP BY OBJECT_ID
		HAVING COUNT(OBJECT_ID) < 2
		)
SELECT	U.DatabaseName,
		SCHEMA_NAME(T.Schema_ID) AS SchemaName,
		OBJECT_NAME(I.OBJECT_ID) AS ObjectName
FROM	UniqueObjects AS U
	INNER JOIN sys.indexes AS I ON U.object_id = I.object_id
	INNER JOIN sys.tables as t ON t.object_id = I.object_id
WHERE	I.type_desc = 'HEAP'
ORDER BY OBJECT_NAME(I.OBJECT_ID)
		