SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Description: 

	Checks if the given job name is running and if runing, waits for 
	given 'WaitTime' and checks again, in a loop.
	If the job is not running, this proc will start it!

	Once the given job completes execution, this stored procedure will exit
	with a return code for the the status of the job being watched

	Return Codes
	Failed		= 0
	Successful	= 1
	Cancelled	= 3


Modifications: 
9/30/2009 
	Originial script into store procedure and add return code to provide the status of the job

10/26/2010
	Modified to add raiseerror to fail if the job failed and also add raise error to print out 
	status of the job by using "WITH NOWAIT" option.
	Also modify the parameter not to 

11/7/2010 
		Insert into TABLE Variable from EXEC any SP is not allowed in SQL 2000. 
		Hence createing temporary table #xp_results instead of TABLE variable @xp_results
	
Example 1> 
DECLARE @RetStatus int
exec dbo.sp_sp_start_job_wait 'DBA - Test Job','00:00:01',@RetStatus OUTPUT
select @RetStatus

Example 2>
exec dbo.sp_sp_start_job_wait 'zzzDBATest'
*/ 

CREATE PROCEDURE dbo.usp_Start_Job_Wait
(
@job_name SYSNAME,
@WaitTime DATETIME = '00:00:05',  -- this is parameter for check frequency
@JobCompletionStatus INT = null OUTPUT
)
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

-- DECLARE @job_name	sysname
DECLARE @job_id		UNIQUEIDENTIFIER
DECLARE @job_owner	sysname

--Createing TEMP TABLE
CREATE TABLE #xp_results (job_id             UNIQUEIDENTIFIER NOT NULL,
                        last_run_date         INT              NOT NULL,
                        last_run_time         INT              NOT NULL,
                        next_run_date         INT              NOT NULL,
                        next_run_time         INT              NOT NULL,
                        next_run_schedule_id  INT              NOT NULL,
                        requested_to_run      INT              NOT NULL, -- BOOL
                        request_source        INT              NOT NULL,
                        request_source_id     sysname          COLLATE database_default NULL,
                        running               INT              NOT NULL, -- BOOL
                        current_step          INT              NOT NULL,
                        current_retry_attempt INT              NOT NULL,
                        job_state             INT              NOT NULL)

SELECT @job_id = job_id FROM msdb.dbo.sysjobs
WHERE name = @job_name

SELECT @job_owner = SUSER_SNAME()

INSERT INTO #xp_results
EXECUTE master.dbo.xp_sqlagent_enum_jobs  1, @job_owner, @job_id 

-- Start the job if the job is not running
IF NOT EXISTS(SELECT TOP 1 * FROM #xp_results WHERE running = 1)
	EXEC msdb.dbo.sp_start_job @job_name = @job_name

-- Give 2 sec for think time.
WAITFOR DELAY '00:00:02'

DELETE FROM #xp_results
INSERT INTO #xp_results
EXECUTE master.dbo.xp_sqlagent_enum_jobs  1, @job_owner, @job_id 

WHILE EXISTS(SELECT TOP 1 * FROM #xp_results WHERE running = 1)
BEGIN

	WAITFOR DELAY @WaitTime

	-- Information 
	raiserror('JOB IS RUNNING', 0, 1 ) WITH NOWAIT	

	DELETE FROM #xp_results

	INSERT INTO #xp_results
	EXECUTE master.dbo.xp_sqlagent_enum_jobs  1, @job_owner, @job_id 

END

SELECT @JobCompletionStatus = run_status 
FROM msdb.dbo.sysjobhistory
WHERE job_id = @job_id

IF @JobCompletionStatus = 1
	PRINT 'The job ran Successful' 
ELSE IF @JobCompletionStatus = 3
	PRINT 'The job is Cancelled'
ELSE 
BEGIN
	RAISERROR ('[ERROR]:%s job is either failed or not in good state. Please check',16, 1, @job_name) WITH LOG
END

RETURN @JobCompletionStatus

GO