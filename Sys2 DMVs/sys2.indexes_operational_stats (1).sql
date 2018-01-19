------------------------------------------------------------------------
-- Script:			sys2.indexes_operational_stats.sql
-- Version:			3
-- Release Date:	2009-12-27
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.indexes_operational_stats('<schema>.<table>')					
-- Notes:			If you pass a NULL value as parameter, you'll get all the indexes in ALL tables.
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.indexes_operational_stats', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.indexes_operational_stats
GO

CREATE FUNCTION sys2.indexes_operational_stats(@tablename sysname)
RETURNS TABLE 
AS
RETURN
SELECT TOP 4096
	[schema_name] = s.[name],
	[object_name] = o.[name],
	[object_type] = o.[type],
	[object_type_desc] = o.[type_desc],
	[index_name] = i.[name],
	[index_type] = i.[type],
	[index_type_desc] = i.[type_desc],	
	os.* 
FROM 
	sys.dm_db_index_operational_stats(db_id(), object_id(@tablename), NULL, NULL) os
INNER JOIN
	sys.indexes i on i.[object_id] = os.[object_id] and i.index_id = os.index_id
LEFT OUTER JOIN
	sys.objects o ON i.[object_id] = o.[object_id]
LEFT OUTER JOIN
	sys.schemas s ON o.[schema_id] = s.[schema_id]
WHERE 
	i.[type] <> 0
AND
	o.[type] IN ('U', 'V')
ORDER BY
	i.[type],
	o.[name],
	i.[name]
GO


