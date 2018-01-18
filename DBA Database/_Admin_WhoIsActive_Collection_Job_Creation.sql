USE [msdb]
GO

/****** Object:  Job [_ADMIN_WhoIsActive Collection]    Script Date: 12/20/2017 4:02:45 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 12/20/2017 4:02:45 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'_ADMIN_WhoIsActive Collection')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'_ADMIN_WhoIsActive Collection', 
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

END
/****** Object:  Step [Start Job Step]    Script Date: 12/20/2017 4:02:45 PM ******/
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
		@command=N'USE MASTER;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CPU Utilization Collection]    Script Date: 12/20/2017 4:02:45 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CPU Utilization Collection', 
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
SET QUOTED_IDENTIFIER ON;
DECLARE @T TABLE(
	[SqlCpuUtilization] [int] NOT NULL,
	[SystemIdleProcess] [int] NOT NULL,
	[OtherProcessCpuUtilization] [int] NOT NULL,
	[EventTime] [datetime] NOT NULL
	);

DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info WITH (NOLOCK)); 

INSERT INTO @T
-- This version works with SQL Server 2014
SELECT TOP(256) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM (SELECT record.value(''(./Record/@id)[1]'', ''int'') AS record_id, 
			record.value(''(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]'', ''int'') 
			AS [SystemIdle], 
			record.value(''(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]'', ''int'') 
			AS [SQLProcessUtilization], [timestamp] 
	  FROM (SELECT [timestamp], CONVERT(xml, record) AS [record] 
			FROM sys.dm_os_ring_buffers WITH (NOLOCK)
			WHERE ring_buffer_type = N''RING_BUFFER_SCHEDULER_MONITOR'' 
			AND record LIKE N''%<SystemHealth>%'') AS x) AS y 
ORDER BY record_id DESC OPTION (RECOMPILE);

INSERT INTO dbo.CpuUtilization
SELECT	T.*
FROM	@T AS T
	LEFT OUTER JOIN dbo.CpuUtilization AS C ON T.EventTime = C.EventTime
WHERE	C.EventTime IS NULL
OPTION (RECOMPILE);
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Admin_WhoIsActive Collection]    Script Date: 12/20/2017 4:02:45 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 3)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Admin_WhoIsActive Collection', 
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
/****** Object:  Step [Prune dbo.WhoisActive And dbo.CpuUtilization]    Script Date: 12/20/2017 4:02:45 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 4)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Prune dbo.WhoisActive And dbo.CpuUtilization', 
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
DECLARE @ID BIGINT;
DECLARE @D DATETIME;

-- dbo.WhoIsActive clean up keep last 7 days of data
SET	@D = (SELECT CAST(DATEADD(DAY, -7, GETDATE()) AS date));
SELECT	@ID = MAX(RowId)
FROM	dbo.WhoIsActive WITH(NOLOCK)
WHERE	collection_time <= @D;

DELETE FROM dbo.WhoIsActive
WHERE	RowId < @ID;

--dbo.CpuUtilization clean up keep last 30 days of data
SET	@D = (SELECT CAST(DATEADD(DAY, -30, GETDATE()) AS date));

DELETE	FROM dbo.CpuUtilization
WHERE	EventTime < @D;
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_Admin_WhoIsActive Collection', 
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
