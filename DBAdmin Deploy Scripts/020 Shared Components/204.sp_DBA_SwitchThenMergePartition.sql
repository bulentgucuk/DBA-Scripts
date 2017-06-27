USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DBA_SwitchThenMergePartition]') AND type in (N'P', N'PC'))
	EXEC( 'CREATE PROCEDURE [dbo].[sp_DBA_SwitchThenMergePartition] AS' )
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE dbo.sp_DBA_SwitchThenMergePartition
	  @PSName SYSNAME = 'PS_CustomerActionLog' --'DailyRollingPS'-- 'ThreeMonth_MonthlyRollingPS'--
	, @PartitionPeriod VARCHAR(7) = 'BIGINT' --'Daily' -- 'Monthly' --
	, @Debug BIT = 1
	, @DryRun BIT = 1
	, @NumberOfPastPartitionsToKeep SMALLINT = 10
AS
BEGIN

/*************

EXEC  dbo.sp_DBA_SwitchThenMergePartition
	  @PSName = 'PS_CustomerActionLog'-- 'ThreeMonth_MonthlyRollingPS'--
	, @PartitionPeriod = 'BIGINT' --'Daily' -- 'Monthly' --
	, @Debug = 1
	, @DryRun = 1
	, @NumberOfPastPartitionsToKeep = 10

*************/

	SET NOCOUNT ON;

	DECLARE	@SwithBoundary NVARCHAR(32)
		, @SwithBoundaryDate DATETIME
		, @PFName SYSNAME
		, @SQL NVARCHAR(MAX);

	IF OBJECT_ID('tempdb..#PartitionsToMerge') IS NOT NULL
		DROP TABLE #PartitionsToMerge;


	SELECT	DISTINCT 	
		pf.name AS [partition_function],
		ps.name AS [partition_scheme],
		prv.value AS [included_boundary_value],
		dds.destination_id AS [partition_number],
		p.rows AS [rows],
		DENSE_RANK()OVER(ORDER BY pf.name,prv.value) AS RowID
	INTO	#PartitionsToMerge
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
	AND		PS.name = @PSName
	AND		prv.value IS  NOT NULL

	DECLARE	@CurrentRowId INT = 1
		, @MaxRowId INT

	IF @PartitionPeriod = 'Daily'
		BEGIN
			SELECT	@MaxRowId = MAX(RowId)
			FROM #PartitionsToMerge
			WHERE	included_boundary_value IS NOT NULL
			AND		CAST(included_boundary_value AS DATETIME) < DATEADD(DAY, -@NumberOfPastPartitionsToKeep ,CAST(GETDATE() AS DATETIME));
		END

	IF @PartitionPeriod = 'Monthly'
		BEGIN
			SELECT	@MaxRowId = MAX(RowId)
			FROM #PartitionsToMerge
			WHERE	included_boundary_value IS NOT NULL
			AND		CAST(included_boundary_value AS DATETIME) < DATEADD(MONTH, -@NumberOfPastPartitionsToKeep ,CAST(GETDATE() AS DATETIME));
		END

	IF @PartitionPeriod = 'INT' OR @PartitionPeriod = 'BIGINT'
		BEGIN
			SELECT	@MaxRowId = MAX(RowId) - @NumberOfPastPartitionsToKeep
			FROM #PartitionsToMerge
			WHERE	included_boundary_value IS NOT NULL
			
		END



	WHILE @CurrentRowId <= @MaxRowId
		BEGIN

			EXEC dbo.sp_DBA_GetPartitionedTables
				  @DBName = NULL
				, @PSName = @PSName--'DailyRollingPS'
				, @Debug = @Debug -- Prints the commands being executed
				, @DryRun = @DryRun -- Does not execute the commands if set to 1 else executes the commands


			SELECT	@SwithBoundary = CAST(included_boundary_value AS NVARCHAR(32))
			FROM	#PartitionsToMerge
			WHERE	RowId = @CurrentRowId


			IF ISDATE(@SwithBoundary) = 1
				BEGIN
					SET @SwithBoundaryDate = @SwithBoundary;

					SELECT	@PFName = partition_function
					FROM	#PartitionsToMerge
					WHERE	RowID = @CurrentRowId
					AND		partition_scheme = @PSName

					-- Build the switch command
					SELECT @SQL = 'ALTER PARTITION FUNCTION ' + QUOTENAME(@PFName) + '() MERGE RANGE (' + '''' + CONVERT(VARCHAR(10), @SwithBoundaryDate, 111) + '''' + ');' ;
				END

			IF ISNUMERIC(@SwithBoundary) = 1
				BEGIN

					SELECT	@PFName = partition_function
					FROM	#PartitionsToMerge
					WHERE	RowID = @CurrentRowId
					AND		partition_scheme = @PSName

					-- Build the switch command
					SELECT @SQL = 'ALTER PARTITION FUNCTION ' + QUOTENAME(@PFName) + '() MERGE RANGE (' + @SwithBoundary + ');' ;					

				END

					
			IF @Debug = 1
				BEGIN
					PRINT '---------------------- PARTITION MERGE -----------------------'
					PRINT 'Merge partition function command : ' + CAST(@SQL AS VARCHAR(512));
					PRINT '---------------------- PARTITION MERGE -----------------------'
					PRINT ''
				END

			IF @DryRun = 0
				BEGIN
					EXEC sys.sp_executesql @stmt = @SQL;
				END
				
			SELECT @CurrentRowId = @CurrentRowId + 1;

		END

END
GO
