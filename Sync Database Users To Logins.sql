/***
Script generates commands to sync database users to server logins that has the same name but different SID
***/
DECLARE @SQL nvarchar(2000)
DECLARE @name nvarchar(128)
DECLARE @database_id int

SET NOCOUNT ON;

IF OBJECT_ID ('tempdb..#LoginsToSync') IS NOT NULL
	DROP TABLE #LoginsToSync;
CREATE TABLE #LoginsToSync
	(
	[database_name] nvarchar(128) NOT NULL,
	[user_name] nvarchar(128) NOT NULL,
	[sync_command_text] nvarchar(200) NOT NULL
	)

IF OBJECT_ID ('tempdb..#databases') IS NOT NULL
	DROP TABLE #databases;
CREATE TABLE #databases
	(
	  [database_id] int NOT NULL
	, [database_name] nvarchar(128) NOT NULL
	, [processed] bit NOT NULL)

INSERT INTO #databases ([database_id], [database_name], [processed])
SELECT	[database_id], [name], 0 
FROM	sys.databases
WHERE	name NOT IN ('master', 'tempdb', 'msdb', 'distribution', 'model')

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
		INSERT INTO #LoginsToSync (database_name, user_name, sync_command_text)
		SELECT	
			  DB_NAME()
			, dp.name
			, ' + '''' +
			'USE ' + QUOTENAME(@name) +'; ALTER USER ' + ''''+ ' + QUOTENAME(dp.name) + ' + '''' +  ' with LOGIN = ' + ''''+ ' + QUOTENAME(sp.name) + ' + '''' +  ';'
			+ '''' +
			CHAR(13) +
			'FROM	sys.database_principals AS dp
			LEFT OUTER JOIN sys.server_principals AS sp ON dp.name = sp.name
		WHERE	dp.type <> ''R''
		AND		sp.sid <> dp.sid
		order by dp.name'
		--PRINT @SQL;

		EXEC sys.sp_executesql @SQL

		UPDATE #databases SET processed = 1 WHERE database_id = @database_id;
	END

SELECT	[database_name], [user_name], [sync_command_text] 
FROM	#LoginsToSync
ORDER BY [database_name], [user_name];

DROP TABLE #databases;
DROP TABLE #LoginsToSync;

SET NOCOUNT OFF;
