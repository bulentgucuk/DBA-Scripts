-- Find size of data cache for databases
SELECT	COUNT(1) * 8/1024 AS cache_size_mb,
		CASE database_id 
			WHEN 32767 THEN 'ResourceDb'
			ELSE DB_NAME(database_id) 
		END AS Database_name

FROM	sys.dm_os_buffer_descriptors
GROUP BY DB_NAME(database_id) ,database_id
ORDER BY cache_size_mb DESC;