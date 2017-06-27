-- Find when Stored Procedure Executed
SELECT	OBJECT_NAME(objectid) [Store Procedure Name],
		a.last_execution_time [Last Execution Time]
FROM	sys.dm_exec_query_stats a
	CROSS APPLY     sys.dm_exec_sql_text(a.sql_handle) as b
WHERE OBJECT_NAME(objectid) = 'ADD_INVENTORY_SCAN'
ORDER BY a.last_execution_time DESC
