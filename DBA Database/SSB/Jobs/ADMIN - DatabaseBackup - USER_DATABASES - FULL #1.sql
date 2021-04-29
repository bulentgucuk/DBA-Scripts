USE [msdb]
GO

/****** Object:  Job [ADMIN - DatabaseBackup - USER_DATABASES - FULL #1]    Script Date: 6/30/2020 6:01:37 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 6/30/2020 6:01:37 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'ADMIN - DatabaseBackup - USER_DATABASES - FULL #1')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ADMIN - DatabaseBackup - USER_DATABASES - FULL #1', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Source: https://ola.hallengren.com  -- backup job step has been altered to change the number of backup files based on the size of the data space used in the database.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [Start Job step 1]    Script Date: 6/30/2020 6:01:37 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 1)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Start Job step 1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use master', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [ADMIN - DatabaseBackup - USER_DATABASES - FULL]    Script Date: 6/30/2020 6:01:37 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'ADMIN - DatabaseBackup - USER_DATABASES - FULL', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE [dbo].[DatabaseBackup]
	  @Databases = ''USER_DATABASES''
	, @URL = ''https://sadbprod01backups.blob.core.windows.net/backupcontainer''
	, @BackupType = ''FULL''
	, @DirectoryStructure = NULL
	, @Verify = ''N''
	, @Compress = ''Y''
	, @CheckSum = ''Y''
	, @LogToTable = ''Y''
	, @Execute = ''Y''
	, @BufferCount = 50
	, @Blocksize = 65536
	, @MaxTransferSize = 4194304
	, @MaxFileSize = 199680   /* Maximum backup file size in MB */
	, @DatabasesInParallel = ''Y'';
', 
		@database_name=N'master', 
		@output_file_name=N'$(ESCAPE_SQUOTE(SQLLOGDIR))\DatabaseBackup_FULL#1_$(ESCAPE_SQUOTE(JOBID))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Re-try failed backups]    Script Date: 6/30/2020 6:01:37 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 3)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Re-try failed backups', 
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
	, @GoBackStartTime DATETIME = DATEADD(DAY, -1, GETDATE());

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
AND		CommandType = ''BACKUP_DATABASE''
AND		Command NOT LIKE ''%DIFFERENTIAL%''
AND		ErrorNumber > 0;

--SELECT * FROM #FailedCommands;

IF OBJECT_ID(''tempdb..#DbSize'') IS NOT NULL
	DROP TABLE #DbSize
CREATE TABLE #DbSize (
	  DatabaseName SYSNAME
	, DatabaseId INT NOT NULL
	, DBFileName SYSNAME
	, FileId INT NOT NULL
	, PhysicalDBFileName VARCHAR(1024)
	, FileType VARCHAR(32)
	, TotalSpace DECIMAL(19,2)
	, SpaceUsed DECIMAL(19,2)
	, FreeSpaceInMB DECIMAL(19,2)
	, DBFileGroupName VARCHAR(128)
	, DataFGDesc VARCHAR(128)
	, ISDefaultFileGroup BIT
	);

