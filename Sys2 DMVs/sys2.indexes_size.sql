------------------------------------------------------------------------
-- Script:			sys2.indexes_size.sql
-- Version:			2.1
-- Release Date:	2010-02-23
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.indexes_size('<schema>.<table>')					
-- Notes:			If you pass a NULL value as parameter, you'll get all the indexes in ALL tables.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Version History
--
-- 2.1				Fixed management of partitioned objects
--					Uses sys.allocation_units instead of sys.dm_db_index_physical_stats()
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.indexes_size', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.indexes_size
GO

CREATE FUNCTION sys2.indexes_size(@tablename sysname)
RETURNS TABLE 
AS
RETURN
WITH cte AS
(
SELECT 
	[schema_name] = s.[name],
	[object_name] = o.[name],
	[object_type] = o.[type],
	[object_type_desc] = o.[type_desc],
	[index_name] = i.[name],
	[index_type] = i.[type],
	[index_type_desc] = i.[type_desc],	
	alloc_unit_type_desc = au.type_desc,
    space_used_in_kb = (au.used_pages * 8.0),
    space_used_in_mb = (au.used_pages * 8.0 / 1024.0) 
FROM 
    sys.indexes i
INNER JOIN
	sys.partitions p on p.[object_id] = i.[object_id] and p.index_id = i.index_id
INNER JOIN
	sys.allocation_units au on p.partition_id = au.container_id 
INNER JOIN
	sys.objects o ON i.[object_id] = o.[object_id]
INNER JOIN
	sys.schemas s ON o.[schema_id] = s.[schema_id]
WHERE 
	(o.[object_id] = object_id(@tablename) OR @tablename IS NULL)
AND
	i.[type] <> 0
AND
	o.[type] IN ('U', 'V')
)
SELECT TOP 4096
	[schema_name],
	[object_name],
	[object_type],
	[object_type_desc],
	[index_name],
	[index_type],
	[index_type_desc],
	[alloc_unit_type_desc],
	space_used_in_kb = SUM(space_used_in_kb),
	space_used_in_mb = SUM(space_used_in_mb)
FROM
	cte	
GROUP BY
	[schema_name],
	[object_name],
	[object_type],
	[object_type_desc],
	[index_name],
	[index_type],
	[index_type_desc],
	[alloc_unit_type_desc]
ORDER BY
	[index_type],
	[object_name],
	[index_name]
GO


