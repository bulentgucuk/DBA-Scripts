-- Find Detailed Information on Existing Indexes
DECLARE
	@SchemaName SysName,
	@TableName SysName,
	@Sort tinyint,
	@Delimiter VarChar(1)

SELECT
	@SchemaName ='',
	@TableName ='',-- CHANGE THE TABLE NAME OR PASS EMPTY STRING FOR ALL 
	@Sort =5,
	@Delimiter =','


SELECT
	sys.schemas.schema_id, 
	sys.schemas.name AS schema_name,
	sys.objects.object_id, 
	sys.objects.name AS object_name,
	sys.indexes.index_id, ISNULL(sys.indexes.name, '---') AS index_name, sys.indexes.is_disabled,
	partitions.data_compression_desc,
	partitions.Rows, partitions.SizeMB, IndexProperty(sys.objects.object_id,
	sys.indexes.name, 'IndexDepth') AS IndexDepth,
	sys.indexes.type, sys.indexes.type_desc, sys.indexes.fill_factor,
	sys.indexes.is_unique, sys.indexes.is_primary_key, sys.indexes.is_unique_constraint,
	ISNULL(Index_Columns.index_columns_key, '---') AS index_columns_key,
	ISNULL(Index_Columns.index_columns_include, '---') AS index_columns_include,
	ISNULL(sys.dm_db_index_usage_stats.user_seeks,0) AS user_seeks,
	ISNULL(sys.dm_db_index_usage_stats.user_scans,0) AS user_scans,
	ISNULL(sys.dm_db_index_usage_stats.user_lookups,0) AS user_lookups,
	ISNULL(sys.dm_db_index_usage_stats.user_updates,0) AS user_updates,
	sys.dm_db_index_usage_stats.last_user_seek, sys.dm_db_index_usage_stats.last_user_scan,
	sys.dm_db_index_usage_stats.last_user_lookup, sys.dm_db_index_usage_stats.last_user_update,
	ISNULL(sys.dm_db_index_usage_stats.system_seeks,0) AS system_seeks,
	ISNULL(sys.dm_db_index_usage_stats.system_scans,0) AS system_scans,
	ISNULL(sys.dm_db_index_usage_stats.system_lookups,0) AS system_lookups,
	ISNULL(sys.dm_db_index_usage_stats.system_updates,0) AS system_updates,
	sys.dm_db_index_usage_stats.last_system_seek, sys.dm_db_index_usage_stats.last_system_scan,
	sys.dm_db_index_usage_stats.last_system_lookup, sys.dm_db_index_usage_stats.last_system_update,
	(
		(
			(CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_seeks,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_seeks,0)))*10
			+ CASE WHEN sys.indexes.type=2 THEN (CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_scans,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_scans,0)))*1 ELSE 0 END
			+ 1
		)
		/CASE WHEN sys.indexes.type=2 THEN (CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_updates,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_updates,0))+1) ELSE 1 END
	) AS Score
FROM
	sys.objects
	JOIN sys.schemas ON sys.objects.schema_id=sys.schemas.schema_id
	JOIN sys.indexes ON sys.indexes.object_id=sys.objects.object_id
	JOIN (
		SELECT
			ps.object_id, ps.index_id, p.data_compression_desc,SUM(ps.row_count) AS Rows,
			CONVERT(numeric(19,3), CONVERT(numeric(19,3), SUM(ps.in_row_reserved_page_count+ps.lob_reserved_page_count+ps.row_overflow_reserved_page_count))/CONVERT(numeric(19,3), 128)) AS SizeMB
		FROM sys.dm_db_partition_stats AS ps
			INNER JOIN sys.partitions AS p ON p.object_id = ps.object_id AND p.index_id = ps.index_id AND p.partition_id = ps.partition_id AND p.partition_number = ps.partition_number
		GROUP BY ps.object_id, ps.index_id, P.data_compression_desc
	) AS partitions ON sys.indexes.object_id=partitions.object_id AND sys.indexes.index_id=partitions.index_id
	CROSS APPLY (
		SELECT
			LEFT(index_columns_key, LEN(index_columns_key)-1) AS index_columns_key,
			LEFT(index_columns_include, LEN(index_columns_include)-1) AS index_columns_include
		FROM
			(
				SELECT
					(
						SELECT sys.columns.name + @Delimiter + ' '
						FROM
							sys.index_columns
							JOIN sys.columns ON
								sys.index_columns.column_id=sys.columns.column_id
								AND sys.index_columns.object_id=sys.columns.object_id
						WHERE
							sys.index_columns.is_included_column=0
							AND sys.indexes.object_id=sys.index_columns.object_id
							AND sys.indexes.index_id=sys.index_columns.index_id
						ORDER BY key_ordinal
						FOR XML PATH('')
					) AS index_columns_key,
					(
						SELECT sys.columns.name + @Delimiter + ' '
						FROM
							sys.index_columns
							JOIN sys.columns ON
								sys.index_columns.column_id=sys.columns.column_id
								AND sys.index_columns.object_id=sys.columns.object_id
						WHERE
							sys.index_columns.is_included_column=1
							AND sys.indexes.object_id=sys.index_columns.object_id
							AND sys.indexes.index_id=sys.index_columns.index_id
						ORDER BY index_column_id
						FOR XML PATH('')
					) AS index_columns_include
			) AS Index_Columns
	) AS Index_Columns
	LEFT OUTER JOIN sys.dm_db_index_usage_stats ON
		sys.indexes.index_id=sys.dm_db_index_usage_stats.index_id
		AND sys.indexes.object_id=sys.dm_db_index_usage_stats.object_id
		AND sys.dm_db_index_usage_stats.database_id=DB_ID()
