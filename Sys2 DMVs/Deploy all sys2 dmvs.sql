------------------------------------------------------------------------
-- Script:			sys2.buffer_cache_usage.sql
-- Version:			1
-- Release Date:	2011-03-04
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.plan_cache_size				
-- Notes:			Show how much memory is being used for Plan Cache
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.buffer_cache_usage', 'V') IS NOT NULL)
	DROP VIEW sys2.buffer_cache_usage
GO

CREATE VIEW sys2.buffer_cache_usage
as
with cte as
(
select 
	database_id,
	(count(*) * 8) / 1024. as cache_memory_usage_in_mb    
from 
	sys.dm_os_buffer_descriptors with (nolock)
group by
	database_id
)
select	
	database_name = d.name, 
	cache_memory_usage_in_mb
from	
	cte c
inner join
	sys.databases d on c.database_id = d.database_id
GO

------------------------------------------------------------------------
-- Script:			sys2.databases_backup_info.sql
-- Version:			1.1
-- Release Date:	2011-02-13
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.databases_backup_info					
-- Notes:			Returns information of last backup of each database
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.databases_backup_info', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.databases_backup_info
GO

CREATE FUNCTION sys2.databases_backup_info(@days_back int = 7)
RETURNS TABLE 
AS
RETURN
with cte as
(
select  
	dummy = 1,
	rn = row_number() over (partition by bs.database_name, bs.type  order by bs.backup_finish_date desc),
	bs.database_name,  
	bs.backup_start_date,  
	bs.backup_finish_date, 
	case 
		when bs.type = 'I' then 'Diff'
		when bs.type = 'D' then 'Full'  
		when bs.type = 'L' then 'Log'  
	end as backup_type 
from   
	msdb.dbo.backupmediafamily  bmf
inner join
	msdb.dbo.backupset bs ON bmf.media_set_id = bs.media_set_id  
where  
	(bs.backup_start_date >= convert(char(8), getdate() - @days_back, 112))  
), cte2 as
(
select 
	database_name,
	full_backup = isnull([full], 0),
	diff_backup = isnull([diff], 0),
	log_backup = isnull([log], 0),	
	full_backup_start_date = backup_start_date + [full] - [full],
	full_backup_end_date = backup_finish_date + [full] - [full],
	diff_backup_start_date = backup_start_date + [diff] - [diff],
	diff_backup_end_date = backup_finish_date + [diff] - [diff],
	log_backup_start_date = backup_start_date + [log] - [log],
	log_backup_end_date = backup_finish_date + [log] - [log]
from 
	cte 
pivot
	(max(dummy) for backup_type in ([full], [diff], [log])) as p
where 
	rn = 1 
), cte3 as
(
select
	database_name,
	full_backup = max(full_backup),	
	diff_backup = max(diff_backup),	
	log_backup = max(log_backup),	
	full_backup_start_date = max(full_backup_start_date),
	full_backup_end_date = max(full_backup_end_date),
	diff_backup_start_date = max(diff_backup_start_date),
	diff_backup_end_date = max(diff_backup_end_date),
	log_backup_start_date = max(log_backup_start_date),
	log_backup_end_date = max(log_backup_end_date)
from
	cte2 c
group by
	database_name
)
select
	d.database_id,
	database_name = isnull(d.name, c.database_name),
	d.is_read_only,
	d.recovery_model,
	d.recovery_model_desc,
	d.state,
	d.state_desc,
	full_backup = isnull(c.full_backup, 0),
	diff_backup = isnull(c.diff_backup, 0),
	log_backup = isnull(c.log_backup, 0),	
	c.full_backup_start_date,
	c.full_backup_end_date,
	c.diff_backup_start_date,
	c.diff_backup_end_date,
	c.log_backup_start_date,
	c.log_backup_end_date
from
	cte3 c
full outer join
	sys.databases d on c.database_name = d.name
GO
------------------------------------------------------------------------
-- Script:			sys2.databases_files.sql
-- Version:			2
-- Release Date:	2010-04-28
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.databases_files					
-- Notes:			
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Version History
--
-- 1				First Version
-- 2				Added "space_used_in_mb". This column will show the used space for the active database
------------------------------------------------------------------------


IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.databases_files', 'V') IS NOT NULL)
	DROP VIEW sys2.databases_files
GO

