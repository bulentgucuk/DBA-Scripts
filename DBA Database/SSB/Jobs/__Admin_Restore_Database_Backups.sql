USE [msdb]
GO

/****** Object:  Job [__Admin_Restore_Database_Backups]    Script Date: 6/30/2020 8:38:50 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 6/30/2020 8:38:50 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'__Admin_Restore_Database_Backups')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'__Admin_Restore_Database_Backups', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [Start job step 1]    Script Date: 6/30/2020 8:38:51 PM ******/
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
/****** Object:  Step [Find the Database Backup File Properties]    Script Date: 6/30/2020 8:38:51 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Find the Database Backup File Properties', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [DBA]
GO
EXEC dbo.rp_GetDatabaseBackupFileProperties
	@RestorePath = ''G:\Backup\'';
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Powershell AzCopy Database Backup Files]    Script Date: 6/30/2020 8:38:51 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 3)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Powershell AzCopy Database Backup Files', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell.exe -File C:\PowerShell\_CopyDbBackupsFromAzureBlob.ps1', 
		@output_file_name=N'$(ESCAPE_SQUOTE(SQLLOGDIR))\AzCopy_Posh_DatabaseBackup_$(ESCAPE_SQUOTE(JOBID))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore Databases]    Script Date: 6/30/2020 8:38:51 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 4)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore Databases', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBA;
GO
EXEC dbo.rp_RestoreDatabase
	@DataFileRestorePath = ''F:\Data\'',
	@LogFileRestorePath = ''G:\Logs\'';', 
		@database_name=N'master', 
		@output_file_name=N'$(ESCAPE_SQUOTE(SQLLOGDIR))\Restore_DatabaseBackup_$(ESCAPE_SQUOTE(JOBID))_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Powershell Delete Database Backup Files]    Script Date: 6/30/2020 8:38:51 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 5)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Powershell Delete Database Backup Files', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell.exe -File C:\PowerShell\_DeleteDbBackupsCopiedForRestore.ps1', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Set DB Recovery Simple]    Script Date: 6/30/2020 8:38:51 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 6)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Set DB Recovery Simple', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBA;
GO
SET NOCOUNT ON;
DECLARE	@MinRowId SMALLINT = 1
	, @MaxRowId SMALLINT
	, @DbOwnerString NVARCHAR(512)
	, @DbRecoveryString NVARCHAR(512)
DECLARE	@T TABLE (
	RowId SMALLINT IDENTITY(1,1) NOT NULL
	, DatabaseName VARCHAR(128) NOT NULL
	, DbOwnerString NVARCHAR(512) NULL
	, DbRecoveryString NVARCHAR(512) NULL
	)
INSERT INTO @T (DatabaseName)
SELECT	DISTINCT(RestoreDatabaseNameAs)
FROM	dbo.RestoreDatabaseRequest
WHERE	IsActive = 1;

UPDATE @T
SET
	  DbOwnerString = ''ALTER AUTHORIZATION ON DATABASE::'' + QUOTENAME(DatabaseName) + '' TO SA;''
	, DbRecoveryString = ''ALTER DATABASE '' + + QUOTENAME(DatabaseName) + '' SET RECOVERY SIMPLE;''

SELECT * FROM @T

-- Capture the rowcount
SET @MaxRowId = @@ROWCOUNT;

WHILE @MinRowId <= @MaxRowId
	BEGIN
		SELECT
			  @DbOwnerString = DbOwnerString
			, @DbRecoveryString = DbRecoveryString
		FROM	@T
		WHERE	RowId = @MinRowId;

		PRINT @DbOwnerString;
		EXEC sp_executesql @stmt = @DbOwnerString;

		PRINT @DbRecoveryString;
		EXEC sp_executesql @stmt = @DbRecoveryString;

		SELECT @MinRowId = @MinRowId + 1;
	END
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Grant db_owner role membership]    Script Date: 6/30/2020 8:38:51 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 7)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Grant db_owner role membership', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBA;
GO
SET NOCOUNT ON;
DECLARE	@MinRowId SMALLINT = 1
	, @MaxRowId SMALLINT
	, @String NVARCHAR(512)
DECLARE	@T TABLE (
	RowId SMALLINT IDENTITY(1,1) NOT NULL
	, GroupName VARCHAR(64) NOT NULL
	, DatabaseName VARCHAR(128) NOT NULL
	, String NVARCHAR(512) NOT NULL
	)
INSERT INTO @T (GroupName, DatabaseName, String)
SELECT
	  p.name AS ''GroupName''
	, d.name AS ''DatabaseName''
	, CASE
		WHEN d.name = ''DBA'' THEN ''USE '' + QUOTENAME(d.name) + ''; IF NOT EXISTS (
		SELECT	*
		FROM	SYS.database_principals
		WHERE	name = '' + '''''''' + + p.name + '''''''' + '') BEGIN '' + ''CREATE USER '' + QUOTENAME (p.name) + '' FOR LOGIN '' + QUOTENAME (p.name) + '' WITH DEFAULT_SCHEMA=[dbo]; END'' +'' ALTER ROLE [db_datareader] ADD MEMBER '' + QUOTENAME (p.name) + '';''
		ELSE ''USE '' + QUOTENAME(d.name) + ''; IF NOT EXISTS (
		SELECT	*
		FROM	SYS.database_principals
		WHERE	name = '' + '''''''' + p.name + '''''''' + '') BEGIN '' + ''CREATE USER '' + QUOTENAME (p.name) + '' FOR LOGIN '' + QUOTENAME (p.name) + '' WITH DEFAULT_SCHEMA=[dbo]; END'' + '' ALTER ROLE [db_owner] ADD MEMBER '' + QUOTENAME (p.name) + '';''
	  END AS ''String''
FROM	SYS.server_principals AS p
	CROSS JOIN sys.databases AS d
WHERE	p.name IN (''SSBINFO\SSB Analytics Sec'', ''SSBINFO\SSB IE Sec'', ''SSBINFO\SSB Eng Sec'', ''SSBINFO\SSB CRM Sec'', ''SSBINFO\SSB ETL Sec'', ''SSBINFO\SSB - IT & Engineering - Database Engineering - Security'', ''SSBINFO\SSB Rpt Sec'',''SSBINFO\SSB QA Sec'')
AND		d.database_id > 4
AND		d.is_read_only = 0
AND		d.name IN  (
			SELECT	DISTINCT(RestoreDatabaseNameAs)
			FROM	dbo.RestoreDatabaseRequest
			WHERE	IsActive = 1
		)

-- Capture the rowcount
SET @MaxRowId = @@ROWCOUNT;

WHILE @MinRowId <= @MaxRowId
	BEGIN
		SELECT	@String = String
		FROM	@T
		WHERE	RowId = @MinRowId;

		PRINT @String;
		EXEC sp_executesql @stmt = @String;

		SELECT @MinRowId = @MinRowId + 1;
	END
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Fix Oprhan Users in Restored Databases]    Script Date: 6/30/2020 8:38:51 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 8)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Fix Oprhan Users in Restored Databases', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBA;
GO
SET NOCOUNT ON;
DECLARE @SQL nvarchar(2000)
DECLARE @name nvarchar(128)
DECLARE @database_id int
DECLARE @rowid SMALLINT

-- Create table to store orphan users in the databases
IF OBJECT_ID (''tempdb..#orphan_users'') IS NOT NULL
	DROP TABLE #orphan_users;

CREATE TABLE #orphan_users
	(
	  rowid SMALLINT IDENTITY NOT NULL
	, database_name nvarchar(128) NOT NULL
	, [user_name] nvarchar(128) NOT NULL
	, sync_command_text nvarchar(256) NOT NULL
	, processed BIT NOT NULL
	)

-- Create #databases temp table to store the databases restored in the last 1 day
IF OBJECT_ID (''tempdb..#databases'') IS NOT NULL
	DROP TABLE #databases;

CREATE TABLE #databases
	(
	  database_id int NOT NULL
	, database_name nvarchar(128) NOT NULL
	, processed bit NOT NULL)

INSERT INTO #databases (database_id, database_name, processed)
SELECT database_id, name, 0 AS processed
FROM master.sys.databases AS D
	INNER JOIN (
			SELECT	DISTINCT(RestoreDatabaseNameAs)
			FROM	dbo.RestoreDatabaseRequest
			WHERE	IsActive = 1
		) AS r ON r.RestoreDatabaseNameAs = d.name

-- While loop to find all the orphan users from all the user databases
WHILE (SELECT COUNT(processed) FROM #databases WHERE processed = 0) > 0
	BEGIN
		SELECT TOP 1
			@name = database_name,
			@database_id = database_id
		FROM #databases
		WHERE processed = 0
		ORDER BY database_id

		SELECT @SQL =

''USE ['' + @name + ''];
INSERT INTO #orphan_users (database_name, user_name, sync_command_text, processed)
SELECT	DB_NAME(), dp.name, '' + '''''''' + ''USE ['' + @name + ''];  ALTER USER ['' + '''''''' + '' + dp.name + '' + '''''''' + ''] '' + ''WITH LOGIN = ['' + '''''''' + '' + sp.name + '' + '''''''' + ''];'' +  '''''''' +  '','' + ''0'' + 
'' FROM    master.sys.server_principals AS sp
        INNER JOIN sys.database_principals AS dp ON sp.name = dp.name
WHERE   sp.type = ''''S''''  --SQL_LOGIN
AND		sp.sid <> dp.sid
''

		PRINT @SQL;

		EXEC sys.sp_executesql @SQL

		UPDATE #databases SET processed = 1 WHERE database_id = @database_id;
	END

-- While lopp to synch the users in user database to login in the master database
WHILE (SELECT COUNT(processed) FROM #orphan_users WHERE processed = 0) > 0
	BEGIN
		SELECT @SQL = '''';
		SELECT TOP 1
			  @rowid = rowid
			, @SQL = sync_command_text
		FROM #orphan_users
		WHERE processed = 0
		ORDER BY rowid

		PRINT @SQL;

		EXEC sys.sp_executesql @SQL;

		UPDATE #orphan_users SET processed = 1 WHERE rowid = @rowid;

	END


DROP TABLE #databases;
DROP TABLE #orphan_users;

SET NOCOUNT OFF;
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Set IsActive to False for the databases restored]    Script Date: 6/30/2020 8:38:51 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 9)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Set IsActive to False for the databases restored', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBA
GO
UPDATE [dbo].[RestoreDatabaseRequest]
SET	IsActive = 0
WHERE	IsActive = 1
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Database Restore Report Email]    Script Date: 6/30/2020 8:38:51 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 10)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Database Restore Report Email', 
		@step_id=10, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [DBA]
GO

DECLARE
	  @tableHTML NVARCHAR(MAX)
	, @Subj varchar(75);

EXEC dbo.sp_DatabaseRestoreReport @tableHTML output;

SELECT @Subj = @@servername + '' Database Restore Report'';

EXEC msdb.dbo.sp_send_dbmail
	  @recipients = ''devops@ssbinfo.com;ssb-allimplementation@ssbinfo.com;ssb-databaseengineering@ssbinfo.com''
	, @blind_copy_recipients = ''bgucuk@ssbinfo.com''
	, @subject = @Subj
	, @body_format = ''html''
	, @Body = @tableHTML;

GO', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Insert DB names In Prod But Non in dbo.RestoreDatabaseRequest table]    Script Date: 6/30/2020 8:38:51 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 11)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Insert DB names In Prod But Non in dbo.RestoreDatabaseRequest table', 
		@step_id=11, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBA
GO
INSERT INTO	dbo.RestoreDatabaseRequest
(
    DatabaseName,
    ProdServerName,
    RestoreDatabaseNameAs,
    IsActive

)
SELECT	R.name, ''vm-db-prod-01'', R.name, 0--, L.*
FROM	[VM-DB-PROD-01].MASTER.SYS.DATABASES AS R
	LEFT OUTER JOIN dbo.RestoreDatabaseRequest as L on r.name = l.DatabaseName
WHERE	r.database_id > 4
AND		R.is_read_only = 0
AND		R.state = 0
and		l.DatabaseName is null
and		r.name not in (''DBA'',''Asana'',''testASU'',''Ducks_Reporting_Restored'')

UNION

SELECT	R.name, ''vm-db-prod-02'', R.name, 0 --, L.*
FROM	[VM-DB-PROD-02].MASTER.SYS.DATABASES AS R
	LEFT OUTER JOIN dbo.RestoreDatabaseRequest as L on r.name = l.DatabaseName
WHERE	r.database_id > 4
AND		R.is_read_only = 0
AND		R.state = 0
and		l.DatabaseName is null
and		r.name not in (''DBA'',''Asana'',''testASU'',''Ducks_Reporting_Restored'')
ORDER BY R.name
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'__Admin_Restore_Database_Backups #2', 
		@enabled=0, 
		@freq_type=1, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20181229, 
		@active_end_date=99991231, 
		@active_start_time=72500, 
		@active_end_time=235959, 
		@schedule_uid=N'e458979b-06aa-4ad5-a5db-ec670c24d39c'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

