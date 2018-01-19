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
