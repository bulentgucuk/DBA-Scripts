USE msdb
GO
-- Declare variables for necessary email content
DECLARE @ServerName VARCHAR(128),
		@ComputerNamePhysicalNetBIOS VARCHAR(128),
		@Datetime DATETIME,
		@EmailRecipients VARCHAR(512),
		@EmailSubject VARCHAR(128),
		@MessageBody VARCHAR(512)

-- Set variables to proper values
SELECT	@ComputerNamePhysicalNetBIOS = CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(128)),
		@ServerName = CAST(SERVERPROPERTY('ServerName') AS VARCHAR(128)),
		@Datetime = GETDATE(),
		@EmailRecipients = 'bgucuk@servicesource.com', -- if more than one email address use ; between email addresses
		@EmailSubject = 'SQL Server Services Have Been Started!!!'

SELECT	@MessageBody = 'SQL Server services have been started on a SQL Server Instance named ' + @ServerName + CHAR(13) +
		'running on windows server ' + @ComputerNamePhysicalNetBIOS + '.' + CHAR(13) + CHAR(13) +
		'Investigate the service restart if it has not been communicated.'

EXEC	sp_send_dbmail
	@recipients = @EmailRecipients,
	@subject = @EmailSubject,
	@body = @MessageBody,
	@body_format = 'TEXT'
