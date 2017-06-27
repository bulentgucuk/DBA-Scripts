USE [msdb]
GO

/****** Object:  Job [A DBA Restore Phoenix2 Tlog Files (Log Shipping)]    Script Date: 10/18/2011 14:08:28 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Log Shipping]    Script Date: 10/18/2011 14:08:29 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Log Shipping' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Log Shipping'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'A DBA Restore Phoenix2 Tlog Files (Log Shipping)', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Log Shipping', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Insert Tlog files to be Restored]    Script Date: 10/18/2011 14:08:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Insert Tlog files to be Restored', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE AdminTools
GO
-- INSERT TLOG FILES TO TABLE FOR RESTORE PROCESS

INSERT INTO dbo.RestorePhoenix2Log (
	RestoreFromFolder,
	ResoreLogFileName
	)

SELECT	''\\sqlclr03-p\I$'' AS RestoreFromFolder,
		SUBSTRING(BMF.physical_device_name,3,100) AS ResoreLogFileName
FROM	[SQLCLR03-P].msdb.dbo.backupmediafamily AS BMF
	INNER JOIN [SQLCLR03-P].msdb.dbo.backupset AS BS
		ON BMF.media_set_id = BS.media_set_id
	LEFT OUTER JOIN dbo.RestorePhoenix2Log AS RP
		ON SUBSTRING(BMF.physical_device_name,3,100) = RP.ResoreLogFileName
WHERE	BMF.Physical_device_name LIKE ''%Phoenix2_tlog%.trn%''
AND		BS.Backup_Start_Date > DATEADD(HOUR,-2,GETDATE())
AND		RP.ResoreLogFileName IS NULL
ORDER BY BMF.media_set_Id ASC
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore TLog]    Script Date: 10/18/2011 14:08:29 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore TLog', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE AdminTools
GO
-- RESTORE DATABASE IF IT''S IN RESTORING MODE
IF EXISTS(	SELECT	NAME
			FROM	MASTER.SYS.DATABASES
			WHERE	NAME = ''Phoenix2''
			AND		state = 1
			AND		state_desc = ''RESTORING''
		)
	BEGIN

		-- SET XACT_ABORT ON TO ROLL BACK IN CASE ANY RUNTIME ERROR OCCURS
		SET XACT_ABORT ON;
		-- DECLARE THE VARIABLAS TO DRIVE THE RESTORE PROCESS
		DECLARE	@MinRowIdRestored INT,
				@MaxRowId INT,
				@NumberOfFilesToBeRestored TINYINT

		-- FIND THE FILE TO BE RESTORED
		SELECT	@MinRowIdRestored = ISNULL(MIN(RowId),1)
		FROM	dbo.RestorePhoenix2Log
		WHERE	RestoreCompleted = 0

		-- FIND THE MAX RECORD
		SELECT	@MaxRowId = MAX(RowID)
		FROM	dbo.RestorePhoenix2Log
		WHERE	RestoreCompleted = 0

		SELECT	@NumberOfFilesToBeRestored = @MaxRowId - @MinRowIdRestored

		WHILE	@NumberOfFilesToBeRestored > 3
			BEGIN
			
			-- FIND THE BACKUP FILE TO BE RESTORED
			DECLARE @STR VARCHAR(2000),
					@BackuptobeRestored VARCHAR (1000)
			SELECT	@BackuptobeRestored = RestoreFromFolder + ResoreLogFileName
			FROM	dbo.RestorePhoenix2Log
			WHERE	RowId = @MinRowIdRestored

			SELECT @BackuptobeRestored as BackuptobeRestored
			
			-- UPDATE THE TABLE TO MARK THE RESTORE PROCESS STARTED
			UPDATE	dbo.RestorePhoenix2Log
			SET		RestoreStartDateTime = GETDATE(),
					RestoreStarted = 1
			WHERE	RowId = @MinRowIdRestored
			
			-- START RESTORE PROCESS -----------------------------------------------------------------------------------
			-- CREATE TEMP TABLE TO STORE BACKUP FILE METADATA
			IF EXISTS (
						SELECT	NAME
						FROM	Tempdb.sys.tables
						WHERE	NAME = ''RestorePhoenix2''
						)
				BEGIN
					DROP TABLE TempDb.dbo.RestorePhoenix2
				END
			CREATE TABLE TempDb.dbo.RestorePhoenix2 (
				RowId TINYINT IDENTITY(1,1),
				LogicalName VARCHAR (128),
				PhysicalName VARCHAR (512),
				Type CHAR(1),
				FileGroupName VARCHAR (128),
				Size numeric(20,0) ,
				MaxSize numeric(20,0) ,
				FileId BIGINT,
				CreatLSN numeric(25,0),
				DropLSN numeric(25,0),
				UniqeId VARCHAR (255),
				ReadOnlyLSN NUMERIC(25,0),
				ReadWriteLSN NUMERIC(25,0),
				BackupSizeInBytes BIGINT,
				SourceBlockSize INT,
				FileGroupId INT,
				LogGroupGUID VARCHAR(128),
				DifferentialBaseLSN NUMERIC(25,0) ,
				DifferentialBaseGUID UNIQUEIDENTIFIER,
				IsReadOnly BIT,
				IsPresent BIT,
				TDEThumbprint VARCHAR(255)
			 )

			SELECT	@STR = ''RESTORE FILELISTONLY FROM  DISK = '' + ''''''''+ @BackuptobeRestored + ''''''''
			 
			INSERT INTO TempDb.dbo.RestorePhoenix2
			EXEC (@STR)

			-- DECLARE VARIABLES FOR DYNAMIC RESTORE
			DECLARE	@DataFileLoopDeclare TINYINT --NUMBER OF VARIABLES THAT NEED TO BE CREATED FOR DATAFILES
			DECLARE	@Restore VARCHAR(MAX) -- DYNAMIC RESTORE STATEMENT
			SELECT	@Restore = ''RESTORE LOG Phoenix2 FROM DISK = '' + ''''''''+ @BackuptobeRestored + ''''''''+'' WITH''

			SELECT	@DataFileLoopDeclare = MAX(RowId)
			FROM	TempDb.dbo.RestorePhoenix2
			WHERE	Type = ''D''

			-- CONFIGURE DATA FILES RESTORE LOCATION
			WHILE	@DataFileLoopDeclare > 0
				BEGIN
					--SELECT	@Restore = @Restore + '' MOVE '' + '''''''' + LogicalName + '''''''' + '' TO '' + ''''''K:\DATA\BackOffice\'' +
					SELECT	@Restore = @Restore + '' MOVE '' + '''''''' + LogicalName + '''''''' + '' TO '' + 
							CASE
								WHEN LogicalName LIKE ''INVENTORY%'' THEN + ''''''I:\Data\Phoenix2\'' 
								ELSE + ''''''H:\DATA\Phoenix2\'' 
							END 
							
							+ REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX(''%\%'',REVERSE(PhysicalName))-1)) + ''''''''
							+ '',''
					FROM	TempDb.dbo.RestorePhoenix2
					WHERE	RowId = @DataFileLoopDeclare

					--PRINT	@Restore
					SELECT	@DataFileLoopDeclare = @DataFileLoopDeclare - 1
				END

			--CONFIGURE LOG FILE RESTORE LOCATION
			SELECT	@Restore = @Restore + '' MOVE '' + '''''''' + LogicalName + '''''''' + '' TO '' + ''''''G:\Log\Phoenix2\'' +
					REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX(''%\%'',REVERSE(PhysicalName))-1)) + ''''''''
					+ '',''
			FROM	TempDb.dbo.RestorePhoenix2
			WHERE	Type = ''L''
			SELECT	@Restore = @Restore + 
				'' STATS = 5, REPLACE, NORECOVERY'' 
			SELECT	@Restore
			DROP TABLE TempDb.dbo.RestorePhoenix2
			DECLARE	@ERR INT

			-- RESTORE DATABASE
			EXEC	(@Restore)
			
			
			-- UPDATE THE TABLE TO MARK THE RESTORE PROCESS COMPLETED
			UPDATE	dbo.RestorePhoenix2Log
			SET		RestoreCompleteDateTime = GETDATE(),
					RestoreCompleted = 1
			WHERE	RowId = @MinRowIdRestored
			
			-- FIND THE FILE TO BE RESTORED NEXT
			SELECT	@MinRowIdRestored = ISNULL(MIN(RowId),1)
			FROM	dbo.RestorePhoenix2Log
			WHERE	RestoreCompleted = 0

			SELECT	@NumberOfFilesToBeRestored = @NumberOfFilesToBeRestored - 1
			
			END
	
	END

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'A DBA Restore Phoenix2 Tlog Files (Log Shipping)', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20111018, 
		@active_end_date=99991231, 
		@active_start_time=300, 
		@active_end_time=235959, 
		@schedule_uid=N'550c89aa-79de-48e7-bd1b-faa9d4766b8b'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


