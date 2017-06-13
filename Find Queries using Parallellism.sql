SELECT TOP 10
p.*,
q.*,
qs.*,
cp.plan_handle
FROM
sys.dm_exec_cached_plans cp
CROSS apply sys.dm_exec_query_plan(cp.plan_handle) p
CROSS apply sys.dm_exec_sql_text(cp.plan_handle) AS q
JOIN sys.dm_exec_query_stats qs
ON qs.plan_handle = cp.plan_handle
WHERE
cp.cacheobjtype = 'Compiled Plan' AND
p.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
max(//p:RelOp/@Parallel)', 'float') > 0
OPTION (MAXDOP 1)