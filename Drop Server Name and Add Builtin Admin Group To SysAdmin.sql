USE [master]
--check the server names
--SELECT * FROM SYS.SERVERS
GO

-- Drop the original image of the windows server
EXEC SP_DROPSERVER  @@SERVERNAME

GO

-- Add the new windows netbios server name as local server
DECLARE @Servername SYSNAME

SELECT @Servername = CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS SYSNAME)

IF  NOT EXISTS (
		SELECT	*
		FROM	sys.servers
		WHERE	is_linked = 0
		)
	BEGIN
		EXEC SP_ADDSERVER @servername, @local = 'Local'
	END

GO

-- Add builtin adminstrators group as sysadmin 

IF NOT EXISTS (
		SELECT	*
		FROM	SYS.server_principals
		WHERE	name = 'BUILTIN\administrators'
		)
	BEGIN
		CREATE LOGIN [BUILTIN\administrators] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english];
	END


IF NOT EXISTS (
		SELECT	SRM.role_principal_id, SP.name AS Role_Name, SRM.member_principal_id, SP2.name  AS Member_Name
		FROM	sys.server_role_members AS SRM
			INNER JOIN sys.server_principals AS SP
				ON SRM.Role_principal_id = SP.principal_id
			INNER JOIN sys.server_principals AS SP2
				ON SRM.member_principal_id = SP2.principal_id
		WHERE	SP.name = 'sysadmin'
		AND		sp2.name = 'BUILTIN\administrators'
		)
	BEGIN
		EXEC master..sp_addsrvrolemember @loginame = N'BUILTIN\administrators', @rolename = N'sysadmin';
	END
