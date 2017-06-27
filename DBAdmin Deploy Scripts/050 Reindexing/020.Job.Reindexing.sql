USE DBAdmin
GO
IF dbo.fn_SQLVersion() < 9
    GOTO TheEnd

IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: User DB - Reindexing')
    BEGIN 
        PRINT 'Job: [DBAdmin: User DB - Reindexing] already exists. Skipping Job Creation'
        GOTO TheEnd
    END

PRINT 'Creating Job: [DBAdmin: User DB - Reindexing]'

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @LogFile        NVARCHAR(256)
DECLARE @LogFolder      NVARCHAR(256)
DECLARE @Step2Cmd       NVARCHAR(2048)

SELECT  @LogFile      = ParmValue + '\User DB.RebuildIndexes.log',
        @LogFolder    = ParmValue 
    FROM DBAdmin_InstallParms 
    WHERE ParmName = 'LogFolder'

SELECT @Step2Cmd = N'EXECUTE [pr_RenameFile]
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''User DB.RebuildIndexes.log'',
        @NewFileName         = NULL,
        @Debug               = 0
'

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Database Maintenance]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Database Maintenance]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: User DB - Reindexing', 
        @enabled=0, 
        @notify_level_eventlog=0, 
        @notify_level_email=0, 
        @notify_level_netsend=0, 
        @notify_level_page=0, 
        @delete_level=0, 
        @description=N'No description available.', 
        @category_name=N'[Database Maintenance]', 
        @owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [PlaceHolder]    Script Date: 11/07/2008 08:43:11 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'PlaceHolder for Job Start', 
        @step_id=1, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_success_step_id=0, 
        @on_fail_action=3, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'SELECT GETDATE()', 
        @database_name=N'master', 
        @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Reindex OAS]    Script Date: 11/07/2008 08:43:11 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Reindex', 
        @step_id=2, 
        @cmdexec_success_code=0, 
        @on_success_action=3, 
        @on_success_step_id=0, 
        @on_fail_action=3, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=N'EXEC [DBAdmin].[dbo].[pr_RebuildIndexes]
    @DBGroup                    = ''User'',
    @IncludeDBs                 = NULL,
    @ExcludeDBs                 = NULL,
    @RebuildFragLevel           = 15,
    @ReorgFragLevel             = 5,
    @RebuildOnline              = 1,
    @AllowOffline               = 0,
    @StopTime                   = NULL,
    @MaxProcessors              = NULL,
    @LogIndexCommands           = 0,
    @LogCommandsOnly            = 0

', 
        @database_name=N'DBAdmin', 
        @output_file_name=@LogFile, 
        @flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Log File Rename]    Script Date: 11/07/2008 08:43:11 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log File Rename', 
        @step_id=3, 
        @cmdexec_success_code=0, 
        @on_success_action=1, 
        @on_success_step_id=0, 
        @on_fail_action=2, 
        @on_fail_step_id=0, 
        @retry_attempts=0, 
        @retry_interval=0, 
        @os_run_priority=0, @subsystem=N'TSQL', 
        @command=@Step2Cmd, 
        @database_name=N'DBAdmin', 
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

PRINT 'Job Created [DBAdmin: User DB - Reindexing]'


TheEnd:
