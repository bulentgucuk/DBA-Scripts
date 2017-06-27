------------------------------------------------------------------------
-- Script:			sys2.stats.sql
-- Version:			2
-- Release Date:	2011-09-13
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.stats('<schema>.<table>')					
-- Notes:			If you pass a NULL value as parameter, you'll get all the statistics in ALL tables.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Version History
--
-- 2				Added "used_columns" column
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.stats', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.stats
GO

CREATE FUNCTION sys2.stats(@tablename sysname)
RETURNS TABLE 
AS
RETURN
SELECT TOP 40960	
	[schema_name] = s.[name],
	[table_name] = t.[name],
	[statistic_name] = st.name,
	[stats_id],
	[on_index] = case when i.index_id is null then 0 else 1 end,
	last_update = STATS_DATE(st.object_id, st.stats_id),
	[auto_created],
	[user_created],	
	used_columns = SUBSTRING((SELECT ', ' + c.name FROM sys.stats_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = st.object_id AND ic.stats_id = st.stats_id ORDER BY ic.stats_column_id FOR XML PATH('')), 3, 2048)--,
	-- /* ENABLE ONLY IF YOU'RE USING SQL2008 OR ABOVE */ st.[has_filter],
	-- /* ENABLE ONLY IF YOU'RE USING SQL2008 OR ABOVE */st.[filter_definition]				
FROM 
	sys.tables t
INNER JOIN
	sys.schemas s ON t.[schema_id] = s.[schema_id]
INNER JOIN
	sys.stats st on t.object_id = st.object_id
LEFT OUTER JOIN
	sys.indexes i on st.object_id = i.object_id and st.stats_id = i.index_id
WHERE
	(t.[object_id] = object_id(@tablename) OR @tablename IS NULL)
GO
 