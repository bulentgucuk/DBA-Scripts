USE [msdb]
GO

/****** Object:  Job [ADMIN_Rebuild_NoneCompressed_Index_Compressed]    Script Date: 6/23/2020 8:12:15 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 6/23/2020 8:12:16 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'ADMIN_Rebuild_NoneCompressed_Index_Compressed')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ADMIN_Rebuild_NoneCompressed_Index_Compressed', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [Start job step 1]    Script Date: 6/23/2020 8:12:16 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 1)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Start job step 1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use master;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Index Compression Broncos]    Script Date: 6/23/2020 8:12:16 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Index Compression Broncos', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE Broncos
GO
SET QUOTED_IDENTIFIER ON;
/**
SERVERPROPERTY(''EngineEdition'')
1 = Personal or Desktop Engine (Not available in SQL Server 2005 (9.x) and later versions.)
2 = Standard (This is returned for Standard, Web, and Business Intelligence.)
3 = Enterprise (This is returned for Evaluation, Developer, and both Enterprise editions.)
4 = Express (This is returned for Express, Express with Tools and Express with Advanced Services)
5 = SQL Database
6 - SQL Data Warehouse
8 = managed instance
Base data type: int
**/
--Drop temp table before populating
DROP TABLE IF EXISTS #PreCompresion;
SELECT
	  ROW_NUMBER()OVER(ORDER BY s.name, t.name, i.index_id) AS RowId
	, ROW_NUMBER()OVER(PARTITION BY s.name, t.name ORDER BY  s.name, t.name, i.index_id) AS PartitionId	
	, DB_NAME() AS ''DatabaseName''
	, s.name AS ''SchemaName''
	, t.Name AS ''TableName''
	, t.create_date AS ''CreateDate''
	, CASE
		WHEN I.index_id = 0 THEN ''HEAP''
		ELSE i.Name
		END AS ''IndexName''
	, i.index_id AS ''IndexId''
	, MAX(ps.row_count) AS ''RowCount''
	, SUM(ps.reserved_page_count) * 8.0 / (1024) as ''SpaceInMB''
	, (SUM(ps.reserved_page_count) * 8.0 / (1024))/ 1024 as ''SpaceInGB''
	, CASE
		WHEN MAX(ps.row_count) = 0 THEN 0
		ELSE (8 * 1024* SUM(ps.reserved_page_count)) / NULLIF(MAX(ps.row_count), 0)
		END AS ''Bytes/Row''
	, p.Data_compression_desc
INTO #PreCompresion
FROM	sys.dm_db_partition_stats AS ps
	INNER JOIN sys.indexes AS i ON ps.object_id = i.object_id and ps.index_id = i.index_id
	INNER JOIN sys.tables AS t ON i.object_id = t.object_id
	INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
	INNER JOIN sys.partitions as p ON p.index_id = i.index_id and p.object_id = t.object_id
WHERE	t.is_ms_shipped = 0
and		ps.row_count > 1000
and		p.data_compression_desc in (''COLUMNSTORE'', ''NONE'')
GROUP BY s.name, t.Name, i.Name, i.index_id, t.create_date, p.Data_compression_desc;

--Alter the table to add the RebuidIndexCompressStmt and date fields for the operation and logging 
ALTER TABLE #PreCompresion ADD RebuidIndexCompressStmt NVARCHAR(512) NULL;
ALTER TABLE #PreCompresion ADD RebuildIndexStartDatetime DATETIME NULL;
ALTER TABLE #PreCompresion ADD RebuildIndexEndDatetime DATETIME NULL;

--Tables with clustered columnstore indexes
DROP TABLE IF EXISTS #ColumnStoreIndexedTables;
-- Distinct tables with more than 1 index
WITH CTE_DISTINCT_Tables AS (
	SELECT	DISTINCT DatabaseName
		, SchemaName
		, TableName
	FROM	#PreCompresion
	WHERE	PartitionId > 1
	)
-- Get all the tables with columnstore index
SELECT	t.*
INTO	#ColumnStoreIndexedTables
FROM	#PreCompresion AS t
	INNER JOIN CTE_DISTINCT_Tables AS cte ON cte.DatabaseName = t.DatabaseName AND cte.SchemaName = t.SchemaName AND cte.TableName = t.TableName
WHERE	t.data_compression_desc = ''COLUMNSTORE'';

--See if the indexes can be rebuild online with the editin installed
DECLARE @RebuildOnlineOrOffline NVARCHAR(3)
SELECT	@RebuildOnlineOrOffline =
			CASE WHEN SERVERPROPERTY(''EngineEdition'') IN (3, 5, 6, 8) THEN ''ON''
				 ELSE ''OFF''
			END;
