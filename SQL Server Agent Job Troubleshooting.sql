/*
----------------------------------------------------------------------------
-- Object Name: MSSQLTips_SGolovko_Tip44_CheckJobs_script.sql
-- Business Process: Database Administration
-- Purpose: To check SQL Server Agent Jobs
-- Database: msdb
-- Dependent Objects: system tables and procedures only
-- Created On: 2017-10-05 
-- Created: By Svetlana Golovko for MSSQLTips.com 
-- https://www.mssqltips.com/sqlservertip/4870/sql-server-agent-jobs-monitoring-script/
----------------------------------------------------------------------------
*/

USE msdb
GO
SET NOCOUNT ON;

DECLARE @Min_hist_length INT,       
        @DBA_Group      SYSNAME,
        @DBA_Op_Email   NVARCHAR(100),
        @DBA_Operator   SYSNAME
 
SELECT @Min_hist_length = 10,                     -- minimum history per job
       @DBA_Group       = 'DOMAIN\DBA_Group',     -- DBA group name in Active Directory
       @DBA_Op_Email    = 'dba_group@domain.com', -- DBA group distribution email (for an operator)
       @DBA_Operator    = 'TestOp_valid'          -- DBA Operator name

-- get members of the DBA group
DECLARE @TestTable TABLE ([account name]      NVARCHAR(256), 
                          [type]              NVARCHAR(30), 
                          [privilege]         NVARCHAR(30), 
                          [mapped login name] NVARCHAR(256), 
                          [permission path]   NVARCHAR(256)
                  );

INSERT INTO @TestTable
EXEC  sys.xp_logininfo @DBA_Group , 'members';

