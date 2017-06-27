SELECT
	'[' + ss.name + '].[' + so.name + ']' AS [object],
	si.name [index],
	si.type_desc [index_type],
--	so.object_id,
--	dds.partition_scheme_id,
	sc.name AS [column],
	ps.name AS [partition_scheme],
	pf.name AS [partition_function],
	st.name [parameter_type],
--	ds.data_space_id,
--	ds.type,
	dds.destination_id AS [partition_number],
--	pp.parameter_id [parameter_id],
	pf.type_desc + ' ' + CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS [boundary_type],
	prv.value AS [included_boundary_value],
	ds.name AS [filegroup],
	p.rows AS [rows],
	CASE WHEN p2.total_rows = 0 THEN 0 ELSE CAST(p.rows AS float) / CAST(p2.total_rows AS float) END AS [percent_of_rows]
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
		AND sic.partition_ordinal = 1 --This may support larger values in the future. Only one column per partition function in the current SQL Server release.
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
--AND		PS.name = 'ps_Daily_SAHAgentUsage'
ORDER BY so.name ASC, si.name ASC, ps.name ASC, dds.destination_id DESC, pp.parameter_id ASC