/****
SELECT t.*,
	CASE
		WHEN t.IndexId = 0 THEN ''ALTER TABLE '' + QUOTENAME(t.SchemaName) + ''.'' + QUOTENAME(t.TableName) + '' REBUILD WITH (DATA_COMPRESSION = PAGE);''
		WHEN t.IndexId = 1 AND t.data_compression_desc = ''COLUMNSTORE'' AND cte.RowId IS NULL THEN ''ALTER INDEX '' + QUOTENAME(t.IndexName) + '' ON '' + QUOTENAME(t.SchemaName) + ''.'' + QUOTENAME(t.TableName) + '' REBUILD WITH (ONLINE = OFF, DATA_COMPRESSION = PAGE);''
		WHEN t.IndexId = 1 AND t.data_compression_desc = ''COLUMNSTORE'' AND cte.RowId IS NOT NULL THEN ''ALTER INDEX '' + QUOTENAME(t.IndexName) + '' ON '' + QUOTENAME(t.SchemaName) + ''.'' + QUOTENAME(t.TableName) + '' REBUILD WITH (ONLINE = OFF, DATA_COMPRESSION = PAGE);''
		WHEN t.IndexId > 1 AND t.data_compression_desc = ''NONE'' AND cte.RowId IS NOT NULL THEN ''ALTER INDEX '' + QUOTENAME(t.IndexName) + '' ON '' + QUOTENAME(t.SchemaName) + ''.'' + QUOTENAME(t.TableName) + '' REBUILD WITH (ONLINE = OFF, DATA_COMPRESSION = PAGE);''
		ELSE ''ALTER INDEX '' + QUOTENAME(t.IndexName) + '' ON '' + QUOTENAME(t.SchemaName) + ''.'' + QUOTENAME(t.TableName) + '' REBUILD WITH (ONLINE = '' + @RebuildOnlineOrOffline + '', DATA_COMPRESSION = PAGE);''
	  END AS RebuidIndexCompressStmt
	, cte.*
FROM	#PreCompresion AS t
	LEFT OUTER JOIN #ColumnStoreIndexedTables AS cte ON cte.DatabaseName = t.DatabaseName AND cte.SchemaName = t.SchemaName AND cte.TableName = t.TableName
ORDER BY t.schemaname, t.tablename, t.indexid

SELECT * FROM #PreCompresion
SELECT * FROM #ColumnStoreIndexedTables
****/
--Set the indexes on tables with columnstore index
UPDATE t
SET	t.RebuidIndexCompressStmt =
	CASE
		WHEN t.IndexId = 0 THEN ''ALTER TABLE '' + QUOTENAME(t.SchemaName) + ''.'' + QUOTENAME(t.TableName) + '' REBUILD WITH (DATA_COMPRESSION = PAGE);''
		WHEN t.IndexId = 1 AND t.data_compression_desc = ''COLUMNSTORE'' AND cte.RowId IS NULL THEN ''ALTER INDEX '' + QUOTENAME(t.IndexName) + '' ON '' + QUOTENAME(t.SchemaName) + ''.'' + QUOTENAME(t.TableName) + '' REBUILD WITH (ONLINE = OFF, DATA_COMPRESSION = PAGE);''
		WHEN t.IndexId = 1 AND t.data_compression_desc = ''COLUMNSTORE'' AND cte.RowId IS NOT NULL THEN ''ALTER INDEX '' + QUOTENAME(t.IndexName) + '' ON '' + QUOTENAME(t.SchemaName) + ''.'' + QUOTENAME(t.TableName) + '' REBUILD WITH (ONLINE = OFF, DATA_COMPRESSION = PAGE);''
		WHEN t.IndexId > 1 AND t.data_compression_desc = ''NONE'' AND cte.RowId IS NOT NULL THEN ''ALTER INDEX '' + QUOTENAME(t.IndexName) + '' ON '' + QUOTENAME(t.SchemaName) + ''.'' + QUOTENAME(t.TableName) + '' REBUILD WITH (ONLINE = OFF, DATA_COMPRESSION = PAGE);''
		ELSE ''ALTER INDEX '' + QUOTENAME(t.IndexName) + '' ON '' + QUOTENAME(t.SchemaName) + ''.'' + QUOTENAME(t.TableName) + '' REBUILD WITH (ONLINE = '' + @RebuildOnlineOrOffline + '', DATA_COMPRESSION = PAGE);''
	  END
FROM	#PreCompresion AS t
	LEFT OUTER JOIN #ColumnStoreIndexedTables AS cte ON cte.DatabaseName = t.DatabaseName AND cte.SchemaName = t.SchemaName AND cte.TableName = t.TableName;

DECLARE
	  @Rowid INT = 1
	, @MaxRowid INT
	, @RebuidIndexCompressStmt NVARCHAR(512);

IF OBJECT_ID(''dbo.RebuildIndexCompressed'') IS NOT NULL
	DROP TABLE dbo.RebuildIndexCompressed;

SELECT	ROW_NUMBER()OVER(ORDER BY t.SchemaName, t.TableName, t.IndexId) AS RowId
	, t.DatabaseName
	, t.SchemaName
	, t.TableName
	, t.IndexName
	, t.IndexId
	, t.[RowCount]
	, t.SpaceInMB
	, t.SpaceInGB
	, t.[Bytes/Row]
	, t.data_compression_desc
	, t.RebuidIndexCompressStmt
	, t.RebuildIndexStartDatetime
	, t.RebuildIndexEndDatetime
INTO	dbo.RebuildIndexCompressed
FROM	#PreCompresion AS t
WHERE	t.data_compression_desc = ''NONE'';


--Get the rowcount
SELECT @MaxRowid = COUNT(Rowid)
FROM dbo.RebuildIndexCompressed;

--Get the minrowid
SELECT @Rowid = MIN(Rowid)
FROM dbo.RebuildIndexCompressed
WHERE	RebuildIndexStartDatetime IS NULL
AND		RebuildIndexEndDatetime IS NULL;

WHILE @Rowid <= @MaxRowid
	BEGIN
		-- Get the index rebuild statement
		SELECT	@RebuidIndexCompressStmt = RebuidIndexCompressStmt
		FROM	dbo.RebuildIndexCompressed
		WHERE	RowId = @Rowid;

		-- Update the RebuildIndexStartDatetime
		UPDATE dbo.RebuildIndexCompressed
		SET		RebuildIndexStartDatetime = GETDATE()
		WHERE	RowId = @Rowid;

		-- Execute statement
		EXEC sys.sp_executesql @stmt  = @RebuidIndexCompressStmt;

		-- Update the RebuildIndexEndDatetime
		UPDATE dbo.RebuildIndexCompressed
		SET		RebuildIndexEndDatetime = GETDATE()
		WHERE	RowId = @Rowid;

		SELECT @Rowid = @Rowid + 1;

	END

GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


