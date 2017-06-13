-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2008 version
SELECT DB_NAME(st.dbid) AS [DatabaseName], mg.requested_memory_kb, mg.ideal_memory_kb,
mg.request_time, mg.grant_time, mg.query_cost, mg.dop, st.[text]
FROM sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
ORDER BY mg.requested_memory_kb DESC;


-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2005 version
SELECT DB_NAME(st.dbid) AS [DatabaseName], mg.requested_memory_kb,
mg.request_time, mg.grant_time, mg.query_cost, mg.dop, st.[text]
FROM sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
ORDER BY mg.requested_memory_kb DESC;