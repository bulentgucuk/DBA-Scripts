USE [msdb]
GO

/****** Object:  Job [DBA Check Identity Values for All Tables]    Script Date: 3/28/2016 10:23:18 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 3/28/2016 10:23:18 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'DBA Check Identity Values for All Tables')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Check Identity Values for All Tables', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA Group', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [Populate checkidentity table]    Script Date: 3/28/2016 10:23:18 AM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 1)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Populate checkidentity table', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- job step 1 to populate the checkidentity table
USE master 
DECLARE	@Str VARCHAR (2000),
		@DbName VARCHAR (128),
		@MaxRowId TINYINT

DECLARE	@T TABLE (
	ROWID TINYINT IDENTITY (1,1),
	DbName VARCHAR(128)
	)
INSERT	@T
SELECT	Name
FROM	Sys.Databases
WHERE	database_id > 4
AND		State = 0
AND		Is_Read_Only = 0
ORDER BY Name

SELECT	@MaxRowId = MAX(RowId) FROM @T

select	* from @t

WHILE	@MaxRowId > 0
	BEGIN
		SELECT	@DbName = ''''
		SELECT	@DbName = DbName
		FROM	@T
		WHERE	RowId = @MaxRowId
		
		SELECT	@Str = ''USE '' + @DbName + CHAR(13)
		SELECT	@Str = @Str + ''INSERT INTO DBadmin.dbo.CheckIdentity'' + CHAR(13)-- change the dbname
		SELECT	@Str = @Str + ''([ServerName]
							   ,[DatabaseName]
							   ,[TableName]
							   ,[ColumnName]
							   ,[DataType]
							   ,[CurrentIdentityValue]
							   ,[PercentageUsed]
							   ,[CreatedDate]
							   ,[CreatedBy])'' + CHAR(13)		
		SELECT	@Str = @Str + ''
			SELECT	@@SERVERNAME AS ServerName,
					DB_Name() AS DatabaseName,
					QUOTENAME(SCHEMA_NAME(t.schema_id)) + ''''.'''' +  QUOTENAME(t.name) AS TableName, 
					c.name AS ColumnName,
					CASE c.system_type_id
						WHEN 127 THEN ''''bigint''''
						WHEN 56 THEN ''''int''''
						WHEN 52 THEN ''''smallint''''
						WHEN 48 THEN ''''tinyint''''
					END AS ''''DataType'''',
					IDENT_CURRENT(SCHEMA_NAME(t.schema_id)  + ''''.'''' + t.name) AS CurrentIdentityValue,
					CASE c.system_type_id
						WHEN 127 THEN (IDENT_CURRENT(SCHEMA_NAME(t.schema_id)  + ''''.'''' + t.name) * 100.) / 9223372036854775807
						WHEN 56 THEN (IDENT_CURRENT(SCHEMA_NAME(t.schema_id)  + ''''.'''' + t.name) * 100.) / 2147483647
						WHEN 52 THEN (IDENT_CURRENT(SCHEMA_NAME(t.schema_id)  + ''''.'''' + t.name) * 100.) / 32767
						WHEN 48 THEN (IDENT_CURRENT(SCHEMA_NAME(t.schema_id)  + ''''.'''' + t.name) * 100.) / 255
					END AS ''''PercentageUsed'''',
					GETDATE() AS CreatedDate,
					SUSER_NAME() AS CreatedBy
			FROM	sys.columns AS c 
				INNER JOIN
				sys.tables AS t 
				ON t.[object_id] = c.[object_id]
			WHERE	c.is_identity = 1''
		PRINT @Str
		EXEC (@Str)
		SELECT	@MaxRowId = @MaxRowId - 1
	END', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Email to Group]    Script Date: 3/28/2016 10:23:18 AM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Email to Group', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE MASTER
DECLARE @SubjectLine VARCHAR(255)
SELECT	@SubjectLine = ''Identity Values For '' + @@SERVERNAME


exec msdb.dbo.sp_send_dbmail
	@recipients = ''BankrateInsuranceITDBAGroup@netquote.com'',
	--@copy_recipients = ''BankrateInsuranceITDBAGroup@netquote.com'',
	@subject = @SubjectLine,
	@query_result_width =  2048,
	@attach_query_result_as_file = 0,
	@Query = ''
			SET NOCOUNT ON
			DECLARE	@HourAgo DATETIME
			SELECT	@HourAgo = DATEADD(HOUR,-1, GETDATE())
			SELECT [DatabaseName]
				  ,[TableName]
				  ,[ColumnName]
				  ,[DataType]
				  ,[CurrentIdentityValue]
				  ,[PercentageUsed]
			FROM [DBadmin].[dbo].[CheckIdentity]
			WHERE	CreatedDate > @HourAgo
			  and percentageused > 50.0
			ORDER BY [DatabaseName],[TableName]
			''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete records older than 4 weeks]    Script Date: 3/28/2016 10:23:18 AM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId AND step_id = 3)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete records older than 4 weeks', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBadmin

SET NOCOUNT ON
DECLARE	@MonthAgo DATETIME
SELECT	@MonthAgo = DATEADD(MONTH,-1, GETDATE())
DELETE FROM dbo.CheckIdentity
WHERE	CreatedDate < @MonthAgo
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA CheckIdentity Values for All Tables', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20101115, 
		@active_end_date=99991231, 
		@active_start_time=81500, 
		@active_end_time=235959, 
		@schedule_uid=N'099aab4e-b457-454a-a273-5714df3e666f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


