-- stats date
SELECT	Object_name(object_id) as ObjectName,
		Object_Id,
		Name, 
		STATS_DATE(object_id, stats_id) AS statistics_update_date,
		Stats_id,
		Auto_Created,
		User_Created,
		no_Recompute
FROM sys.stats 
WHERE	Object_id >= 100
ORDER BY STATS_DATE(object_id, stats_id) DESC