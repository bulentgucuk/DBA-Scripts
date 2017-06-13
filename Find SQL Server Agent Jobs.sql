IF OBJECT_ID('tempdb..#JobStatus') IS NOT NULL
	DROP TABLE #JobStatus;
CREATE TABLE #JobStatus(
       job_id uniqueidentifier 
      ,originating_server nvarchar(30)
      ,name sysname
      ,enabled tinyint
      ,description nvarchar(512)
      ,start_step_id int
      ,category sysname
      ,owner sysname
      ,notify_level_eventlog int
      ,notify_level_email int
      ,notify_level_netsend int
      ,notify_level_page int
      ,notify_email_operator sysname
      ,notify_netsend_operator sysname
      ,notify_page_operator sysname
      ,delete_level int
      ,date_created datetime
      ,date_modified datetime
      ,version_number int
      ,last_run_date int
      ,last_run_time int
      ,last_run_outcome int
      ,next_run_date int
      ,next_run_time int
      ,next_run_schedule_id int
      ,current_execution_status int
      ,current_execution_step sysname 
      ,current_retry_attempt int
      ,has_step int
      ,has_schedule int
      ,has_target int
      ,type int     
); 

INSERT INTO #JobStatus
EXEC dbo.sp_help_job

SELECT J.originating_server
	, j.name
	, j.enabled
	, j.description
	, j.last_run_date
	, j.last_run_time
	, JS.next_run_date
	, JS.next_run_time
FROM #JobStatus AS j
	INNER JOIN msdb.dbo.sysjobschedules AS JS ON JS.job_id = j.job_id
ORDER BY j.name, js.schedule_id
