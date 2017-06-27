SET NOCOUNT ON;
DECLARE @SQL nvarchar(2000)
DECLARE @name nvarchar(128)
DECLARE @database_id int

CREATE TABLE #databases (database_id int NOT NULL, databasename nvarchar(128) NOT NULL, processed bit NOT NULL)
INSERT INTO #databases
        (database_id, databasename, processed)
SELECT database_id, name, 0 FROM master.sys.databases WHERE name NOT IN ('master', 'tempdb', 'msdb', 'distribution')

WHILE (SELECT COUNT(processed) FROM #databases WHERE processed = 0) > 0
	BEGIN
		SELECT TOP 1
			@name = databasename,
			@database_id = database_id
		FROM #databases
		WHERE processed = 0
		ORDER BY database_id

		SELECT @SQL = 'USE [' + @name + '];  REVOKE CONNECT TO [GUEST];'

		PRINT @SQL;

		UPDATE #databases SET processed = 1 WHERE database_id = @database_id;
	END

DROP TABLE #databases;

SET NOCOUNT OFF; 