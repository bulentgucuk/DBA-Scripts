USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_MonitorStoppedReplicationAlert]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[usp_MonitorStoppedReplicationAlert]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_MonitorStoppedReplicationAlert] 
AS
Set NOCOUNT ON
----Set Mail Profile
Declare @oper_email varchar(150) = 'dba@shopathome.com'
--Declare @oper_email varchar(150) = 'jleonard@shopathome.com'
declare @msg  Nvarchar(max)


--Set limit in minutes (applies to all jobs)
DECLARE @currently_running_jobs TABLE (
    job_id UNIQUEIDENTIFIER NOT NULL
    ,last_run_date INT NOT NULL
    ,last_run_time INT NOT NULL
    ,next_run_date INT NOT NULL
    ,next_run_time INT NOT NULL
    ,next_run_schedule_id INT NOT NULL
    ,requested_to_run INT NOT NULL
    ,-- BOOL
    request_source INT NOT NULL
    ,request_source_id SYSNAME COLLATE database_default NULL
    ,running INT NOT NULL
    ,-- BOOL
    current_step INT NOT NULL
    ,current_retry_attempt INT NOT NULL
    ,job_state INT NOT NULL
    ) -- 0 = Not idle or suspended, 1 = Executing, 2 = Waiting For Thread, 3 = Between Retries, 4 = Idle, 5 = Suspended, [6 = WaitingForStepToFinish], 7 = PerformingCompletionActions
 
--Capture Jobs currently working
INSERT INTO @currently_running_jobs
EXECUTE master.dbo.xp_sqlagent_enum_jobs 1,''

--Temp table exists check
IF OBJECT_ID('tempdb..#ReplicationAgents') IS NOT NULL
    DROP TABLE #ReplicationAgents
 
CREATE TABLE #ReplicationAgents (
    [JobID] [UNIQUEIDENTIFIER] NOT NULL
    ,[JobName] [sysname] NOT NULL
    ,currentretryattempt int
    ,job_state int
    )


INSERT INTO #ReplicationAgents (
    JobID
    ,JobName
    ,Currentretryattempt
    ,job_state

    )
SELECT jobs.Job_ID AS JobID
    ,jobs.NAME AS JobName
    ,crj.current_retry_attempt 
    ,crj.job_state
FROM @currently_running_jobs crj
INNER JOIN msdb..sysjobs AS jobs with (nolock) ON crj.job_id = jobs.job_id
Inner join msdb..sysjobsteps js on crj.job_id = js.job_id and crj.[current_step] = js.step_id 
INNER JOIN msdb..sysjobactivity AS act with (nolock)  ON act.job_id = crj.job_id 
    AND act.stop_execution_date IS NULL
    AND act.start_execution_date IS NOT NULL
left outer JOIN msdb..sysjobhistory AS hist with (nolock) ON hist.job_id = crj.job_id 
    AND hist.step_id = 0 
and jobs.NAME like @@SERVERNAME+'%'

If exists (select * from  #ReplicationAgents where job_state <> 1)
begin

-- Send email 

	Set @msg = 

	N'<H1>One or more Agents have stopped</H1>' +
    N'<table border="1">' +
    N'<tr><th>Agent Name</th>' 
	
    +
    CAST ( ( SELECT distinct td = rj.JobName,       ''
					
         From #ReplicationAgents rj where rj.job_state <> 1 
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' 
	EXEC msdb.dbo.sp_send_dbmail 
	@recipients=@oper_email,
	@subject = 'Stopped Replication Agent Alert',
	@Body = @msg, 
	@body_format = 'HTML' ,
	@profile_name = 'Default',
	@importance = 'high'
	

	
	drop table #ReplicationAgents


END
Else
begin
Print 'No Email Sent'
end










GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
