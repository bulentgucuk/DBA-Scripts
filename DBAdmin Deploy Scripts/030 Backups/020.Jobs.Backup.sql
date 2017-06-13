USE DBAdmin
GO

CREATE TABLE #Config  (FullBackupFolder VARCHAR(256)    NULL,
                       DiffBackupFolder VARCHAR(256)    NULL,
                       TLogBackupFolder VARCHAR(256)    NULL,
                       SystemBackupFolder VARCHAR(256)  NULL,
                       FullBackupRetentionDays VARCHAR(10) NULL,
                       DiffBackupRetentionDays VARCHAR(10) NULL,
                       TLogBackupRetentionDays VARCHAR(10) NULL,
                       SystemBackupRetentionDays VARCHAR(10) NULL,
                       TargetDataDomain VARCHAR(32)     NULL,
                       LogFolder        VARCHAR(256)    NULL,
                       PageOperator     NVARCHAR(256)   NULL,
                       EmailOperator    NVARCHAR(256)   NULL,
                       CreateStdJobs    BIT             NULL,
                       CreateLTSPJobs   BIT             NULL,
                       [DateFormat]     VARCHAR(4)      NULL)


DECLARE @FullBackupFolder   NVARCHAR(256)
DECLARE @DiffBackupFolder   NVARCHAR(256)
DECLARE @TLogBackupFolder   NVARCHAR(256)
DECLARE @SystemBackupFolder NVARCHAR(256)
DECLARE @FullBackupRetentionDays   NVARCHAR(10)
DECLARE @DiffBackupRetentionDays   NVARCHAR(10)
DECLARE @TLogBackupRetentionDays   NVARCHAR(10)
DECLARE @SystemBackupRetentionDays NVARCHAR(10)
DECLARE @TargetDataDomain   NVARCHAR(32)

DECLARE @LogFolder          VARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @CreateStdJobs      BIT
DECLARE @CreateLTSPJobs     BIT
DECLARE @DateFormat         VARCHAR(4)
DECLARE @IsProduction       BIT

SELECT @IsProduction        = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'IsProduction'
SELECT @FullBackupFolder    = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'FullBackupFolder'
SELECT @DiffBackupFolder    = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'FullBackupFolder'  -- We are currently forcing this
SELECT @TLogBackupFolder    = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'TLogBackupFolder'
SELECT @SystemBackupFolder  = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'SystemBackupFolder'
SELECT @FullBackupRetentionDays = ParmValue FROM DBAdmin..DBAdmin_InstallParms WHERE ParmName = 'FullBackupRetentionDays'
SELECT @DiffBackupRetentionDays = ParmValue FROM DBAdmin..DBAdmin_InstallParms WHERE ParmName = 'FullBackupRetentionDays' -- We are currently forcing this
SELECT @TLogBackupRetentionDays = ParmValue FROM DBAdmin..DBAdmin_InstallParms WHERE ParmName = 'TLogBackupRetentionDays'
SELECT @SystemBackupRetentionDays = ParmValue FROM DBAdmin..DBAdmin_InstallParms WHERE ParmName = 'SystemBackupRetentionDays'
SELECT @TargetDataDomain          = ParmValue FROM DBAdmin..DBAdmin_InstallParms WHERE ParmName = 'TargetDataDomain'

SELECT @LogFolder           = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'LogFolder'
SELECT @PageOperator        = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'JobPageOperator' AND @IsProduction = 1
SELECT @EmailOperator       = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'JobEmailOperator' AND @IsProduction = 0
SELECT @CreateStdJobs       = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'CreateStdBackupJobs'
SELECT @CreateLTSPJobs      = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'CreateLTSPBackupJobs'
SELECT @DateFormat          = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'FileDateFormat'

INSERT #Config VALUES (@FullBackupFolder,
                       @DiffBackupFolder,
                       @TLogBackupFolder,
                       @SystemBackupFolder,
                       @FullBackupRetentionDays,
                       @DiffBackupRetentionDays,
                       @TLogBackupRetentionDays,
                       @SystemBackupRetentionDays,
                       @TargetDataDomain,
                       @LogFolder,
                       @PageOperator,
                       @EmailOperator,
                       @CreateStdJobs,
                       @CreateLTSPJobs,
                       @DateFormat)
GO
-- ****************************************************************************************
-- Create the Standard Backup jobs:
--      File Cleanup - Deletes Full backups (.BAK) after <configured> days
--                     Deleted Differential backups (.DIF) after <configured> days
--                     Deleted T-Log backups (.TRN) after <configured> days
--                     Deleted log files (.TXT) after <configured> days
--                     Deleted log files (.LOG) after <configured> days
--      System DB - Full Backups           Runs once daily, at 2:00am
--      User DB - Differential Backups     Runs once daily, at 1:00am 
--      User DB - Full Backups             Runs weekly, Sundays at 6:00pm
--      User DB - Transaction Log Backups  Runs every 1 hour
-- ****************************************************************************************

USE [msdb]
GO
DECLARE @FullBackupFolder   NVARCHAR(256)
DECLARE @DiffBackupFolder   NVARCHAR(256)
DECLARE @TLogBackupFolder   NVARCHAR(256)
DECLARE @SystemBackupFolder NVARCHAR(256)
DECLARE @FullBackupRetentionDays   NVARCHAR(10)
DECLARE @DiffBackupRetentionDays   NVARCHAR(10)
DECLARE @TLogBackupRetentionDays   NVARCHAR(10)
DECLARE @SystemBackupRetentionDays NVARCHAR(10)
DECLARE @TargetDataDomain   NVARCHAR(32)

DECLARE @LogFolder          NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @StepCommand        NVARCHAR(2048)
DECLARE @StepLog            NVARCHAR(1024)
DECLARE @DateFormat         VARCHAR(256)
    
