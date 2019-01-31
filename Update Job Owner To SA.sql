USE MSDB;
GO
SET NOCOUNT ON;
/********************************

This script is used to update the job owner to sa for
the jobs that is not already owned by sa.

********************************/
DECLARE
	  @MinRowId INT = 1
	, @MaxRowId INT
	, @jobId UNIQUEIDENTIFIER
	, @owner_login_name NVARCHAR(128) = N'sa';

-- Store the job steps in a temp table to update the in the loop later
IF OBJECT_ID('tempdb..#Jobs') IS NOT NULL
	DROP TABLE #Jobs;
CREATE TABLE #Jobs (
	  RowId INT IDENTITY (1,1) NOT NULL
	, job_id UNIQUEIDENTIFIER NOT NULL
	, jobname SYSNAME NOT NULL
	, owner_sid VARBINARY(85)
	);

INSERT INTO #Jobs (job_id, jobname, owner_sid )
SELECT	j.job_id, j.name, j.owner_sid
FROM	dbo.sysjobs AS j
WHERE	J.owner_sid <> 0x01 -- sid for SA
ORDER BY j.name

SET	@MaxRowId = @@ROWCOUNT;

WHILE @MinRowId <= @MaxRowId
	BEGIN
		SELECT	@jobId = job_id
		FROM	#Jobs
		WHERE	RowId = @MinRowId;
		
		EXEC sp_update_job @job_id = @jobId, @owner_login_name = @owner_login_name;

		SET @MinRowId = @MinRowId + 1;
	END
--Return list of jobs and original owner sid
SELECT * FROM #Jobs;
DROP TABLE #Jobs;