-- get issues sorted by severity
WITH jobs_problems
AS (
SELECT  j.[name] AS job_name, 
      j.[enabled] job_enabled, 
      CASE WHEN s.[enabled] = 0 
            THEN s.[name] 
            ELSE NULL END AS schedule_name, 
      CASE WHEN s.[enabled] = 0 
            THEN s.[enabled] 
            ELSE NULL END AS schedule_enabled, 
      o.[name] AS operator_name,
      j.owner_sid,
      ISNULL(jh.hist_length,0) AS hist_length,
      CASE WHEN j.[enabled] = 0 
            THEN 'disabled job' 
            ELSE NULL END AS Problem1,
      CASE WHEN js.last_run_outcome = 0 OR (st.last_run_outcome = 0  AND jh.job_id IS NOT NULL)
            THEN 'failed job or job''s step' 
            ELSE NULL END AS Problem2,
      CASE WHEN j.[description] IS NULL 
            THEN 'no description' 
            ELSE NULL END AS Problem3,
      CASE WHEN sh.job_id IS NULL 
            THEN 'no schedule' 
            ELSE NULL END AS Problem4,
      CASE WHEN s.[enabled] = 0 
            THEN 'job with disabled schedule' 
            ELSE NULL END AS Problem5,
      CASE WHEN j.category_id = 0 
            THEN 'unassigned category = "[Uncategorized (Local)]"' 
            ELSE NULL END AS Problem6,
      CASE WHEN IS_SRVROLEMEMBER('sysadmin', SUSER_SNAME(j.owner_sid)) = 1 
               OR (SUSER_SNAME(j.owner_sid) IN (SELECT [mapped login name] FROM @TestTable) AND IS_SRVROLEMEMBER('sysadmin', @DBA_Group) = 1)
            THEN 'owned by sysadmin'  
            ELSE NULL END AS Problem7,
      CASE WHEN  SUSER_SNAME (j.owner_sid) IS NULL OR l.hasaccess = 0 OR l.denylogin = 1 
            THEN 'no owner or owner login is disabled'  
            ELSE NULL END AS Problem8,
      CASE WHEN j.notify_level_email < 1 
            THEN 'no notification' 
            ELSE NULL END AS Problem9,
      CASE WHEN o.[id] IS NULL 
            THEN 'no operator' 
            WHEN o.[name] != @DBA_Operator OR o.email_address != @DBA_Op_Email  OR (o.[name] IS NOT NULL AND  o.email_address IS NULL )
            THEN 'issue with operator'
            ELSE NULL END AS Problem10,
      CASE WHEN j.[enabled] = 1 AND ISNULL(jh.hist_length,0) < @Min_hist_length
            THEN 'not enough history' 
            ELSE NULL END AS Problem11,
      CASE WHEN sc.job_id IS NOT NULL  
            THEN 'potential job step issue' 
            ELSE NULL END AS Problem12
FROM dbo.sysjobs j  JOIN 
      dbo.sysjobsteps st ON j.job_id = st.job_id LEFT JOIN 
      dbo.sysjobschedules sh ON j.job_id = sh.job_id LEFT JOIN 
      dbo.sysschedules s ON sh.schedule_id = s.schedule_id AND s.[enabled] = 0 LEFT JOIN 
      dbo.sysoperators o ON j.notify_email_operator_id = o.[id] LEFT JOIN 
      master.sys.syslogins l ON j.owner_sid = l.[sid] LEFT JOIN 
      dbo.sysjobservers js ON j.job_id = js.job_id LEFT JOIN
      (SELECT COUNT(*) hist_length, job_id  FROM sysjobhistory 
         GROUP BY job_id) jh ON j.job_id = jh.job_id LEFT JOIN
      (SELECT j.job_id, COUNT(s.step_id) countsteps FROM dbo.sysjobs j LEFT JOIN 
               dbo.sysjobsteps s ON s.job_id=j.job_id 
            WHERE s.on_success_action = 1 
            GROUP BY j.job_id,  s.on_success_action
            HAVING  COUNT(s.step_id) > 1
            UNION
            SELECT j.job_id, NULL FROM dbo.sysjobs j 
            WHERE  j.start_step_id > 1
            UNION
            SELECT j.job_id, COUNT(s.step_id) countsteps FROM dbo.sysjobs j LEFT JOIN 
               dbo.sysjobsteps s ON s.job_id=j.job_id 
            AND s.on_success_action = 1 
            GROUP BY j.job_id,  s.on_success_action
            HAVING  COUNT(s.step_id) < 1) sc ON j.job_id = sc.job_id
WHERE 
      (sh.job_id IS NULL -- job with no schedule
      OR j.[description] IS NULL -- job without description
      OR s.[enabled] = 0 -- job with disabled schedule
      OR j.[enabled] = 0 -- disabled job
      OR js.last_run_outcome = 0 OR (st.last_run_outcome = 0  AND jh.job_id IS NOT NULL) -- failed job or job step
      OR j.category_id = 0 -- unassigned category = "[Uncategorized (Local)]"
      OR (IS_SRVROLEMEMBER('sysadmin', SUSER_SNAME(j.owner_sid)) = 1
      OR SUSER_SNAME (j.owner_sid) IS NULL
      OR (SUSER_SNAME(j.owner_sid) IN (SELECT [mapped login name] FROM @TestTable) 
            AND IS_SRVROLEMEMBER('sysadmin', @DBA_Group) = 1)
         ) -- job owned by sysadmin 
      OR o.[id] IS NULL   -- no operator
      OR (o.[name] != @DBA_Operator OR o.email_address != @DBA_Op_Email 
            OR (o.[name] IS NOT NULL AND  o.email_address IS NULL ) ) -- operator not valid
      OR SUSER_SNAME (j.owner_sid) IS NULL -- no job owner (deleted)
      OR j.notify_level_email < 1 -- no notification
      OR (j.[enabled] = 1 AND ISNULL(jh.hist_length,0)  < @Min_hist_length ) -- not enough history
      OR sc.job_id IS NOT NULL -- potential job step issue
))
SELECT  job_name, 
      job_enabled, 
      MIN(schedule_name) AS disabled_schedule_name,
      MIN(operator_name) AS operator_name,
      SUSER_SNAME(owner_sid)   AS owner_name, 
      hist_length,
      /*-- SQL Server 2012 and higher
      CONCAT(MIN(Problem1) + '; ', 
            MIN(Problem2) + '; ',  
            MIN(Problem3) + '; ' , 
            MIN(Problem4) + '; ' , 
            MIN(Problem5) + '; ', 
            MIN(Problem6) + '; ', 
            MIN(Problem7) + '; ', 
            MIN(Problem8) + '; ', 
            MIN(Problem9) + '; ', 
            MIN(Problem10) + '; ', 
            MIN(Problem11) + '; ', 
            MIN(Problem12) + '; ') AS issues_report,*/
       ISNULL((MIN(Problem1) + '; '), '') +
            ISNULL((MIN(Problem2) + '; '), '') + 
            ISNULL((MIN(Problem3) + '; '), '')  + 
            ISNULL((MIN(Problem4) + '; '), '')  +
            ISNULL((MIN(Problem5) + '; '), '') +
            ISNULL((MIN(Problem6) + '; '), '') +
            ISNULL((MIN(Problem7) + '; '), '') +
            ISNULL((MIN(Problem8) + '; '), '') +
            ISNULL((MIN(Problem9) + '; '), '') +
            ISNULL((MIN(Problem10) + '; '), '') + 
            ISNULL((MIN(Problem11) + '; '), '') +
            ISNULL((MIN(Problem12) + '; '), '') AS issues_report, -- SQL Server 2008 compatible
      (  CASE WHEN MIN(Problem1)  IS NULL THEN 0 ELSE 1 END + 
         CASE WHEN MIN(Problem2)  IS NULL THEN 0 ELSE 1 END  +  
         CASE WHEN MIN(Problem3)  IS NULL THEN 0 ELSE 1 END  +  
         CASE WHEN MIN(Problem4)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem5)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem6)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem7)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem8)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem9)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem10) IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem11) IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem12) IS NULL THEN 0 ELSE 1 END  ) AS severity
FROM jobs_problems
GROUP BY job_name, job_enabled, owner_sid, hist_length
ORDER BY 
(        CASE WHEN MIN(Problem1)  IS NULL THEN 0 ELSE 1 END + 
         CASE WHEN MIN(Problem2)  IS NULL THEN 0 ELSE 1 END  +  
         CASE WHEN MIN(Problem3)  IS NULL THEN 0 ELSE 1 END  +  
         CASE WHEN MIN(Problem4)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem5)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem6)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem7)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem8)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem9)  IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem10) IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem11) IS NULL THEN 0 ELSE 1 END  + 
         CASE WHEN MIN(Problem12) IS NULL THEN 0 ELSE 1 END  )
         DESC
