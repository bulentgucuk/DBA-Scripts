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

DECLARE @profile_name sysname,
        @account_name sysname,
        @SMTP_servername sysname,
        @email_address NVARCHAR(128),
        @display_name NVARCHAR(128),
        @replyto_address NVARCHAR(128);

-- Profile name. Replace with the name for your profile.  This will typically
-- be the name of the instance <machine\instance> or <default instance>
--SET @profile_name = '!! CHANGE THIS VALUE !!';
    SET @profile_name = @@SERVERNAME;

-- Account information. Replace with the information for your account.

    SET @account_name = @profile_name;
    SET @SMTP_servername = 'SMTP.NQ.CORP';
    SET @display_name = @account_name;

IF EXISTS (SELECT * FROM [DBAdmin].[dbo].[DBAdmin_InstallParms] WHERE ParmName = 'IsProduction' AND ParmValue = '1')
BEGIN
    SET @email_address = 'QA_DBA@bankrateinsurance.com';
    SET @replyto_address = 'QA_DBA@bankrateinsurance.com';
END
ELSE
BEGIN
    SET @email_address = 'QA_DBA@bankrateinsurance.com';
    SET @replyto_address = 'QA_DBA@bankrateinsurance.com';
END

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
    @replyto_address = @replyto_address;

IF @rv<>0
BEGIN
    RAISERROR('Failed to create the specified Database Mail account (%s).', 16, 1, @account_name) ;
    GOTO done;
END

-- Add the profile
EXECUTE @rv=msdb.dbo.sysmail_add_profile_sp
    @profile_name = @profile_name ;

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

COMMIT TRANSACTION;

done:

GO

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
