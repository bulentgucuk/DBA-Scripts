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
