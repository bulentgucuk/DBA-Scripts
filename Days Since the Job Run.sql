select MAX(DATEDIFF(dd, CONVERT(datetime, CAST(SJH.[run_date] AS CHAR(8)), 101), GETDATE())) AS [Days Since Last Run]
FROM msdb.dbo.[sysjobhistory] SJH INNER JOIN [msdb].dbo.[sysjobs] SJ ON SJH.[job_id] = SJ.[job_id] 
WHERE SJH.[step_id] = 0 
GROUP BY SJ.[name] 
ORDER BY SJ.[name]