USE [master]
GO
CREATE LOGIN [NQCORP\BRI DBA] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
EXEC master..sp_addsrvrolemember @loginame = N'NQCORP\BRI DBA', @rolename = N'sysadmin'
GO

