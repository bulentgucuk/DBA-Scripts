-- find the last time stats updated
SELECT	NAME AS index_name,
		STATS_DATE(object_id, index_id) AS statistics_update_date
FROM	sys.indexes
WHERE	OBJECT_ID > 100
AND		NAME IS NOT NULL
AND		STATS_DATE(object_id, index_id) IS NOT NULL
--AND		NAME = 'PK_ACCOUNTS'
ORDER BY statistics_update_date






