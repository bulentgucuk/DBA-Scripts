------------------------------------------------------------------------
-- Script:			sys2.objects_dependencies.sql
-- Version:			1.2
-- Release Date:	2010-02-05
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2008 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.objects_dependencies('<schema>.<table>')					
-- Notes:			Display all the objects from which the specified <schema>.<table> depends on.
--					If you pass a NULL value as parameter, you'll get information for ALL tables.
-- SQLCMD Mode:		On
------------------------------------------------------------------------
:ON ERROR EXIT

DECLARE @major INT
DECLARE @minor INT
DECLARE @revision INT 

SET @major = (@@microsoftversion & 0xFF000000) / 0x001000000
SET @minor = (@@microsoftversion & 0x00FF0000) / 0x000010000
SET @revision = (@@microsoftversion & 0x0000FFFF)

IF (@major < 10) BEGIN
	RAISERROR('This script need SQL Server 2008 or higher to be executed', 16, 1)
END
GO

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.objects_dependencies', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.objects_dependencies
GO

CREATE FUNCTION sys2.objects_dependencies(@tablename sysname)
RETURNS TABLE 
AS
RETURN
SELECT
	[schema_name] = s.name,
	[object_name] = o.name,
	object_type = o.[type],
	object_type_desc = o.type_desc,
	d.* 
FROM 
	sys.sql_expression_dependencies d
INNER JOIN
	sys.objects o ON d.referencing_id = o.[object_id]	
LEFT OUTER JOIN
	sys.schemas s ON o.[schema_id] = s.[schema_id]
WHERE 
	(o.[object_id] = object_id(@tablename) OR @tablename IS NULL)
GO