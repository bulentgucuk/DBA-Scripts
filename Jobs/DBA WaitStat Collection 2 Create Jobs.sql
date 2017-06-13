USE [msdb]
GO

/****** Object:  Job [Wait Stats, Waiting Task, Virtual File Stats Collection]    Script Date: 7/8/2016 11:53:37 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/8/2016 11:53:37 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Wait Stats, Waiting Task, Virtual File Stats Collection', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'The stored the data in the tables in DBA database', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect sys.dm_os_wait_stats]    Script Date: 7/8/2016 11:53:38 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect sys.dm_os_wait_stats', 
		@step_id=1, 
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
SET NOCOUNT ON;
WITH [Waits] AS
	(SELECT
		[wait_type],
		[wait_time_ms] / 1000.0 AS [WaitS],
		([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
		[signal_wait_time_ms] / 1000.0 AS [SignalS],
		[waiting_tasks_count] AS [WaitCount],
		100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
		ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
	FROM sys.dm_os_wait_stats
	WHERE [wait_type] NOT IN (
		N''CLR_SEMAPHORE'',    N''LAZYWRITER_SLEEP'',
		N''RESOURCE_QUEUE'',   N''SQLTRACE_BUFFER_FLUSH'',
		N''SLEEP_TASK'',       N''SLEEP_SYSTEMTASK'',
		N''WAITFOR'',          N''HADR_FILESTREAM_IOMGR_IOCOMPLETION'',
		N''CHECKPOINT_QUEUE'', N''REQUEST_FOR_DEADLOCK_SEARCH'',
		N''XE_TIMER_EVENT'',   N''XE_DISPATCHER_JOIN'',
		N''LOGMGR_QUEUE'',     N''FT_IFTS_SCHEDULER_IDLE_WAIT'',
		N''BROKER_TASK_STOP'', N''CLR_MANUAL_EVENT'',
		N''CLR_AUTO_EVENT'',   N''DISPATCHER_QUEUE_SEMAPHORE'',
		N''TRACEWRITE'',       N''XE_DISPATCHER_WAIT'',
		N''BROKER_TO_FLUSH'',  N''BROKER_EVENTHANDLER'',
		N''FT_IFTSHC_MUTEX'',  N''SQLTRACE_INCREMENTAL_FLUSH_SLEEP'',
		N''DIRTY_PAGE_POLL'')
	)
INSERT INTO [dbo].[Waits]
           ([WaitType]
           ,[Wait_S]
           ,[Resource_S]
           ,[Signal_S]
           ,[WaitCount]
           ,[Percentage]
           ,[AvgWait_S]
           ,[AvgRes_S]
           ,[AvgSig_S]
           ,[CreatedDate])
SELECT DISTINCT
	[W1].[wait_type] AS [WaitType], 
	CAST ([W1].[WaitS] AS DECIMAL(14, 2)) AS [Wait_S],
	CAST ([W1].[ResourceS] AS DECIMAL(14, 2)) AS [Resource_S],
	CAST ([W1].[SignalS] AS DECIMAL(14, 2)) AS [Signal_S],
	[W1].[WaitCount] AS [WaitCount],
	CAST ([W1].[Percentage] AS DECIMAL(4, 2)) AS [Percentage],
	CAST (([W1].[WaitS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgWait_S],
	CAST (([W1].[ResourceS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgRes_S],
	CAST (([W1].[SignalS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgSig_S],
	CAST(GETDATE() AS SMALLDATETIME) AS ''CreatedDate''
FROM [Waits] AS [W1]
	INNER JOIN [Waits] AS [W2] ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum], [W1].[wait_type], [W1].[WaitS], [W1].[ResourceS], [W1].[SignalS], [W1].[WaitCount], [W1].[Percentage]
HAVING SUM ([W2].[Percentage]) - [W1].[Percentage] < 95; -- percentage threshold
GO', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect sys.dm_os_waiting_tasks]    Script Date: 7/8/2016 11:53:38 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect sys.dm_os_waiting_tasks', 
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
SET NOCOUNT ON;
INSERT INTO [dbo].[WaitingTasks]
           ([session_id]
           ,[exec_context_id]
           ,[wait_duration_ms]
           ,[wait_type]
           ,[blocking_session_id]
           ,[blocking_exec_context_id]
           ,[resource_description]
           ,[program_name]
           ,[DatabaseName]
           ,[text]
           ,[query_plan]
           ,[cpu_time]
           ,[memory_usage]
           ,[CreatedDate])
SELECT
	[owt].[session_id],
	[owt].[exec_context_id],
	[owt].[wait_duration_ms],
	[owt].[wait_type],
	[owt].[blocking_session_id],
	[owt].[blocking_exec_context_id],
	[owt].[resource_description],
	[es].[program_name],
	DB_NAME([est].[dbid]) AS ''DatabaseName'',
	[est].[text],
	[eqp].[query_plan],
	[es].[cpu_time],
	[es].[memory_usage],
	CAST(GETDATE() AS SMALLDATETIME) AS ''CreatedDate''
FROM sys.dm_os_waiting_tasks [owt]
INNER JOIN sys.dm_exec_sessions [es] ON
	[owt].[session_id] = [es].[session_id]
INNER JOIN sys.dm_exec_requests [er] ON
	[es].[session_id] = [er].[session_id]
OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
WHERE [es].[is_user_process] = 1
ORDER BY [owt].[session_id], [owt].[exec_context_id]
GO', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect sys.dm_io_virtual_file_stats]    Script Date: 7/8/2016 11:53:38 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect sys.dm_io_virtual_file_stats', 
		@step_id=3, 
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
DECLARE @CaptureID INT;
 
SELECT @CaptureID = MAX(CaptureID) FROM [dbo].[DatabaseFileLatency];
 
IF @CaptureID IS NULL	
BEGIN
  SET @CaptureID = 1;
END
ELSE
BEGIN
  SET @CaptureID = @CaptureID + 1;
END  
 
--SELECT @CaptureID;


INSERT INTO [dbo].[DatabaseFileLatency] 
(
	[CaptureID],
	[CaptureDate],
	[ReadLatency],
	[WriteLatency],
	[Latency],
	[AvgBPerRead],
	[AvgBPerWrite],
	[AvgBPerTransfer],
	[Drive],
	[DB],
	[database_id],
	[file_id],
	[sample_ms],
	[num_of_reads],
	[num_of_bytes_read],
	[io_stall_read_ms],
	[num_of_writes],
	[num_of_bytes_written],
	[io_stall_write_ms],
	[io_stall],
	[size_on_disk_MB],
	[file_handle],
	[physical_name]
)
SELECT 
    --virtual file latency
	@CaptureID,
	GETDATE(),
	CASE 
		WHEN [num_of_reads] = 0 
			THEN 0 
		ELSE ([io_stall_read_ms]/[num_of_reads]) 
	END [ReadLatency],
	CASE 
		WHEN [io_stall_write_ms] = 0 
			THEN 0 
		ELSE ([io_stall_write_ms]/[num_of_writes]) 
	END [WriteLatency],
	CASE 
		WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
             THEN 0 
		ELSE ([io_stall]/([num_of_reads] + [num_of_writes])) 
	END [Latency],
	--avg bytes per IOP
	CASE 
		WHEN [num_of_reads] = 0 
			THEN 0 
		ELSE ([num_of_bytes_read]/[num_of_reads]) 
	END [AvgBPerRead],
	CASE 
		WHEN [io_stall_write_ms] = 0 
			THEN 0 
		ELSE ([num_of_bytes_written]/[num_of_writes]) 
	END [AvgBPerWrite],
	CASE 
		WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
			THEN 0 
		ELSE (([num_of_bytes_read] + [num_of_bytes_written])/([num_of_reads] + [num_of_writes])) 
	END [AvgBPerTransfer],
	LEFT([mf].[physical_name],2) [Drive],
	DB_NAME([vfs].[database_id]) [DB],
	[vfs].[database_id],
	[vfs].[file_id],
	[vfs].[sample_ms],
	[vfs].[num_of_reads],
	[vfs].[num_of_bytes_read],
	[vfs].[io_stall_read_ms],
	[vfs].[num_of_writes],
	[vfs].[num_of_bytes_written],
	[vfs].[io_stall_write_ms],
	[vfs].[io_stall],
	[vfs].[size_on_disk_bytes]/1024/1024. [size_on_disk_MB],
	[vfs].[file_handle],
	[mf].[physical_name]
FROM [sys].[dm_io_virtual_file_stats](NULL,NULL) AS vfs
JOIN [sys].[master_files] [mf] 
    ON [vfs].[database_id] = [mf].[database_id] 
    AND [vfs].[file_id] = [mf].[file_id]
ORDER BY [Latency] DESC;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Prune the tables]    Script Date: 7/8/2016 11:53:38 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Prune the tables', 
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

DECLARE @ID BIGINT
-- dbo.WaitingTasks cleanup
SELECT	@ID = MAX(WaitingTaskID) - 50000
FROM	dbo.WaitingTasks WITH(NOLOCK);

DELETE FROM dbo.WaitingTasks
WHERE	WaitingTaskID < @ID;

-- dbo.WhoIsActive cleanup
SELECT	@ID = MAX(RowId)- 50000
FROM	dbo.WhoIsActive WITH(NOLOCK);

DELETE FROM dbo.WhoIsActive
WHERE	RowId < @ID;

-- dbo.DatabaseFileLatency cleanup
SELECT	@ID = MAX(RowId)- 50000
FROM	dbo.DatabaseFileLatency WITH(NOLOCK);

DELETE FROM dbo.DatabaseFileLatency
WHERE	RowId < @ID;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Waits and Waiting Task Collection', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160606, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'7833e996-fb13-458a-8942-a65922ffc25e'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


USE [msdb]
GO

/****** Object:  Job [WhoIsActive Collection]    Script Date: 7/8/2016 11:53:59 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 7/8/2016 11:53:59 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'WhoIsActive Collection', 
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
/****** Object:  Step [WhoIsActive Collection]    Script Date: 7/8/2016 11:53:59 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'WhoIsActive Collection', 
		@step_id=1, 
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

IF OBJECT_ID (''dbo.WhoIsActive_Temp'') IS NOT NULL
	BEGIN
		DROP TABLE dbo.WhoIsActive_Temp;
	END

DECLARE
    @destination_table VARCHAR(4000) ,
    @msg NVARCHAR(1000) ;
SET @destination_table = ''WhoIsActive_Temp'';

DECLARE @schema VARCHAR(4000) ;
EXEC sp_WhoIsActive
@get_transaction_info = 1,
@get_plans = 1,
@return_schema = 1,
@schema = @schema OUTPUT ;

SET @schema = REPLACE(@schema, ''<table_name>'', @destination_table) ;

PRINT @schema
EXEC(@schema) ;


    DECLARE @numberOfRuns INT ;
    SET @numberOfRuns = 1 ;
    WHILE @numberOfRuns > 0
        BEGIN;
            EXEC dbo.sp_WhoIsActive @get_transaction_info = 1, @get_plans = 1,
                @destination_table = @destination_table ;
            SET @numberOfRuns = @numberOfRuns - 1 ;
            IF @numberOfRuns > 0
                BEGIN
                    SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + '': '' +
                     ''Logged info. Waiting...''
                    RAISERROR(@msg,0,0) WITH nowait ;
                    WAITFOR DELAY ''00:00:05''
                END
            ELSE
                BEGIN
                    SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + '': '' + ''Done.''
                    RAISERROR(@msg,0,0) WITH nowait ;
                END
        END ;
    GO

INSERT INTO [dbo].[WhoIsActive]
           ([dd hh:mm:ss.mss]
           ,[session_id]
           ,[sql_text]
           ,[login_name]
           ,[wait_info]
           ,[tran_log_writes]
           ,[CPU]
           ,[tempdb_allocations]
           ,[tempdb_current]
           ,[blocking_session_id]
           ,[reads]
           ,[writes]
           ,[physical_reads]
           ,[query_plan]
           ,[used_memory]
           ,[status]
           ,[tran_start_time]
           ,[open_tran_count]
           ,[percent_complete]
           ,[host_name]
           ,[database_name]
           ,[program_name]
           ,[start_time]
           ,[login_time]
           ,[request_id]
           ,[collection_time]
		   )
SELECT
            [dd hh:mm:ss.mss]
           ,[session_id]
           ,[sql_text]
           ,[login_name]
           ,[wait_info]
           ,[tran_log_writes]
           ,[CPU]
           ,[tempdb_allocations]
           ,[tempdb_current]
           ,[blocking_session_id]
           ,[reads]
           ,[writes]
           ,[physical_reads]
           ,[query_plan]
           ,[used_memory]
           ,[status]
           ,[tran_start_time]
           ,[open_tran_count]
           ,[percent_complete]
           ,[host_name]
           ,[database_name]
           ,[program_name]
           ,[start_time]
           ,[login_time]
           ,[request_id]
           ,[collection_time]
FROM	[dbo].[WhoIsActive_Temp];
DROP TABLE [dbo].[WhoIsActive_Temp];', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'WhoIsActive Collection', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160607, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'dd7aad20-3537-4b8c-832d-b32466dfb4a8'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