SELECT  @FullBackupFolder  = FullBackupFolder,
        @DiffBackupFolder  = DiffBackupFolder,
        @TLogBackupFolder  = TLogBackupFolder,
        @SystemBackupFolder = SystemBackupFolder,
        @FullBackupRetentionDays  = FullBackupRetentionDays,
        @DiffBackupRetentionDays  = DiffBackupRetentionDays,
        @TLogBackupRetentionDays  = TLogBackupRetentionDays,
        @SystemBackupRetentionDays = SystemBackupRetentionDays,
        @TargetDataDomain          = TargetDataDomain,
        @LogFolder     = LogFolder,
        @EmailOperator = EmailOperator,
        @PageOperator  = PageOperator,
        @DateFormat    = [DateFormat]
    FROM #Config

IF @DateFormat IS NOT NULL
    BEGIN
        SELECT @DateFormat = '
          ,@DOSDateFormat = ''' + @DateFormat + ''' '
    END
ELSE
    BEGIN
        SELECT @DateFormat = ''
    END

/****** Object:  Job [File Cleanup]    Script Date: 10/18/2007 07:47:31 ******/
IF  NOT EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: File Cleanup') AND 
    EXISTS (SELECT *
               FROM #Config
               WHERE LTRIM(RTRIM(COALESCE(FullBackupFolder, ''))) != '' AND
                     LTRIM(RTRIM(COALESCE(LogFolder, ''))) != '')
BEGIN

    BEGIN TRANSACTION
    DECLARE @ReturnCode INT
    SELECT @ReturnCode = 0
    /****** Object:  JobCategory [Database Maintenance]    Script Date: 10/18/2007 07:47:31 ******/
    IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
    BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    END

    DECLARE @jobId BINARY(16)
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: File Cleanup', 
            @enabled=1, 
            @notify_level_eventlog=0, 
            @notify_level_email=2, 
            @notify_level_netsend=0, 
            @notify_level_page=2, 
            @delete_level=0, 
            @description=N'Delete old Backup and Report files', 
            @category_name=N'Database Maintenance', 
            @owner_login_name=N'sa',
            @notify_email_operator_name=@EmailOperator, 
            @notify_page_operator_name=@PageOperator,
            @job_id = @jobId OUTPUT
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Delete Full Backup files]    Script Date: 10/18/2007 07:47:32 ******/
    SELECT @StepCommand= '
    EXECUTE [DBAdmin].[dbo].[pr_DeleteFiles] 
           @RootFolder = ''' + @FullBackupFolder + '''
          ,@FileSuffix = ''BAK''
          ,@ProcessSubFolders = 1
          ,@CutOffDate = NULL
          ,@CutOffDays = ' + @FullBackupRetentionDays + '
          ,@ForceDeleteForReadonly = 1
          ,@Debug = 0
          ,@OnlyDeleteArchived = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Full Backup files', 
            @step_id=1, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Delete Differential Backup Files]    Script Date: 10/18/2007 07:47:32 ******/
    SELECT @StepCommand= 'EXECUTE [DBAdmin].[dbo].[pr_DeleteFiles] 
           @RootFolder = ''' + @DiffBackupFolder + '''
          ,@FileSuffix = ''DIF''
          ,@ProcessSubFolders = 1
          ,@CutOffDate = NULL
          ,@CutOffDays = ' + @DiffBackupRetentionDays + '
          ,@ForceDeleteForReadonly = 1
          ,@Debug = 0
          ,@OnlyDeleteArchived = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Differential Backup Files', 
            @step_id=2, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Delete Transaction Log Backup Files]    Script Date: 10/18/2007 07:47:32 ******/
    SELECT @StepCommand= 'EXECUTE [DBAdmin].[dbo].[pr_DeleteFiles] 
           @RootFolder = ''' + @TLogBackupFolder + '''
          ,@FileSuffix = ''TRN''
          ,@ProcessSubFolders = 1
          ,@CutOffDate = NULL
          ,@CutOffDays = ' + @TLogBackupRetentionDays + '
          ,@ForceDeleteForReadonly = 1
          ,@Debug = 0
          ,@OnlyDeleteArchived = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Transaction Log Backup Files', 
            @step_id=3, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Delete Log Report Files]  (TXT)   Script Date: 10/18/2007 07:47:32 ******/
    SELECT @StepCommand= 'EXECUTE [DBAdmin].[dbo].[pr_DeleteFiles] 
           @RootFolder = ''' + @LogFolder + '''
          ,@FileSuffix = ''TXT''
          ,@ProcessSubFolders = 1
          ,@CutOffDate = NULL
          ,@CutOffDays = 7
          ,@ForceDeleteForReadonly = 1
          ,@Debug = 0
          ,@OnlyDeleteArchived = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Log Report Files (TXT)', 
            @step_id=4, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Delete Log Report Files (LOG)]    Script Date: 10/18/2007 07:47:32 ******/
    SELECT @StepCommand= 'EXECUTE [DBAdmin].[dbo].[pr_DeleteFiles] 
           @RootFolder = ''' + @LogFolder + '''
          ,@FileSuffix = ''LOG''
          ,@ProcessSubFolders = 1
          ,@CutOffDate = NULL
          ,@CutOffDays = 7
          ,@ForceDeleteForReadonly = 1
          ,@Debug = 0
          ,@OnlyDeleteArchived = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Log Report Files (LOG)', 
            @step_id=5, 
            @cmdexec_success_code=0, 
            @on_success_action=1, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Delete Old Files', 
            @enabled=1, 
            @freq_type=4, 
            @freq_interval=1, 
            @freq_subday_type=8, 
            @freq_subday_interval=12, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=0, 
            @active_start_date=20071009, 
            @active_end_date=99991231, 
            @active_start_time=170000, 
            @active_end_time=165959
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    COMMIT TRANSACTION
    GOTO EndSave
    QuitWithRollback:
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
    EndSave:

END
GO

USE [msdb]
GO
DECLARE @FullBackupFolder   NVARCHAR(256)
DECLARE @DiffBackupFolder   NVARCHAR(256)
DECLARE @TLogBackupFolder   NVARCHAR(256)
DECLARE @SystemBackupFolder NVARCHAR(256)
DECLARE @FullBackupRetentionDays   NVARCHAR(10)
DECLARE @DiffBackupRetentionDays   NVARCHAR(10)
DECLARE @TLogBackupRetentionDays   NVARCHAR(10)
DECLARE @SystemBackupRetentionDays NVARCHAR(10)
DECLARE @TargetDataDomain   NVARCHAR(32)

