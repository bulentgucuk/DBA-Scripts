SELECT mg.granted_memory_kb, mg.session_id, t.text, qp.query_plan

FROM sys.dm_exec_query_memory_grants AS mg

CROSS APPLY sys.dm_exec_sql_text(mg.sql_handle) AS t

CROSS APPLY sys.dm_exec_query_plan(mg.plan_handle) AS qp

-- where mg.session_id <> @@SPID /*uncomment to exclude your current session*/

ORDER BY 1 DESC OPTION (MAXDOP 1) 