INSERT INTO #DbSize
EXEC SP_MSFOREACHDB
''USE [?];
SELECT	DB_NAME() AS DatabaseName,
		DB_ID() AS DatabaseId,
		dbf.Name AS DBFileName,
		dbf.File_id AS FileId,
		dbf.physical_name AS PhysicalDBFileName,
		dbf.Type_Desc AS FileType,
		STR((dbf.Size/128.0),10,2) AS TotalSpace,
		CAST(FILEPROPERTY(dbf.name, ''''SpaceUsed'''')/128.0  AS DECIMAL(9,2)) AS SpaceUsed,
		STR((Size/128.0 - CAST(FILEPROPERTY(dbf.name, ''''SpaceUsed'''') AS int)/128.0),9,2) AS FreeSpaceInMB,
		dbfg.Name AS DBFileGroupName,
		dbfg.type_desc AS DataFGDesc,
		dbfg.is_default AS ISDefaultFileGroup
FROM	sys.database_files AS dbf
	LEFT OUTER JOIN sys.data_spaces AS dbfg ON dbf.data_space_id = dbfg.data_space_id
ORDER BY dbf.type_desc DESC, dbf.file_id;''

IF OBJECT_ID(''tempdb..#DbsToBeBackedUp'') IS NOT NULL
	DROP TABLE #DbsToBeBackedUp;
CREATE TABLE #DbsToBeBackedUp
	( RowId SMALLINT IDENTITY(1,1)
	, DatabaseName VARCHAR(128)
	, DatabaseFileSizeInGB DECIMAL (12,2)
	, SpaceUsedInGB DECIMAL(12,2)
	, FreeSpaceInGB DECIMAL(12,2)
	);
INSERT INTO #DbsToBeBackedUp
SELECT	DatabaseName, sum(totalspace/1024) as DatabaseFileSizeInGB, sum(spaceused/1024) as SpaceUsedInGB, sum(freespaceinMB/1024) as FreeSpaceInGB
FROM	#DbSize
WHERE	DatabaseId > 4
AND		DatabaseName IN (SELECT DatabaseName FROM #FailedCommands)
GROUP BY DatabaseName
ORDER BY DatabaseName;

DECLARE @RowId SMALLINT
	, @MaxRowId SMALLINT
	, @DatabaseName VARCHAR(128)
	, @SpaceUsedInGB DECIMAL(12,2)
	, @BackupFileNumber SMALLINT;

SELECT	@RowId = MIN(RowId)
	, @MaxRowId = MAX(RowId)
FROM	#DbsToBeBackedUp;


WHILE @RowId <= @MaxRowId
	BEGIN
		SELECT	@DatabaseName = DatabaseName
			, @BackupFileNumber = 
				CASE WHEN SpaceUsedInGB < 200 THEN  1
					 WHEN SpaceUsedInGB > 200 AND SpaceUsedInGB < 500 THEN 2
					 WHEN SpaceUsedInGB > 500 AND SpaceUsedInGB < 750 THEN 3
					 WHEN SpaceUsedInGB > 750 THEN 4
			END
		FROM	#DbsToBeBackedUp
		WHERE	RowId = @RowId;

		EXECUTE [dbo].[DatabaseBackup]
			  @Databases = @DatabaseName
			, @URL = N''https://sadbprod01backups.blob.core.windows.net/backupcontainer''
			, @BackupType = ''FULL''
			, @DirectoryStructure = NULL
			, @Verify = ''N''
			, @Compress = ''Y''
			, @CheckSum = ''Y''
			, @LogToTable = ''Y''
			, @Execute = ''Y''
			, @BufferCount = 50
			, @Blocksize = 65536
			, @MaxTransferSize = 4194304
			, @NumberOfFiles = @BackupFileNumber;

		SELECT	@RowId = @RowId + 1;
	END

-- Drop temp tables
DROP TABLE #FailedCommands;
DROP TABLE #DbSize;
DROP TABLE #DbsToBeBackedUp;
GO', 
		@database_name=N'master', 
		@output_file_name=N'$(ESCAPE_SQUOTE(SQLLOGDIR))\Re-try_DatabaseBackup_FULL_$(ESCAPE_SQUOTE(JOBID))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Original]    Script Date: 6/30/2020 6:01:37 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId AND step_id = 4)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Original', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON;
IF OBJECT_ID(''tempdb..#DbSize'') IS NOT NULL
	DROP TABLE #DbSize
CREATE TABLE #DbSize (
	  DatabaseName SYSNAME
	, DatabaseId INT NOT NULL
	, DBFileName SYSNAME
	, FileId INT NOT NULL
	, PhysicalDBFileName VARCHAR(1024)
	, FileType VARCHAR(32)
	, TotalSpace DECIMAL(19,2)
	, SpaceUsed DECIMAL(19,2)
	, FreeSpaceInMB DECIMAL(19,2)
	, DBFileGroupName VARCHAR(128)
	, DataFGDesc VARCHAR(128)
	, ISDefaultFileGroup BIT
	)
INSERT INTO #DbSize
EXEC SP_MSFOREACHDB
''USE [?];
SELECT	DB_NAME() AS DatabaseName,
		DB_ID() AS DatabaseId,
		dbf.Name AS DBFileName,
		dbf.File_id AS FileId,
		dbf.physical_name AS PhysicalDBFileName,
		dbf.Type_Desc AS FileType,
		STR((dbf.Size/128.0),10,2) AS TotalSpace,
		CAST(FILEPROPERTY(dbf.name, ''''SpaceUsed'''')/128.0  AS DECIMAL(9,2)) AS SpaceUsed,
		STR((Size/128.0 - CAST(FILEPROPERTY(dbf.name, ''''SpaceUsed'''') AS int)/128.0),9,2) AS FreeSpaceInMB,
		dbfg.Name AS DBFileGroupName,
		dbfg.type_desc AS DataFGDesc,
		dbfg.is_default AS ISDefaultFileGroup
FROM	sys.database_files AS dbf
	LEFT OUTER JOIN sys.data_spaces AS dbfg ON dbf.data_space_id = dbfg.data_space_id
ORDER BY dbf.type_desc DESC, dbf.file_id;''

IF OBJECT_ID(''tempdb..#DbsToBeBackedUp'') IS NOT NULL
	DROP TABLE #DbsToBeBackedUp;
CREATE TABLE #DbsToBeBackedUp
	( RowId SMALLINT IDENTITY(1,1)
	, DatabaseName VARCHAR(128)
	, DatabaseFileSizeInGB DECIMAL (12,2)
	, SpaceUsedInGB DECIMAL(12,2)
	, FreeSpaceInGB DECIMAL(12,2)
	);
INSERT INTO #DbsToBeBackedUp
SELECT	DatabaseName, sum(totalspace/1024) as DatabaseFileSizeInGB, sum(spaceused/1024) as SpaceUsedInGB, sum(freespaceinMB/1024) as FreeSpaceInGB
FROM	#DbSize
WHERE	DatabaseId > 4
GROUP BY DatabaseName
ORDER BY DatabaseName;

DECLARE @RowId SMALLINT
	, @MaxRowId SMALLINT
	, @DatabaseName VARCHAR(128)
	, @SpaceUsedInGB DECIMAL(12,2)
	, @BackupFileNumber SMALLINT;

SELECT	@RowId = MIN(RowId)
	, @MaxRowId = MAX(RowId)
FROM	#DbsToBeBackedUp;

WHILE @RowId <= @MaxRowId
	BEGIN
		SELECT	@DatabaseName = DatabaseName
			, @BackupFileNumber = 
				CASE WHEN SpaceUsedInGB < 200 THEN  1
					 WHEN SpaceUsedInGB > 200 AND SpaceUsedInGB < 500 THEN 2
					 WHEN SpaceUsedInGB > 500 THEN 3
			END
		FROM	#DbsToBeBackedUp
		WHERE	RowId = @RowId;


		EXECUTE [dbo].[DatabaseBackup]
			  @Databases = @DatabaseName
			, @URL = ''https://sadbprod01backups.blob.core.windows.net/backupcontainer''
			, @BackupType = ''FULL''
			, @DirectoryStructure = NULL
			, @Verify = ''N''
			, @Compress = ''Y''
			, @CheckSum = ''Y''
			, @LogToTable = ''Y''
			, @Execute = ''Y''
			, @BufferCount = 50
			, @Blocksize = 65536
			, @MaxTransferSize = 4194304
			, @NumberOfFiles = @BackupFileNumber;

		SELECT	@RowId = @RowId + 1;
	END

DROP TABLE #DbSize;
DROP TABLE #DbsToBeBackedUp;
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'ADMIN - DatabaseBackup - USER_DATABASES - FULL', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180513, 
		@active_end_date=99991231, 
		@active_start_time=150000, 
		@active_end_time=235959, 
		@schedule_uid=N'8c1c6bb8-05ac-4f33-8deb-2d8bf0396f88'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


