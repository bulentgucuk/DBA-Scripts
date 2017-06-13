-- ADD LINKED SERVER PASSING THE LOGIN USED FOR KERBEROS AUTH
USE [master]
GO
IF NOT EXISTS (
			SELECT	1
			FROM	SYS.servers
			WHERE	name = 'SQLCLR07-P'
			)
	BEGIN
		EXEC master.dbo.sp_addlinkedserver @server = N'SQLCLR07-P', @srvproduct=N'SQL Server'
		EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N'SQLCLR07-P', @locallogin = NULL , @useself = N'True'
	END
GO

