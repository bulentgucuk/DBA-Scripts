/**************************************************************************
** CREATED BY:   Bulent Gucuk
** CREATED DATE: 2019.11.15
** CREATION:     Ensure that if the user exists in db not in db_owner role
**************************************************************************/
SET NOCOUNT ON; 

EXECUTE sp_MSforeachdb '
USE [?]
IF ''?''  LIKE (''%_Integration'') 
	AND NOT EXISTS (SELECT 1 FROM sys.databases WHERE is_read_only = 1 AND name = ''?'')
BEGIN

	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''SSBINFO\tfrancis'')
		BEGIN
			CREATE USER [SSBINFO\tfrancis] FOR LOGIN [SSBINFO\tfrancis];
		END
		ALTER ROLE [db_owner] ADD MEMBER [SSBINFO\tfrancis];		
END'

GO

EXECUTE sp_MSforeachdb '
USE [?]
IF ''?''  LIKE (''%_Reporting'') 
	AND NOT EXISTS (SELECT 1 FROM sys.databases WHERE is_read_only = 1 AND name = ''?'')
BEGIN
	
	IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N''SSBINFO\tfrancis'')
		BEGIN
			CREATE USER [SSBINFO\tfrancis] FOR LOGIN [SSBINFO\tfrancis];
		END
		ALTER ROLE [db_owner] ADD MEMBER [SSBINFO\tfrancis];		
END'

GO