use msdb
GO

UPDATE sysjobsteps
    SET command = REPLACE(command, 'lp_', 'pr_')
    FROM sysjobsteps js
        INNER JOIN sysjobs j
            ON j.job_id = js.job_id
    WHERE j.name LIKE 'DBAdmin%'
     AND  js.command LIKE '%lp_%'



