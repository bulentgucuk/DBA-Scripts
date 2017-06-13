USE DBAdmin;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_GetTablePartitionInfo]') AND type in (N'P', N'PC'))
	EXEC( 'CREATE PROCEDURE [dbo].[pr_GetTablePartitionInfo] AS' );
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE [dbo].[pr_GetTablePartitionInfo] (
      @databaseName SYSNAME
    , @schemaName SYSNAME = '%'
    , @tableName SYSNAME = '%'
    , @filegroup SYSNAME = '%'
    , @partitionScheme SYSNAME = '%'
    , @partitionFunction SYSNAME = '%'
    , @debug BIT = 0
)
---------------------------------------------------------------------------------------
-- Procedure Name: pr_GetTablePartitionInfo
-- Description: This procedure retrieves the partition information from the specified
--              database.  This procedure is valuable in its own right, but is expected
--              to be used in conjunction with other stored procs that will create a
--              table to store this result set.  The table data type "partitionInfoTableType"
--              is designed to create a table in the proper format.
--
-- Parameters:  
--              @databaseName   - The name of the database to look in for the partition info.
--                                This parameter is required.
--              @schemaName     - This is the name of the schema by which the partitioned
--                                table is owned. This is used to filter the results and can contain wildcards.
--              @tableName      - The name of the partitioned table. This is used to filter 
--                                the results and can contain wildcards.
--              @filegroup      - This is the name of a filegroup.  This is used to 
--                                filter the results  and can contain wildcards.
--              @partitionScheme- This is the name of a partition scheme.  This is used to filter
--                                the results and can contain wildcards.
--              @partitionFunction-This is the name of a partition function.  This is used to filter
--                                the results and can contain wildcards.
--              @debug      - When a value of 1, then certain information is printed for debugging.
--                                The default is 0.
--
-- History
-- Date         Who               What
-- 08/26/2013   David Creighton   Creation
---------------------------------------------------------------------------------------
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQLCmd nvarchar(max);

	SET @SQLCmd = N'
	SET NOCOUNT ON;
	USE ' + QUOTENAME(@databaseName) + '; 
	SELECT
		DB_NAME() AS [DatabaseName]
		,OBJECT_SCHEMA_NAME(p.object_id) AS [SchemaName]
		,OBJECT_NAME(p.object_id) AS [TableName]
		,p.index_id AS [IndexId]
		,CASE
			WHEN p.index_id = 0 THEN ''HEAP''
			ELSE i.name
		END AS [IndexName]
		,p.partition_id AS [PartitionId]
		,p.partition_number AS [PartitionNumber]
		, case
			when pf.boundary_value_on_right=1 then ''RIGHT''
			else ''LEFT''
		  end AS [RangeType]
		,prv_left.VALUE AS [LowerBoundary]
		,prv_right.VALUE AS [UpperBoundary]
		,CASE
			WHEN fg.name IS NULL THEN ds.name
			ELSE fg.name
		END AS [FileGroupName]
		,CASE
			WHEN p.index_id IN (0,1) THEN p.ROW_COUNT
			ELSE 0
		 END AS [RowCount]
		,CAST(p.used_page_count * 0.0078125 AS NUMERIC(18,2)) AS [UsedPages_MB]
		,CAST(p.in_row_data_page_count * 0.0078125 AS NUMERIC(18,2)) AS [DataPages_MB]
		,CAST(p.reserved_page_count * 0.0078125 AS NUMERIC(18,2)) AS [ReservedPages_MB]
		,CASE
			WHEN p.index_id IN (0,1) THEN ''data''
			ELSE ''index''
		END [Type]
		,ps.name AS PartitionScheme
		,pf.name AS PartitionFunction
	FROM sys.dm_db_partition_stats p
		INNER JOIN sys.indexes i
			ON i.OBJECT_ID = p.OBJECT_ID AND i.index_id = p.index_id
		INNER JOIN sys.data_spaces ds
			ON ds.data_space_id = i.data_space_id
		LEFT OUTER JOIN sys.partition_schemes ps
			ON ps.data_space_id = i.data_space_id
		LEFT OUTER JOIN sys.destination_data_spaces dds
			ON dds.partition_scheme_id = ps.data_space_id
			AND dds.destination_id = p.partition_number
		LEFT OUTER JOIN sys.filegroups fg
			ON fg.data_space_id = dds.data_space_id
		LEFT OUTER JOIN sys.partition_range_values prv_right
			ON prv_right.function_id = ps.function_id
			AND prv_right.boundary_id = p.partition_number
		LEFT OUTER JOIN sys.partition_range_values prv_left
			ON prv_left.function_id = ps.function_id
			AND prv_left.boundary_id = p.partition_number - 1
		LEFT OUTER JOIN sys.partition_functions pf
			ON ps.function_id = pf.function_id
	WHERE
		OBJECTPROPERTY(p.OBJECT_ID, ''ISMSSHipped'') = 0
		AND p.index_id in (0,1)
		--
		-- Filters
		--
		AND OBJECT_SCHEMA_NAME(p.object_id) LIKE ''' + @schemaName + '''
		AND OBJECT_NAME(p.object_id) LIKE ''' + @tableName + '''
		AND CASE
				WHEN fg.name IS NULL THEN ds.name
				ELSE fg.name
			END LIKE ''' + @filegroup + '''
		AND COALESCE(ps.name,'''') LIKE ''' + @partitionScheme + '''
		AND COALESCE(pf.name,'''') LIKE ''' + @partitionFunction + '''
	ORDER BY
		1, 2, 3, 4, 7;'

	IF (@debug = 1)
		PRINT @SQLCmd;

	EXEC (@SQLCmd);

END
GO
