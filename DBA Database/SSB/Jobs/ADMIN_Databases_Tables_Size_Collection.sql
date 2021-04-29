USE [msdb]
GO

/****** Object:  Job [ADMIN_Databases_Tables_Size_Collection]    Script Date: 6/23/2020 7:55:12 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 6/23/2020 7:55:12 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'ADMIN_Databases_Tables_Size_Collection')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ADMIN_Databases_Tables_Size_Collection', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Job collects table size information for all the databases and then inserts the latest data to VM-MONITOR-01.DBA.dbo.TableSizeReport', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQL Agent Monitoring', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [Start Job Step]    Script Date: 6/23/2020 7:55:12 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 1)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Start Job Step', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE Master', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Database File Statistics Collection]    Script Date: 6/23/2020 7:55:12 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Database File Statistics Collection', 
		@step_id=2, 
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
  
DECLARE @LogDate as DATETIME;
SELECT @LogDate = GETDATE();
  
CREATE TABLE #DataFileStatistics(DatabaseName varchar(128), LogicalName varchar(128), FilePathAndName varchar(256), SizeInMB DECIMAL(10,2), SpaceUsedInMB DECIMAL(10,2), SizeInGB DECIMAL(10,2), SpaceUsedInGB DECIMAL(10,2))
EXEC sp_MSforeachdb ''USE [?]; INSERT INTO #DataFileStatistics
SELECT DB_NAME(DB_ID()),
 Name,
 physical_name,
 CONVERT(DECIMAL(10,2), ((size * 8.0) / 1024.0)),
 CAST(FILEPROPERTY(name, ''''SpaceUsed'''')/128.0 AS DECIMAL(10,2)),
 CONVERT(DECIMAL(10,2),(((size * 8.0) / 1024.0)/1024.0)),
 CAST(FILEPROPERTY(name, ''''SpaceUsed'''')/128.0/ 1024.0 AS DECIMAL(10,2))
FROM sys.database_files
WHERE DB_NAME(DB_ID()) = ''''?''''
''
INSERT INTO DBA.dbo.DataFileStatistics(LogDate, DatabaseName, LogicalName, FilePathAndName, SizeInMB, SpaceUsedInMB, SizeInGB, SpaceUsedInGB, PercentageInUse)
SELECT @LogDate as ''LogDate'',
 DatabaseName,
 LogicalName,
 FilePathAndName,
 SizeInMB,
 SpaceUsedInMB,
 SizeInGB,
 SpaceUsedInGB,
 CONVERT(DECIMAL(5,2), ((SpaceUsedInMB / SizeInMB)* 100)) as ''PercentageInUse''
FROM #DataFileStatistics
ORDER BY  DatabaseName;

DROP TABLE #DataFileStatistics;
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Table Size Statistics Collection]    Script Date: 6/23/2020 7:55:12 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 3)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Table Size Statistics Collection', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=3, 
		@retry_interval=2, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBA;
GO
SET NOCOUNT ON;
-- Get Table Statistics (Row Count, total space used)
IF OBJECT_ID(''tempdb..#TableStatistics'') IS NOT NULL
	BEGIN
		DROP TABLE #TableStatistics;
	END
CREATE TABLE #TableStatistics (DatabaseName SYSNAME, SchemaName SYSNAME, TableName VARCHAR(128), TableRowCount BIGINT, TotalSpaceKB VARCHAR(20), UsedSpaceKB VARCHAR(20), UnusedSpaceKB VARCHAR(20), Data_Compression_Desc VARCHAR(60));

EXEC sp_msforeachdb ''USE [?];
	INSERT INTO #TableStatistics 
	SELECT
		  ''''?'''' as DatabaseName
		, s.Name AS SchemaName
		, t.NAME AS TableName
		, p.rows AS TableRowCount
		, SUM(a.total_pages) * 8 AS TotalSpaceKB
		, SUM(a.used_pages) * 8 AS UsedSpaceKB
		, (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
		, p.data_compression_desc
	FROM	sys.tables AS t
		INNER JOIN sys.indexes AS i ON t.OBJECT_ID = i.object_id
		INNER JOIN sys.partitions AS p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
		INNER JOIN sys.allocation_units AS a ON p.partition_id = a.container_id
		LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
	--WHERE    p.rows > 0 AND t.is_ms_shipped = 0    AND i.OBJECT_ID > 255 
	GROUP BY	t.Name, s.Name, p.Rows, p.data_compression_desc
	ORDER BY s.name,  t.name'' ;

DECLARE	@LogDate DATETIME;
SET	@LogDate = GETDATE();
INSERT INTO [dbo].[TableStatistics]
           ([LogDate]
           ,[DatabaseName]
           ,[SchemaName]
           ,[TableName]
           ,[TableRowCount]
           ,[TotalSpaceKB]
           ,[UsedSpaceKB]
           ,[UnusedSpaceKB]
           ,[Data_Compression_Desc])

SELECT	 @LogDate AS ''LogDate'',[DatabaseName], [SchemaName], [TableName], [TableRowCount], [TotalSpaceKB], [UsedSpaceKB], [UnusedSpaceKB], [Data_Compression_Desc]
FROM	#TableStatistics;

DROP TABLE #TableStatistics;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Insert Latest Data To VM-MONITOR-01]    Script Date: 6/23/2020 7:55:12 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 4)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Insert Latest Data To VM-MONITOR-01', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBA;
GO
SET NOCOUNT ON;
DECLARE @MaxLogDate DATETIME;

SELECT	@MaxLogDate = MAX(LogDate)
FROM	dbo.TableStatistics;

INSERT INTO [vm-monitor-01].DBA.dbo.TableSizeReport
SELECT	CAST([LogDate] AS DATE) AS ''ReportDate''
	, @@SERVERNAME AS ServerName
	, [DatabaseName]
	, [SchemaName]
	, [TableName]
	, [TableRowCount]
	, CAST(CAST([TotalSpaceKB] / 1024 AS DECIMAL (12,2))/ 1024 AS DECIMAL (12,2)) AS ''TotalSpaceInGB''
	, [Data_Compression_Desc]
FROM	dbo.TableStatistics
WHERE	LogDate >= @MaxLogDate
ORDER BY TotalSpaceInGB DESC;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'ADMIN_Databases_Tables_Size_Collection', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20171222, 
		@active_end_date=99991231, 
		@active_start_time=100, 
		@active_end_time=235959, 
		@schedule_uid=N'207fe4a9-45a3-4ee2-adcf-036a210ee418'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


