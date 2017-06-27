SELECT CASE 
			WHEN st.dbid = 32767 THEN 'MSSQLResourceDB'
			ELSE db_name(st.dbid)
		END AS 'DBName',
		cp.objtype AS [CacheType],
		COUNT_BIG(*) AS [Total Plans],
		SUM(CAST(cp.size_in_bytes AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs],
		AVG(cp.usecounts) AS [Avg Use Count],
		SUM(CAST((CASE WHEN cp.usecounts = 1 THEN size_in_bytes
				ELSE 0
				END) AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs – USE Count 1],
		SUM(CASE WHEN cp.usecounts = 1 THEN 1
				ELSE 0
				END) AS [Total Plans – USE Count 1]

FROM   sys.dm_exec_cached_plans as cp
	CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
GROUP BY st.dbid ,cp.objtype
ORDER BY st.dbid, [Total MBs – USE Count 1] DESC
GO