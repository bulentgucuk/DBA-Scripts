------------------------------------------------------------------------
-- Script:			sys2.objects_partition_ranges.sql
-- Version:			1
-- Release Date:	2010-01-07
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.objects_partition_ranges('<schema>.<table>')					
-- Notes:			Display the partition ranges for a partitioned objects
--					If you pass a NULL value as parameter, you'll get all ALL tables.
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.objects_partition_ranges', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.objects_partition_ranges
GO

CREATE FUNCTION sys2.objects_partition_ranges(@tablename sysname)
RETURNS TABLE 
AS
RETURN
SELECT TOP 16777216
	[schema_name] = s.[name],
	[object_name] = o.[name],
	[object_type] = o.[type],
	[object_type_desc] = o.[type_desc],
	[index_name] = i.[name],
	[index_type] = i.[type],
	[index_type_desc] = i.[type_desc],	
	p.partition_number,
	p.[rows],
	-- /* ENABLE ONLY IF YOU'RE USING SQL2008 OR ABOVE */ p.data_compression,						
	-- /* ENABLE ONLY IF YOU'RE USING SQL2008 OR ABOVE */ p.data_compression_desc,
	partition_schema = ps.name,
	partition_function = pf.name,
	pf.fanout,
	pf.boundary_value_on_right,
	destination_data_space = ds2.name,
	boundary_value = prv.value
FROM 
	sys.partitions p
INNER JOIN
	sys.indexes i on p.[object_id] = i.[object_id] and p.index_id = i.index_id
INNER JOIN
	sys.objects o ON i.[object_id] = o.[object_id]
INNER JOIN
	sys.schemas s ON o.[schema_id] = s.[schema_id]
INNER JOIN
	sys.data_spaces ds on i.data_space_id = ds.data_space_id
INNER JOIN
	sys.partition_schemes ps on ds.data_space_id = ps.data_space_id and ds.[type] = ps.[type]
INNER JOIN
	sys.partition_functions pf on ps.function_id = pf.function_id
INNER JOIN
	sys.destination_data_spaces dds on ps.data_space_id = dds.partition_scheme_id and p.partition_number = dds.destination_id
INNER JOIN
	sys.data_spaces ds2 ON dds.data_space_id = ds2.data_space_id
INNER JOIN
	sys.partition_range_values prv on prv.function_id = ps.function_id and p.partition_number = prv.boundary_id
WHERE
	(p.[object_id] = object_id(@tablename) OR @tablename IS NULL)
AND
	o.[type] IN ('U', 'V')
ORDER BY	
	prv.value	
GO
