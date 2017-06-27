USE [msdb]
GO

/****** Object:  Job [DBA Collect SQL Server Jobs]    Script Date: 02/19/2011 08:14:12 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [DBA Jobs]    Script Date: 02/19/2011 08:14:12 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'DBA Jobs' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'DBA Jobs'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Collect SQL Server Jobs', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Collects SQL Server Jobs from production servers.', 
		@category_name=N'DBA Jobs', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete Rows older than 30 days]    Script Date: 02/19/2011 08:14:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete Rows older than 30 days', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE NetQuoteTechnologyOperations
SET NOCOUNT ON
DECLARE	@MinDateToKeep DATETIME -- keep last 30 days of data
SELECT	@MinDateToKeep = CAST(FLOOR(CAST(DATEADD(MONTH,-1,GETDATE()) AS FLOAT)) AS DATETIME)


DELETE FROM dbo.JobAudit
WHERE	DateRowCreated < @MinDateToKeep
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Collect SQL Server Jobs]    Script Date: 02/19/2011 08:14:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Collect SQL Server Jobs', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE NetQuoteTechnologyOperations
-- INITIALIZE PARAMETERS
SET NOCOUNT ON
-- MOVE RECORDS TO AUDIT TABLE
INSERT INTO DBO.JobAudit
SELECT	ServerName,
		JobName,
		[Enabled],
		DateCreated,
		DateModified,
		GETDATE()
FROM	dbo.JobsReport (NOLOCK)

-- TRUNCATE JobsReport before loading
TRUNCATE TABLE dbo.JobsReport

DECLARE	@RowId INT,
		@ServerName VARCHAR(30)
		
DECLARE	@Table TABLE (
	Rowid INT IDENTITY(1,1),
	ServerName VARCHAR(30)
	)
INSERT INTO @Table
SELECT	ServerName
FROM	dbo.ServerList
WHERE	Active = 1
AND	ServerName <> ''BPDBXX0011''
--AND	ServerName <> ''[SPDBXX0013\BO01]''

--select * from @Table

-- CREATE TABLE VARIABLE TO HOLD RECORDS TEMPORARY
IF EXISTS (	
		SELECT	NAME
		FROM	Tempdb.sys.Tables
		WHERE	Name = ''JobReport'' )
	BEGIN
		DROP TABLE Tempdb.dbo.JobReport
	END

CREATE TABLE Tempdb.dbo.JobReport (
	ServerName VARCHAR (30),
	JobName VARCHAR(255),
	[Enabled] BIT,
	LastRunOutCome TINYINT,
	LastRunDate INT,
	LastRunTime INT,
	LastRunDurationInSec INT,
	NextRunDate INT,
	NextRunTime INT,
	DateCreated DATETIME,
	DateModified DATETIME
	)


SELECT	@RowId = MAX(Rowid)
FROM	@Table

WHILE @RowId > 0
	BEGIN
		SELECT	@ServerName = ServerName
		FROM	@Table
		WHERE	RowId = @RowId

		DECLARE	@SelectStmt VARCHAR(1024),
				@SelectFrom	VARCHAR(1024),
				@Query VARCHAR(2048)
				
		SET	@SelectStmt = 
		''INSERT INTO Tempdb.dbo.JobReport (
				JobName,
				[Enabled],
				LastRunOutCome,
				LastRunDate,
				LastRunTime,
				LastRunDurationInSec,
				NextRunDate,
				NextRunTime,
				DateCreated,
				DateModified )
		SELECT   J.Name AS ServerName
				,J.Enabled AS Enabled
				,S1.Last_Run_OutCome AS LastRunOutCome
				,S1.Last_Run_Date AS LastRunDate
				,S1.Last_Run_Time AS LastRunTime
				,S1.Last_Run_Duration AS LastRunDuration
				,S2.Next_Run_Date AS NextRunDate
				,S2.Next_Run_Time AS NextRunTime
				,J.Date_Created AS DateCreated
				,J.Date_Modified AS DateModified

		FROM ''

		SET @SelectFrom = @ServerName +''.MSDB.DBO.SYSJOBS AS J (NOLOCK) INNER JOIN '' +
						  @ServerName +''.MSDB.DBO.SYSJOBSERVERS AS S1 (NOLOCK)ON J.Job_Id = S1.Job_Id INNER JOIN '' +
						  @ServerName +''.MSDB.DBO.SYSJOBSCHEDULES AS S2 (NOLOCK)
										ON S2.Job_Id = J.Job_Id
										ORDER BY J.Name''
		SET	@Query = @SelectStmt + @SelectFrom
		--SELECT	@Query 
		PRINT	@Query
		EXEC (@Query )
		UPDATE Tempdb.dbo.JobReport
		SET	ServerName = @ServerName
		INSERT INTO dbo.JobsReport
		SELECT	* FROM Tempdb.dbo.JobReport
		TRUNCATE TABLE Tempdb.dbo.JobReport
		
			
		SELECT	@RowId = @RowId - 1
	END
	
	--select * from Tempdb.dbo.JobReport
	DROP TABLE Tempdb.dbo.JobReport
	

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Collect SQL Server Jobs', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20090410, 
		@active_end_date=99991231, 
		@active_start_time=700, 
		@active_end_time=235959, 
		@schedule_uid=N'1be6b66d-e310-453d-af8a-fd10b836b1b9'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


