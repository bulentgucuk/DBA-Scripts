USE [msdb]
GO

/****** Object:  Job [ADMIN - DatabaseIntegrityCheck - USER_DATABASES #1]    Script Date: 6/30/2020 6:02:35 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 6/30/2020 6:02:35 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
SELECT @jobId = job_id FROM msdb.dbo.sysjobs WHERE (name = N'ADMIN - DatabaseIntegrityCheck - USER_DATABASES #1')
IF (@jobId IS NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ADMIN - DatabaseIntegrityCheck - USER_DATABASES #1', 
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
/****** Object:  Step [Start job step 1]    Script Date: 6/30/2020 6:02:36 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId AND step_id = 1)
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
/****** Object:  Step [ADMIN - DatabaseIntegrityCheck - USER_DATABASES]    Script Date: 6/30/2020 6:02:36 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId AND step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ADMIN - DatabaseIntegrityCheck - USER_DATABASES', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE [dbo].[DatabaseIntegrityCheck]
@Databases = ''USER_DATABASES'',
@DatabasesInParallel = ''Y'',
@LogToTable = ''Y''', 
		@database_name=N'master', 
		@output_file_name=N'$(ESCAPE_SQUOTE(SQLLOGDIR))\DatabaseIntegrityCheck_#1_$(ESCAPE_SQUOTE(JOBID))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ADMIN - DatabaseIntegrityCheck - USER_DATABASES - Retry]    Script Date: 6/30/2020 6:02:36 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId AND step_id = 3)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ADMIN - DatabaseIntegrityCheck - USER_DATABASES - Retry', 
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
	, @GoBackStartTime DATETIME = DATEADD(DAY, -3, GETDATE())
	, @CommandType NVARCHAR(60) = ''DBCC_CHECKDB''
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
AND		CommandType = @CommandType
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

			EXECUTE [dbo].[DatabaseIntegrityCheck]
			  @Databases = @DbName
			, @LogToTable = ''Y''
			, @Execute = ''Y'';

		SET @MaxRowId = @MaxRowId -1;
	END
-- Drop temp table
DROP TABLE #FailedCommands;
', 
		@database_name=N'master', 
		@output_file_name=N'$(ESCAPE_SQUOTE(SQLLOGDIR))\DatabaseIntegrityCheck_Retry_$(ESCAPE_SQUOTE(JOBID))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'ADMIN - DatabaseIntegrityCheck - USER_DATABASES #1', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180513, 
		@active_end_date=99991231, 
		@active_start_time=111500, 
		@active_end_time=235959, 
		@schedule_uid=N'a2a69c10-675e-4fd7-813f-0ef126c0a6da'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


