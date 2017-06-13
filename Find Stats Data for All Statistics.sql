-- stats date
SELECT	
		OBJECT_SCHEMA_NAME(OBJECT_ID) AS 'SchemaName',
		Object_name(object_id) as ObjectName,
		Object_Id,
		Name, 
		STATS_DATE(object_id, stats_id) AS statistics_update_date,
		Stats_id,
		Auto_Created,
		User_Created,
		no_Recompute
FROM sys.stats 
WHERE	Object_id >= 100
--AND		OBJECT_SCHEMA_NAME(OBJECT_ID) = 'dbo'
--ORDER BY STATS_DATE(object_id, stats_id) DESC
ORDER BY SchemaName, OBJECTNAME