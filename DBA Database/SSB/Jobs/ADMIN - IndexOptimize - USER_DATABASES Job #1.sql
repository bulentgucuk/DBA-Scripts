USE [msdb]
GO

/****** Object:  Job [ADMIN - IndexOptimize - USER_DATABASES Job #1]    Script Date: 6/30/2020 6:03:10 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 6/30/2020 6:03:10 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'ADMIN - IndexOptimize - USER_DATABASES Job #1')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ADMIN - IndexOptimize - USER_DATABASES Job #1', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Source: https://ola.hallengren.com', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [Start job step 1]    Script Date: 6/30/2020 6:03:11 PM ******/
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
		@command=N'USE master;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ADMIN - IndexOptimize - USER_DATABASES]    Script Date: 6/30/2020 6:03:11 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ADMIN - IndexOptimize - USER_DATABASES', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE dbo.IndexOptimize
	@Databases = ''USER_DATABASES'',
	@FragmentationLow = NULL,
	@FragmentationMedium = ''INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
	@FragmentationHigh = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
	@FragmentationLevel1 = 10,
	@FragmentationLevel2 = 30,
	@MinNumberOfPages = 1000,
	@LOBCompaction = ''Y'',
	@OnlyModifiedStatistics = ''Y'',
	@SortInTempdb = ''Y'',
	@MaxDOP = 4,
	@PartitionLevel = ''Y'',
	@MSShippedObjects = ''Y'',
	@DatabaseOrder = ''DATABASE_NAME_ASC'',
	@DatabasesInParallel = ''Y'',
	@Execute = ''Y'',
	@LogToTable = ''Y'';', 
		@database_name=N'master', 
		@output_file_name=N'$(ESCAPE_SQUOTE(SQLLOGDIR))\IndexOptimize_$(ESCAPE_SQUOTE(JOBID))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ADMIN - IndexOptimize - USER_DATABASES Retry]    Script Date: 6/30/2020 6:03:11 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 3)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ADMIN - IndexOptimize - USER_DATABASES Retry', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE master;
GO
SET NOCOUNT ON;
DECLARE @DbName VARCHAR(128)
	, @IndexName VARCHAR(256)
	, @RetryStartDateTime DATETIME = GETDATE()
	, @GoBackStartTime DATETIME = DATEADD(DAY, -1, GETDATE())
	, @RowId INT
	, @MaxRowId INT;

-- Find failed commands
IF OBJECT_ID(''Tempdb..#FailedCommands'') IS NOT NULL
	DROP TABLE #FailedCommands;

SELECT	ROW_NUMBER()OVER(Order by ID) AS ''RowId''
	, DatabaseName
	, SchemaName
	, ObjectName
	, ErrorNumber
INTO	#FailedCommands
FROM	dbo.commandlog
WHERE	StartTime > @GoBackStartTime
AND		CommandType = ''ALTER_INDEX''
AND		ErrorNumber > 0;

--SELECT * FROM #FailedCommands;

SELECT	@MaxRowId = MAX(RowId)
FROM	#FailedCommands;


WHILE @MaxRowId >= 1
	BEGIN
		SELECT
			  @DbName = DatabaseName
			, @IndexName = DatabaseName + ''.'' + SchemaName + ''.'' + ObjectName
		FROM	#FailedCommands
		WHERE	RowId = @MaxRowId;

		EXECUTE [dbo].[IndexOptimize]
			  @Databases  = @DbName
			, @FragmentationLow  = NULL
			, @FragmentationMedium  = ''INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE''
			, @FragmentationHigh  = ''INDEX_REBUILD_ONLINE,INDEX_REORGANIZE,INDEX_REBUILD_OFFLINE''
			, @FragmentationLevel1 = 10
			, @FragmentationLevel2 = 30
			, @MinNumberOfPages = 1000
			, @SortInTempdb = ''Y''
			, @MaxDOP = 4  --In SQL Server Standard Edition index maintenance is a single threaded operation
			--, @FillFactor = 80 --Leave it alone to the setting of each index blanket 80 is just an overkill
			, @PadIndex  = NULL
			, @LOBCompaction  = ''Y''
			, @PartitionLevel = ''Y''
			, @MSShippedObjects  = ''N''
			, @Indexes  = @IndexName
			, @TimeLimit = NULL
			, @Delay = NULL
			, @WaitAtLowPriorityMaxDuration = NULL
			, @WaitAtLowPriorityAbortAfterWait = NULL
			, @LockTimeout = NULL
			, @LogToTable = ''Y''
			, @Execute = ''Y''

		SET @MaxRowId = @MaxRowId -1;
	END
-- Drop temp table
DROP TABLE #FailedCommands;
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'ADMIN - IndexOptimize - USER_DATABASES', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=63, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190315, 
		@active_end_date=99991231, 
		@active_start_time=150100, 
		@active_end_time=235959, 
		@schedule_uid=N'ed4544a3-6b85-4485-a16f-ae2a93dd66d0'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

