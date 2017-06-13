------------------------------------------------------------------------
-- Script:			sys2.tables_columns.sql
-- Version:			1.2
-- Release Date:	2010-02-22
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.objects_data_spaces('<schema>.<table>')					
-- Notes:			Return tables and their columns and types. 
--					Also tell if a column is a LOB column or not and, if yes, in which filegroup is stored
--					If you pass a NULL value as parameter, you'll get data for ALL tables.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Version History
--
-- 1.1				Added "max_length" column
-- 1.2				Added "text_in_row_limit" and "large_value_types_out_of_row" columns
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.tables_columns', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.tables_columns
GO

CREATE FUNCTION sys2.tables_columns(@tablename SYSNAME)
RETURNS TABLE 
AS
RETURN
WITH cte AS
(
	SELECT
		[schema_name] = s.[name],
		[table_name] = t.[name],
		[column_name] = c.name,
		c.column_id,
		[type_name] = ty.name,
		c.max_length,
		is_lob = CASE WHEN (c.max_length = -1 OR ty.name IN ('text', 'ntext', 'image')) THEN 1 ELSE 0 END,
		lob_data_space = sp.name,
		t.text_in_row_limit,
		t.large_value_types_out_of_row
	FROM 
		sys.tables t
	INNER JOIN
		sys.schemas s ON t.[schema_id] = s.[schema_id]
	INNER JOIN
		sys.columns c ON t.object_id = c.object_id
	INNER JOIN
		sys.types ty ON c.system_type_id = ty.system_type_id and c.user_type_id = ty.user_type_id
	LEFT JOIN
		sys.data_spaces sp on t.lob_data_space_id = sp.data_space_id
	WHERE
		(t.[object_id] = object_id(@tablename) OR @tablename IS NULL)
)
SELECT TOP 16777216
	[schema_name],
	[table_name],
	[column_name],
	[type_name],
	max_length,
	text_in_row_limit,
	large_value_types_out_of_row,
	is_lob,
	lob_data_space = CASE is_lob WHEN 1 then lob_data_space ELSE NULL END
FROM
	cte
ORDER BY
	table_name,
	column_id