DECLARE @LogFolder          NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @StepCommand        NVARCHAR(2048)
DECLARE @StepLog            NVARCHAR(1024)

SELECT  @FullBackupFolder  = FullBackupFolder,
        @DiffBackupFolder  = DiffBackupFolder,
        @TLogBackupFolder  = TLogBackupFolder,
        @SystemBackupFolder = SystemBackupFolder,
        @FullBackupRetentionDays  = FullBackupRetentionDays,
        @DiffBackupRetentionDays  = DiffBackupRetentionDays,
        @TLogBackupRetentionDays  = TLogBackupRetentionDays,
        @SystemBackupRetentionDays = SystemBackupRetentionDays,
        @TargetDataDomain          = TargetDataDomain,
        @LogFolder     = LogFolder,
        @EmailOperator = EmailOperator,
        @PageOperator  = PageOperator
    FROM #Config

/****** Object:  Job [System DB - STD Full Backups]    Script Date: 10/18/2007 07:57:17 ******/
IF  NOT EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: System DB - STD Full Backups') AND 
    EXISTS (SELECT *
               FROM #Config
               WHERE LTRIM(RTRIM(COALESCE(SystemBackupFolder, ''))) != '' AND
                     LTRIM(RTRIM(COALESCE(LogFolder, ''))) != '')
BEGIN

    BEGIN TRANSACTION
    DECLARE @ReturnCode INT
    SELECT @ReturnCode = 0
    /****** Object:  JobCategory [Database Maintenance]    Script Date: 10/18/2007 07:57:17 ******/
    IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
    BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    END

    DECLARE @jobId BINARY(16)
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: System DB - STD Full Backups', 
            @enabled=1, 
            @notify_level_eventlog=0, 
            @notify_level_email=2, 
            @notify_level_netsend=0, 
            @notify_level_page=2, 
            @delete_level=0, 
            @description=N'No description available.', 
            @category_name=N'Database Maintenance', 
            @owner_login_name=N'sa',
            @notify_email_operator_name=@EmailOperator, 
            @notify_page_operator_name=@PageOperator,
            @job_id = @jobId OUTPUT
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Full Backup]    Script Date: 10/18/2007 07:57:17 ******/
    SELECT @StepCommand= '
----------------------------------------------------------------------------------------
BEGIN
    DECLARE @status INT = 0;
    EXECUTE DBAdmin.dbo.' +
        CASE @TargetDataDomain
            WHEN 'SPBACKUP' THEN 'OpenSPBackup_RepToBP60d'
            WHEN 'SPBACK0050' THEN 'OpenSPBack0050_RepToBP15d'
            WHEN 'DPBACKUP' THEN 'OpenDPBackup_RepToBP60d'
            WHEN 'DPBACK0050' THEN 'OpenDPBack0050_RepToBP15d'
        END + ' @status = @status OUTPUT;
END
IF (SELECT @status) != 0
BEGIN
    RAISERROR(''50005 Connection to DataDomain Failed'', 16, -1, @@SERVERNAME);
    GOTO EXITT;
END
ELSE
BEGIN
    EXECUTE [pr_DatabaseBackup]
        @DBGroup = ''System'',                         -- OPTIONAL. User / System / All / [NULL]. Over-rides @IncludeDBs
        @IncludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to include. @DBGroup *or* @IncludeDBs must be entered.
        @ExcludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to exclude, operates in conjunction with @DBGroup.
        @BackupFolder = ''' + @SystemBackupFolder + ''',     -- REQUIRED. Target Folder, should NOT include DB specific folder - use @CreateSubFolder.
        @FileSuffix = NULL,                            -- OPTIONAL. BAK / DIF / TRN / [NULL], will default based on @BackupType if omitted.
        @BackupType = ''Full'',                        -- OPTIONAL. Full / Diff / TLog, will default to Full if omitted.
        @CreateSubFolder = 1,                          -- OPTIONAL. Create sub-folders for each database, defaults to 1 (Yes).
        @VerifyBackup = 1,                             -- OPTIONAL. Should the Backups be verified.
        @Debug = 0,                                    -- OPTIONAL. Display Debug information, defaults to 0 (No).
        @NativeCompression = 1                         -- OPTIONAL. For SQL 2008 ONLY, use Compression for Native Backups
 END
 
 EXITT:
----------------------------------------------------------------------------------------',
           @StepLog = @LogFolder + '\System DB.Full Backups.txt'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Full Backup', 
            @step_id=1, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin',  
            @output_file_name=@StepLog, 
            @flags=2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Log File Rename]    Script Date: 05/08/2008 08:57:19 ******/
    SELECT @StepCommand= 'EXECUTE [pr_RenameFile] 
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''System DB.Full Backups.txt'', 
        @NewFileName         = NULL, 
        @Debug               = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log File Rename', 
            @step_id=2, 
            @cmdexec_success_code=0, 
            @on_success_action=1, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'System DB - Full Backup', 
            @enabled=1, 
            @freq_type=4, 
            @freq_interval=1, 
            @freq_subday_type=1, 
            @freq_subday_interval=8, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=0, 
            @active_start_date=20071009, 
            @active_end_date=99991231, 
            @active_start_time=20000, 
            @active_end_time=235959
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    COMMIT TRANSACTION
    GOTO EndSave
    QuitWithRollback:
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
    EndSave:

END
GO

USE [msdb]
GO
DECLARE @FullBackupFolder   NVARCHAR(256)
DECLARE @DiffBackupFolder   NVARCHAR(256)
DECLARE @TLogBackupFolder   NVARCHAR(256)
DECLARE @SystemBackupFolder NVARCHAR(256)
DECLARE @FullBackupRetentionDays   NVARCHAR(10)
DECLARE @DiffBackupRetentionDays   NVARCHAR(10)
DECLARE @TLogBackupRetentionDays   NVARCHAR(10)
DECLARE @SystemBackupRetentionDays NVARCHAR(10)
DECLARE @TargetDataDomain   NVARCHAR(32)

