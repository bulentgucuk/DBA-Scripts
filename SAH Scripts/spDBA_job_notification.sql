USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spDBA_job_notification]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[spDBA_job_notification]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spDBA_job_notification]  @job_id uniqueidentifier as 
/*********************************************************************************************************
 Purpose: SQL Job Agent does not send the error messages on failure, 
           so this procedure queries msdb to for the error message and sends an email.

    usage: EXEC spDBA_job_notification [JOBID]					SQL2000
    usage: EXEC spDBA_job_notification $(ESCAPE_NONE(JOBID))		SQL2005 SP1 + 

2007.1.22  Jameel Ahmed Created 
    TODO: You will need to modify the @Email_To, @Email_From, & sp_sendmail according t your environment.
*********************************************************************************************************/
set  nocount on
declare @Today datetime, @CrLf varchar(10), @stat_Failed tinyint, @stat_Succeeded tinyint, @stat_Retry tinyint, @stat_Canceled tinyint, @stat_In_progress tinyint
declare @Email_To nvarchar(100), @Email_From nvarchar(50), @subject varchar(200), @Body varchar(max)
declare @job_name sysname, @step_name sysname, @Err_severity int, @run_datetime datetime, @DBname sysname
	  ,@command varchar(3200), @ErrMessage varchar(max)
set @Body = ''
set @CrLf = char(10)--+char(13)  --carriage return & line feed
--constants for Job Status execution: 
set @stat_Failed	  = 0
set @stat_Succeeded	  = 1
set @stat_Retry		  = 2
set @stat_Canceled	  = 3 
set @stat_In_progress	  = 4 
set @Today = getdate()

set @Email_TO   = 'dba@shopathome.com'
set @Email_From = @@servername + '@shopathome.com'

DECLARE curFailedJobs CURSOR READ_ONLY FOR 

	select sj.name, sjh.step_name, sjh.sql_severity, sjs.database_name ,run_datetime= convert(datetime, left( run_date ,4)+'/'+substring( run_date ,5,2)+'/'+right( run_date ,2)+' '+ left( run_time ,2)+':'+substring( run_time ,3,2)+':'+right( run_time ,2) ) 
	 	     ,sjs.command, sjh.message	--,sjh.run_status
	
	from msdb..sysjobs sj 
	
	join (select instance_id,job_id,step_id,step_name,sql_message_id,sql_severity,message,run_status,run_duration,operator_id_emailed,operator_id_netsent,operator_id_paged,retries_attempted,server
		,run_date= convert(varchar(8), run_date )		 
		,run_time= case when len(convert(varchar(8), run_time )) = 5 then '0' + convert(varchar(8), run_time ) else convert(varchar(8), run_time ) end    
	      from msdb..sysjobhistory) sjh on sj.job_id=sjh.job_id 
	
	join  msdb..sysjobsteps         sjs on sjs.job_id=sjh.job_id AND sjs.step_id=sjh.step_id 
	
	-- sjh_Min contains the most recent instance_id (an identity column) from where we should start checking for any failed status records.
	join (  
           -- to account for when there is are multiple log history
		   select  job_id, instance_id = max(instance_id) from msdb..sysjobhistory where job_id = @job_id  AND step_id =0 GROUP BY job_id
		   UNION  
           -- to account for when you run the job for the first time, there is no history, there will not be any records where the step_id=0.
select  job_id, instance_id = Min(instance_id) from msdb..sysjobhistory where job_id = @job_id  AND NOT EXISTS (select * from msdb..sysjobhistory where job_id = @job_id  AND step_id =0 ) GROUP BY job_id
	      )sjh_Min on sjh_Min.job_id =sj.job_id 
           AND sjh.instance_id > sjh_Min.instance_id -- we only want the most recent error message(s).
	
	where  sj.job_id = @job_id  
		  AND sjh.step_id<>0					 --exclude the job outcome step
		  AND sjh.run_status IN (@stat_Failed )  --filter for only failed status
	ORDER BY sjh.instance_id

OPEN curFailedJobs
FETCH NEXT FROM curFailedJobs INTO @job_name, @step_name, @Err_severity, @DBname, @run_datetime, @command , @ErrMessage 
WHILE @@fetch_status=0
BEGIN
	   -- Build the Email Body
	set @Body = @Body + 'Step name= ' + @step_name + @CrLf + 'DB Name = ' + convert(varchar(50), ISNULL(@DBname,'')) + @CrLf + 'Run Date = ' + convert(varchar(50),@run_datetime ) + @CrLf
       			 
	if (@Err_severity<>0) 
		set @Body = @Body + 
			     'Severity = ' + convert(varchar(10),@Err_severity) + @CrLf 

       set @Body = @Body + 
                 	     'Error    = ' + ISNULL(@ErrMessage,'') + @CrLf +  @CrLf + 
			     'Command  = ' + ISNULL(@command,'') + @CrLf  

	FETCH NEXT FROM curFailedJobs INTO @job_name, @step_name, @Err_severity, @DBname, @run_datetime, @command , @ErrMessage 
END
CLOSE curFailedJobs
DEALLOCATE curFailedJobs


-- Send the Email
if (rtrim(@Body)<>'')
begin 
	set @subject =@job_name +' FAILED on \\'+@@servername
        set @Body = -- 'Server= ' + @@servername + @CrLf  +
 		'Job_name = ' + @job_name  + @CrLf  +
 		'--------------------------------------'+ @CrLf  + @Body

	-- print 'Message Length = ' + convert(varchar(20),len(@Body))
	-- print @Body
    EXEC msdb.dbo.sp_send_dbmail  @recipients=@Email_To ,@subject = @subject ,@body = @Body  --SQL2005+
   
end

GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
