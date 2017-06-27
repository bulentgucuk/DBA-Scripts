USE [msdb]
GO

/****** Object:  Job [DBA Rebuild Reorganize Indexes on All Databases]    Script Date: 09/20/2011 11:43:44 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 09/20/2011 11:43:44 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Rebuild Reorganize Indexes on All Databases', 
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
/****** Object:  Step [Delete Records in DefragmentIndexes Table]    Script Date: 09/20/2011 11:43:44 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Records in DefragmentIndexes Table', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBAdmin

SET NOCOUNT ON

DECLARE	@MaxDateMinus30Days DATETIME

SELECT	@MaxDateMinus30Days = DATEADD(DAY,-30, CAST(FLOOR(CAST(MAX(DefragmentDate) AS FLOAT)) AS DATETIME))
FROM	dbo.DefragmentIndexes

SELECT	@MaxDateMinus30Days

DELETE FROM dbo.DefragmentIndexes
WHERE	DefragmentDate < @MaxDateMinus30Days', 
		@database_name=N'master', 
		@output_file_name=N'F:\SSIS\IndexMaintenanceJobLog.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Index rebuild with New Proc]    Script Date: 09/20/2011 11:43:44 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Index rebuild with New Proc', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBAdmin
SET NOCOUNT ON
DECLARE	@RowId TINYINT,
		@DbName SYSNAME;
DECLARE	@DbNames TABLE(
		RowId TINYINT IDENTITY (1,1),
		DbName SYSNAME
		)
INSERT INTO @DbNames
SELECT	Name
FROM	SYS.DATABASES
WHERE	Is_Read_Only = 0
AND	State_Desc = ''ONLINE''
AND	Name <> ''Tempdb''


SELECT	@RowId = MAX(RowId) FROM @DbNames
WHILE	@RowId > 0
	BEGIN
		SELECT	@DbName = DbName FROM @DbNames WHERE RowId = @RowId
		--PRINT	@DBNAME
		EXEC dbo.dba_Index_defrag
			@dbName = @DbName, 
			@statsMode = ''SAMPLED'', 
			@defragType = ''REBUILD'', 
			@minFragPercent = 30,
			@maxFragPercent = 100,
			@minRowCount = 1000,
			@logHistory = 1,
			@sortInTempdb = 1
		SELECT	@RowId = @RowId - 1
	END

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Rebuild Reorganize Indexes', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20080508, 
		@active_end_date=99991231, 
		@active_start_time=4500, 
		@active_end_time=235959, 
		@schedule_uid=N'5e73426a-fc6a-435c-8bf2-790b266cca10'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


