-- Enable Database Mail for this instance

EXECUTE sp_configure 'show advanced', 1;

RECONFIGURE;

EXECUTE sp_configure 'Database Mail XPs',1;

RECONFIGURE;

GO

 

-- Create a Database Mail account

EXECUTE msdb.dbo.sysmail_add_account_sp

    @account_name = 'Primary Account',

    @description = 'Account used by all mail profiles.',

    @email_address = 'myaddress@mydomain.com',

    @replyto_address = 'myaddress@mydomain.com',

    @display_name = 'Database Mail',

    @mailserver_name = 'mail.mydomain.com';

 

-- Create a Database Mail profile

EXECUTE msdb.dbo.sysmail_add_profile_sp

    @profile_name = 'Default Public Profile',

    @description = 'Default public profile for all users';

 

-- Add the account to the profile

EXECUTE msdb.dbo.sysmail_add_profileaccount_sp

    @profile_name = 'Default Public Profile',

    @account_name = ' Primary Account',

    @sequence_number = 1;

 

-- Grant access to the profile to all msdb database users

EXECUTE msdb.dbo.sysmail_add_principalprofile_sp

    @profile_name = 'Default Public Profile',

    @principal_name = 'public',

    @is_default = 1;

GO

 

--send a test email

EXECUTE msdb.dbo.sp_send_dbmail

    @subject = 'Test Database Mail Message',

    @recipients = 'testaddress@mydomain.com',

    @query = 'SELECT @@SERVERNAME';

GO
