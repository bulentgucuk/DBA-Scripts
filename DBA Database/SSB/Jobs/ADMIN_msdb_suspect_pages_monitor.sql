USE [msdb]
GO

/****** Object:  Job [ADMIN_msdb_suspect_pages_monitor]    Script Date: 6/23/2020 7:57:17 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 6/23/2020 7:57:17 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'ADMIN_msdb_suspect_pages_monitor')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ADMIN_msdb_suspect_pages_monitor', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [Start job step 1]    Script Date: 6/23/2020 7:57:17 PM ******/
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
/****** Object:  Step [Check record count and send alert if there is any record]    Script Date: 6/23/2020 7:57:17 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check record count and send alert if there is any record', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE msdb;
GO
--Check if there is any record in msdb.dbo.suspect_pages
--Update the email recipient parameter in line 13 for testing and other purposes
IF (
SELECT	COUNT(*)
FROM	dbo.suspect_pages
WHERE	event_type IN (1,2,3)
	) > 0
	BEGIN
	--Start building the email properties and content
		DECLARE @recipients NVARCHAR(MAX);
		SELECT	@recipients = ''bulentgucuk@gmail.com'';
		DECLARE @tableHTML NVARCHAR(MAX);
		DECLARE @Table NVARCHAR(MAX) = N'''';

		SELECT @Table = @Table +''<tr style="background-color:white;font-size: 12px;text-align:center;">'' +
			''<td>'' + CAST(@@servername AS VARCHAR(128)) + ''</td>'' +
			''<td>'' + CAST([d].[name] AS VARCHAR(128)) + ''</td>'' +
			''<td>'' + CAST([sp].[database_id] AS VARCHAR(8)) + ''</td>'' +
			''<td>'' + CAST([sp].[file_id] AS VARCHAR(8)) + ''</td>'' +
			''<td>'' + CAST([sp].[page_id] AS VARCHAR(128)) + ''</td>'' +
			''<td>'' + CAST([sp].[event_type] AS VARCHAR(128)) + ''</td>'' +
			''<td>'' + CAST([sp].[error_count] AS VARCHAR(128)) + ''</td>'' +
			''<td>'' + CAST([sp].[last_update_date] AS VARCHAR(64)) + ''</td>'' +
			''</tr>''
		FROM	dbo.suspect_pages AS sp
			INNER JOIN sys.databases AS d ON sp.database_id = d.database_id
		WHERE	sp.event_type IN (1,2,3);

		SELECT @tableHTML =
		N''https://docs.microsoft.com/en-us/sql/relational-databases/backup-restore/manage-the-suspect-pages-table-sql-server?view=sql-server-2017'' +
		N''<table border="1" align="left" cellpadding="2" cellspacing="0" style="color:black;font-family:arial,helvetica,sans-serif;" >'' +--text-align:center;" >'' +
		N''<tr style ="font-size: 12px;font-weight: normal;background: white;">
		<th>ServerName</th>
		<th>DatabaseName</th>
		<th>database_id</th>
		<th>file_id</th>
		<th>page_id</th>
		<th>event_type</th>
		<th>error_count</th>
		<th>last_update_date</th></tr>'' + @Table +	N''</table>'';

		DECLARE @Subj varchar(128);
		SELECT @Subj = @@servername + ''.msdb.dbo.suspect_pages Monitor'';

		EXEC msdb.dbo.sp_send_dbmail
			  @recipients = @recipients
			, @subject = @Subj
			, @body_format = ''HTML''
			, @Body = @tableHTML;
	END
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'ADMIN_msdb_suspect_pages_monitor', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190313, 
		@active_end_date=99991231, 
		@active_start_time=1000, 
		@active_end_time=235959, 
		@schedule_uid=N'b769375a-bb8f-41ed-b86c-d4bc25445502'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


