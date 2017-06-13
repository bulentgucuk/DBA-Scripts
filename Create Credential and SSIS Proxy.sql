USE [master]
GO
-- Create Login If not exists
/****** Object:  Login [NQCORP\svc_rpt_ssis_proxy]    Script Date: 5/2/2014 1:57:11 PM ******/
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'NQCORP\svc_rpt_ssis_proxy')
CREATE LOGIN [NQCORP\svc_rpt_ssis_proxy] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO


-- Proxy setup Starts here
--Step #1 - Creating a credential to be used by proxy
USE MASTER
GO
--Drop the credential if it is already existing
IF EXISTS (SELECT 1 FROM sys.credentials WHERE name = N'RptSSISproxycredential')
BEGIN
DROP CREDENTIAL [RptSSISproxycredential]
END
GO
CREATE CREDENTIAL [RptSSISproxycredential]
WITH IDENTITY = N'NQCORP\svc_rpt_ssis_proxy',
SECRET = N'BRI-NQC0rp-SS1S!'
GO 


--Step #2 - Creating a proxy account
USE msdb
GO
--Drop the proxy if it is already existing
IF EXISTS (SELECT 1 FROM msdb.dbo.sysproxies WHERE name = N'RptSSISproxy')
BEGIN
EXEC dbo.sp_delete_proxy
@proxy_name = N'RptSSISproxy'
END
GO
--Create a proxy and use the same credential as created above
EXEC msdb.dbo.sp_add_proxy
@proxy_name = N'RptSSISproxy',
@credential_name=N'RptSSISproxycredential',
@enabled=1
GO
--To enable or disable you can use this command
EXEC msdb.dbo.sp_update_proxy
@proxy_name = N'RptSSISproxy',
@enabled = 1 --@enabled = 0
GO 

--Step #3 - Granting proxy account to SQL Server Agent Sub-systems
USE msdb
GO
--Grant created proxy to SQL Agent subsystem
--You can grant created proxy to as many as available subsystems
EXEC msdb.dbo.sp_grant_proxy_to_subsystem
@proxy_name=N'RptSSISproxy',
@subsystem_id=11 --subsystem 11 is for SSIS as you can see in the above image
GO
--View all the proxies granted to all the subsystems
EXEC dbo.sp_enum_proxy_for_subsystem 


--Step #4 - Granting proxy access to security principals
USE msdb
GO
--Grant proxy account access to security principals that could be
--either login name or fixed server role or msdb role
--Please note, Members of sysadmin server role are allowed to use any proxy
EXEC msdb.dbo.sp_grant_login_to_proxy
@proxy_name=N'RptSSISproxy'
,@login_name=N'NQCORP\BRI Business Intelligence'

GO
EXEC msdb.dbo.sp_grant_login_to_proxy
@proxy_name=N'RptSSISproxy'
,@login_name=N'NQCORP\svc_rpt_ssis_proxy'

GO

--View logins provided access to proxies
EXEC dbo.sp_enum_login_for_proxy
GO 