DECLARE @LogFolder          NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @CreateStdBackup    BIT
DECLARE @StepCommand        NVARCHAR(2048)
DECLARE @StepLog            NVARCHAR(1024)

SELECT  @FullBackupFolder  = FullBackupFolder,
        @DiffBackupFolder  = DiffBackupFolder,
        @TLogBackupFolder  = TLogBackupFolder,
        @SystemBackupFolder = SystemBackupFolder,
        @FullBackupRetentionDays  = FullBackupRetentionDays,
        @DiffBackupRetentionDays  = DiffBackupRetentionDays,
        @TLogBackupRetentionDays  = TLogBackupRetentionDays,
        @SystemBackupRetentionDays = SystemBackupRetentionDays,
        @TargetDataDomain = TargetDataDomain,
        @LogFolder     = LogFolder,
        @EmailOperator = EmailOperator,
        @PageOperator  = PageOperator,
        @CreateStdBackup = CreateStdJobs
    FROM #Config

/****** Object:  Job [User DB - STD Differential Backups]    Script Date: 10/18/2007 07:52:34 ******/
IF  NOT EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: User DB - STD Differential Backups')  
AND EXISTS (SELECT *
               FROM #Config
               WHERE LTRIM(RTRIM(COALESCE(DiffBackupFolder, ''))) != '' AND
                     LTRIM(RTRIM(COALESCE(LogFolder, ''))) != '')
AND @CreateStdBackup = 1
BEGIN

    BEGIN TRANSACTION
    DECLARE @ReturnCode INT
    SELECT @ReturnCode = 0
    /****** Object:  JobCategory [Database Maintenance]    Script Date: 10/18/2007 07:52:34 ******/
    IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
    BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    END

    DECLARE @jobId BINARY(16)
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: User DB - STD Differential Backups', 
            @enabled=1, 
            @notify_level_eventlog=0, 
            @notify_level_email=2, 
            @notify_level_netsend=0, 
            @notify_level_page=2, 
            @delete_level=0, 
            @description=N'No description available.', 
            @category_name=N'Database Maintenance', 
            @owner_login_name=N'sa',
            @notify_email_operator_name=@EmailOperator, 
            @notify_page_operator_name=@PageOperator,
            @job_id = @jobId OUTPUT
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Differential Backup]    Script Date: 10/18/2007 07:52:34 ******/
    SELECT @StepCommand= '
----------------------------------------------------------------------------------------
BEGIN
    DECLARE @status INT = 0;
    EXECUTE DBAdmin.dbo.' +
        CASE @TargetDataDomain
            WHEN 'SPBACKUP' THEN 'OpenSPBackup_RepToBP60d'
            WHEN 'SPBACK0050' THEN 'OpenSPBack0050_RepToBP15d'
            WHEN 'DPBACKUP' THEN 'OpenDPBackup_RepToBP60d'
            WHEN 'DPBACK0050' THEN 'OpenDPBack0050_RepToBP15d'
        END + ' @status = @status OUTPUT;
END
IF (SELECT @status) != 0
BEGIN
    RAISERROR(''50005 Connection to DataDomain Failed'', 16, -1, @@SERVERNAME);
    GOTO EXITT;
END
ELSE
BEGIN
    EXECUTE [pr_DatabaseBackup]
        @DBGroup = ''User'',                           -- OPTIONAL. User / System / All / [NULL]. Over-rides @IncludeDBs
        @IncludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to include. @DBGroup *or* @IncludeDBs must be entered.
        @ExcludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to exclude, operates in conjunction with @DBGroup.
        @BackupFolder = ''' + @DiffBackupFolder + ''',     -- REQUIRED. Target Folder, should NOT include DB specific folder - use @CreateSubFolder.
        @FileSuffix = NULL,                            -- OPTIONAL. BAK / DIF / TRN / [NULL], will default based on @BackupType if omitted.
        @BackupType = ''Diff'',                        -- OPTIONAL. Full / Diff / TLog, will default to Full if omitted.
        @CreateSubFolder = 1,                          -- OPTIONAL. Create sub-folders for each database, defaults to 1 (Yes).
        @VerifyBackup = 1,                             -- OPTIONAL. Should the Backups be verified.
        @Debug = 0,                                    -- OPTIONAL. Display Debug information, defaults to 0 (No).
        @NativeCompression = 1                         -- OPTIONAL. For SQL 2008 ONLY, use Compression for Native Backups
 END
 
 EXITT:
----------------------------------------------------------------------------------------',
           @StepLog = @LogFolder + '\User DB.Differential Backups.txt'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Differential Backup', 
            @step_id=1, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @output_file_name=@StepLog, 
            @flags=2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Log File Rename]    Script Date: 05/08/2008 08:57:19 ******/
    SELECT @StepCommand= 'EXECUTE [pr_RenameFile] 
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''User DB.Differential Backups.txt'', 
        @NewFileName         = NULL, 
        @Debug               = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log File Rename', 
            @step_id=2, 
            @cmdexec_success_code=0, 
            @on_success_action=1, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'User DB - Differential Backup', 
            @enabled=1, 
            @freq_type=4, 
            @freq_interval=1, 
            @freq_subday_type=1, 
            @freq_subday_interval=8, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=0, 
            @active_start_date=20071009, 
            @active_end_date=99991231, 
            @active_start_time=10000, 
            @active_end_time=235959
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    COMMIT TRANSACTION
    GOTO EndSave
    QuitWithRollback:
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
    EndSave:

END
GO

USE [msdb]
GO
DECLARE @FullBackupFolder   NVARCHAR(256)
DECLARE @DiffBackupFolder   NVARCHAR(256)
DECLARE @TLogBackupFolder   NVARCHAR(256)
DECLARE @SystemBackupFolder NVARCHAR(256)
DECLARE @FullBackupRetentionDays   NVARCHAR(10)
DECLARE @DiffBackupRetentionDays   NVARCHAR(10)
DECLARE @TLogBackupRetentionDays   NVARCHAR(10)
DECLARE @SystemBackupRetentionDays NVARCHAR(10)
DECLARE @TargetDataDomain   NVARCHAR(32)

