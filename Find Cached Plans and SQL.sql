--DBCC FREEPROCCACHE
--GO

--SELECT * FROM AdventureWorks.Production.Product
--GO

--SELECT * FROM AdventureWorks.Production.Product -- return records
--GO 

SELECT	stats.execution_count AS exec_count,
		p.size_in_bytes as [size],
		[sql].[text] as [plan_text]
FROM	sys.dm_exec_cached_plans p
	outer apply sys.dm_exec_sql_text (p.plan_handle) sql
	join sys.dm_exec_query_stats stats
		ON stats.plan_handle = p.plan_handle
GO
