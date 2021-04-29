SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#Schemas') IS NOT NULL
	DROP TABLE #Schemas;

CREATE TABLE #Schemas (
	  servername NVARCHAR(32) NOT NULL
	, databasename SYSNAME NOT NULL
	, schemaname SYSNAME NOT NULL
	, schema_id INT NOT NULL
	, principal_id INT NOT NULL
	, principalname NVARCHAR(128) NOT NULL
	, type_desc NVARCHAR(128)
	, objectname NVARCHAR(128) NULL
	, object_id INT NULL
	);
DECLARE @SQL_command_01 NVARCHAR(2000);
SET @SQL_command_01 = 
'USE [?]
IF EXISTS (SELECT 1 FROM sys.databases WHERE name <> ''tempdb'' and name = ''?'' and is_read_only = 0)
BEGIN
	DECLARE @message nvarchar(4000);
	SET @message = ''?'';
	RAISERROR (@message,0,1) WITH NOWAIT;
	SELECT	@@SERVERNAME AS servername
		, DB_NAME() AS databasename
		, s.name schemaname
		, s.schema_id
		, p.principal_id
		, p.name principalname
		, p.type_desc
		, o.name as objectname
		, o.object_id
	FROM	sys.schemas AS s 
		INNER JOIN sys.database_principals AS p ON s.principal_id = p.principal_id
		LEFT OUTER JOIN sys.objects AS o ON s.schema_id = o.schema_id
	WHERE	s.principal_id > 4
	AND		s.principal_id < 16384
	AND		p.name NOT LIKE ''%\svc%''
	AND		p.type_desc <> ''DATABASE_ROLE''
	ORDER BY s.schema_id;
END'
INSERT INTO #Schemas
EXEC SP_MSFOREACHDB @command1 = @SQL_command_01;

SELECT	*
FROM	#Schemas
