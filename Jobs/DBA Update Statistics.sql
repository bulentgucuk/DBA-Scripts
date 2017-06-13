USE [msdb]
GO

/****** Object:  Job [A DBA Update Statistics]    Script Date: 10/25/2011 13:54:15 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 10/25/2011 13:54:16 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'A DBA Update Statistics', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBAs', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Update Stats For All Online Databases]    Script Date: 10/25/2011 13:54:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Update Stats For All Online Databases', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- DYNAMICALLY RUN DBCC CHECKDB
SET NOCOUNT ON
DECLARE	@RowId TINYINT,
		@DbName SYSNAME,
		@Str VARCHAR(100);
DECLARE	@DbNames TABLE(
		RowId TINYINT IDENTITY (1,1),
		DbName SYSNAME
		)
INSERT INTO @DbNames
SELECT	Name
FROM	SYS.DATABASES
WHERE	Is_Read_Only = 0
AND		State_Desc = ''ONLINE''
AND		Name <> ''Tempdb''

SELECT	@RowId = MAX(RowId) FROM @DbNames
WHILE	@RowId > 0
	BEGIN
		SELECT	@DbName = DbName FROM @DbNames WHERE RowId = @RowId
		--PRINT	@DBNAME
		--SELECT	@Str = ''USE '' + @DbName + '' DBCC CHECKDB WITH PHYSICAL_ONLY ''
		SELECT	@Str = ''USE '' + @DbName + '' EXEC dbo.sp_updatestats''
		PRINT	@STR
		EXEC	(@STR)
		SELECT	@RowId = @RowId - 1
	END', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'A DBA Update Statistics', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=12, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20111025, 
		@active_end_date=99991231, 
		@active_start_time=111000, 
		@active_end_time=110959, 
		@schedule_uid=N'23324071-4bbf-4efc-b7a6-d0c65ae666fc'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


