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
