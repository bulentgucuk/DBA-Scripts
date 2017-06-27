
-- Find the Index Stats Date for All Table
SELECT	o.name AS TableName
      , i.name AS IndexName
      , i.type_desc AS IndexType
      , STATS_DATE(i.[object_id], i.index_id) AS StatisticsDate

FROM	sys.indexes i
	INNER JOIN sys.objects o
		ON i.[object_id] = o.[object_id]

WHERE	o.type = 'U'     --Only get indexes for User Created Tables
AND		i.name IS NOT NULL
ORDER BY	o.name, i.type