CREATE VIEW sys2.databases_files
AS
with cte as
(
select 
	database_name = d.name,
	mf.database_id,
	file_id,
	file_name = mf.name,
	physical_name,
	size_in_mb = (cast(size as bigint)* 8) / 1024.,	
	space_used_in_mb = (cast(fileproperty(mf.name, 'SpaceUsed') as bigint)* 8) / 1024.,      
	max_size_in_mb = case when max_size > -1 then (cast(max_size as bigint)* 8) / 1024. else null end,
	growth_in_mb = case when is_percent_growth <> 0 then null else (cast(growth as bigint) * 8) / 1024. end,
	growth_in_percent = case when is_percent_growth <> 0 then growth else null end,
	database_read_only = d.is_read_only,
	file_read_only = mf.is_read_only,
	database_state_desc = d.state_desc
from 
	sys.master_files mf
inner join
	sys.databases d on d.database_id = mf.database_id
)
select	
	database_name,
	database_id,
	file_id,
	file_name,
	physical_name,
	size_in_mb,	
	space_used_in_mb,
	max_size_in_mb,
	available_space_for_growth_in_mb = max_size_in_mb - size_in_mb,
	growth_in_mb,
	growth_in_percent,
	database_state_desc,
	database_read_only,
	file_read_only
from
	cte
GO

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
GO
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

------------------------------------------------------------------------
-- Script:			sys2.indexes_per_table
-- Version:			1
-- Release Date:	2010-08-09
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.indexes_per_table		
-- Notes:			Display a list of all table along with information 
--					regarding presence of clustered and nonclustered 
--					indexes
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.indexes_per_table', 'V') IS NOT NULL)
	DROP VIEW sys2.indexes_per_table
GO

CREATE VIEW sys2.indexes_per_table
as
with cte as
(
	select 
		table_name = o.name,	
		o.[object_id],
		i.index_id,
		i.type,
		i.type_desc
	from 
		sys.indexes i
	inner join
		sys.objects o on i.[object_id] = o.[object_id]
	where
		o.type in ('U')
	and
		o.is_ms_shipped = 0 and i.is_disabled = 0  and i.is_hypothetical = 0 
	and
		i.type <= 2
), cte2 as
(
select
	*
from
	cte c
pivot
	(count(type) for type_desc in ([HEAP], [CLUSTERED], [NONCLUSTERED])) pv
)
select
	c2.table_name,
	[rows] = max(p.rows),
	is_heap = sum([HEAP]),
	is_clustered = sum([CLUSTERED]),
	num_of_nonclustered = sum([NONCLUSTERED])
from
	cte2 c2
inner join
	sys.partitions p on c2.[object_id] = p.[object_id] and c2.index_id = p.index_id
group by
	table_name
GO
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


------------------------------------------------------------------------
-- Script:			sys2.indexes_usage_stats.sql
-- Version:			4
-- Release Date:	2010-04-29
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.indexes_usage_stats('<schema>.<table>')					
-- Notes:			If you pass a NULL value as parameter, you'll get all the indexes in ALL tables.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Version History
--
-- 4				Added "total_seeks", "total_scans", "total_lookups" and "total_updates" columns
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.indexes_usage_stats', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.indexes_usage_stats
GO

CREATE FUNCTION sys2.indexes_usage_stats(@tablename sysname)
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
	i.is_disabled,
	i.is_primary_key,
	i.is_unique_constraint,
	total_seeks = user_seeks + system_seeks,
	total_scans = user_scans + system_scans,
	total_lookups = user_lookups + system_lookups,
	total_updates = user_updates + system_updates,	
	u.*	
FROM 
    sys.indexes i
INNER JOIN
    sys.dm_db_index_usage_stats u on i.[object_id] = u.[object_id] and i.[index_id] = u.[index_id]
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
AND
	u.[database_id] = db_id()
ORDER BY
	u.[user_seeks]
GO


------------------------------------------------------------------------
-- Script:			sys2.logs_usage
-- Version:			1
-- Release Date:	2010-03-03
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			Thomas Kejser (MS SQL CAT Team)
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.logs_usage		
-- Notes:			Display Transaction Log usage data
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.logs_usage', 'V') IS NOT NULL)
	DROP VIEW sys2.logs_usage
GO

