USE [msdb]
GO

DECLARE @LogFolder          VARCHAR(256)
DECLARE @EmailOperator      NVARCHAR(256)
DECLARE @StepCommand        NVARCHAR(4000)
DECLARE @StepLog            NVARCHAR(1024)

SELECT @LogFolder           = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'LogFolder'
SELECT @EmailOperator       = ParmValue FROM DBAdmin..DBAdmin_InstallParms  WHERE ParmName = 'JobEmailOperator'

IF  NOT EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBAdmin: msdb DB Backup History Cleanup')
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
    EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBAdmin: msdb DB Backup History Cleanup', 
            @enabled=1, 
            @notify_level_eventlog=0, 
            @notify_level_email=2, 
            @notify_level_netsend=0, 
            @notify_level_page=0, 
            @delete_level=0, 
            @description=N'No description available.', 
            @category_name=N'Database Maintenance', 
            @owner_login_name=N'sa',
            @notify_email_operator_name=@EmailOperator, 
            @job_id = @jobId OUTPUT
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
    /****** Object:  Step [Set CheckDB Schedule]    Script Date: 10/18/2007 07:57:17 ******/
    SELECT @StepCommand= N'
USE msdb;
GO
DECLARE	@dt	DATETIME;
SELECT @dt = CAST(DATEDIFF(DAY, 60, GETDATE()) AS DATETIME) -- 60 Days ago midnight

EXEC dbo.sp_delete_backuphistory @dt;

EXEC dbo.sp_purge_jobhistory  @oldest_date= @dt;

EXEC dbo.sp_maintplan_delete_log null,null, @dt;

EXEC dbo.sysmail_delete_mailitems_sp @sent_before = @dt, @sent_status = NULL;

DELETE FROM	dbo.sysjobactivity
WHERE	job_history_id IS NULL
OR		start_execution_date < @dt;
',
           @StepLog = @LogFolder + '\msdb DB Backup History Cleanup.txt'
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'msdb DB Backup History Cleanup', 
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
            @database_name=N'msdb',  
            @output_file_name=@StepLog, 
            @flags=2
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

    SELECT @StepCommand= 'EXEC [pr_RenameFile] 
        @Folder              = ''' + @LogFolder + '\'',
        @FileName            = ''msdb DB Backup History Cleanup.txt'', 
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

        EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Cleanup msdb DB Backup History', 
            @enabled=1, 
            @freq_type=8, 
            @freq_interval=1, 
            @freq_subday_type=1, 
            @freq_subday_interval=0, 
            @freq_relative_interval=0, 
            @freq_recurrence_factor=1, 
            @active_start_date=20100527, 
            @active_end_date=99991231, 
            @active_start_time=40000, 
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
