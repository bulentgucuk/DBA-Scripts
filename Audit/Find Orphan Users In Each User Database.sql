DECLARE @SQL nvarchar(2000)
DECLARE @name nvarchar(128)
DECLARE @database_id int

SET NOCOUNT ON;

IF NOT EXISTS (SELECT name FROM tempdb.sys.tables WHERE name like '%#orphan_users%')
	BEGIN
		CREATE TABLE #orphan_users
			(
			database_name nvarchar(128) NOT NULL,
			[user_name] nvarchar(128) NOT NULL,
			drop_command_text nvarchar(200) NOT NULL
			)
	END

CREATE TABLE #databases (database_id int NOT NULL, database_name nvarchar(128) NOT NULL, processed bit NOT NULL)

INSERT INTO #databases (database_id, database_name, processed)
SELECT database_id, name, 0 FROM master.sys.databases WHERE name NOT IN ('master', 'tempdb', 'msdb', 'distribution', 'model')

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
INSERT INTO #orphan_users (database_name, user_name, drop_command_text)
SELECT  DB_NAME(), u.name, ' + '''' + 'USE [' + @name + '];  DROP USER [' + '''' + ' + u.name + ' + '''' + '] ' + '''' +
'FROM    master..syslogins l
        RIGHT JOIN sysusers u ON l.sid = u.sid
WHERE   l.sid IS NULL
        AND issqlrole <> 1
        AND isapprole <> 1
        AND ( u.name <> ' + '''' + 'INFORMATION_SCHEMA' + ''''
              + ' AND u.name <> ' + '''' + 'guest' + ''''
              + ' AND u.name <> ' + '''' + 'dbo' + ''''
              + ' AND u.name <> ' + '''' + 'sys' + ''''
              + ' AND u.name <> ' + '''' + 'system_function_schema' + '''' + ')'

		PRINT @SQL;

		EXEC sys.sp_executesql @SQL

		UPDATE #databases SET processed = 1 WHERE database_id = @database_id;
	END

SELECT database_name, [user_name], drop_command_text FROM #orphan_users ORDER BY [database_name], [user_name];

DROP TABLE #databases;
DROP TABLE #orphan_users;

SET NOCOUNT OFF;
