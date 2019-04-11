USE [msdb]
GO
/*********************************************************************************************
** Author name:   Bulent Gucuk
** Created date:  2019.04.09
** Purpose:       Create SQL Server Agent job to invoke web request to webhook
** Created for:   SDO-1295: Document spWhoIsActive Job Setup
**                https://ssbinfo.atlassian.net/browse/SDO-1295
** Copyright © 2019, SSB, All Rights Reserved 

** !!!!!!!!!!!!!!!! Parameters to update !!!!!!!!!!!!!!!!
** @JobCategoryName on Line 21, make sure there is one for the client that corresponds to metadata TenantName
** @JobName on line 32, make sure to update the name of the job that orders the job named with the clients other jobs
** Webhook value on line 80 for powershell input parameter for the  for the Runbook created
*********************************************************************************************/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory  ******/
--GET THE JOB Category
DECLARE @JobCategoryName NVARCHAR(256) = 'Oilers Entertainment Group Canada Corp'

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=@JobCategoryName AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=@JobCategoryName
	IF (@@ERROR <> 0 OR @ReturnCode <> 0)
	GOTO QuitWithRollback
END

-- Create the job
-- Update the tenant name part for the job name
DECLARE @JobName SYSNAME = 'Oilers.ClientDW.WhoIsActive'

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = @JobName)
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@JobName, 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'The job is for executing sp_whoisactive and persisting results in Client Azure SQL Database.', 
		@category_name=@JobCategoryName, 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'OpsGenie SQL Agent Incidents', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [Start job step 1]    Script Date: 4/8/2019 8:50:47 AM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 1)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Start job step 1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use master;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Powershell to invoke webhook]    Script Date: 4/8/2019 8:50:47 AM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Powershell to invoke webhook', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell "C:\PowerShell\ClientDW_WhoisActive\ClientDW_WhoIsActive.ps1 -Webhook ''https://s13events.azure-automation.net/webhooks?token=MAKESUREYOUCOPIEDTHERIGHTWEBHOOK'' -Method ''Post'' "', 
		@flags=0, 
		@proxy_name=N'CmdExeProxy'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=@JobName, 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190301, 
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
GO
