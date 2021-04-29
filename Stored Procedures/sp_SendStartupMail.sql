/* sp_SendStartupMail - get alerted when your SQL Server starts up.

Documentation: https://www.brentozar.com/go/startupmail

To set this up, you need to:

1. Enable startup stored procs

2. Configure database mail: at least one profile and one operator

3. If you have multiple profiles and/or operators, configure the table that
  sp_SendStartupMail uses to pick which profile & operator to use

4. Create sp_SendStartupMail and mark it as a startup stored procedure 

And the below script will help. Let's get started.
*/
USE master;
GO


/* 1. Enable startup stored procs if they're not already enabled: */
IF 0 = (SELECT value_in_use FROM sys.configurations WHERE name = 'scan for startup procs')
	AND 0 = (SELECT value FROM sys.configurations WHERE name = 'scan for startup procs')
	BEGIN

	PRINT '/* WARNING! Startup stored procs not enabled. Run this to enable: */';
	IF 0 = (SELECT value_in_use FROM sys.configurations WHERE name = 'show advanced options')
		BEGIN
		PRINT 'EXEC sp_configure ''show advanced options'', 1;';
		PRINT 'RECONFIGURE;';
		END

	PRINT 'EXEC sp_configure ''scan for startup procs'', 1;';
	PRINT 'RECONFIGURE;';
	PRINT '/* And then restart the SQL Server service. (Or it will take effect automatically on the next restart.) */';
	END
GO


/* 2. Configure database mail: at least one profile and one operator */
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysmail_profile)
	BEGIN
	PRINT 'Database mail is not configured. Configure it: https://www.brentozar.com/blitz/database-mail-configuration/';
	PRINT 'Then create and enable an operator: https://www.brentozar.com/blitz/configure-sql-server-operators/';
	END
ELSE IF NOT EXISTS (SELECT COUNT(*) FROM msdb.dbo.sysoperators WHERE enabled = 1)
	BEGIN
	PRINT 'No operators are enabled. Create and enable one: https://www.brentozar.com/blitz/configure-sql-server-operators/'
	END
ELSE
	PRINT 'No work to do here. Keep going.';
GO



/* Create a table to hold the mail config: */
IF NOT EXISTS(SELECT * FROM sys.all_objects WHERE name = 'sp_SendStartupEmail_Config')
	BEGIN
	CREATE TABLE dbo.sp_SendStartupEmail_Config
		(DatabaseMailProfileName SYSNAME, Recipients VARCHAR(MAX));
	END


/* 3. If you have multiple profiles and/or operators, configure the table that
  sp_SendStartupMail uses to pick which profile & operator to use. */
SELECT 'Profiles' AS table_name, name
	FROM msdb.dbo.sysmail_profile;
SELECT 'Recipients' AS table_name, email_address
	FROM msdb.dbo.sysoperators;
GO


/* Armed with the above list of profiles & recipients, pick the one you want to use: */
INSERT INTO dbo.sp_SendStartupEmail_Config (DatabaseMailProfileName, Recipients)
	VALUES ('MyProfileNameGoesHere', 'EmailAddressGoesHere');
GO




/* 4. Create sp_SendStartupMail and mark it as a startup stored procedure  */
IF OBJECT_ID('dbo.sp_SendStartupEmail') IS NULL
  EXEC ('CREATE PROCEDURE dbo.sp_SendStartupEmail AS RETURN 0;');
GO

ALTER PROC dbo.sp_SendStartupEmail AS
BEGIN
/* More info: https://www.BrentOzar.com/go/startupmail
Contributors from the live stream: JediMindGorilla, GSerdjinn, WetSeal, RenegadeLarsen
*/
DECLARE @DatabaseMailProfileName SYSNAME = NULL, 
	@Recipients VARCHAR(MAX) = NULL,
	@StringToExecute NVARCHAR(4000);


/* If the config table exists, get recipients & valid email profile */
IF EXISTS (SELECT * FROM sys.all_objects WHERE name = 'sp_SendStartupEmail_Config')
	BEGIN
	SET @StringToExecute = N'SELECT TOP 1 @DatabaseMailProfileName_Table = DatabaseMailProfileName, @Recipients_Table = Recipients 
		FROM dbo.sp_SendStartupEmail_Config mc
		INNER JOIN msdb.dbo.sysmail_profile p ON mc.DatabaseMailProfileName = p.name;'
	EXEC sp_executesql @StringToExecute, N'@DatabaseMailProfileName_Table SYSNAME OUTPUT, @Recipients_Table VARCHAR(MAX) OUTPUT',
		@DatabaseMailProfileName_Table = @DatabaseMailProfileName OUTPUT, @Recipients_Table = @Recipients OUTPUT;
	END

IF @DatabaseMailProfileName IS NULL AND 1 = (SELECT COUNT(*) FROM msdb.dbo.sysmail_profile)
	SELECT TOP 1 @DatabaseMailProfileName = name
	FROM msdb.dbo.sysmail_profile;

/* If they didn't specify a recipient, use the last operator that got an email */
IF @Recipients IS NULL
	SELECT TOP (1) @Recipients = email_address 
	FROM msdb.dbo.sysoperators o 
	WHERE o.[enabled] = 1 ORDER BY o.last_email_date DESC;

IF @DatabaseMailProfileName IS NULL OR @Recipients IS NULL 
	RETURN;

DECLARE @email_subject NVARCHAR(255) = N'SQL Server Started: ' + COALESCE(@@SERVERNAME, N'Unknown Server Name'),
	@email_body NVARCHAR(MAX);

IF NOT EXISTS (SELECT * FROM sys.databases WHERE state NOT IN (0, 1, 7, 10))
	SET @email_body = N'All databases okay.';
ELSE
	BEGIN
	SELECT @email_body = CONCAT(@email_body, COALESCE(name, N' Database ID ' + CAST(database_id AS NVARCHAR(10))), N' state: ' + state_desc + NCHAR(13) + NCHAR(10)) 
		FROM sys.databases
		WHERE state NOT IN (0, 1, 7, 10);

	IF @email_body IS NULL
		SET @email_body = N'We couldn''t get a list of databases with problems. Better check on this server manually.';
	END


EXEC msdb.dbo.sp_send_dbmail  
    @profile_name = @DatabaseMailProfileName,  
    @recipients = @Recipients,  
    @body = @email_body,  
    @subject = @email_subject ;

END
GO

/* Mark this stored procedure as a startup stored procedure: */
EXEC sp_procoption @ProcName = N'sp_SendStartupEmail',
	@OptionName = 'startup',
	@OptionValue = 'on';
GO




/* To test it, just run it and verify that it runs without error, and you get an email: */
EXEC sp_SendStartupEmail;
GO



/*
MIT License

Copyright (c) 2020 Brent Ozar Unlimited

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/