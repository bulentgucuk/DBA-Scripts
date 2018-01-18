--https://www.mssqltips.com/sqlservertip/5258/sql-server-database-mail-health-check-for-all-sql-servers/
SET NOCOUNT ON;

DECLARE 
      @SQLAgentEnabled INT = 0,
      @SQLAgentStarted INT = 0,
      @DBMailEnabled INT = 0, 
      @MailProfileEnabled INT = 0, 
      @MailAccountEnabled INT = 0,
      @SQLAgentMailEnabled INT = 0, 
      @SQLAgentMailProfileEnabled SYSNAME,  
      @failed_emails_last24hours INT, 
      @failed_email_test INT,
      @failed_email_error INT

-- SQL Server Agent enabled
SELECT   @SQLAgentEnabled = CAST(value_in_use AS INT) 
FROM sys.configurations 
WHERE [name] ='Agent XPs';

-- SQL Server Agent status
IF (SELECT CAST(SERVERPROPERTY('Edition') AS VARCHAR(30))) NOT LIKE 'Express Edition%'
BEGIN
   SELECT @SQLAgentStarted = CASE WHEN status_desc = 'Running' THEN 1 ELSE 0 END
   FROM    sys.dm_server_services
   WHERE servicename LIKE 'SQL Server Agent%'
END;

-- SQL Database Mail is enabled
SELECT @DBMailEnabled = CAST(value_in_use AS INT) 
FROM sys.configurations 
WHERE [name] ='Database Mail XPs';

-- @SQLAgentMailEnabled
SELECT @MailProfileEnabled = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END 
FROM msdb.dbo.sysmail_profile;

-- @MailAccountEnabled
SELECT @MailAccountEnabled  = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END 
FROM msdb.dbo.sysmail_account;

-- SQL Server Agent is enabled to use Database Mail
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                       N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                       N'UseDatabaseMail',
               @SQLAgentMailEnabled OUTPUT;

-- SQL Server Agent is enabled to use Database Mail and Mail Profile is assigned
EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
                                       N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                       N'DatabaseMailProfile',
               @SQLAgentMailProfileEnabled OUTPUT;

-- Testing email
DECLARE @profile SYSNAME, @retry_sec INT, @retry VARCHAR(10)

-- Find Mail profile name
SELECT TOP 1 @profile = [name] 
FROM msdb.dbo.sysmail_profile 
ORDER BY  profile_id ;

-- get email retry interval configuration value
SELECT @retry_sec = paramvalue,
   @retry = RIGHT('0' + CAST(paramvalue / 3600 AS VARCHAR),2) + ':' +
         RIGHT('0' + CAST((paramvalue / 60) % 60 AS VARCHAR),2) + ':' +
         RIGHT('0' + CAST((paramvalue % 60) + 5 AS VARCHAR),2)
FROM msdb.dbo.sysmail_configuration
WHERE paramname = 'AccountRetryDelay';

-- Check if there are failed emails for the last 24 hours
SELECT @failed_emails_last24hours = COUNT(*) 
FROM msdb.dbo.sysmail_event_log
WHERE event_type='error' AND log_date > DATEADD(dd, -1, GETDATE());

-- Send Test email
BEGIN TRY
   EXEC msdb.dbo.sp_send_dbmail
      @profile_name = @profile, 
             @recipients = $(DBA_Email),
             @subject = 'Daily Test DB Mail',
             @body = @@SERVERNAME
END TRY

BEGIN CATCH
   SELECT @failed_email_error = ERROR_NUMBER() 
END CATCH;

-- wait for retry interval (from DB mail configuration) plus 5 more seconds
WAITFOR DELAY @retry
-- WAITFOR DELAY '00:00:05' -- or set it to fixe 5 seconds if you don't want to wait

-- Check if the test email failed
SELECT @failed_email_test = CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
FROM msdb.dbo.sysmail_event_log
WHERE event_type='error' AND
   log_date > DATEADD(ss, @retry_sec + 5, GETDATE());

-- Final report
SELECT @@SERVERNAME AS Server_Name, 
   CAST(GETDATE() AS SMALLDATETIME) AS Run_Date,
   FinalResult = @SQLAgentEnabled * @SQLAgentStarted * @DBMailEnabled * @MailProfileEnabled * @MailAccountEnabled * @SQLAgentMailEnabled * 
         (CASE WHEN @SQLAgentMailProfileEnabled IS NOT NULL THEN 1 ELSE 0 END) * 
         (CASE WHEN ISNULL(@failed_email_error, 0) = 0 THEN 1 ELSE 0 END) *
         (CASE WHEN @failed_emails_last24hours = 0 THEN 1 ELSE 0 END),
   Notes =  CASE WHEN CAST(SERVERPROPERTY('Edition') AS VARCHAR(30)) LIKE 'Express Edition%' 
         THEN 'Express Edition, DB Mail not supported' ELSE 
         CASE WHEN @SQLAgentEnabled = 0 THEN 'SQL Agent disabled; ' 
            ELSE '' END +
         CASE WHEN @DBMailEnabled = 0 THEN 'DB Mail disabled; ' 
            ELSE '' END +
         CASE WHEN @MailProfileEnabled = 0 THEN 'Mail Profile disabled; ' 
            ELSE '' END + 
         CASE WHEN @MailAccountEnabled = 0 THEN 'Mail Account disabled; ' 
            ELSE '' END + 
         CASE WHEN @SQLAgentMailEnabled = 0 THEN 'SQL Agent Mail disabled; ' 
            ELSE '' END + 
         CASE WHEN @SQLAgentMailProfileEnabled IS NOT NULL THEN '' 
            ELSE 'SQL Agent Mail Profile disabled; ' END + 
         CASE WHEN @failed_emails_last24hours > 0 
            THEN 'failed email(s) during last 24 hours; ' ELSE '' END +
         CASE WHEN @failed_email_error > 0 THEN 'failed email test; ' ELSE '' END END;