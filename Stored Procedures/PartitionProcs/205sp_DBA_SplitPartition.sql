USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DBA_SplitPartition]') AND type in (N'P', N'PC'))
	EXEC( 'CREATE PROCEDURE [dbo].[sp_DBA_SplitPartition] AS' )
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE dbo.sp_DBA_SplitPartition
	  @PSName SYSNAME = 'DailyRollingPS'-- 'ThreeMonth_MonthlyRollingPS'--
	, @PartitionPeriod VARCHAR(7) = 'Daily' -- 'Monthly' --
	, @Debug BIT = 1
	, @DryRun BIT = 1
	, @NumberOfFuturePartitions SMALLINT = 4
AS
BEGIN

/****

EXEC dbo.sp_DBA_SplitPartition
	  @PSName  = 'DailyRollingPS'--'ThreeMonth_MonthlyRollingPS'--
	, @PartitionPeriod = 'Daily' --'Monthly' --
	, @Debug = 1
	, @DryRun = 1
	, @NumberOfFuturePartitions = 3 ;


***/



	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#TablePartitions') IS NOT NULL
		DROP TABLE #TablePartitions;

	DECLARE	@SwitchPartitionNumber INT
		, @SwithBoundary NVARCHAR(32)
		, @SwithBoundaryDate DATETIME
		, @SQL NVARCHAR(MAX)
		, @FGName SYSNAME
		, @MaxPartitionDifference SMALLINT
		, @NextPartitionBoundary DATETIME
		, @PFName SYSNAME;


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
	INTO	#TablePartitions
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
	ORDER BY so.name ASC, si.name ASC, ps.name ASC, dds.destination_id DESC, pp.parameter_id ASC;



	SELECT	@SwithBoundary = CAST(MAX(included_boundary_value) AS NVARCHAR(32))
	FROM	#TablePartitions
	WHERE	included_boundary_value IS NOT NULL;


	IF ISDATE(@SwithBoundary) = 1
		BEGIN
			SET @SwithBoundaryDate = @SwithBoundary;
		
			SELECT	@SwitchPartitionNumber = partition_number,
					@FGName = [filegroup],
					@PFName = partition_function
			FROM	#TablePartitions
			WHERE	included_boundary_value = @SwithBoundaryDate;
		END


	-- GET THE @MaxPartitionDifference BASED ON @PartitionPeriod
		IF @PartitionPeriod = 'Monthly'
			BEGIN 
				SELECT @MaxPartitionDifference = DATEDIFF(MONTH, GETDATE(), @SwithBoundaryDate);
			END

		IF @PartitionPeriod = 'Daily'
			BEGIN 
				SELECT @MaxPartitionDifference = DATEDIFF(DAY, GETDATE(), @SwithBoundaryDate);
			END

		/***	
		SELECT DISTINCT *,
			@SwithBoundaryDate AS 'SwithBoundaryDate', @MaxPartitionDifference AS 'MaxPartitionDifference', @NumberOfFuturePartitions AS 'NumberOfFuturePartitions',
			@PartitionPeriod AS 'PartitionPeriod',
			@NextPartitionBoundary AS 'NextPartitionBoundary'
		FROM #TablePartitions;
		***/

	IF @MaxPartitionDifference <= 0
	--IF @MaxPartitionDifference <= @NumberOfFuturePartitions
		BEGIN 
			IF @PartitionPeriod = 'Monthly'
				BEGIN 
					SELECT	@NextPartitionBoundary = CAST(DATEADD(MONTH, 1, CAST(DATEADD(DAY, -(DATEPART(DAY,GETDATE())) + 1, GETDATE()) AS DATE)) AS DATETIME);
				END

			IF @PartitionPeriod = 'Daily'
				BEGIN
					--SELECT	@NextPartitionBoundary = DATEADD(DAY,1,CAST(GETDATE() AS DATE));--@SwithBoundaryDate);
					SELECT	@NextPartitionBoundary = DATEADD(DAY,1,CAST(@SwithBoundaryDate AS DATE));--@SwithBoundaryDate);
				END

			--SELECT	@MaxPartitionDifference = 1
	
		END


	IF @MaxPartitionDifference > 0 AND @MaxPartitionDifference < @NumberOfFuturePartitions
	--IF @MaxPartitionDifference <= @NumberOfFuturePartitions
		BEGIN 
			IF @PartitionPeriod = 'Monthly'
				BEGIN 
					SELECT	@NextPartitionBoundary = DATEADD(MONTH,1,CAST(@SwithBoundaryDate AS DATETIME));
				END

			IF @PartitionPeriod = 'Daily'
				BEGIN
					--SELECT	@NextPartitionBoundary = DATEADD(DAY,1,CAST(GETDATE() AS DATE));--@SwithBoundaryDate);
					SELECT	@NextPartitionBoundary = DATEADD(DAY,1,CAST(@SwithBoundaryDate AS DATE));--@SwithBoundaryDate);
				END

			--SELECT	@MaxPartitionDifference = 1
	
		END



	WHILE	@MaxPartitionDifference < @NumberOfFuturePartitions
		BEGIN
			-- Build the alter partition scheme command
			SELECT @SQL = 'ALTER PARTITION SCHEME ' + QUOTENAME(@PSName) + ' NEXT USED ' + QUOTENAME(@FGName) + ';' ;
	
			IF @Debug = 1
				BEGIN
					PRINT '---------------------- PARTITION SCHEME INFO -----------------------'
					PRINT ''
					PRINT 'Alter partition scheme command  : ' + CAST(@SQL AS VARCHAR(512));
					PRINT ''
					PRINT '---------------------- PARTITION SCHEME INFO -----------------------'
					PRINT ''
				END

			IF @DryRun = 0
				BEGIN
					EXEC sys.sp_executesql @stmt = @SQL;
				END


			-- Build the partition function split command
			SELECT	@SQL = 'ALTER PARTITION FUNCTION ' + QUOTENAME(@PFName) + '()' + ' SPLIT RANGE (' + '''' + CONVERT(VARCHAR(10), @NextPartitionBoundary, 111) + '''' + ');' ;

				IF @Debug = 1
					BEGIN
						PRINT '---------------------- PARTITION FUNCTION SPLIT INFO -----------------------'
						PRINT ''
						PRINT 'Partition boundary value          : ' + CAST(@NextPartitionBoundary AS VARCHAR(32));
						PRINT 'Alter partition function command  : ' + CAST(@SQL AS VARCHAR(512));
						PRINT ''
						PRINT '---------------------- PARTITION FUNCTION SPLIT INFO -----------------------'
						PRINT ''
					END

				IF @DryRun = 0
					BEGIN
						EXEC sys.sp_executesql @stmt = @SQL;
					END
		

			IF @PartitionPeriod = 'MONTHLY'
				SELECT	@NextPartitionBoundary = DATEADD(MONTH, 1, @NextPartitionBoundary);

			IF @PartitionPeriod = 'DAILY'
				SELECT	@NextPartitionBoundary = DATEADD(DAY, 1, @NextPartitionBoundary);

			SELECT @MaxPartitionDifference = @MaxPartitionDifference + 1


		END
			
END