CREATE VIEW sys2.logs_usage
AS
WITH cte as
(
SELECT 
	name, 
	db.log_reuse_wait_desc, 
	size_mb = ls.cntr_value / 1024.,
	used_mb = lu.cntr_value / 1024.,
	used_percent = CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT),
	log_status = CASE 
		WHEN CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT) > .75
			THEN CASE 
					/* tempdb special monitoring */ 
					WHEN db.name = 'tempdb' AND log_reuse_wait_desc NOT IN ('CHECKPOINT', 'NOTHING') THEN 'WARNING'  					
					WHEN db.name <> 'tempdb' THEN 'WARNING' 
					ELSE 'OK' 
				END 
		ELSE 'OK' 
	END 	
FROM 
	sys.databases db 
JOIN 
	sys.dm_os_performance_counters lu ON db.name = lu.instance_name 
JOIN 
	sys.dm_os_performance_counters ls ON db.name = ls.instance_name 
WHERE 
	lu.counter_name LIKE 'Log File(s) Used Size (KB)%' 
AND 
	ls.counter_name LIKE 'Log File(s) Size (KB)%' 
)
select
	*
from
	cte
GO

------------------------------------------------------------------------
-- Script:			sys2.missing_indexes.sql
-- Version:			6
-- Release Date:	2011-09-06
-- Author:			Davide Mauri (SolidQ Italy)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.missing_indexes			
-- Notes:			Display all the detected missing indexes in ALL tables and ALL databases
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.missing_indexes', 'V') IS NOT NULL)
	DROP VIEW sys2.missing_indexes
GO

CREATE VIEW sys2.missing_indexes
AS
WITH cte AS
(
SELECT
    d.database_id,
    d.[object_id],
    d.index_handle,
	database_name = db_name(d.database_id),
    d.statement as fully_qualified_object,
    d.equality_columns,
    d.inequality_columns,
    d.included_columns,
	gs.user_seeks, 
	gs.avg_user_impact,
	gs.last_user_seek,
	gs.last_user_scan,
	total_columns_to_index = (select count(*) from sys.dm_db_missing_index_columns(d.index_handle)),
	command = 'CREATE INDEX IX_' + 
			CAST(ABS(CHECKSUM(isnull(equality_columns, '') + isnull(inequality_columns, '') + isnull(included_columns, ''))) as varchar(100)) + 
			' ON ' + 
			d.statement + 
			' (' + isnull(equality_columns, '') + 
			case when (equality_columns + inequality_columns) is null then '' else ',' end + 
			isnull(inequality_columns, '')  + ')' + 
			isnull(' INCLUDE (' + included_columns + ')', '')
FROM
    sys.dm_db_missing_index_groups g 
LEFT OUTER JOIN 
    sys.dm_db_missing_index_group_stats gs on gs.group_handle = g.index_group_handle 
LEFT OUTER JOIN
    sys.dm_db_missing_index_details d on g.index_handle = d.index_handle
)
SELECT
	*
FROM
	cte

GO

------------------------------------------------------------------------
-- Script:			sys2.objects_data_spaces.sql
-- Version:			2.2
-- Release Date:	2010-02-23
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.objects_data_spaces('<schema>.<table>')					
-- Notes:			Display in which partition an object (table or index) resides.
--					If you pass a NULL value as parameter, you'll get data for ALL tables.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Version History
--
-- 2.1				Added information regarding the data space in which LOB data is stored
-- 2.2				Added "space_used" and "alloc_unit_type_desc" columns
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.objects_data_spaces', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.objects_data_spaces
GO

CREATE FUNCTION sys2.objects_data_spaces(@tablename sysname)
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
	alloc_unit_type_desc = au.type_desc,
	p.partition_number,
	p.[rows],								
	space_used_in_kb = (au.used_pages * 8.0),
    space_used_in_mb = (au.used_pages * 8.0 / 1024.0),      
	-- /* ENABLE ONLY IF YOU'RE USING SQL2008 OR ABOVE */ p.data_compression,						
	-- /* ENABLE ONLY IF YOU'RE USING SQL2008 OR ABOVE */ p.data_compression_desc,
	data_space_name = ds.name,
	data_space_type = ds.type,
	data_space_type_desc = ds.type_desc,
	[filegroup_name] = f.name,	
	f.is_read_only,
	lob_data_space = lobds.name
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
LEFT JOIN
	sys.partition_schemes ps on i.data_space_id = ps.data_space_id	
LEFT JOIN
	sys.destination_data_spaces dds on dds.partition_scheme_id = ps.data_space_id and p.partition_number = dds.destination_id
