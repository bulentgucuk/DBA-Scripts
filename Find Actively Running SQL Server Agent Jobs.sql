USE msdb;
GO
SELECT
    j.name AS job_name,
    ja.start_execution_date,      
    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
    Js.step_name
FROM dbo.sysjobactivity AS ja
	LEFT OUTER JOIN dbo.sysjobhistory AS jh ON ja.job_history_id = jh.instance_id
	INNER JOIN dbo.sysjobs AS j ON ja.job_id = j.job_id
	INNER JOIN dbo.sysjobsteps AS js ON ja.job_id = js.job_id AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC)
AND ja.start_execution_date is not null
AND ja.stop_execution_date is null
--AND j.name = 'NameOfTheJob' -- Uncomment and supply the name of the job you need to find out if it's actively running
GO