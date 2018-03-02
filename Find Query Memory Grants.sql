-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2008 version
SELECT	DB_NAME(s.database_id) AS [DatabaseName]
	, s.login_name
	, s.session_id
	, r.status
	, r.blocking_session_id
	, r.cpu_time
	, r.logical_reads
	, r.writes
	, r.wait_resource
	, r.wait_type
	, r.wait_time
	, r.granted_query_memory
	, mg.requested_memory_kb
	, mg.ideal_memory_kb
	, mg.request_time
	, mg.grant_time
	, mg.query_cost
	, mg.dop
	, st.[text]
FROM	sys.dm_exec_sessions AS s
	INNER JOIN sys.dm_exec_requests as r on r.session_id = s.session_id
	INNER JOIN sys.dm_exec_query_memory_grants AS mg ON mg.session_id = s.session_id
	CROSS APPLY sys.dm_exec_sql_text(mg.sql_handle) AS st
	--CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE	MG.session_id <> @@SPID
ORDER BY mg.requested_memory_kb DESC
OPTION (MAXDOP 1, RECOMPILE)




-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2005 version
SELECT DB_NAME(st.dbid) AS [DatabaseName], mg.requested_memory_kb,
mg.request_time, mg.grant_time, mg.query_cost, mg.dop, st.[text]
FROM sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
ORDER BY mg.requested_memory_kb DESC;