WHERE
	sys.objects.type='u'
	AND	sys.objects.is_ms_shipped = 0
	AND sys.schemas.name LIKE CASE WHEN @SchemaName='' THEn sys.schemas.name ELSE @SchemaName END
	AND sys.objects.name LIKE CASE WHEN @TableName='' THEn sys.objects.name ELSE @TableName END
ORDER BY
	CASE @Sort
		WHEN 1 THEN
			(
				(
					(CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_seeks,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_seeks,0)))*10
					+ CASE WHEN sys.indexes.type=2 THEN (CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_scans,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_scans,0)))*1 ELSE 0 END
					+ 1
				)
				/CASE WHEN sys.indexes.type=2 THEN (CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_updates,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_updates,0))+1) ELSE 1 END
			)*-1
		WHEN 2 THEN
			(
				(
					(CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_seeks,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_seeks,0)))*10
					+ CASE WHEN sys.indexes.type=2 THEN (CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_scans,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_scans,0)))*1 ELSE 0 END
					+ 1
				)
				/CASE WHEN sys.indexes.type=2 THEN (CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_updates,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_updates,0))+1) ELSE 1 END
			)
		ELSE NULL
	END,
	CASE @Sort
		WHEN 3 THEN sys.schemas.name
		WHEN 4 THEN sys.schemas.name
		WHEN 5 THEN sys.schemas.name
		ELSE NULL
	END,
	CASE @Sort
		WHEN 1 THEN CONVERT(VarChar(10), sys.dm_db_index_usage_stats.user_seeks*-1)
		WHEN 2 THEN CONVERT(VarChar(10), sys.dm_db_index_usage_stats.user_seeks)
		ELSE NULL
	END,
	CASE @Sort
		WHEN 3 THEN sys.objects.name
		WHEN 4 THEN sys.objects.name
		WHEN 5 THEN sys.objects.name
		ELSE NULL
	END,
	CASE @Sort
		WHEN 1 THEN sys.dm_db_index_usage_stats.user_scans*-1
		WHEN 2 THEN sys.dm_db_index_usage_stats.user_scans
		WHEN 4 THEN
			(
				(
					(CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_seeks,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_seeks,0)))*10
					+ CASE WHEN sys.indexes.type=2 THEN (CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_scans,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_scans,0)))*1 ELSE 0 END
					+ 1
				)
				/CASE WHEN sys.indexes.type=2 THEN (CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_updates,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_updates,0))+1) ELSE 1 END
			)*-1
		WHEN 5 THEN
			(
				(
					(CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_seeks,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_seeks,0)))*10
					+ CASE WHEN sys.indexes.type=2 THEN (CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_scans,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_scans,0)))*1 ELSE 0 END
					+ 1
				)
				/CASE WHEN sys.indexes.type=2 THEN (CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.user_updates,0))+CONVERT(Numeric(19,6), ISNULL(sys.dm_db_index_usage_stats.system_updates,0))+1) ELSE 1 END
			)
		ELSE NULL
	END,
	CASE @Sort
		WHEN 3 THEN sys.indexes.name
		ELSE NULL
	END
GO