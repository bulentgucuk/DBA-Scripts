-------------------------------------------------------------
--  Database Mail Simple Configuration Template.
--
--  This template creates a Database Mail profile, an SMTP account and 
--  associates the account to the profile.
--  The template does not grant access to the new profile for
--  any database principals.  Use msdb.dbo.sysmail_add_principalprofile
--  to grant access to the new profile for users who are not
--  members of sysadmin.
-------------------------------------------------------------
EXEC sp_configure 'show advanced options', 1
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sp_configure 'Database Mail XPs', 1
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sp_configure 'show advanced options', 0
GO
RECONFIGURE WITH OVERRIDE
GO

DECLARE @profile_name sysname,
        @account_name sysname,
        @SMTP_servername sysname,
        @email_address NVARCHAR(128),
        @display_name NVARCHAR(128),
        @replyto_address NVARCHAR(128),
		@port INT,
		@username NVARCHAR(128),
		@password NVARCHAR(128);

-- Profile name. Replace with the name for your profile.  This will typically
-- be the name of the instance <machine\instance> or <default instance>
--SET @profile_name = '!! CHANGE THIS VALUE !!';
    SET @profile_name = 'Mandrill';
	

-- Account information. Replace with the information for your account.

    SET @account_name = @profile_name;
    SET @SMTP_servername = 'smtp.mandrillapp.com';
    SET @display_name = @@SERVERNAME;
	SET @email_address = 'no-reply@ssbinfo.com';
    SET @replyto_address = 'no-reply@ssbinfo.com';
	SET @port = 587;
	SET @username = 'services@ssbinfo.com';
	SET @password = 'ln7E7Ue-1B_4LCRa3kEgmg';

-- Verify the specified account and profile do not already exist.
IF EXISTS (SELECT * FROM msdb.dbo.sysmail_profile WHERE name = @profile_name)
BEGIN
  RAISERROR('The specified Database Mail profile (%s) already exists.', 16, 1, @profile_name);
  GOTO done;
END;

IF EXISTS (SELECT * FROM msdb.dbo.sysmail_account WHERE name = @account_name )
BEGIN
 RAISERROR('The specified Database Mail account %s already exists.', 16, 1, @account_name) ;
 GOTO done;
END;

-- Start a transaction before adding the account and the profile
BEGIN TRANSACTION ;

DECLARE @rv INT;

-- Add the account
EXECUTE @rv=msdb.dbo.sysmail_add_account_sp
    @account_name = @account_name,
    @email_address = @email_address,
    @display_name = @display_name,
    @mailserver_name = @SMTP_servername,
    @replyto_address = @replyto_address,
	@port = @port,
	@username = @username,
	@password = @password

IF @rv<>0
BEGIN
    RAISERROR('Failed to create the specified Database Mail account (%s).', 16, 1, @account_name) ;
    GOTO done;
END

-- Add the profile
EXECUTE @rv=msdb.dbo.sysmail_add_profile_sp
    @profile_name = @profile_name,
	@description = 'Profile used for administrative mail.';

IF @rv<>0
BEGIN
    RAISERROR('Failed to create the specified Database Mail profile (%s).', 16, 1, @profile_name);
    ROLLBACK TRANSACTION;
    GOTO done;
END;

-- Associate the account with the profile.
EXECUTE @rv=msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = @profile_name,
    @account_name = @account_name,
	@sequence_number = 1 ;

IF @rv<>0
BEGIN
    RAISERROR('Failed to associate the speficied profile with the specified account (%s).', 16, 1, @account_name) ;
    ROLLBACK TRANSACTION;
    GOTO done;
END;

/***
-- Make the profile public default
EXECUTE @rv=msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = @profile_name,
    @principal_name = 'public',
    @is_default = 1 ;

IF @rv<>0
BEGIN
    RAISERROR('Failed to make profile public and default profile (%s).', 16, 1, @profile_name) ;
    ROLLBACK TRANSACTION;
    GOTO done;
END;
***/

COMMIT TRANSACTION;

done:

GO


