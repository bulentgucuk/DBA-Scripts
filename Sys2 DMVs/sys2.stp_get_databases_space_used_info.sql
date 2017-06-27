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
