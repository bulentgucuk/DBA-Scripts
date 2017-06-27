/***
https://www.mssqltips.com/sqlservertip/4600/simple-script-to-check-sql-server-replication-jobs/
***/

CREATE PROCEDURE GetReplicationAgentStatus
AS

BEGIN
set nocount on
set transaction isolation level read uncommitted 

/*
Make sure your agents are in the correct category 
i.e Merge agents under REPL-Merge, 
Distribution agents under REPL-Distribution 
and LogReader agent under REPL-LogReader
*/

select s.job_id,s.name,s.enabled,c.name as categoryname into #JobList 
from msdb.dbo.sysjobs s inner join msdb.dbo.syscategories c on s.category_id = c.category_id
where c.name in ('REPL-Merge','REPL-Distribution','REPL-LogReader')

create TABLE #xp_results  
   (job_id                UNIQUEIDENTIFIER NOT NULL,
    last_run_date         INT              NOT NULL,
    last_run_time         INT              NOT NULL,
    next_run_date         INT              NOT NULL,
    next_run_time         INT              NOT NULL,
    next_run_schedule_id  INT              NOT NULL,
    requested_to_run      INT              NOT NULL, 
    request_source        INT              NOT NULL,
    request_source_id     sysname          COLLATE database_default NULL,
    running               INT              NOT NULL,
    current_step          INT              NOT NULL,
    current_retry_attempt INT              NOT NULL,
    job_state             INT              NOT NULL)

insert into #xp_results 
exec master.dbo.xp_sqlagent_enum_jobs 1, ''

select j.name,j.categoryname,j.enabled, AgentStatus = CASE WHEN r.running =1 THEN 'Running' else 'Stopped'   end
from #JobList j inner join #xp_results r on j.job_id=r.job_id

-- Uncomment the below portion and use correct parameters to send email alert
/*
if exists (select j.name,j.categoryname,j.enabled,r.running
from #JobList j inner join #xp_results r   on j.job_id=r.job_id where running =0 )
begin
   declare @subject nvarchar(100)
   select @subject = N'Replication Agents Status on '+@@servername

   EXEC msdb.dbo.sp_send_dbmail
      @profile_name = 'ProfileName',
      @recipients = N'email id',
      @subject = @subject,
      @body = 'One or more agents found stopped'
end
*/
drop table #JobList,#xp_results
END