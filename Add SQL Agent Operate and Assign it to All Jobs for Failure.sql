USE MSDB
select sj.name, sj.enabled, sj.category_id, sj.job_id
FROM dbo.sysjobs sj 
where sj.category_id = 3
order by sj.name

USE [msdb]
GO

-- Create Operator [SQL Agent Monitoring]
IF NOT EXISTS (SELECT name FROM msdb.dbo.sysoperators WHERE name = N'SQL Agent Monitoring')
EXEC msdb.dbo.sp_add_operator @name=N'SQL Agent Monitoring', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'monitoring-sqlagent@ssbinfo.com', 
		@category_name=N'[Uncategorized]'
GO

DECLARE
	  @Operator varchar(50)
	, @AlertText varchar(max);

SET @Operator = 'SQL Agent Monitoring';
SET @AlertText = '';

--Create the alert text 
SELECT @AlertText = 'EXEC msdb.dbo.sp_update_job 
	@job_ID = ''' + convert(varchar(50),job_id) + ''' , 
	@notify_level_email = 2, 
	@notify_email_operator_name = ''' + @operator + '''; ' 
	+ char(10) + @AlertText 
FROM dbo.sysjobs sj 
WHERE sj.category_id <> 3  -- category_id = 3 is 'Database Maintenance' category

--Print the alert text and confirm it is valid before exec 
PRINT @AlertText;

--Uncomment below and comment the PRINT to exec alerts 
EXEC (@AlertText);

GO
