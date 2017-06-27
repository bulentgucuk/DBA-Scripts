USE DBAdmin
GO
IF dbo.fn_SQLVersion() < 9
    BEGIN
        PRINT 'DBAdmin CheckDB processing is not written for SQL 2000. Use the Standard Maintenance Plan processing.'
        PRINT '*** Processing of this script is being aborted ***'
        RAISERROR ('DBAdmin CheckDB processing is not written for SQL 2000', 20, 1) WITH LOG
    END
GO

CREATE TABLE #Config  (LogFolder        VARCHAR(256)    NULL,
                       PageOperator     NVARCHAR(256)   NULL,
                       EmailOperator    NVARCHAR(256)   NULL)

/*
** IF THIS IS A PRODUCTION INSTANCE, SET THE PAGE OPERATOR TO GOI_SQL_Server_DBA AND THE 
** EMAIL OPERATOR TO NULL.  IF THIS IS A NON-PRODUCTION INSTANCE, SET THE EMAIL OPERATOR
** TO GOI_SQL_Server_DBA AND THE PAGE OPERATOR TO NULL.
*/

DECLARE @IsProduction       BIT
DECLARE @LogFolder          VARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)

SELECT @IsProduction        = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'IsProduction'
SELECT @LogFolder           = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'LogFolder'
SELECT @PageOperator        = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'JobPageOperator' AND @IsProduction = 1
SELECT @EmailOperator       = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'JobEmailOperator' AND @IsProduction = 0

INSERT #Config VALUES (@LogFolder,
                       @PageOperator,
                       @EmailOperator)
GO

USE [msdb]
GO
DECLARE @LogFolder          NVARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @PageOperator       NVARCHAR(256)
DECLARE @StepCommand        NVARCHAR(2048)
DECLARE @StepLog            NVARCHAR(1024)
    
SELECT  @LogFolder     = LogFolder,
        @EmailOperator = EmailOperator,
        @PageOperator  = PageOperator
    FROM #Config




IF  NOT EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: CHECKDB Processing')
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
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: CHECKDB Processing', 
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
    /****** Object:  Step [Set CheckDB Schedule]    Script Date: 10/18/2007 07:57:17 ******/
    SELECT @StepCommand= 'EXEC [pr_Set_CheckDB_Schedule]',
           @StepLog = @LogFolder + '\Set CheckDB Schedule.txt'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Set CheckDB Schedule', 
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
    /****** Object:  Step [Log File Rename (Set CheckDB Schedule)]    Script Date: 05/08/2008 08:57:19 ******/
    SELECT @StepCommand= 'EXEC [pr_RenameFile] 
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''Set CheckDB Schedule.txt'', 
        @NewFileName         = NULL, 
        @Debug               = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log File Rename (Set CheckDB Schedule)', 
            @step_id=2, 
            @cmdexec_success_code=0, 
            @on_success_action=3, 
            @on_success_step_id=0, 
            @on_fail_action=3, 
            @on_fail_step_id=0, 
            @retry_attempts=0, 
            @retry_interval=0, 
            @os_run_priority=0, @subsystem=N'TSQL', 
            @command=@StepCommand, 
            @database_name=N'DBAdmin', 
            @flags=0    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [CheckDB Processing]    Script Date: 10/18/2007 07:57:17 ******/
    SELECT @StepCommand= 'EXEC [pr_CheckDB_Processing]',
           @StepLog = @LogFolder + '\CheckDB Processing.txt'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CheckDB Processing', 
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
            @output_file_name=@StepLog, 
            @flags=2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Log File Rename (CheckDB Processing)]    Script Date: 05/08/2008 08:57:19 ******/
    SELECT @StepCommand= 'EXEC [pr_RenameFile] 
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''CheckDB Processing.txt'', 
        @NewFileName         = NULL, 
        @Debug               = 0'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log File Rename (CheckDB Processing)', 
            @step_id=4, 
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
    EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'CHECKDB Processing', 
            @enabled=1, 
            @freq_type=4, 
            @freq_interval=1, 
            @freq_subday_type=1, 
            @freq_subday_interval=12, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=0, 
            @active_start_date=20100101, 
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