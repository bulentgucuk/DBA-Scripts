-- Find Partitioned Tables in a Database
SELECT DISTINCT
	QUOTENAME(ss.name) + '.' + QUOTENAME(so.name) AS [object],
	si.name [index],
	si.type_desc [index_type],
	sc.name AS [column],
	ps.name AS [partition_scheme],
	pf.name AS [partition_function],
	st.name [parameter_type],
	pf.type_desc + ' ' + CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS [boundary_type],
	ds.name AS [filegroup],
	dds.destination_id AS [PartitionId]
FROM sys.data_spaces ds
	INNER JOIN sys.destination_data_spaces dds
		ON ds.data_space_id = dds.data_space_id
	INNER JOIN sys.partition_schemes ps
		ON ps.data_space_id = dds.partition_scheme_id
	INNER JOIN sys.indexes si
		ON si.data_space_id = dds.partition_scheme_id
	INNER JOIN sys.index_columns sic
		ON si.object_id = sic.object_id
		AND si.index_id = sic.index_id
		AND sic.partition_ordinal = 1
	INNER JOIN sys.columns sc
		ON sic.object_id = sc.object_id
		AND sic.column_id = sc.column_id
	INNER JOIN sys.objects so
		ON si.object_id = so.object_id
	INNER JOIN sys.schemas ss
		ON so.schema_id = ss.schema_id
	INNER JOIN sys.partitions p
		ON dds.destination_id = p.partition_number
		AND so.object_id = p.object_id
		AND si.index_id = p.index_id
	INNER JOIN (
		SELECT
			object_id,
			index_id,
			SUM(rows) AS total_rows
		FROM sys.partitions
		GROUP BY object_id, index_id
	) p2
		ON so.object_id = p2.object_id
		AND si.index_id = p2.index_id
	INNER JOIN sys.partition_functions pf
		ON ps.function_id = pf.function_id
	INNER JOIN sys.partition_parameters pp
		ON pf.function_id = pp.function_id
	INNER JOIN sys.types st
		ON pp.system_type_id = st.system_type_id
	LEFT OUTER JOIN sys.partition_range_values prv
		ON pp.function_id = prv.function_id
		AND pp.parameter_id = prv.parameter_id
		AND (
			(pf.boundary_value_on_right = 1 AND prv.boundary_id = dds.destination_id - 1) 
			OR (pf.boundary_value_on_right = 0 AND prv.boundary_id = dds.destination_id)
		)
WHERE	si.type_desc = 'CLUSTERED'
--AND	ss.name = 'Evaluated'
--AND so.name LIKE 'Prices%'
ORDER BY [object] ASC, [index] ASC, [partition_scheme] ASC