DECLARE @LogFolder          NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @CreateStdBackup    BIT
DECLARE @StepCommand        NVARCHAR(2048)
DECLARE @StepLog            NVARCHAR(1024)

SELECT  @FullBackupFolder  = FullBackupFolder,
        @DiffBackupFolder  = DiffBackupFolder,
        @TLogBackupFolder  = TLogBackupFolder,
        @SystemBackupFolder = SystemBackupFolder,
        @FullBackupRetentionDays  = FullBackupRetentionDays,
        @DiffBackupRetentionDays  = DiffBackupRetentionDays,
        @TLogBackupRetentionDays  = TLogBackupRetentionDays,
        @SystemBackupRetentionDays = SystemBackupRetentionDays,
        @TargetDataDomain = TargetDataDomain,
        @LogFolder     = LogFolder,
        @EmailOperator = EmailOperator,
        @PageOperator  = PageOperator,
        @CreateStdBackup = CreateStdJobs
    FROM #Config

/****** Object:  Job [User DB - STD Full Backups]    Script Date: 10/18/2007 07:54:50 ******/
IF  NOT EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: User DB - STD Full Backups')
AND EXISTS (SELECT *
               FROM #Config
               WHERE LTRIM(RTRIM(COALESCE(FullBackupFolder, ''))) != '' AND
                     LTRIM(RTRIM(COALESCE(LogFolder, ''))) != '')
AND @CreateStdBackup = 1
BEGIN

    BEGIN TRANSACTION
    DECLARE @ReturnCode INT
    SELECT @ReturnCode = 0
    /****** Object:  JobCategory [Database Maintenance]    Script Date: 10/18/2007 07:54:50 ******/
    IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
    BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    END

    DECLARE @jobId BINARY(16)
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: User DB - STD Full Backups', 
            @enabled=1, 
            @notify_level_eventlog=0, 
            @notify_level_email=2, 
            @notify_level_netsend=0, 
            @notify_level_page=2, 
            @delete_level=0, 
            @description=N'No description available.', 
            @category_name=N'Database Maintenance', 
            @owner_login_name=N'sa',
            @notify_email_operator_name=@EmailOperator, 
            @notify_page_operator_name=@PageOperator, 
            @job_id = @jobId OUTPUT
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Full Backup]    Script Date: 10/18/2007 07:54:51 ******/
    SELECT @StepCommand= '
----------------------------------------------------------------------------------------
BEGIN
    DECLARE @status INT = 0;
    EXECUTE DBAdmin.dbo.' +
        CASE @TargetDataDomain
            WHEN 'SPBACKUP' THEN 'OpenSPBackup_RepToBP60d'
            WHEN 'SPBACK0050' THEN 'OpenSPBack0050_RepToBP15d'
            WHEN 'DPBACKUP' THEN 'OpenDPBackup_RepToBP60d'
            WHEN 'DPBACK0050' THEN 'OpenDPBack0050_RepToBP15d'
        END + ' @status = @status OUTPUT;
END
IF (SELECT @status) != 0
BEGIN
    RAISERROR(''50005 Connection to DataDomain Failed'', 16, -1, @@SERVERNAME);
    GOTO EXITT;
END
ELSE
BEGIN
    EXECUTE [pr_DatabaseBackup]
        @DBGroup = ''User'',                           -- OPTIONAL. User / System / All / [NULL]. Over-rides @IncludeDBs
        @IncludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to include. @DBGroup *or* @IncludeDBs must be entered.
        @ExcludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to exclude, operates in conjunction with @DBGroup.
        @BackupFolder = ''' + @FullBackupFolder + ''',     -- REQUIRED. Target Folder, should NOT include DB specific folder - use @CreateSubFolder.
        @FileSuffix = NULL,                            -- OPTIONAL. BAK / DIF / TRN / [NULL], will default based on @BackupType if omitted.
        @BackupType = ''Full'',                        -- OPTIONAL. Full / Diff / TLog, will default to Full if omitted.
        @CreateSubFolder = 1,                          -- OPTIONAL. Create sub-folders for each database, defaults to 1 (Yes).
        @VerifyBackup = 1,                             -- OPTIONAL. Should the Backups be verified.
        @Debug = 0,                                    -- OPTIONAL. Display Debug information, defaults to 0 (No).
        @NativeCompression = 1                         -- OPTIONAL. For SQL 2008 ONLY, use Compression for Native Backups
 END
 
 EXITT:
----------------------------------------------------------------------------------------',
           @StepLog = @LogFolder + '\User DB.Full Backups.txt'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Full Backup', 
            @step_id=1, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @output_file_name=@StepLog, 
            @flags=2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Log File Rename]    Script Date: 05/08/2008 08:57:19 ******/
    SELECT @StepCommand= 'EXECUTE [pr_RenameFile] 
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''User DB.Full Backups.txt'', 
        @NewFileName         = NULL, 
        @Debug               = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log File Rename', 
            @step_id=2, 
            @cmdexec_success_code=0, 
            @on_success_action=1, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'User DB - Full Backup', 
            @enabled=1, 
            @freq_type=8, 
            @freq_interval=1, 
            @freq_subday_type=1, 
            @freq_subday_interval=0, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=1, 
            @active_start_date=20071009, 
            @active_end_date=99991231, 
            @active_start_time=180000, 
            @active_end_time=235959
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    COMMIT TRANSACTION
    GOTO EndSave
    QuitWithRollback:
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
    EndSave:

END
GO

USE [msdb]
GO
DECLARE @FullBackupFolder   NVARCHAR(256)
DECLARE @DiffBackupFolder   NVARCHAR(256)
DECLARE @TLogBackupFolder   NVARCHAR(256)
DECLARE @SystemBackupFolder NVARCHAR(256)
DECLARE @FullBackupRetentionDays   NVARCHAR(10)
DECLARE @DiffBackupRetentionDays   NVARCHAR(10)
DECLARE @TLogBackupRetentionDays   NVARCHAR(10)
DECLARE @SystemBackupRetentionDays NVARCHAR(10)
DECLARE @TargetDataDomain   NVARCHAR(32)

