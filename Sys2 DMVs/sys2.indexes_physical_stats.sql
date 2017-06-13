------------------------------------------------------------------------
-- Script:			sys2.indexes_physical_stats.sql
-- Version:			3
-- Release Date:	2009-12-27
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.indexes_physical_stats('<schema>.<table>', '<scan_type'>)					
-- Notes:			If you pass a NULL value as parameter, you'll get all the indexes in ALL tables.
--					<scan_type> values are the same values use by sys.dm_db_index_physical_stats.
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.indexes_physical_stats', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.indexes_physical_stats
GO

CREATE FUNCTION sys2.indexes_physical_stats(@tablename sysname, @scan_type varchar(32))
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
	p.*
FROM 
    sys.indexes i
INNER JOIN
    sys.dm_db_index_physical_stats(db_id(), object_id(@tablename), null, null, @scan_type) p on i.[object_id] = p.[object_id] and i.[index_id] = p.[index_id]
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


	