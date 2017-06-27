USE [msdb]
GO

/****** Object:  Job [DBA Backup User Databases To Data Domain]    Script Date: 09/20/2011 11:45:12 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 09/20/2011 11:45:12 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Backup User Databases To Data Domain', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Backup User Databases Except ODS', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA Group', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Connect to Data Domain]    Script Date: 09/20/2011 11:45:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Connect to Data Domain', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Connect to Data Domain
EXECUTE xp_cmdshell ''Net use \\10.60.120.140 Kv5apmENxb /USER:web.prod\IUSR_SQL_SERVICE /PERSISTENT:YES''
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Backup User Databases]    Script Date: 09/20/2011 11:45:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Backup User Databases', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON
-- Declare variable
DECLARE	@DbName VARCHAR (100),
		@Str VARCHAR (1000),
		@RowId TINYINT,
		@BackupDate VARCHAR(8), -- Sets the date
		@BackupHour VARCHAR(2), -- Sets the hour
		@BackupMinute VARCHAR (2), -- Sets the minute
		@BackupTime VARCHAR (12) -- Stores above info for backup time

-- Declare table variable
DECLARE	@Table TABLE (
			RowId TINYINT IDENTITY (1,1),
			DbName VARCHAR (100)
		)
-- Insert databases to be backed up to table variable
INSERT INTO @Table
SELECT	NAME
FROM	SYS.Databases
WHERE	database_id > 4
AND	Name NOT LIKE ''ODS%''

--select * from @Table

-- Set @RowId and go into while loop to backup
SELECT	@RowId = MAX(RowId)
FROM	@Table
WHILE	@RowId > 0
	BEGIN
		-- Set the date part of the backup file name
		SELECT	@BackupDate = CONVERT (VARCHAR(8),GETDATE(),112)
		SELECT	@BackupHour = DATEPART(HH,GETDATE())
		SELECT	@BackupMinute = DATEPART(MI,GETDATE())
		-- Set length of the hour to 2 digit if it''s 1 digit
		IF LEN (@BackupHour) = 1
			BEGIN
				SET	@BackupHour = ''0''+ @BackupHour
			END

		-- Set length of the minute to 2 digit if it''s 1 digit
		IF LEN (@BackupMinute) = 1
			BEGIN
				SET	@BackupMinute = ''0''+ @BackupMinute
			END

		SELECT	@BackupTime = @BackupDate + @BackupHour + @BackupMinute
		--  Start backup database
		SELECT	@Str = ''''
		SELECT	@Str = ''BACKUP DATABASE ''+ DbName + '' TO DISK = ''''\\10.60.120.140\Backup\SPDBXX0028\UserDatabases\''+ DbName +
		--SELECT	@Str = ''BACKUP DATABASE ''+ DbName + '' TO DISK = ''''C:\TEMP\''+ DbName +
				''_db_full_'' + @BackupTime +''.bak''''''
				+ '' WITH STATS = 5, COMPRESSION''
		FROM	@Table
		WHERE	RowId = @RowId		
		PRINT	@Str
		EXEC	(@Str)
		SELECT	@RowId = @RowId - 1		
	END


', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Disconnect from Data Domain]    Script Date: 09/20/2011 11:45:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Disconnect from Data Domain', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Disconnect from Data Domain
EXECUTE xp_cmdshell ''NET USE \\10.60.120.140 /DELETE''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA Backup User Databases To Data Domain', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080723, 
		@active_end_date=99991231, 
		@active_start_time=183500, 
		@active_end_time=235959, 
		@schedule_uid=N'a3c9a3f8-0736-453d-97e1-b5a568f4c0b5'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


