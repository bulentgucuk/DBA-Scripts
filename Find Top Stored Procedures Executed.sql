
-- Find top 20 most executed stored procs in the Current Database

SELECT	TOP 20 DENSE_RANK() OVER (ORDER BY SUM(execution_count) DESC) AS rank, 
		OBJECT_NAME(qt.objectid, qt.dbid) AS 'ProcedureName', 
		(CASE WHEN qt.dbid = 32767 THEN 'mssqlresource' ELSE DB_NAME(qt.dbid)
		END ) AS 'DatabaseName',
		OBJECT_SCHEMA_NAME(qt.objectid,qt.dbid) AS 'Schema',
		SUM(execution_count) AS 'TotalExecutions',SUM(total_worker_time) AS 'TotalCPUTimeMS',
		SUM(total_elapsed_time) AS 'TotalRunTimeMS',
		SUM(total_logical_reads) AS 'TotalLogicalReads',SUM(total_logical_writes) AS 'TotalLogicalWrites',
		MIN(creation_time) AS 'EarliestPlan', MAX(last_execution_time) AS 'LastExecutionTime'
FROM sys.dm_exec_query_stats qs
	CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE OBJECT_NAME(qt.objectid, qt.dbid) IS NOT NULL
AND		qt.dbid = DB_ID()
GROUP BY OBJECT_NAME(qt.objectid, qt.dbid),qt.dbid,OBJECT_SCHEMA_NAME(qt.objectid,qt.dbid)
