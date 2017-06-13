-- Find Table and Index space used with detailed info
DECLARE	@PageSize	FLOAT
SELECT	@PageSize = v.low/1024.0
FROM	MASTER.dbo.spt_values v
WHERE	v.number = 1
AND		v.type = 'E'

SELECT	SCHEMA_NAME(tbl.schema_id) as [Schema],
		tbl.name,
		--tbl.*,
		idx.index_id,
		CAST(CASE idx.index_id WHEN 1 THEN 1 ELSE 0 END AS bit) AS [HasClusteredIndex],
		ISNULL( ( SELECT SUM (spart.rows) FROM sys.partitions spart WHERE spart.object_id = tbl.object_id and spart.index_id < 2), 0) AS [RowCount],
		ISNULL((SELECT @PageSize * SUM(a.used_pages - CASE WHEN a.type <> 1 THEN a.used_pages WHEN p.index_id < 2 THEN a.data_pages ELSE 0 END) 
                FROM	sys.indexes as i
					JOIN	sys.partitions as p
						ON	p.object_id = i.object_id
						AND p.index_id = i.index_id
					JOIN	sys.allocation_units as a
						ON a.container_id = p.partition_id
				WHERE	i.object_id = tbl.object_id  ) , 0.0) AS [IndexSpaceUsed],
		ISNULL((SELECT	@PageSize * SUM(CASE WHEN a.type <> 1 THEN a.used_pages WHEN p.index_id < 2 THEN a.data_pages ELSE 0 END)
				FROM	sys.indexes as i
					JOIN	sys.partitions as p
						ON	p.object_id = i.object_id
						AND p.index_id = i.index_id
					JOIN	sys.allocation_units as a
						ON	a.container_id = p.partition_id
				WHERE i.object_id = tbl.object_id) , 0.0) AS [DataSpaceUsed]

FROM	sys.tables AS tbl
	INNER JOIN sys.indexes AS idx
		ON	idx.object_id = tbl.object_id
		AND idx.index_id < 2
ORDER BY [DataSpaceUsed] DESC

