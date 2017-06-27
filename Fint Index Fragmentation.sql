
SELECT a.database_id
		,a.object_id
		,a.index_id
		,b.name
		,a.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats (DB_ID(), object_id('billableleads'),
     NULL, NULL, NULL) AS a
    JOIN sys.indexes AS b 
	ON a.object_id = b.object_id 
	AND a.index_id = b.index_id
where a.database_id = db_id()
order by a.object_id
GO
