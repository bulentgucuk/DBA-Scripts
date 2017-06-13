USE [msdb]
GO

/****** Object:  Job [DBA Delete System Database Backup Files]    Script Date: 03/13/2013 11:47:24 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBA Delete System Database Backup Files')
EXEC msdb.dbo.sp_delete_job @job_id=N'2f239945-5b99-49bd-8153-1688dc8379cb', @delete_unused_schedule=1
GO

USE [msdb]
GO

/****** Object:  Job [DBA Delete System Database Backup Files]    Script Date: 03/13/2013 11:47:24 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 03/13/2013 11:47:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Delete System Database Backup Files', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Powershell script to delete backup files older than 3 days.  It does not delete backup files that have donotdelete or goldcopy in the backup file name.  The path and the number of days to keep can be changed it the parameters. The job is invoked upon successfull completion of ''DBA Backup System Databases'' job.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DBA Delete System Database Backup Files]    Script Date: 03/13/2013 11:47:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA Delete System Database Backup Files', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'PowerShell', 
		@command=N'
$Path = "Y:\MSSQL\Backups\"

$Daysback = "-3"

$CurrentDate = Get-Date

$DatetoDelete = $CurrentDate.AddDays($Daysback)

Get-ChildItem $Path -Exclude *goldcopy*,*donotdelete* | Where-Object {$_.LastWriteTime.Date -lt $DatetoDelete } | Remove-Item', 
		@database_name=N'master', 
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

GO


