USE master;
GO
/***
Check all databases where shema owner is not dbo and generate alter uahtorization
statement to change it to dbo.
***/
SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#SchemasOwnedByUser') IS NOT NULL
	DROP TABLE #SchemasOwnedByUser
CREATE TABLE #SchemasOwnedByUser (
	  DBname NVARCHAR(128)
	, schemaname NVARCHAR(128)
	, schema_id INT NOT NULL
	, principalname NVARCHAR(128)
	, type_desc NVARCHAR(128)
	, objectname NVARCHAR(128)
	, SQLstmt NVARCHAR(256)
	)
DECLARE @SQL_command_01 VARCHAR(2000);
SET @SQL_command_01 = 
'USE [?]
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = ''?'' and is_read_only = 0)
BEGIN
	DECLARE @message NVARCHAR(4000)
	SET @message = ''?''
	RAISERROR (@message,0,1) with nowait
	SELECT	d.name AS DatabaseName, s.name as schemaname, s.schema_id, p.name as principalname, p.type_desc, o.name as objectname, CONCAT(''USE'', '' '' , QUOTENAME(d.name), '' '', ''ALTER AUTHORIZATION ON SCHEMA::'',QUOTENAME(s.name),'' TO dbo;'') AS SQLstmt
	FROM	sys.schemas as s
		INNER JOIN sys.database_principals as p on s.principal_id = p.principal_id
		INNER JOIN sys.databases as d on d.name = db_name()
		LEFT OUTER JOIN sys.objects as o on s.schema_id = o.schema_id
	WHERE	s.schema_id > 4
	AND		s.principal_id <> 1
	AND		p.type_desc <> ''DATABASE_ROLE''
	AND		p.name not like ''%\svc%''
	AND		p.name like ''mgmt\%''
	AND		p.name <> ''NT AUTHORITY\ANONYMOUS LOGON''
	ORDER BY s.schema_id;

END'
INSERT INTO #SchemasOwnedByUser
EXEC SP_MSFOREACHDB @command1 = @SQL_command_01;

SELECT *
FROM	#SchemasOwnedByUser
--WHERE	type_desc <> 'WINDOWS_GROUP'
ORDER BY DBname;

