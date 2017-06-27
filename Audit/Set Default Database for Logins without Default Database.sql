SELECT SL.name,
	SL.dbname,
	'USE [tempdb];
ALTER LOGIN [' + SL.name + '] WITH DEFAULT_DATABASE=[tempdb];
CREATE USER [' + SL.name + '] FOR LOGIN [' + SL.name + '] WITH DEFAULT_SCHEMA = [dbo];' AS SQL_command
FROM sys.[syslogins] SL
	LEFT JOIN sys.[databases] SD
		ON SL.[dbname] = SD.[name]
WHERE SD.name IS NULL
ORDER BY SL.[name], SL.[dbname]; 