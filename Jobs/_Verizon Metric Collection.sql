USE [msdb]
GO

/****** Object:  Job [_ADMIN_AdvatarMetricGathering]    Script Date: 07/08/2016 23:07:24 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 07/08/2016 23:07:24 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'_ADMIN_AdvatarMetricGathering', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [_ADMIN_AdvatarMetricGathering]    Script Date: 07/08/2016 23:07:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'_ADMIN_AdvatarMetricGathering', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON
  
DECLARE @LoggingDateTime as DATETIME
SELECT @LoggingDateTime = GETDATE()
  
CREATE TABLE #DataFileStatistics(DatabaseName nvarchar(128), LogicalName nvarchar(128), FilePathAndName nvarchar(256), SizeInMB DECIMAL(10,2), SpaceUsedInMB DECIMAL(10,2), SizeInGB DECIMAL(10,2), SpaceUsedInGB DECIMAL(10,2))
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
INSERT INTO AdvatarMetrics.dbo.DataFileStatistics(LogginDateTime, DatabaseName, LogicalName, FilePathAndName, SizeInMB, SpaceUsedInMB, SizeInGB, SpaceUsedInGB, PercentageInUse)
SELECT @LoggingDateTime as ''LoggingDateTime'',
 DatabaseName,
 LogicalName,
 FilePathAndName,
 SizeInMB,
 SpaceUsedInMB,
 SizeInGB,
 SpaceUsedInGB,
 CONVERT(DECIMAL(5,2), ((SpaceUsedInMB / SizeInMB)* 100)) as ''PercentageInUse''
FROM #DataFileStatistics
ORDER BY
 DatabaseName
  
DROP TABLE #DataFileStatistics
  
CREATE TABLE #TableStatistics (TableName nvarchar(128), TableRowCount int, ReservedKB varchar(20), DataKB varchar(20), IndexKB varchar(20), UnusedKB varchar(20))
EXEC sp_MSforeachtable ''insert into #TableStatistics EXEC sp_spaceused ''''?'''' ''
  
INSERT INTO AdvatarMetrics.dbo.TableStatistics(LoggingDateTime, TableName, TableRowCount, ReservedMB, DataMB, IndexMB, UnusedMB)
SELECT @LoggingDateTime as ''LoggingDateTime'', TableName, TableRowCount,
 CONVERT(DECIMAL(10,2), (CONVERT(int, REPLACE(ReservedKB, '' KB'', ''''))/1024.0)) as ''ReservedMB'',
 CONVERT(DECIMAL(10,2), (CONVERT(int, REPLACE(DataKB, '' KB'', ''''))/1024.0)) as ''DataMB'',
 CONVERT(DECIMAL(10,2), (CONVERT(int, REPLACE(IndexKB, '' KB'', ''''))/1024.0)) as ''IndexMB'',
 CONVERT(DECIMAL(10,2), (CONVERT(int, REPLACE(UnusedKB, '' KB'', ''''))/1024.0)) as ''UnusedMB''
FROM #TableStatistics
ORDER BY ReservedMB DESC
  
DROP TABLE #TableStatistics
  
  
SELECT A.job_id as ''JobID'',
 A.name AS ''JobName'',
 MAX(msdb.dbo.agent_datetime(B.run_date,B.run_time)) AS ''JobExecutionDateTime'',
 CASE
 WHEN A.[enabled] = 1 THEN ''Enabled''
 ELSE ''Disabled''
 END as ''JobStatus''
INTO #Jobs
FROM msdb.dbo.sysjobhistory B INNER JOIN
 msdb.dbo.sysjobs A ON B.job_id = A.job_id
WHERE B.step_id = 0
GROUP BY
 A.job_id, A.name, A.[enabled]
  
  
INSERT INTO AdvatarMetrics.dbo.MostRecentJobExecutionHistory(LoggingDateTime, JobName, JobExecutionDateTime, IsEnabled, JobOutcome)
SELECT @LoggingDateTime as ''LoggingDateTime'',
 A.JobName,
 A.JobExecutionDateTime,
 A.JobStatus,
 CASE
 WHEN B.run_status=0 THEN ''Failed''
 WHEN B.run_status=1 THEN ''Succeeded''
 WHEN B.run_status=2 THEN ''Retry''
 WHEN B.run_status=3 THEN ''Cancelled''
 ELSE ''Unknown''
 END as ''JobOutcome''
FROM #Jobs A INNER JOIN
 msdb.dbo.sysjobhistory B ON A.JobID = B.job_id AND
 A.JobExecutionDateTime = (msdb.dbo.agent_datetime(B.run_date,B.run_time))
WHERE B.step_id=0
ORDER BY A.JobStatus DESC, A.JobName
  
DROP TABLE #Jobs
  
  
CREATE TABLE #FreeSpace(Drive char(1), MBFree int)
  
INSERT INTO #FreeSpace
EXEC xp_fixeddrives
  
INSERT INTO AdvatarMetrics.dbo.DiskCapacity(LoggingDateTime, Drive, MBFree)
SELECT @LoggingDateTime as ''LoggingDateTime'', Drive, MBFree
FROM #FreeSpace
  
DROP TABLE #FreeSpace
', 
		@database_name=N'Advatar', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [_ADMIN_DatabaseGrowthAlert]    Script Date: 07/08/2016 23:07:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'_ADMIN_DatabaseGrowthAlert', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE AdvatarMetrics;
GO
SET NOCOUNT ON;
IF OBJECT_ID (''dbo.DBSizeCheck'') IS NOT NULL
	BEGIN
		DROP TABLE dbo.DBSizeCheck;
	END

CREATE TABLE dbo.DBSizeCheck 
	(
	  RowNumber INT
	, DatabaseName VARCHAR(128)
	, LogicalName VARCHAR(128)
	, FilePathAndName VARCHAR(128)
	, SizeInGB DECIMAL(10,2)
	)

INSERT INTO dbo.DBSizeCheck
SELECT	
	  ROW_NUMBER() OVER(PARTITION BY LogicalName ORDER BY LogginDateTime DESC) AS ''RowNumber''
	, DatabaseName
	, LogicalName
	, FilePathAndName
	, SizeInGB
FROM (
	select top 8
		DatabaseName
		, LogicalName
		, FilePathAndName
		, SizeInGB
		, SpaceUsedInGB
		, PercentageInUse
		, LogginDateTime
	from dbo.DataFileStatistics
	WHERE	DatabaseName IN (''Advatar'', ''tempdb'')
	AND		LogginDateTime > DATEADD(MINUTE, - 5, GETDATE())
	ORDER BY DataFileStatisticsID DESC
	) AS Tempdbs

IF EXISTS (
		SELECT	Cur.RowNumber
			, cur.DatabaseName
			, Cur.LogicalName
			, Cur.SizeInGB AS ''CurrentSizeInGB''
			, Prev.SizeInGB AS ''PeviousSizeInGB''
			, Cur.SizeInGB - Prev.SizeInGB AS ''SizeDiff''
		FROM	dbo.DBSizeCheck AS Cur
			LEFT OUTER JOIN dbo.DBSizeCheck AS Prev ON Cur.RowNumber + 1 = Prev.RowNumber AND Cur.LogicalName = Prev.LogicalName
		WHERE	Prev.RowNumber IS NOT NULL
		AND		Cur.SizeInGB <> Prev.SizeInGB
		)
	BEGIN

		DECLARE @EmailRecipients VARCHAR(512) = ''supportinternal@invidi.com; bgucuk@invidi.com''
			, @SubjectLine VARCHAR(128) = ''Verizon BDMS Database Growth Alert''
			, @xml NVARCHAR(MAX)
			, @body NVARCHAR(MAX)


		SET @xml = CAST(( SELECT
			  Cur.DatabaseName AS ''td'',''''
			, Cur.LogicalName  AS ''td'',''''
			, Cur.SizeInGB AS ''td'',''''
			, Prev.SizeInGB  AS ''td'',''''
			, Cur.SizeInGB - Prev.SizeInGB  AS ''td'',''''
		FROM	dbo.DBSizeCheck AS Cur
			LEFT OUTER JOIN dbo.DBSizeCheck AS Prev ON Cur.RowNumber + 1 = Prev.RowNumber AND Cur.LogicalName = Prev.LogicalName
		WHERE	Prev.RowNumber IS NOT NULL
		AND		Cur.SizeInGB <> Prev.SizeInGB
		FOR XML PATH(''tr''), ELEMENTS ) AS NVARCHAR(MAX))


		SET @body =''<html><body><H3>Verizon DB Growth</H3>
		<table border = 1> 
		<tr>
		<th> DatabaseName </th> <th> LogicalName </th> <th> CurrentSizeInGB </th> <th> PeviousSizeInGB </th> <th> SizeDiff </th></tr>''    

		 
		SET @body = @body + @xml +''</table></body></html>''
		
		EXEC msdb.dbo.sp_send_dbmail  
			  @recipients = @EmailRecipients
			, @subject = @SubjectLine
			, @importance = ''High''
			, @body = @body
			, @body_format =''HTML'';
	

	END
DROP TABLE dbo.DBSizeCheck;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [_ADMIN_Tempdb Usage Metrics Collection]    Script Date: 07/08/2016 23:07:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'_ADMIN_Tempdb Usage Metrics Collection', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use tempdb;
GO
SET NOCOUNT ON;
DECLARE @Date DATETIME = GETDATE()
INSERT INTO [AdvatarMetrics].[dbo].[TempDBSpaceUsageHighLevel]
           ([user_obj_kb]
           ,[internal_obj_kb]
           ,[version_store_kb]
           ,[freespace_kb]
           ,[mixedextent_kb]
           ,[CreatedDate])

SELECT
	SUM (user_object_reserved_page_count)*8 as user_obj_kb,
	SUM (internal_object_reserved_page_count)*8 as internal_obj_kb,
	SUM (version_store_reserved_page_count)*8  as version_store_kb,
	SUM (unallocated_extent_page_count)*8 as freespace_kb,
	SUM (mixed_extent_page_count)*8 as mixedextent_kb,
	@Date AS ''CreatedDate''
FROM sys.dm_db_file_space_usage;

INSERT INTO [AdvatarMetrics].[dbo].[TempDBSpaceUsageSessionLevel]
           ([host_name]
           ,[login_name]
           ,[program_name]
           ,[QueryExecContextDBID]
           ,[QueryExecContextDBNAME]
           ,[ModuleObjectId]
           ,[Query_Text]
           ,[session_id]
           ,[request_id]
           ,[exec_context_id]
           ,[OutStanding_user_objects_page_counts]
           ,[OutStanding_internal_objects_page_counts]
           ,[start_time]
           ,[command]
           ,[open_transaction_count]
           ,[percent_complete]
           ,[estimated_completion_time]
           ,[cpu_time]
           ,[total_elapsed_time]
           ,[reads]
           ,[writes]
           ,[logical_reads]
           ,[granted_query_memory]
           ,[CreatedDate])
SELECT es.host_name , es.login_name , es.program_name,
st.dbid as QueryExecContextDBID, DB_NAME(st.dbid) as QueryExecContextDBNAME, st.objectid as ModuleObjectId,
SUBSTRING(st.text, er.statement_start_offset/2 + 1,(CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max),st.text)) * 2 ELSE er.statement_end_offset 
END - er.statement_start_offset)/2) as Query_Text,
tsu.session_id ,tsu.request_id, tsu.exec_context_id, 
(tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) as OutStanding_user_objects_page_counts,
(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) as OutStanding_internal_objects_page_counts,
er.start_time, er.command, er.open_transaction_count, er.percent_complete, er.estimated_completion_time, er.cpu_time, er.total_elapsed_time, er.reads,er.writes, 
er.logical_reads, er.granted_query_memory,
@Date AS ''CreatedDate''
FROM sys.dm_db_task_space_usage tsu
	inner join sys.dm_exec_requests er ON ( tsu.session_id = er.session_id and tsu.request_id = er.request_id)
	inner join sys.dm_exec_sessions es ON ( tsu.session_id = es.session_id )
	CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE (tsu.internal_objects_alloc_page_count+tsu.user_objects_alloc_page_count) > 0
ORDER BY (tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count)+(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) DESC;
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [_ADMIN L Drive Space Alert]    Script Date: 07/08/2016 23:07:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'_ADMIN L Drive Space Alert', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE AdvatarMetrics;
GO
SET NOCOUNT ON;
DECLARE @FreeSpace INT
	, @AlertThreshold INT = 153600 -- 150GB
	, @Drive CHAR (1) = ''L'' 

SELECT	@FreeSpace = MBFree
FROM	dbo.DiskCapacity
WHERE	LoggingDateTime = (select MAX(LoggingDateTime) from DiskCapacity)
AND		Drive = @Drive;

--SELECT @FreeSpace;

IF @FreeSpace < @AlertThreshold
	BEGIN
		DECLARE @EmailRecipients VARCHAR(512) = ''supportinternal@invidi.com; bgucuk@invidi.com''
			, @SubjectLine VARCHAR(128) = ''Verizon Drive Space Alert''
			, @MessageBody VARCHAR(512) = ''The '' + @Drive + '' drive free space is '' + CAST(@FreeSpace AS VARCHAR(16)) + ''MB. This is less than alert threshold ''
					+ CAST(@AlertThreshold AS VARCHAR(16)) + ''MB.''
		
		EXEC msdb.dbo.sp_send_dbmail  
			--@profile_name = ''Adventure Works Administrator'',  
			  @recipients = @EmailRecipients
			, @body = @MessageBody
			, @subject = @SubjectLine
			, @importance = ''High'';
	
	END

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [AdvatarMetrics Delete Records Older Than 60 Days]    Script Date: 07/08/2016 23:07:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'AdvatarMetrics Delete Records Older Than 60 Days', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE AdvatarMetrics;
GO
SET NOCOUNT ON;
DECLARE @Date DATETIME = CAST(DATEADD(DAY, -60, GETDATE()) AS DATE);

DELETE FROM dbo.TableStatistics
WHERE LoggingDateTime <= @Date;

DELETE FROM dbo.DataFileStatistics
WHERE LogginDateTime <= @Date;

DELETE FROM dbo.MostRecentJobExecutionHistory
WHERE LoggingDateTime <= @Date;

DELETE FROM dbo.DiskCapacity
WHERE LoggingDateTime <= @Date;

DELETE FROM dbo.IndexFragmentationLog
WHERE varReindexJobStart <= @Date;
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_ADMIN_AdvatarMetricGathering', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=2, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20151221, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'c6f726a8-94a8-4104-ba2b-cae6c1c1909f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