DECLARE @LogFolder          NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @CreateStdBackup    BIT
DECLARE @StepCommand        NVARCHAR(2048)
DECLARE @StepLog            NVARCHAR(1024)

SELECT  @FullBackupFolder  = FullBackupFolder,
        @DiffBackupFolder  = DiffBackupFolder,
        @TLogBackupFolder  = TLogBackupFolder,
        @SystemBackupFolder = SystemBackupFolder,
        @FullBackupRetentionDays  = FullBackupRetentionDays,
        @DiffBackupRetentionDays  = DiffBackupRetentionDays,
        @TLogBackupRetentionDays  = TLogBackupRetentionDays,
        @SystemBackupRetentionDays = SystemBackupRetentionDays,
        @TargetDataDomain = TargetDataDomain,
        @LogFolder     = LogFolder,
        @EmailOperator = EmailOperator,
        @PageOperator  = PageOperator,
        @CreateStdBackup = CreateStdJobs
    FROM #Config

/****** Object:  Job [User DB - STD Transaction Log Backups]    Script Date: 10/18/2007 07:55:45 ******/
IF  NOT EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: User DB - STD Transaction Log Backups')
AND EXISTS (SELECT *
               FROM #Config
               WHERE LTRIM(RTRIM(COALESCE(TLogBackupFolder, ''))) != '' AND
                     LTRIM(RTRIM(COALESCE(LogFolder, ''))) != '')
AND @CreateStdBackup = 1
BEGIN

    BEGIN TRANSACTION
    DECLARE @ReturnCode INT
    SELECT @ReturnCode = 0
    /****** Object:  JobCategory [Database Maintenance]    Script Date: 10/18/2007 07:55:45 ******/
    IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
    BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    END

    DECLARE @jobId BINARY(16)
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: User DB - STD Transaction Log Backups', 
            @enabled=1, 
            @notify_level_eventlog=0, 
            @notify_level_email=2, 
            @notify_level_netsend=0, 
            @notify_level_page=2, 
            @delete_level=0, 
            @description=N'No description available.', 
            @category_name=N'Database Maintenance', 
            @owner_login_name=N'sa',
            @notify_email_operator_name=@EmailOperator, 
            @notify_page_operator_name=@PageOperator, 
            @job_id = @jobId OUTPUT
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Transaction Log Backup]    Script Date: 10/18/2007 07:55:45 ******/
    SELECT @StepCommand= '
----------------------------------------------------------------------------------------
BEGIN
    DECLARE @status INT = 0;
    EXECUTE DBAdmin.dbo.' +
        CASE @TargetDataDomain
            WHEN 'SPBACKUP' THEN 'OpenSPBackup_RepToBP60d'
            WHEN 'SPBACK0050' THEN 'OpenSPBack0050_RepToBP15d'
            WHEN 'DPBACKUP' THEN 'OpenDPBackup_RepToBP60d'
            WHEN 'DPBACK0050' THEN 'OpenDPBack0050_RepToBP15d'
        END + ' @status = @status OUTPUT;
END
IF (SELECT @status) != 0
BEGIN
    RAISERROR(''50005 Connection to DataDomain Failed'', 16, -1, @@SERVERNAME);
    GOTO EXITT;
END
ELSE
BEGIN
    EXECUTE [pr_DatabaseBackup]
        @DBGroup = ''User'',                           -- OPTIONAL. User / System / All / [NULL]. Over-rides @IncludeDBs
        @IncludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to include. @DBGroup *or* @IncludeDBs must be entered.
        @ExcludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to exclude, operates in conjunction with @DBGroup.
        @BackupFolder = ''' + @TLogBackupFolder + ''',     -- REQUIRED. Target Folder, should NOT include DB specific folder - use @CreateSubFolder.
        @FileSuffix = NULL,                            -- OPTIONAL. BAK / DIF / TRN / [NULL], will default based on @BackupType if omitted.
        @BackupType = ''TLog'',                        -- OPTIONAL. Full / Diff / TLog, will default to Full if omitted.
        @CreateSubFolder = 1,                          -- OPTIONAL. Create sub-folders for each database, defaults to 1 (Yes).
        @VerifyBackup = 1,                             -- OPTIONAL. Should the Backups be verified.
        @Debug = 0,                                    -- OPTIONAL. Display Debug information, defaults to 0 (No).
        @NativeCompression = 1                         -- OPTIONAL. For SQL 2008 ONLY, use Compression for Native Backups
 END
 
 EXITT:
----------------------------------------------------------------------------------------',
           @StepLog = @LogFolder + '\User DB.TLog Backups.txt'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Transaction Log Backup', 
            @step_id=1, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @output_file_name=@StepLog, 
            @flags=2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Log File Rename]    Script Date: 05/08/2008 08:57:19 ******/
    SELECT @StepCommand= 'EXECUTE [pr_RenameFile] 
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''User DB.TLog Backups.txt'', 
        @NewFileName         = NULL, 
        @Debug               = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log File Rename', 
            @step_id=2, 
            @cmdexec_success_code=0, 
            @on_success_action=1, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'User DB - Transaction Log Backup', 
            @enabled=1, 
            @freq_type=4, 
            @freq_interval=1, 
            @freq_subday_type=8, 
            @freq_subday_interval=1, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=0, 
            @active_start_date=20071009, 
            @active_end_date=99991231, 
            @active_start_time=0, 
            @active_end_time=235959
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    COMMIT TRANSACTION
    GOTO EndSave
    QuitWithRollback:
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
    EndSave:

END

GO

-- ******************************************************************************************
-- ******************************************************************************************
-- ******************************************************************************************
--
-- Following are the Litespeed equivalent backup jobs
--
-- ******************************************************************************************
-- ******************************************************************************************
-- ******************************************************************************************
USE [msdb]
GO
DECLARE @BackupFolder       NVARCHAR(256)
DECLARE @LogFolder          NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @CreateLTSPBackup   BIT
DECLARE @StepCommand        NVARCHAR(2048)
DECLARE @StepLog            NVARCHAR(1024)
SELECT  @BackupFolder  = BackupFolder,
        @LogFolder     = LogFolder,
        @EmailOperator = EmailOperator,
        @PageOperator  = PageOperator,
        @CreateLTSPBackup = CreateLTSPJobs
    FROM #Config

