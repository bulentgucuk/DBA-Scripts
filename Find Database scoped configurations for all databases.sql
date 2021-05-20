--Find Database scoped configurations for all databases
USE master;
GO
SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#DbScopeConfigs') IS NOT NULL
	DROP TABLE #DbScopeConfigs
CREATE TABLE #DbScopeConfigs (
	  DatabaseName SYSNAME
	, configuration_Id INT NOT NULL
	, name NVARCHAR(60) NOT NULL
	, value SQL_VARIANT NOT NULL
	, value_for_secondary SQL_VARIANT
	, Is_value_default BIT NOT NULL
	)
DECLARE @SQL_command_01 VARCHAR(2000);
SET @SQL_command_01 = 
'USE [?]
IF EXISTS (SELECT 1 FROM sys.databases WHERE database_id > 4 and name = ''?'' and is_read_only = 0)
BEGIN
	declare @message nvarchar(4000)
	set @message = ''?''
	raiserror (@message,0,1) with nowait
	SELECT	DB_NAME() AS DatabaseName
		, configuration_id
		, name
		, value
		, value_for_secondary
		, is_value_default
FROM	sys.database_scoped_configurations;
END'
INSERT INTO #DbScopeConfigs
EXEC SP_MSFOREACHDB @command1 = @SQL_command_01;

select * from #DbScopeConfigs
/** where Is_value_default = 0 **/
