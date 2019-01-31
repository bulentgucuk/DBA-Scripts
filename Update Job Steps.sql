USE MSDB;
GO
SET NOCOUNT ON;
/********************************

This script is used to update the proxies that are being used in the new domain.
Same script can be used to update the other parts of the job step using built-in
SQL Server functions like REPLACE to update the command

********************************/
DECLARE
	  @MinRowId INT = 1
	, @MaxRowId INT
	, @SSISProxy INT
	, @CmdExeProxy INT
	, @jobId UNIQUEIDENTIFIER
	, @StepId INT
	, @subsystem NVARCHAR(40)
	, @Command NVARCHAR(MAX) -- used it to prevent conversion since the system proc uses that data type

-- Get the proxy_id values and store them in the variable
SELECT	@SSISProxy = proxy_id
FROM	dbo.sysproxies
WHERE	name = 'SSISProxy';

SELECT	@CmdExeProxy = proxy_id
FROM	dbo.sysproxies
WHERE	name = 'CmdExeProxy';

-- Store the job steps in a temp table to update the in the loop later
DROP TABLE IF EXISTS #JobSteps;
CREATE TABLE #JobSteps (
	RowId INT IDENTITY (1,1) NOT NULL
	, job_id UNIQUEIDENTIFIER NOT NULL
	, step_id INT NOT NULL
	, jobname SYSNAME NOT NULL
	, step_name SYSNAME NOT NULL
	, subsystem NVARCHAR(40) NOT NULL
	, command NVARCHAR(MAX) NOT NULL

	)
INSERT INTO #JobSteps (job_id, step_id, jobname, step_name, subsystem, command )
SELECT	j.job_id, js.step_id, j.name, js.step_name, js.subsystem, js.command
	--, js.*
FROM	dbo.sysjobsteps as js
	INNER JOIN dbo.sysjobs AS j ON j.job_id = js.job_id
WHERE	J.name LIKE 'CRM PROD%'
AND		js.subsystem IN ('SSIS', 'CmdExec');

SET	@MaxRowId = @@ROWCOUNT;

WHILE @MinRowId <= @MaxRowId
	BEGIN
		SELECT	@jobId = job_id
			, @StepId = step_id
			, @subsystem = subsystem
		FROM	#JobSteps
		WHERE	RowId = @MinRowId
		
		IF @subsystem = 'SSIS'
			BEGIN
				EXEC sp_update_jobstep @job_id = @jobId, @step_id = @stepid, @proxy_id = @SSISProxy;
			END
		IF @subsystem = 'CmdExec'
			BEGIN
				EXEC sp_update_jobstep @job_id = @jobId, @step_id = @stepid, @proxy_id = @CmdExeProxy;
			END
		
		--PRINT @MinRowId;

		SET @MinRowId = @MinRowId + 1;
	END