/****** Object:  Job [User DB - LTSP Differential Backups]    Script Date: 10/18/2007 07:52:34 ******/
IF  NOT EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: User DB - LTSP Differential Backups')
AND EXISTS (SELECT *
               FROM #Config
               WHERE LTRIM(RTRIM(COALESCE(BackupFolder, ''))) != '' AND
                     LTRIM(RTRIM(COALESCE(LogFolder, ''))) != '')
AND @CreateLTSPBackup = 1
BEGIN

    BEGIN TRANSACTION
    DECLARE @ReturnCode INT
    SELECT @ReturnCode = 0
    /****** Object:  JobCategory [Database Maintenance]    Script Date: 10/18/2007 07:52:34 ******/
    IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
    BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    END

    DECLARE @jobId BINARY(16)
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: User DB - LTSP Differential Backups', 
            @enabled=1, 
            @notify_level_eventlog=0, 
            @notify_level_email=2, 
            @notify_level_netsend=0, 
            @notify_level_page=2, 
            @delete_level=0, 
            @description=N'No description available.', 
            @category_name=N'Database Maintenance', 
            @owner_login_name=N'sa',
            @notify_email_operator_name=@EmailOperator, 
            @notify_page_operator_name=@PageOperator, 
            @job_id = @jobId OUTPUT
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Differential Backup]    Script Date: 10/18/2007 07:52:34 ******/
    SELECT @StepCommand= '[pr_DatabaseBackup]
        @DBGroup = ''User'',                           -- OPTIONAL. User / System / All / [NULL]. Over-rides @IncludeDBs
        @IncludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to include. @DBGroup *or* @IncludeDBs must be entered.
        @ExcludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to exclude, operates in conjunction with @DBGroup.
        @BackupFolder = ''' + @BackupFolder + ''',     -- REQUIRED. Target Folder, should NOT include DB specific folder - use @CreateSubFolder.
        @FileSuffix = NULL,                            -- OPTIONAL. BAK / DIF / TRN / [NULL], will default based on @BackupType if omitted.
        @BackupType = ''Diff'',                        -- OPTIONAL. Full / Diff / TLog, will default to Diff if omitted.
        @CreateSubFolder = 1,                          -- OPTIONAL. Create sub-folders for each database, defaults to 1 (Yes).
        @VerifyBackup = 1,                             -- OPTIONAL. Should the Backups be verified.
        @Debug = 0,                                    -- OPTIONAL. Display Debug information, defaults to 0 (No).
        @LTSPBackup = 1                                -- OPTIONAL. Indicates that this will be a Litespeed backup. Other Litespeed parameters are defaulted',
           @StepLog = @LogFolder + '\User LTSP DB.Differential Backups.txt'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Differential Backup', 
            @step_id=1, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @output_file_name=@StepLog, 
            @flags=2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Log File Rename]    Script Date: 05/08/2008 08:57:19 ******/
    SELECT @StepCommand= 'EXECUTE [pr_RenameFile] 
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''User LTSP DB.Differential Backups.txt'', 
        @NewFileName         = NULL, 
        @Debug               = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log File Rename', 
            @step_id=2, 
            @cmdexec_success_code=0, 
            @on_success_action=1, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'User DB - Differential Backup', 
            @enabled=1, 
            @freq_type=4, 
            @freq_interval=1, 
            @freq_subday_type=1, 
            @freq_subday_interval=8, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=0, 
            @active_start_date=20071009, 
            @active_end_date=99991231, 
            @active_start_time=10000, 
            @active_end_time=235959
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    COMMIT TRANSACTION
    GOTO EndSave
    QuitWithRollback:
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
    EndSave:

END
GO

USE [msdb]
GO
DECLARE @BackupFolder       NVARCHAR(256)
DECLARE @LogFolder          NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @CreateLTSPBackup   BIT
DECLARE @StepCommand        NVARCHAR(2048)
DECLARE @StepLog            NVARCHAR(1024)
SELECT  @BackupFolder  = BackupFolder,
        @LogFolder     = LogFolder,
        @EmailOperator = EmailOperator,
        @PageOperator  = PageOperator,
        @CreateLTSPBackup = CreateLTSPJobs
    FROM #Config

/****** Object:  Job [User DB - LTSP Full Backups]    Script Date: 10/18/2007 07:54:50 ******/
IF  NOT EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: User DB - LTSP Full Backups')
AND EXISTS (SELECT *
               FROM #Config
               WHERE LTRIM(RTRIM(COALESCE(BackupFolder, ''))) != '' AND
                     LTRIM(RTRIM(COALESCE(LogFolder, ''))) != '')
