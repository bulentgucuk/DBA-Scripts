USE [DBAdmin]
GO
/****** Object:  StoredProcedure [dbo].[pr_getRunningJobs]    Script Date: 08/11/2011 17:37:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[pr_getRunningJobs] 
@name Varchar(max) = null,
@Return int Output 
as
/*
State Column
0 = Not idle or suspended, 
1 = Executing, 
2 = Waiting For Thread, 
3 = Between Retries, 
4 = Idle, 
5 = Suspended, 
6 = WaitingForStepToFinish, 
7 = PerformingCompletionActions
*/
set nocount on
create table #enum_job ( 
Job_ID uniqueidentifier, 
Last_Run_Date int, 
Last_Run_Time int, 
Next_Run_Date int, 
Next_Run_Time int, 
Next_Run_Schedule_ID int, 
Requested_To_Run int, 
Request_Source int, 
Request_Source_ID varchar(100), 
Running int, 
Current_Step int, 
Current_Retry_Attempt int, 
[State] int 
)     
DECLARE @b binary(16)  
--DECLARE @Return int  
DECLARE @u uniqueidentifier
select @u = job_id from msdb.dbo.sysjobs where name = @name
SET @b = CONVERT(binary(16), @u)
--SELECT @b
--select @u

insert into #enum_job 
     exec master.dbo.xp_sqlagent_enum_jobs 1,sa, @b
if (select count (*) from #enum_job where running = 1) <> 0
begin
select @Return =  [State] from #enum_job where running = 1
end
else
begin
set @Return = 0
end
--select * from #enum_job 
--select @Return
drop table #enum_job

 /*
 DBAdmin..pr_getRunningJobs 'GROW: Process OLAP OASRPTP02A.OAS All' 
 */