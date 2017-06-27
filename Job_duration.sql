WITH job_duration_view
AS
(
SELECT name,
StartTime = CONVERT(DATETIME, RTRIM(last_run_date)) + 
(last_run_time * 9 + last_run_time % 10000 * 6 + last_run_time % 100 * 10 + 25 * last_run_duration) / 216e4 ,
CONVERT(CHAR(8),DATEADD(ss,last_run_duration,CAST(last_run_date AS CHAR(8))),114)
AS duration 
FROM msdb.dbo.sysjobservers js
JOIN msdb.dbo.sysjobs j ON j.job_id = js.job_id 
WHERE last_run_date >0 AND last_run_time >0
) SELECT name AS job_name,StartTime,
StartTime -'19000101'+Duration AS EndDate ,Duration
FROM job_duration_view order by name