AND @CreateLTSPBackup = 1BEGIN

    BEGIN TRANSACTION
    DECLARE @ReturnCode INT
    SELECT @ReturnCode = 0
    /****** Object:  JobCategory [Database Maintenance]    Script Date: 10/18/2007 07:54:50 ******/
    IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
    BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    END

    DECLARE @jobId BINARY(16)
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: User DB - LTSP Full Backups', 
            @enabled=1, 
            @notify_level_eventlog=0, 
            @notify_level_email=2, 
            @notify_level_netsend=0, 
            @notify_level_page=2, 
            @delete_level=0, 
            @description=N'No description available.', 
            @category_name=N'Database Maintenance', 
            @owner_login_name=N'sa',
            @notify_email_operator_name=@EmailOperator, 
            @notify_page_operator_name=@PageOperator, 
            @job_id = @jobId OUTPUT
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Full Backup]    Script Date: 10/18/2007 07:54:51 ******/
    SELECT @StepCommand= '[pr_DatabaseBackup]
        @DBGroup = ''User'',                           -- OPTIONAL. User / System / All / [NULL]. Over-rides @IncludeDBs
        @IncludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to include. @DBGroup *or* @IncludeDBs must be entered.
        @ExcludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to exclude, operates in conjunction with @DBGroup.
        @BackupFolder = ''' + @BackupFolder + ''',     -- REQUIRED. Target Folder, should NOT include DB specific folder - use @CreateSubFolder.
        @FileSuffix = NULL,                            -- OPTIONAL. BAK / DIF / TRN / [NULL], will default based on @BackupType if omitted.
        @BackupType = ''Full'',                        -- OPTIONAL. Full / Diff / TLog, will default to Full if omitted.
        @CreateSubFolder = 1,                          -- OPTIONAL. Create sub-folders for each database, defaults to 1 (Yes).
        @VerifyBackup = 1,                             -- OPTIONAL. Should the Backups be verified.
        @Debug = 0,                                    -- OPTIONAL. Display Debug information, defaults to 0 (No).
        @LTSPBackup = 1                                -- OPTIONAL. Indicates that this will be a Litespeed backup. Other Litespeed parameters are defaulted.',
           @StepLog = @LogFolder + '\User LTSP DB.Full Backups.txt'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Full Backup', 
            @step_id=1, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @output_file_name=@StepLog, 
            @flags=2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Log File Rename]    Script Date: 05/08/2008 08:57:19 ******/
    SELECT @StepCommand= 'EXECUTE [pr_RenameFile] 
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''User LTSP DB.Full Backups.txt'', 
        @NewFileName         = NULL, 
        @Debug               = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log File Rename', 
            @step_id=2, 
            @cmdexec_success_code=0, 
            @on_success_action=1, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'User DB - Full Backup', 
            @enabled=1, 
            @freq_type=8, 
            @freq_interval=1, 
            @freq_subday_type=1, 
            @freq_subday_interval=0, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=1, 
            @active_start_date=20071009, 
            @active_end_date=99991231, 
            @active_start_time=180000, 
            @active_end_time=235959
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    COMMIT TRANSACTION
    GOTO EndSave
    QuitWithRollback:
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
    EndSave:

END
GO

USE [msdb]
GO
DECLARE @BackupFolder       NVARCHAR(256)
DECLARE @LogFolder          NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @CreateLTSPBackup   BIT
DECLARE @StepCommand        NVARCHAR(2048)
DECLARE @StepLog            NVARCHAR(1024)
SELECT  @BackupFolder  = BackupFolder,
        @LogFolder     = LogFolder,
        @EmailOperator = EmailOperator,
        @PageOperator  = PageOperator,
        @CreateLTSPBackup = CreateLTSPJobs
    FROM #Config

/****** Object:  Job [User DB - LTSP Transaction Log Backups]    Script Date: 10/18/2007 07:55:45 ******/
IF  NOT EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: User DB - LTSP Transaction Log Backups')
AND EXISTS (SELECT *
               FROM #Config
               WHERE LTRIM(RTRIM(COALESCE(BackupFolder, ''))) != '' AND
                     LTRIM(RTRIM(COALESCE(LogFolder, ''))) != '')
AND @CreateLTSPBackup = 1
BEGIN

    BEGIN TRANSACTION
    DECLARE @ReturnCode INT
    SELECT @ReturnCode = 0
    /****** Object:  JobCategory [Database Maintenance]    Script Date: 10/18/2007 07:55:45 ******/
    IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
    BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    END

    DECLARE @jobId BINARY(16)
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: User DB - LTSP Transaction Log Backups', 
            @enabled=1, 
            @notify_level_eventlog=0, 
            @notify_level_email=2, 
            @notify_level_netsend=0, 
            @notify_level_page=2, 
            @delete_level=0, 
            @description=N'No description available.', 
            @category_name=N'Database Maintenance', 
            @owner_login_name=N'sa',
            @notify_email_operator_name=@EmailOperator, 
            @notify_page_operator_name=@PageOperator, 
            @job_id = @jobId OUTPUT
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Transaction Log Backup]    Script Date: 10/18/2007 07:55:45 ******/
    SELECT @StepCommand= '[pr_DatabaseBackup]
        @DBGroup = ''User'',                           -- OPTIONAL. User / System / All / [NULL]. Over-rides @IncludeDBs
        @IncludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to include. @DBGroup *or* @IncludeDBs must be entered.
        @ExcludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to exclude, operates in conjunction with @DBGroup.
        @BackupFolder = ''' + @BackupFolder + ''',     -- REQUIRED. Target Folder, should NOT include DB specific folder - use @CreateSubFolder.
        @FileSuffix = NULL,                            -- OPTIONAL. BAK / DIF / TRN / [NULL], will default based on @BackupType if omitted.
        @BackupType = ''TLog'',                        -- OPTIONAL. Full / Diff / TLog, will default to Full if omitted.
        @CreateSubFolder = 1,                          -- OPTIONAL. Create sub-folders for each database, defaults to 1 (Yes).
        @VerifyBackup = 1,                             -- OPTIONAL. Should the Backups be verified.
        @Debug = 0,                                     -- OPTIONAL. Display Debug information, defaults to 0 (No).
        @LTSPBackup = 1                                -- OPTIONAL. Indicates that this will be a Litespeed backup. Other Litespeed parameters are defaulted.',
           @StepLog = @LogFolder + '\User LTSP DB.TLog Backups.txt'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Transaction Log Backup', 
            @step_id=1, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @output_file_name=@StepLog, 
            @flags=2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Log File Rename]    Script Date: 05/08/2008 08:57:19 ******/
    SELECT @StepCommand= 'EXECUTE [pr_RenameFile] 
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''User LTSP DB.TLog Backups.txt'', 
        @NewFileName         = NULL, 
        @Debug               = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log File Rename', 
            @step_id=2, 
            @cmdexec_success_code=0, 
            @on_success_action=1, 
            @on_success_step_id=0, 
            @on_fail_action=2, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'User DB - Transaction Log Backup', 
            @enabled=1, 
            @freq_type=4, 
            @freq_interval=1, 
            @freq_subday_type=8, 
            @freq_subday_interval=1, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=0, 
            @active_start_date=20071009, 
            @active_end_date=99991231, 
            @active_start_time=0, 
            @active_end_time=235959
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    COMMIT TRANSACTION
    GOTO EndSave
    QuitWithRollback:
        IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
    EndSave:

END

GO


DROP TABLE #Config

GO