-- Find Statistics Modification Count
SELECT	OBJECT_SCHEMA_NAME(p.object_id) AS ObjectSchema,
		OBJECT_NAME(p.object_id) AS ObjectName,
		p.object_id ObjectID,
		p.index_id StatsID,
		s.name StatsName,
		sum(pc.modified_count) ModificationCount
FROM	sys.system_internals_partition_columns pc
	INNER JOIN sys.partitions p on pc.partition_id = p.partition_id  
	INNER JOIN sys.stats s on s.object_id = p.object_id and s.stats_id = p.index_id
	INNER JOIN sys.stats_columns sc on sc.object_id = s.object_id and sc.stats_id = s.stats_id and sc.stats_column_id = pc.partition_column_id
group by p.object_id, p.index_id,  s.name 
ORDER BY OBJECT_SCHEMA_NAME(p.object_id),OBJECT_NAME(p.object_id)
