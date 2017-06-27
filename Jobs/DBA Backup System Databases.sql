USE [msdb]
GO

/****** Object:  Job [DBA Backup System Databases]    Script Date: 03/13/2013 11:46:18 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBA Backup System Databases')
EXEC msdb.dbo.sp_delete_job @job_id=N'7b4f9e21-6d96-46c3-b261-078470a05467', @delete_unused_schedule=1
GO

USE [msdb]
GO

/****** Object:  Job [DBA Backup System Databases]    Script Date: 03/13/2013 11:46:18 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 03/13/2013 11:46:18 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Backup System Databases', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Backup system databases compressed upon successful completion starts the ''DBA Delete System Database Files'' Job', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DBA Backup System Databases]    Script Date: 03/13/2013 11:46:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA Backup System Databases', 
		@step_id=1, 
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
		@BackupTime VARCHAR (12), -- Stores above info for backup time
		@BackupFolder VARCHAR(128) -- Stores the location of the folder for backups

--SELECT	@BackupFolder = ''\\colobackup1\db_Share$\COLOBIZOPSQL01\'' -- backslash necessary
SELECT	@BackupFolder = ''Y:\MSSQL\Backups\'' -- backslash necessary

-- Declare table variable
DECLARE	@Table TABLE (
			RowId TINYINT IDENTITY (1,1),
			DbName VARCHAR (100)
		)
-- Insert databases to be backed up to table variable
INSERT INTO @Table
SELECT	NAME
FROM	SYS.Databases
WHERE	database_id <= 4
AND	Name <> ''tempdb''

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
		SELECT	@Str = ''BACKUP DATABASE ''+ QUOTENAME(DbName) + '' TO DISK = ''''''+ @BackupFolder + DbName +
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
		@output_file_name=N'S:\BulentGucukDBBackup\BackupSystemDatabasesOutput.txt', 
		@flags=6
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Start DBA Delete System Database Backup Files Job]    Script Date: 03/13/2013 11:46:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Start DBA Delete System Database Backup Files Job', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE msdb ;
GO

EXEC dbo.sp_start_job 
		@job_name = ''DBA Delete System Database Backup Files'' ;
GO', 
		@database_name=N'master', 
		@output_file_name=N'S:\BulentGucukDBBackup\BackupSystemDatabasesOutput.txt', 
		@flags=6
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA Backup System Databases', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20121023, 
		@active_end_date=99991231, 
		@active_start_time=220500, 
		@active_end_time=235959, 
		@schedule_uid=N'932b998c-c3b1-40b2-a5f1-79eafccdcc02'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


