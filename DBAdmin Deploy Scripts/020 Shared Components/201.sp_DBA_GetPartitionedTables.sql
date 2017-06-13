USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DBA_GetPartitionedTables]') AND type in (N'P', N'PC'))
	EXEC( 'CREATE PROCEDURE [dbo].[sp_DBA_GetPartitionedTables] AS' )
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE dbo.sp_DBA_GetPartitionedTables
		  @DBName SYSNAME
		, @PSName SYSNAME
		, @Debug BIT = 1
		, @DryRun BIT = 1
AS
BEGIN

/***

EXEC dbo.sp_DBA_GetPartitionedTables
	  @DBName = NULL
	, @PSName = 'ThreeMonth_MonthlyRollingPS'
	, @Debug = 1 -- Prints the commands being executed
	, @DryRun = 1 -- Does not execute the commands if set to 1 else executes the commands


DECLARE @DBName SYSNAME 
		, @PSName SYSNAME = 'ThreeMonth_MonthlyRollingPS'
		, @Debug BIT = 1
		, @DryRun BIT = 1;
***/

	SET NOCOUNT ON;
	
	SELECT	@DBName = DB_NAME();


	IF (@PSName IS NULL)
		BEGIN
			RAISERROR('Please pass non null values for @PSName parameter',16,1);
		END

	DECLARE @Sql NVARCHAR(MAX);

	-- Table to store list of partitioned tables
	IF OBJECT_ID('Tempdb..#DynamicPartitionSwitchWork')	IS NOT NULL
		DROP TABLE #DynamicPartitionSwitchWork;

	CREATE TABLE #DynamicPartitionSwitchWork
		(RowId INT IDENTITY NOT NULL,
		TableName sysname NOT NULL,
		IndexName sysname NOT NULL,
		indexType VARCHAR(32) NOT NULL,
		PartitionedColumnName VARCHAR(32) NOT NULL,
		PartitionScheme sysname NOT NULL,
		PartitionFunction sysname NOT NULL,
		PartitionDataType sysname NOT NULL,
		PartitionBoundary sysname NOT NULL,
		FileGroupName VARCHAR(32) NOT NULL
		)

	INSERT INTO #DynamicPartitionSwitchWork
			(
			  TableName ,
			  IndexName ,
			  indexType ,
			  PartitionedColumnName ,
			  PartitionScheme ,
			  PartitionFunction ,
			  PartitionDataType ,
			  PartitionBoundary ,
			  FileGroupName
			)
	SELECT DISTINCT
		ss.name + '.' + so.name AS [object],
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
	--	dds.destination_id AS [partition_number],
	--	pp.parameter_id [parameter_id],
		pf.type_desc + ' ' + CASE pf.boundary_value_on_right WHEN 1 THEN 'RIGHT' ELSE 'LEFT' END AS [boundary_type],
	--	prv.value AS [included_boundary_value],
		ds.name AS [filegroup]
	--	p.rows AS [rows],
	--	CASE WHEN p2.total_rows = 0 THEN 0 ELSE CAST(p.rows AS float) / CAST(p2.total_rows AS float) END AS [percent_of_rows]
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
	ORDER BY [object] ASC;


	DECLARE @Cnt INT = 1,
			@MaxCnt INT;

	SELECT	@MaxCnt = MAX(RowId)
	FROM	#DynamicPartitionSwitchWork;


	-- Variables for creeating the switch tables
	DECLARE @TableName sysname

	WHILE @Cnt <= @MaxCnt
		BEGIN
		
			SELECT	@TableName = TableName
			FROM	#DynamicPartitionSwitchWork
			WHERE	RowId = @Cnt
		
			IF @Debug = 1
				BEGIN
					PRINT '---------------------- PARTITIONED TABLE INFO -----------------------'
					PRINT 'Database name                : ' + @DBName;
					PRINT 'Partition scheme name        : ' + @PSName;
					PRINT 'Working on partitioned table : ' + @TableName;
					PRINT '---------------------- PARTITIONED TABLE INFO -----------------------'
					PRINT ''
				END

			EXEC dbo.sp_DBA_CreateSwitchTable
				  @DBName = @DBName
				, @PSName = @PSName
				, @table_name = @TableName
				, @Debug = @Debug
				, @DryRun = @DryRun;


			SELECT @Cnt = @Cnt + 1;
		END
END
GO
