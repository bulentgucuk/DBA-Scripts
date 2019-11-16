-- Find Detailed Information on Missing Indexes
DECLARE
	@SchemaName  SysName,
	@TableName SysName,
	@Sort tinyint,
	@Delimiter VarChar(1)

SELECT
	@SchemaName ='',
	@TableName = '',-- CHANGE THE TABLE NAME OR PASS EMPTY STRING FOR ALL
	@Sort =1,
	@Delimiter =','

SELECT
	sys.schemas.schema_id, 
	sys.schemas.name AS 'schema_name',
	sys.objects.object_id, 
	sys.objects.name AS 'object_name',
	sys.objects.type,
	partitions.Rows,
	partitions.SizeMB,
	CASE WHEN @Delimiter=',' THEN sys.dm_db_missing_index_details.equality_columns ELSE REPLACE(sys.dm_db_missing_index_details.equality_columns, ',', @Delimiter) END AS 'equality_columns',
	CASE WHEN @Delimiter=',' THEN sys.dm_db_missing_index_details.inequality_columns ELSE REPLACE(sys.dm_db_missing_index_details.inequality_columns, ',', @Delimiter) END AS 'inequality_columns',
	CASE WHEN @Delimiter=',' THEN sys.dm_db_missing_index_details.included_columns ELSE REPLACE(sys.dm_db_missing_index_details.included_columns, ',', @Delimiter) END AS 'included_columns',
	sys.dm_db_missing_index_group_stats.unique_compiles,
	sys.dm_db_missing_index_group_stats.user_seeks,
	sys.dm_db_missing_index_group_stats.user_scans,
	sys.dm_db_missing_index_group_stats.avg_total_user_cost,
	sys.dm_db_missing_index_group_stats.avg_user_impact,
	sys.dm_db_missing_index_group_stats.last_user_seek,
	sys.dm_db_missing_index_group_stats.last_user_scan,
	sys.dm_db_missing_index_group_stats.system_seeks,
	sys.dm_db_missing_index_group_stats.system_scans,
	sys.dm_db_missing_index_group_stats.avg_total_system_cost,
	sys.dm_db_missing_index_group_stats.avg_system_impact,
	sys.dm_db_missing_index_group_stats.last_system_seek,
	sys.dm_db_missing_index_group_stats.last_system_scan,
	(CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.user_seeks)+CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.unique_compiles))*CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.avg_total_user_cost)*CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.avg_user_impact/100.0) AS 'Score'
FROM
	sys.objects
	JOIN (
		SELECT
			object_id, SUM(CASE WHEN index_id BETWEEN 0 AND 1 THEN row_count ELSE 0 END) AS Rows,
			CONVERT(numeric(19,3), CONVERT(numeric(19,3), SUM(in_row_reserved_page_count+lob_reserved_page_count+row_overflow_reserved_page_count))/CONVERT(numeric(19,3), 128)) AS SizeMB
		FROM sys.dm_db_partition_stats
		WHERE sys.dm_db_partition_stats.index_id BETWEEN 0 AND 1 --0=Heap; 1=Clustered; only 1 per table
		GROUP BY object_id
	) AS partitions ON sys.objects.object_id=partitions.object_id
	JOIN sys.schemas ON sys.objects.schema_id=sys.schemas.schema_id
	JOIN sys.dm_db_missing_index_details ON sys.objects.object_id=sys.dm_db_missing_index_details.object_id
	JOIN sys.dm_db_missing_index_groups ON sys.dm_db_missing_index_details.index_handle=sys.dm_db_missing_index_groups.index_handle
	JOIN sys.dm_db_missing_index_group_stats ON sys.dm_db_missing_index_groups.index_group_handle=sys.dm_db_missing_index_group_stats.group_handle
WHERE
	sys.dm_db_missing_index_details.database_id=DB_ID()
	AND sys.schemas.name LIKE CASE WHEN @SchemaName='' THEN sys.schemas.name ELSE @SchemaName END
	AND sys.objects.name LIKE CASE WHEN @TableName='' THEN sys.objects.name ELSE @TableName END
ORDER BY
	CASE @Sort
		WHEN 1 THEN
			(CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.user_seeks)+CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.unique_compiles))*CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.avg_total_user_cost)*CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.avg_user_impact/100.0)*-1
		WHEN 2 THEN
			(CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.user_seeks)+CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.unique_compiles))*CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.avg_total_user_cost)*CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.avg_user_impact/100.0)
		ELSE NULL
	END,
	CASE @Sort
		WHEN 3 THEN sys.schemas.name
		WHEN 4 THEN sys.schemas.name
		WHEN 5 THEN sys.schemas.name
		ELSE NULL
	END,
	CASE @Sort
		WHEN 1 THEN sys.dm_db_missing_index_group_stats.user_seeks*-1
		WHEN 2 THEN sys.dm_db_missing_index_group_stats.user_seeks
	END,
	CASE @Sort
		WHEN 3 THEN sys.objects.name
		WHEN 4 THEN sys.objects.name
		WHEN 5 THEN sys.objects.name
		ELSE NULL
	END,
	CASE @Sort
		WHEN 1 THEN sys.dm_db_missing_index_group_stats.avg_total_user_cost*-1
		WHEN 2 THEN sys.dm_db_missing_index_group_stats.avg_total_user_cost
		WHEN 4 THEN
			(CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.user_seeks)+CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.unique_compiles))*CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.avg_total_user_cost)*CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.avg_user_impact/100.0)*-1
		WHEN 5 THEN
			(CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.user_seeks)+CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.unique_compiles))*CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.avg_total_user_cost)*CONVERT(Numeric(19,6), sys.dm_db_missing_index_group_stats.avg_user_impact/100.0)
		ELSE NULL
	END,
	CASE @Sort
		WHEN 3 THEN sys.dm_db_missing_index_details.equality_columns
		ELSE NULL
	END
OPTION(RECOMPILE)
GO
--*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=