INNER JOIN
	sys.filegroups f on f.data_space_id = CASE WHEN ds.[type] <> 'PS' THEN ds.data_space_id ELSE dds.data_space_id END
LEFT JOIN
	sys.tables t on o.[object_id] = t.[object_id]
LEFT JOIN
	sys.data_spaces lobds on t.lob_data_space_id = lobds.data_space_id
INNER JOIN
    sys.allocation_units au on  p.partition_id = au.container_id 
where
	(p.[object_id] = object_id(@tablename) OR @tablename IS NULL)
AND
	o.[type] IN ('U', 'V')
ORDER BY	
	o.[name]
GO

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
------------------------------------------------------------------------
-- Script:			sys2.plan_cache_size.sql
-- Version:			1
-- Release Date:	2010-07-23
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.plan_cache_size				
-- Notes:			Show how much memory is being used for Plan Cache
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.plan_cache_size', 'V') IS NOT NULL)
	DROP VIEW sys2.plan_cache_size
GO

CREATE VIEW sys2.plan_cache_size
as
with cte as (
	select 
		reused = case when usecounts > 1 then 'reused_plan_mb' else 'not_reused_plan_mb' end, 
		size_in_bytes, 
		cacheobjtype,
		objtype
	from 
		sys.dm_exec_cached_plans
), cte2 as
(
	select 
		reused,
		objtype,
		cacheobjtype,
		size_in_mb = sum(size_in_bytes / 1024. / 1024.) 
	from 
		cte 
	group by 
		reused, cacheobjtype, objtype
), cte3 as
(
	select
		*
	from
		cte2 c
	pivot 
		( sum(size_in_mb) for reused in ([reused_plan_mb], [not_reused_plan_mb])) p
)
select
	objtype, cacheobjtype, [reused_plan_mb] = sum([reused_plan_mb]), [not_reused_plan_mb] = sum([not_reused_plan_mb])
from
	cte3
group by
	objtype, cacheobjtype
with rollup
having
	(objtype is null and cacheobjtype is null) or (objtype is not null and cacheobjtype is not null)
GO

------------------------------------------------------------------------
-- Script:			sys2.query_memory_grants.sql
-- Version:			1.0
-- Release Date:	2010-10-15
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.query_memory_grants(<include_plan>)					
-- Notes:			Wrapper around sys.dm_exec_query_memory_grants. If @include_plan = 1 also gather query plans
--					WARNING: On a highly used system can be time consuming!
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.query_memory_grants', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.query_memory_grants
GO

CREATE FUNCTION sys2.query_memory_grants(@include_plan BIT = 0)
RETURNS TABLE 
AS
RETURN
SELECT 
	database_id = st.dbid,
	[object_id] = st.objectid,
	query_text = st.[text],
	qp.query_plan,	
	object_type = cp.objtype,
	cache_object_type = cp.cacheobjtype,	
	qg.*
FROM 
	sys.dm_exec_query_memory_grants qg
LEFT JOIN
	sys.dm_exec_cached_plans cp on qg.[plan_handle] = cp.[plan_handle]
OUTER APPLY
	sys.dm_exec_sql_text([sql_handle]) st
OUTER APPLY
	sys.dm_exec_query_plan(CASE WHEN @include_plan = 1 THEN qg.[plan_handle] ELSE null END) qp		

GO

------------------------------------------------------------------------
-- Script:			sys2.query_stats.sql
-- Version:			1.2
-- Release Date:	2011-12-12
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			SELECT * FROM sys2.query_stats(<include_plan>)					
-- Notes:			Wrapper around sys.query_stats. If @include_plan = 1 also gather query plans
--					WARNING: On a highly used system can be time consuming!
------------------------------------------------------------------------

------------------------------------------------------------------------
-- Version History
--
-- 1.1				Added "database_id" and "object_id" columns
-- 1.2				Used sys.dm_exec_plan_attributes to get database_id
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.query_stats', 'IF') IS NOT NULL)
	DROP FUNCTION sys2.query_stats
GO

