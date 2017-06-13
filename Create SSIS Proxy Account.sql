-- Create a credential containing the domain account PowerDomain\PowerUser and its password
CREATE CREDENTIAL PowerUser WITH IDENTITY = N'Peak8ddc\SQLService', SECRET = N'$$waz00!*'
GO
USE [msdb]
GO
-- Create a new proxy called SSISProxy and assign the PowerUser credentail to it
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'SSISProxy',@credential_name=N'PowerUser',@enabled=1

-- Grant SSISProxy access to the "SSIS package execution" subsystem
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'SSISProxy', @subsystem_id=11

-- Grant the login testUser the permissions to use SSISProxy
EXEC msdb.dbo.sp_grant_login_to_proxy @login_name = N'PEAK8DDC\rphelps', @proxy_name=N'SSISProxy'
GO