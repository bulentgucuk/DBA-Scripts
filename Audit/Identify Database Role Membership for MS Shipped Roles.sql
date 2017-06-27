
DECLARE @SQL nvarchar(2000)
DECLARE @name nvarchar(128)
DECLARE @database_id int

SET NOCOUNT ON;

IF NOT EXISTS (SELECT name FROM tempdb.sys.tables WHERE name like '%#elevated_users%')
 BEGIN
 CREATE TABLE #elevated_users
 (
 database_name nvarchar(128) NOT NULL,
 [user_name] nvarchar(128) NOT NULL,
 [database_role_name] nvarchar(128) NOT NULL
 )
 END

CREATE TABLE #databases (database_id int NOT NULL, database_name nvarchar(128) NOT NULL, processed bit NOT NULL)

INSERT INTO #databases (database_id, database_name, processed)
SELECT database_id, name, 0 FROM master.sys.databases

WHILE (SELECT COUNT(processed) FROM #databases WHERE processed = 0) > 0
 BEGIN
 SELECT TOP 1
 @name = database_name,
 @database_id = database_id
 FROM #databases
 WHERE processed = 0
 ORDER BY database_id

 SELECT @SQL =

'USE [' + @name + '];
INSERT INTO #elevated_users (database_name, user_name, database_role_name)
SELECT DB_NAME(), SP_L.name AS user_name, SP_R.name AS database_role_name
FROM sys.database_principals SP_L
 INNER JOIN sys.database_role_members SRM ON SP_L.principal_id = SRM.member_principal_id
 INNER JOIN sys.database_principals SP_R ON SRM.role_principal_id = SP_R.principal_id
WHERE SP_R.type_desc = ' + '''' + 'DATABASE_ROLE' + ''''
 + ' AND SP_L.name <> ' + '''' + 'dbo' + ''''
 + ' AND SP_R.is_fixed_role = 1;'

 --PRINT @SQL;

 EXEC sys.sp_executesql @SQL

 UPDATE #databases SET processed = 1 WHERE database_id = @database_id;
 END

SELECT database_name, [user_name], database_role_name
FROM #elevated_users
ORDER BY [database_name], database_role_name, [user_name];

DROP TABLE #databases;
DROP TABLE #elevated_users;

SET NOCOUNT OFF; 
