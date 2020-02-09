/**********************************************************************
This is the text from the stored procedure sp_get_composite_job_info
to be used to capture the job related data in msdb
**********************************************************************/
--CREATE PROCEDURE sp_get_composite_job_info
DECLARE
  @job_id             UNIQUEIDENTIFIER = NULL,
  @job_type           VARCHAR(12)      = NULL,  -- LOCAL or MULTI-SERVER
  @owner_login_name   sysname          = NULL,
  @subsystem          NVARCHAR(40)     = NULL,
  @category_id        INT              = NULL,
  @enabled            TINYINT          = NULL,
  @execution_status   INT              = NULL,  -- 0 = Not idle or suspended, 1 = Executing, 2 = Waiting For Thread, 3 = Between Retries, 4 = Idle, 5 = Suspended, [6 = WaitingForStepToFinish], 7 = PerformingCompletionActions
  @date_comparator    CHAR(1)          = NULL,  -- >, < or =
  @date_created       DATETIME         = NULL,
  @date_last_modified DATETIME         = NULL,
  @description        NVARCHAR(512)    = NULL,  -- We do a LIKE on this so it can include wildcards
  @schedule_id        INT              = NULL   -- if supplied only return the jobs that use this schedule
--AS
--BEGIN
  DECLARE @can_see_all_running_jobs INT
  DECLARE @job_owner   sysname

  SET NOCOUNT ON

  -- By 'composite' we mean a combination of sysjobs and xp_sqlagent_enum_jobs data.
  -- This proc should only ever be called by sp_help_job, so we don't verify the
  -- parameters (sp_help_job has already done this).

  -- Step 1: Create intermediate work tables
  DECLARE @job_execution_state TABLE (job_id                  UNIQUEIDENTIFIER NOT NULL,
                                     date_started            INT              NOT NULL,
                                     time_started            INT              NOT NULL,
                                     execution_job_status    INT              NOT NULL,
                                     execution_step_id       INT              NULL,
                                     execution_step_name     sysname          COLLATE database_default NULL,
                                     execution_retry_attempt INT              NOT NULL,
                                     next_run_date           INT              NOT NULL,
                                     next_run_time           INT              NOT NULL,
                                     next_run_schedule_id    INT              NOT NULL)
  DECLARE @filtered_jobs TABLE (job_id                   UNIQUEIDENTIFIER NOT NULL,
                               date_created             DATETIME         NOT NULL,
                               date_last_modified       DATETIME         NOT NULL,
                               current_execution_status INT              NULL,
                               current_execution_step   NVARCHAR(MAX)          COLLATE database_default NULL,
                               current_retry_attempt    INT              NULL,
                               last_run_date            INT              NOT NULL,
                               last_run_time            INT              NOT NULL,
                               last_run_outcome         INT              NOT NULL,
                               next_run_date            INT              NULL,
                               next_run_time            INT              NULL,
                               next_run_schedule_id     INT              NULL,
                               type                     INT              NOT NULL)
  DECLARE @xp_results TABLE (job_id                UNIQUEIDENTIFIER NOT NULL,
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

  -- Step 2: Capture job execution information (for local jobs only since that's all SQLServerAgent caches)
  SELECT @can_see_all_running_jobs = ISNULL(IS_SRVROLEMEMBER(N'sysadmin'), 0)
  IF (@can_see_all_running_jobs = 0)
  BEGIN
    SELECT @can_see_all_running_jobs = ISNULL(IS_MEMBER(N'SQLAgentReaderRole'), 0)
  END
  SELECT @job_owner = SUSER_SNAME()

  IF ((@@microsoftversion / 0x01000000) >= 8) -- SQL Server 8.0 or greater
    INSERT INTO @xp_results
    EXECUTE master.dbo.xp_sqlagent_enum_jobs @can_see_all_running_jobs, @job_owner, @job_id
  ELSE
    INSERT INTO @xp_results
    EXECUTE master.dbo.xp_sqlagent_enum_jobs @can_see_all_running_jobs, @job_owner

  INSERT INTO @job_execution_state
  SELECT xpr.job_id,
         xpr.last_run_date,
         xpr.last_run_time,
         xpr.job_state,
         sjs.step_id,
         sjs.step_name,
         xpr.current_retry_attempt,
         xpr.next_run_date,
         xpr.next_run_time,
         xpr.next_run_schedule_id
  FROM @xp_results                          xpr
       LEFT OUTER JOIN msdb.dbo.sysjobsteps sjs ON ((xpr.job_id = sjs.job_id) AND (xpr.current_step = sjs.step_id)),
       msdb.dbo.sysjobs_view                sjv
  WHERE (sjv.job_id = xpr.job_id)

  -- Step 3: Filter on everything but dates and job_type
  IF ((@subsystem        IS NULL) AND
      (@owner_login_name IS NULL) AND
      (@enabled          IS NULL) AND
      (@category_id      IS NULL) AND
      (@execution_status IS NULL) AND
      (@description      IS NULL) AND
      (@job_id           IS NULL))
  BEGIN
    -- Optimize for the frequently used case...
    INSERT INTO @filtered_jobs
    SELECT sjv.job_id,
           sjv.date_created,
           sjv.date_modified,
           ISNULL(jes.execution_job_status, 4), -- Will be NULL if the job is non-local or is not in @job_execution_state (NOTE: 4 = STATE_IDLE)
           CASE ISNULL(jes.execution_step_id, 0)
             WHEN 0 THEN NULL                   -- Will be NULL if the job is non-local or is not in @job_execution_state
             ELSE CONVERT(NVARCHAR, jes.execution_step_id) + N' (' + jes.execution_step_name + N')'
           END,
           jes.execution_retry_attempt,         -- Will be NULL if the job is non-local or is not in @job_execution_state
           0,  -- last_run_date placeholder    (we'll fix it up in step 3.3)
           0,  -- last_run_time placeholder    (we'll fix it up in step 3.3)
           5,  -- last_run_outcome placeholder (we'll fix it up in step 3.3 - NOTE: We use 5 just in case there are no jobservers for the job)
           jes.next_run_date,                   -- Will be NULL if the job is non-local or is not in @job_execution_state
           jes.next_run_time,                   -- Will be NULL if the job is non-local or is not in @job_execution_state
           jes.next_run_schedule_id,            -- Will be NULL if the job is non-local or is not in @job_execution_state
           0   -- type placeholder             (we'll fix it up in step 3.4)
    FROM msdb.dbo.sysjobs_view                sjv
         LEFT OUTER JOIN @job_execution_state jes ON (sjv.job_id = jes.job_id)
    WHERE ((@schedule_id IS NULL)
      OR   (EXISTS(SELECT * 
                 FROM sysjobschedules as js
                 WHERE (sjv.job_id = js.job_id)
                   AND (js.schedule_id = @schedule_id))))
  END
  ELSE
  BEGIN
    INSERT INTO @filtered_jobs
    SELECT DISTINCT
           sjv.job_id,
           sjv.date_created,
           sjv.date_modified,
           ISNULL(jes.execution_job_status, 4), -- Will be NULL if the job is non-local or is not in @job_execution_state (NOTE: 4 = STATE_IDLE)
           CASE ISNULL(jes.execution_step_id, 0)
             WHEN 0 THEN NULL                   -- Will be NULL if the job is non-local or is not in @job_execution_state
             ELSE CONVERT(NVARCHAR, jes.execution_step_id) + N' (' + jes.execution_step_name + N')'
           END,
           jes.execution_retry_attempt,         -- Will be NULL if the job is non-local or is not in @job_execution_state
           0,  -- last_run_date placeholder    (we'll fix it up in step 3.3)
           0,  -- last_run_time placeholder    (we'll fix it up in step 3.3)
           5,  -- last_run_outcome placeholder (we'll fix it up in step 3.3 - NOTE: We use 5 just in case there are no jobservers for the job)
           jes.next_run_date,                   -- Will be NULL if the job is non-local or is not in @job_execution_state
           jes.next_run_time,                   -- Will be NULL if the job is non-local or is not in @job_execution_state
           jes.next_run_schedule_id,            -- Will be NULL if the job is non-local or is not in @job_execution_state
           0   -- type placeholder             (we'll fix it up in step 3.4)
    FROM msdb.dbo.sysjobs_view                sjv
         LEFT OUTER JOIN @job_execution_state jes ON (sjv.job_id = jes.job_id)
         LEFT OUTER JOIN msdb.dbo.sysjobsteps sjs ON (sjv.job_id = sjs.job_id)
    WHERE ((@subsystem        IS NULL) OR (sjs.subsystem            = @subsystem))
      AND ((@owner_login_name IS NULL) 
          OR (sjv.owner_sid            = dbo.SQLAGENT_SUSER_SID(@owner_login_name)))--force case insensitive comparation for NT users
      AND ((@enabled          IS NULL) OR (sjv.enabled              = @enabled))
      AND ((@category_id      IS NULL) OR (sjv.category_id          = @category_id))
      AND ((@execution_status IS NULL) OR ((@execution_status > 0) AND (jes.execution_job_status = @execution_status))
                                       OR ((@execution_status = 0) AND (jes.execution_job_status <> 4) AND (jes.execution_job_status <> 5)))
      AND ((@description      IS NULL) OR (sjv.description       LIKE @description))
      AND ((@job_id           IS NULL) OR (sjv.job_id               = @job_id))
      AND ((@schedule_id IS NULL)
        OR (EXISTS(SELECT * 
                 FROM sysjobschedules as js
                 WHERE (sjv.job_id = js.job_id)
                   AND (js.schedule_id = @schedule_id))))
  END

  -- Step 3.1: Change the execution status of non-local jobs from 'Idle' to 'Unknown'
  UPDATE @filtered_jobs
  SET current_execution_status = NULL
  WHERE (current_execution_status = 4)
    AND (job_id IN (SELECT job_id
                    FROM msdb.dbo.sysjobservers
                    WHERE (server_id <> 0)))

  -- Step 3.2: Check that if the user asked to see idle jobs that we still have some.
  --           If we don't have any then the query should return no rows.
  IF (@execution_status = 4) AND
     (NOT EXISTS (SELECT *
                  FROM @filtered_jobs
                  WHERE (current_execution_status = 4)))
  BEGIN
    DELETE FROM @filtered_jobs
  END

  -- Step 3.3: Populate the last run date/time/outcome [this is a little tricky since for
  --           multi-server jobs there are multiple last run details in sysjobservers, so
  --           we simply choose the most recent].
  IF (EXISTS (SELECT *
              FROM msdb.dbo.systargetservers))
  BEGIN
    UPDATE @filtered_jobs
    SET last_run_date = sjs.last_run_date,
        last_run_time = sjs.last_run_time,
        last_run_outcome = sjs.last_run_outcome
    FROM @filtered_jobs         fj,
         msdb.dbo.sysjobservers sjs
    WHERE (CONVERT(FLOAT, sjs.last_run_date) * 1000000) + sjs.last_run_time =
           (SELECT MAX((CONVERT(FLOAT, last_run_date) * 1000000) + last_run_time)
            FROM msdb.dbo.sysjobservers
            WHERE (job_id = sjs.job_id))
      AND (fj.job_id = sjs.job_id)
  END
  ELSE
  BEGIN
    UPDATE @filtered_jobs
    SET last_run_date = sjs.last_run_date,
        last_run_time = sjs.last_run_time,
        last_run_outcome = sjs.last_run_outcome
    FROM @filtered_jobs         fj,
         msdb.dbo.sysjobservers sjs
    WHERE (fj.job_id = sjs.job_id)
  END

  -- Step 3.4 : Set the type of the job to local (1) or multi-server (2)
  --            NOTE: If the job has no jobservers then it wil have a type of 0 meaning
  --                  unknown.  This is marginally inconsistent with the behaviour of
  --                  defaulting the category of a new job to [Uncategorized (Local)], but
  --                  prevents incompletely defined jobs from erroneously showing up as valid
  --                  local jobs.
  UPDATE @filtered_jobs
  SET type = 1 -- LOCAL
  FROM @filtered_jobs         fj,
       msdb.dbo.sysjobservers sjs
  WHERE (fj.job_id = sjs.job_id)
    AND (server_id = 0)
  UPDATE @filtered_jobs
  SET type = 2 -- MULTI-SERVER
  FROM @filtered_jobs         fj,
       msdb.dbo.sysjobservers sjs
  WHERE (fj.job_id = sjs.job_id)
    AND (server_id <> 0)

  -- Step 4: Filter on job_type
  IF (@job_type IS NOT NULL)
  BEGIN
    IF (UPPER(@job_type collate SQL_Latin1_General_CP1_CS_AS) = 'LOCAL')
      DELETE FROM @filtered_jobs
      WHERE (type <> 1) -- IE. Delete all the non-local jobs
    IF (UPPER(@job_type collate SQL_Latin1_General_CP1_CS_AS) = 'MULTI-SERVER')
      DELETE FROM @filtered_jobs
      WHERE (type <> 2) -- IE. Delete all the non-multi-server jobs
  END

  -- Step 5: Filter on dates
  IF (@date_comparator IS NOT NULL)
  BEGIN
    IF (@date_created IS NOT NULL)
    BEGIN
      IF (@date_comparator = '=')
        DELETE FROM @filtered_jobs WHERE (date_created <> @date_created)
      IF (@date_comparator = '>')
        DELETE FROM @filtered_jobs WHERE (date_created <= @date_created)
      IF (@date_comparator = '<')
        DELETE FROM @filtered_jobs WHERE (date_created >= @date_created)
    END
    IF (@date_last_modified IS NOT NULL)
    BEGIN
      IF (@date_comparator = '=')
        DELETE FROM @filtered_jobs WHERE (date_last_modified <> @date_last_modified)
      IF (@date_comparator = '>')
        DELETE FROM @filtered_jobs WHERE (date_last_modified <= @date_last_modified)
      IF (@date_comparator = '<')
        DELETE FROM @filtered_jobs WHERE (date_last_modified >= @date_last_modified)
    END
  END

  -- Return the result set (NOTE: No filtering occurs here)
IF OBJECT_ID('tempdb..#Jobs') IS NOT NULL
	DROP TABLE #Jobs;
  SELECT sjv.job_id,
         originating_server, 
         sjv.name,
         sjv.enabled,
         sjv.description,
         sjv.start_step_id,
         category = ISNULL(sc.name, FORMATMESSAGE(14205)),
         owner = dbo.SQLAGENT_SUSER_SNAME(sjv.owner_sid),
         sjv.notify_level_eventlog,
         sjv.notify_level_email,
         sjv.notify_level_netsend,
         sjv.notify_level_page,
         notify_email_operator   = ISNULL(so1.name, FORMATMESSAGE(14205)),
         notify_netsend_operator = ISNULL(so2.name, FORMATMESSAGE(14205)),
         notify_page_operator    = ISNULL(so3.name, FORMATMESSAGE(14205)),
         sjv.delete_level,
         sjv.date_created,
         sjv.date_modified,
         sjv.version_number,
         fj.last_run_date,
         fj.last_run_time,
         fj.last_run_outcome,
         next_run_date = ISNULL(fj.next_run_date, 0),                                 -- This column will be NULL if the job is non-local
         next_run_time = ISNULL(fj.next_run_time, 0),                                 -- This column will be NULL if the job is non-local
         next_run_schedule_id = ISNULL(fj.next_run_schedule_id, 0),                   -- This column will be NULL if the job is non-local
         current_execution_status = ISNULL(fj.current_execution_status, 0),           -- This column will be NULL if the job is non-local
         current_execution_step = ISNULL(fj.current_execution_step, N'0 ' + FORMATMESSAGE(14205)), -- This column will be NULL if the job is non-local
         current_retry_attempt = ISNULL(fj.current_retry_attempt, 0),                 -- This column will be NULL if the job is non-local
         has_step = (SELECT COUNT(*)
                     FROM msdb.dbo.sysjobsteps sjst
                     WHERE (sjst.job_id = sjv.job_id)),
         has_schedule = (SELECT COUNT(*)
                         FROM msdb.dbo.sysjobschedules sjsch
                         WHERE (sjsch.job_id = sjv.job_id)),
         has_target = (SELECT COUNT(*)
                       FROM msdb.dbo.sysjobservers sjs
                       WHERE (sjs.job_id = sjv.job_id)),
         type = fj.type
INTO #Jobs
  FROM @filtered_jobs                         fj
       LEFT OUTER JOIN msdb.dbo.sysjobs_view  sjv ON (fj.job_id = sjv.job_id)
       LEFT OUTER JOIN msdb.dbo.sysoperators  so1 ON (sjv.notify_email_operator_id = so1.id)
       LEFT OUTER JOIN msdb.dbo.sysoperators  so2 ON (sjv.notify_netsend_operator_id = so2.id)
       LEFT OUTER JOIN msdb.dbo.sysoperators  so3 ON (sjv.notify_page_operator_id = so3.id)
       LEFT OUTER JOIN msdb.dbo.syscategories sc  ON (sjv.category_id = sc.category_id)
  ORDER BY sjv.job_id

--END
SELECT	name
	, enabled
	, category
	, owner
	, date_created
	, date_modified
	, next_run_date
	, next_run_time
	, description
FROM #Jobs
WHERE category = 'gators'
ORDER BY name
OPTION(RECOMPILE);
