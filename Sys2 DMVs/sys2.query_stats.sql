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
