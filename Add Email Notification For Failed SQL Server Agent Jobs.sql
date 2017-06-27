--Create notifications for failed jobs with one easy script
--Here an easy way to setup alerts for all sql agent jobs. 
--Typically I use this to send an email alert when a job fails.
-- I always setup a group email address rather than individuals to make this a one-time setup.


USE [msdb]
GO
--create a DBA Team operator
EXEC msdb.dbo.sp_add_operator @name=N'Production DBA Team', -- Change this to the operator you need to be notified.
		@enabled=1, 
		@email_address=N'DBAS@yourdomain.com' -- Change this to the email address of the operator.
GO
--add notifications for failure to all jobs
DECLARE @QuotedIdentifier char(1); SET @QuotedIdentifier = '' -- use '''' for single quote
DECLARE @ListDelimeter char(1); SET @ListDelimeter = ';'
DECLARE @CSVlist varchar(max) --use varchar(8000) for SQL Server 2000
 
--no event log, email on failure
SELECT	@CSVlist = COALESCE(@CSVlist + @ListDelimeter, '') + @QuotedIdentifier + 
'
EXEC msdb.dbo.sp_update_job @job_id=N'''
+ convert(varchar(max),[job_id]) +
''', 
		@notify_level_eventlog=0,
		@notify_level_email=2, 
		@notify_email_operator_name=N''DBA Team''' -- Change this to the operator you need to be notified.
 + @QuotedIdentifier
from msdb.dbo.sysjobs
 
print @csvlist
--EXEC (@CSVlist)
GO