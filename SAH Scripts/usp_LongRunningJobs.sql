USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_LongRunningJobs]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[usp_LongRunningJobs]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--exec [dbo].[usp_LongRunningJobs] 1

CREATE PROCEDURE [dbo].[usp_LongRunningJobs] @thresholdmin int
AS
Set NOCOUNT ON
----Set Mail Profile
Declare @oper_email varchar(150) = 'dba@shopathome.com'

declare @msg  Nvarchar(max)
--declare @thresholdmin int = 1
--only get jobs that have run within the current day
declare @date date
set @date = convert(date,getdate())


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
IF OBJECT_ID('tempdb..#RunningJobs') IS NOT NULL
    DROP TABLE #RunningJobs
 
CREATE TABLE #RunningJobs (
    [JobID] [UNIQUEIDENTIFIER] NOT NULL
    ,[JobName] [sysname] NOT NULL
    ,[StartExecutionDate] [DATETIME] NOT NULL
    ,[DurationLimit] [INT] NULL
    ,[CurrentDuration] [INT] NULL
	,[current_step] varchar(75)
    )


INSERT INTO #RunningJobs (
    JobID
    ,JobName
    ,StartExecutionDate
    ,DurationLimit
    ,CurrentDuration
	,Current_Step
    )
SELECT jobs.Job_ID AS JobID
    ,jobs.NAME AS JobName
    ,act.start_execution_date AS StartExecutionDate
	,@thresholdmin
    ,DATEDIFF(MI, act.start_execution_date, GETDATE()) AS [CurrentDuration]
	,js.step_name
FROM @currently_running_jobs crj
INNER JOIN msdb..sysjobs AS jobs with (nolock) ON crj.job_id = jobs.job_id
Inner join msdb..sysjobsteps js on crj.job_id = js.job_id and crj.[current_step] = js.step_id 
INNER JOIN msdb..sysjobactivity AS act with (nolock)  ON act.job_id = crj.job_id 
    AND act.stop_execution_date IS NULL
    AND act.start_execution_date IS NOT NULL
left outer JOIN msdb..sysjobhistory AS hist with (nolock) ON hist.job_id = crj.job_id 
    AND hist.step_id = 0 
WHERE crj.job_state = 1
and jobs.NAME = 'Update Merchants for Toolbar XML'
GROUP BY jobs.job_ID
    ,jobs.NAME
    ,act.start_execution_date
    ,DATEDIFF(MI, act.start_execution_date, GETDATE())
    ,js.step_name

-- Send email with results of long-running jobs
--select @msg = jobname + ' has been running for ' + Cast(CurrentDuration as varchar(6) )+' minutes' from RunningJobs with (nolock) order by StartExecutionDate
--Populate LongRunningJobs table with jobs exceeding established limits
--If (select top 1 currentduration from #RunningJobs with (nolock)) > 1 and 

--Update duration and endexecutiondate

update longrunningjobs 
set endexecutiondate = act.stop_execution_date,
CurrentDuration = DATEDIFF(MI, act.start_execution_date, GETDATE())
FROM LongRunningJobs crj
INNER JOIN msdb..sysjobs AS jobs with (nolock) ON crj.jobid = jobs.job_id 
INNER JOIN msdb..sysjobactivity AS act with (nolock)  ON act.job_id = crj.jobid and act.start_execution_date = crj.StartExecutionDate
where crj.EndExecutionDate is null





Print '#Running Jobs'
Select * From #RunningJobs

Print 'LongRunningJobs'
Select * From Master.dbo.LongRunningJobs

SELECT RJ.*
        FROM #RunningJobs RJ
        WHERE CHECKSUM(RJ.JobID, RJ.StartExecutionDate) NOT IN (
                SELECT CHECKSUM(JobID, StartExecutionDate)
                FROM Master.dbo.LongRunningJobs 
                ) and CurrentDuration > DurationLimit
Declare @val bit = 1

IF EXISTS (
        SELECT RJ.*
        FROM #RunningJobs RJ
        WHERE CHECKSUM(RJ.JobID, RJ.StartExecutionDate) NOT IN (
                SELECT CHECKSUM(JobID, StartExecutionDate)
                FROM Master.dbo.LongRunningJobs where rj.jobname = 'Update Merchants for Toolbar XML'
                )  and CurrentDuration > DurationLimit
        ) 
Begin
	set @val = 1
end
else 
begin
	set @val = 0
end
print @val

if @val = 1
begin
Print 'Email Sent'

	Set @msg = 

	N'<H1>Long Running Jobs</H1>' +
    N'<table border="1">' +
    N'<tr><th>Job Name</th>' + 
	 N'<th>StartExecutionDate</th>' + 
    N'<th>Duration</th>' +
	N'<th>CurrentStep</th>' +
	N'<th>Notification</th>' +
	
    +
    CAST ( ( SELECT td = rj.JobName,       '',
					td = rj.StartExecutionDate, '',
                    td = rj.CurrentDuration, '',
					td = rj.Current_Step, '',
					td =  case isnull(lr.Isnotified,0) when 0 then 'New Alert' else 'Already Notified' end,  ''
					
         From #RunningJobs rj left outer join longrunningjobs lr on (rj.jobid = lr.jobid and rj.startexecutiondate = lr.startexecutiondate)		 
		 where rj.CurrentDuration > rj.DurationLimit and rj.StartExecutionDate >= @date 
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' 
	EXEC msdb.dbo.sp_send_dbmail 
	@recipients=@oper_email,
	@subject = 'Long Running Job Alert',
	@Body = @msg, 
	@body_format = 'HTML' 
	



END
Else
begin
Print 'No Email Sent'
end


INSERT INTO Master.[dbo].[LongRunningJobs] (
    [JobID]
    ,[JobName]
    ,[StartExecutionDate]
    ,[DurationLimit]
    ,[CurrentDuration]
	,[current_step] 
    ) (
    SELECT RJ.* FROM #RunningJobs RJ WHERE CHECKSUM(RJ.JobID, RJ.StartExecutionDate) NOT IN (
        SELECT CHECKSUM(JobID, StartExecutionDate)
        FROM master.dbo.LongRunningJobs
        ) and currentduration > @thresholdmin
    )



update LongRunningJobs set isnotified = 1
where endexecutiondate is null










GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
