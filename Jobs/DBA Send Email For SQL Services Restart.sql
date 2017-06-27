USE [msdb]
GO

/****** Object:  Job [DBA Send Email For SQL Services Restart]    Script Date: 03/13/2013 11:44:05 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBA Send Email For SQL Services Restart')
EXEC msdb.dbo.sp_delete_job @job_id=N'41ced687-ac01-44ee-8ee6-ff31a16fdf29', @delete_unused_schedule=1
GO

USE [msdb]
GO

/****** Object:  Job [DBA Send Email For SQL Services Restart]    Script Date: 03/13/2013 11:44:05 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 03/13/2013 11:44:06 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Send Email For SQL Services Restart', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DBA Send Email For SQL Services Restart]    Script Date: 03/13/2013 11:44:06 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA Send Email For SQL Services Restart', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE msdb
GO
-- Declare variables for necessary email content
DECLARE @ServerName VARCHAR(128),
		@ComputerNamePhysicalNetBIOS VARCHAR(128),
		@Datetime DATETIME,
		@EmailRecipients VARCHAR(512),
		@EmailSubject VARCHAR(128),
		@MessageBody VARCHAR(512)

-- Set variables to proper values
SELECT	@ComputerNamePhysicalNetBIOS = CAST(SERVERPROPERTY(''ComputerNamePhysicalNetBIOS'') AS VARCHAR(128)),
		@ServerName = CAST(SERVERPROPERTY(''ServerName'') AS VARCHAR(128)),
		@Datetime = GETDATE(),
		@EmailRecipients = ''bgucuk@servicesource.com'', -- if more than one email address use ; between email addresses
		@EmailSubject = ''SQL Server Services Have Been Started!!!''

SELECT	@MessageBody = ''SQL Server services have been started on a SQL Server Instance named '' + @ServerName + CHAR(13) +
		''running on windows server '' + @ComputerNamePhysicalNetBIOS + ''.'' + CHAR(13) + CHAR(13) +
		''Investigate the service restart if it has not been communicated.''

EXEC	sp_send_dbmail
	@recipients = @EmailRecipients,
	@subject = @EmailSubject,
	@body = @MessageBody,
	@body_format = ''TEXT''
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA Send Email For SQL Services Restart', 
		@enabled=1, 
		@freq_type=64, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20121015, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'fe304225-9741-49b3-ba50-fca4a8c1b246'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


