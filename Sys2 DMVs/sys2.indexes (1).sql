------------------------------------------------------------------------
-- Script:			sys2.indexes.sql
-- Version:			5
-- Release Date:	2011-09-06
-- Author:			Davide Mauri (SolidQ Italy)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.indexes('<schema>.<table>')					
-- Notes:			If you pass a NULL value as parameter, you'll get all the indexes in ALL tables.
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.indexes', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.indexes
GO

CREATE FUNCTION sys2.indexes(@tablename sysname)
RETURNS TABLE 
AS
RETURN
SELECT TOP 2147483647
	[schema_name] = s.[name],
	[object_name] = o.[name],
	[object_type] = o.[type],
	[object_type_desc] = o.[type_desc],
	[index_name] = i.[name],
	[index_type] = i.[type],
	[index_type_desc] = i.[type_desc],	
	[index_key_columns] = SUBSTRING((SELECT ', ' + c.name FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0 ORDER BY ic.key_ordinal FOR XML PATH('')), 3, 2048),
	[index_included_columns] = SUBSTRING((SELECT ', ' + c.name FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1 ORDER BY ic.key_ordinal FOR XML PATH('')), 3, 2048) ,
	-- /* ENABLE ONLY IF YOU'RE USING SQL2008 OR ABOVE */ i.[has_filter], 
	-- /* ENABLE ONLY IF YOU'RE USING SQL2008 OR ABOVE */ i.[filter_definition],	
	i.is_primary_key,
	i.is_unique,
	i.is_unique_constraint,
	i.is_disabled
FROM 
	sys.indexes i
LEFT OUTER JOIN
	sys.objects o ON i.[object_id] = o.[object_id]
LEFT OUTER JOIN
	sys.schemas s ON o.[schema_id] = s.[schema_id]
WHERE 	
	(i.[object_id] = object_id(@tablename) OR @tablename IS NULL)
AND	
	i.[type] <> 0
AND
	o.[type] IN ('U', 'V')
ORDER BY
	o.[name],
	i.[type],
	i.[name]
