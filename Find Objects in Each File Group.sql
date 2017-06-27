SELECT	FILEGROUP_NAME(a.data_space_id) AS FileGroup,
		OBJECT_SCHEMA_NAME (p.object_id) AS SchemaName,
		OBJECT_NAME(p.object_id) AS TableName,
		i.name AS IndexName,
		p.index_id,
		p.partition_id,
		p.rows, 
		p.data_compression,
		p.data_compression_desc,
		a.type,
		a.type_desc,
		a.total_pages,
		a.used_pages,
		a.data_pages
FROM	sys.allocation_units a
	INNER JOIN sys.partitions p
		ON a.container_id = CASE
								WHEN a.type in(1,3) THEN p.hobt_id
								ELSE p.partition_id
							END 
		AND p.object_id > 1024
	LEFT JOIN sys.indexes i
		ON i.object_id = p.object_id
		AND i.index_id = p.index_id
WHERE	OBJECT_SCHEMA_NAME (p.object_id) <> 'SYS' -- ELIMINATE SYS SCHEMA TO EXCLUDE SYSTEM OBJECTS
ORDER BY	FileGroup,
			SchemaName,
			TableName


/* Get Details of Object on different filegroup
Finding User Created Tables*/

SELECT	o.[name],
		o.[type],
		i.[name],
		i.[index_id],
		f.[name]
FROM	sys.indexes i
	INNER JOIN sys.filegroups f
		ON i.data_space_id = f.data_space_id
	INNER JOIN sys.all_objects o
		ON i.[object_id] = o.[object_id]
WHERE	i.data_space_id = f.data_space_id
--AND		o.type = 'U' -- User Created Tables
GO


/* Get Detail about Filegroups */
SELECT	*
FROM	sys.filegroups
GO


/* Get Details of Object on different filegroup
Finding Objects on Specific Filegroup*/
SELECT	SCHEMA_NAME(o.schema_id) AS schemaname,
		o.[name],
		o.[type],
		i.[name],
		i.[index_id],
		f.[name]
FROM	sys.indexes i
	INNER JOIN sys.filegroups f
		ON i.data_space_id = f.data_space_id
	INNER JOIN sys.all_objects o
		ON i.[object_id] = o.[object_id]
WHERE	i.data_space_id = f.data_space_id
--AND		i.data_space_id = 2 -- Filegroup
ORDER BY OBJECT_SCHEMA_NAME(O.object_id), OBJECT_NAME(o.object_id)
GO

/* Get Tables, indexes, Service Broker Queues in FileGroup
Finding Objects on Specific Filegroup*/
SELECT	s.[name] AS SchemaName,
		o.[name] AS TableName,
		o.[type],
		CASE 
			WHEN o.[Type] = 'SQ' THEN 'SERVICE BROKER QUEUE'
			ELSE ISNULL(i.[name], 'TABLE DOES NOT HAVE CLUSTERED INDEX!!!') 
		END AS IndexName,
		ISNULL(i.[index_id], '') AS IndexID,
		ISNULL(f.[name], '') AS FileGroupName
		
FROM	sys.indexes i
	INNER JOIN sys.filegroups f
		ON i.data_space_id = f.data_space_id
	RIGHT OUTER JOIN sys.all_objects o
		ON i.[object_id] = o.[object_id]
	INNER JOIN sys.schemas AS S
		ON S.schema_id = O.schema_id
--WHERE	i.data_space_id = f.data_space_id
WHERE	(o.type = 'U' -- User Created Tables
		OR		O.type = 'SQ')
AND		O.is_ms_shipped = 0
ORDER BY f.[name],S.name, O.name

SELECT

FileGroup = FILEGROUP_NAME(a.data_space_id),

TableName = OBJECT_NAME(p.object_id),

IndexName = i.name

FROM sys.allocation_units a

INNER JOIN sys.partitions p ON a.container_id = CASE WHEN a.type in(1,3) THEN p.hobt_id ELSE p.partition_id END AND p.object_id > 1024

LEFT JOIN sys.indexes i ON i.object_id = p.object_id AND i.index_id = p.index_id

ORDER BY FileGroup