CREATE FUNCTION sys2.query_stats(@include_plan BIT = 0)
RETURNS TABLE 
AS
RETURN
SELECT 
	database_id = cast(epa.database_id as int),
	[object_id] = st.objectid,
	query_text = st.[text],
	statement_text = SUBSTRING(st.[text], (qs.statement_start_offset/2) + 1, ((CASE statement_end_offset WHEN -1 THEN DATALENGTH(st.text) ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1),
	qp.query_plan,	
	object_type = cp.objtype,
	cache_object_type = cp.cacheobjtype,
	avg_worker_time = total_worker_time / (execution_count),
	avg_logical_reads = total_logical_reads / (execution_count),
	avg_logical_writes = total_logical_reads / (execution_count),
	avg_elapsed_time = total_elapsed_time / (execution_count),
	qs.*
FROM 
	sys.dm_exec_query_stats qs
LEFT JOIN
	sys.dm_exec_cached_plans cp on qs.[plan_handle] = cp.[plan_handle]
OUTER APPLY
	sys.dm_exec_sql_text([sql_handle]) st
OUTER APPLY
	(select database_id = [value] from sys.dm_exec_plan_attributes(qs.[plan_handle]) where attribute = 'dbid') epa
OUTER APPLY
	sys.dm_exec_query_plan(CASE WHEN @include_plan = 1 THEN qs.[plan_handle] ELSE null END) qp		

GO

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
 
------------------------------------------------------------------------
-- Script:			sys2.stp_get_databases_space_used_info.sql
-- Version:			1.1
-- Release Date:	2011-02-13
-- Author:			Davide Mauri (Solid Quality Mentors)
-- Credits:			-
-- License:			Microsoft Public License (Ms-PL)
-- Target Version:	SQL Server 2005 RTM or above
-- Tab/indent size:	4
-- Usage:			EXEC sys2.stp_get_database_space_used_info					
-- Notes:			Returns a list of all databases along with the relativa space used, space available, max space and growth
--					"size"			: overall database files size
--					"space_used"	: space used by database data
--					"max size"		: the maximum size to which the database is allowed to grow
--					"growth"		: show size of autogrow, if enabled
------------------------------------------------------------------------

IF NOT EXISTS(SELECT * FROM sys.schemas s WHERE s.[name] = 'sys2')
	EXEC sp_executesql N'CREATE SCHEMA sys2'
go
	
IF (OBJECT_ID('sys2.stp_get_databases_space_used_info', 'P') IS NOT NULL)
	DROP PROCEDURE sys2.stp_get_databases_space_used_info
GO

create procedure sys2.stp_get_databases_space_used_info
as
create table #result
(
	database_name sysname,
	database_id int,
	file_id int,
	file_name sysname,
	physical_name nvarchar(260),
	size_in_mb numeric(25,6),
	space_used_in_mb numeric(25,6),
	max_size_in_mb numeric(25,6),
	available_space_for_growth_in_mb numeric(25,6),
	growth_in_mb numeric(25,6),
	growth_in_percent int,
	database_state_desc nvarchar(60),
	database_read_only bit,
	file_read_only bit,
);

declare @s nvarchar(max)
set @s = '
use [?];
with cte as
(
select 
	database_name = d.name,
	mf.database_id,
	file_id,
	file_name = mf.name,
	physical_name,
	size_in_mb = (cast(size as bigint)* 8) / 1024.,	
	space_used_in_mb = (cast(fileproperty(mf.name, ''SpaceUsed'') as bigint)* 8) / 1024.,      
	max_size_in_mb = case when max_size > -1 then (cast(max_size as bigint)* 8) / 1024. else null end,
	growth_in_mb = case when is_percent_growth <> 0 then null else (cast(growth as bigint) * 8) / 1024. end,
	growth_in_percent = case when is_percent_growth <> 0 then growth else null end,
	database_read_only = d.is_read_only,
	file_read_only = mf.is_read_only,
	database_state_desc = d.state_desc
from 
	sys.master_files mf
inner join
	sys.databases d on d.database_id = mf.database_id
where
	d.name = ''?''
)
select	
	database_name,
	database_id,
	file_id,
	file_name,
	physical_name,
	size_in_mb,	
	space_used_in_mb,
	max_size_in_mb,
	available_space_for_growth_in_mb = max_size_in_mb - size_in_mb,
	growth_in_mb,
	growth_in_percent,
	database_state_desc,
	database_read_only,
	file_read_only
from
	cte
'
;

insert into #result exec sp_MSForEachDB @s;

select perc_space_allocated_used = space_used_in_mb / size_in_mb, perc_space_available_used = space_used_in_mb / max_size_in_mb, * from #result where database_read_only = 0
order by 1 desc, 2 desc
;

drop table #result;

GO

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
GO
		
