-- Find object name exist in user databases
SET   NOCOUNT ON;
DECLARE @ObjectName VARCHAR(128) = '%account%',
		@str varchar(2048),
		@rowid TINYINT,
		@DBname VARCHAR(128);

-- Table variable to loop user databases
DECLARE	@d TABLE (rowid TINYINT IDENTITY,
		DbName sysname
		)

INSERT INTO	@d (DbName)
SELECT name FROM sys.databases
WHERE database_id > 4
ORDER BY name DESC;

-- Temp table to store the objects
IF OBJECT_ID('Tempdb..#o') IS NOT NULL
	BEGIN
		DROP TABLE #o;
	END
CREATE TABLE #o (Rowid SMALLINT IDENTITY,
		DbName sysname,
		SchemaName sysname NULL,
		ObjectName sysname,
		Type_Desc VARCHAR(128),
		Create_Date DATETIME,
		Modify_Date DATETIME,
		is_published BIT
		);
SELECT	@rowid = MAX(rowid)
FROM	@d;WHILE	@rowid > 0
	BEGIN
		SELECT	@DBname = DbName
		FROM	@d
		WHERE	rowid = @rowid		SELECT @str = 'USE ' + @DBname + CHAR(13)		SELECT @str = @str + 'INSERT INTO #o' + CHAR(13)		SELECT @str = @str + 'SELECT ' + '''' + @DBname + '''' + ' AS DbName, SCHEMA_NAME(schema_id) AS SchemaName,name AS ObjectName,type_desc, create_date, modify_date,is_published' + CHAR(13)		SELECT @str = @str + 'FROM sys.objects WHERE NAME LIKE ' + '''' + @ObjectName + ''''				--PRINT @str
		EXEC (@STR);
		
		SET	@rowid = @rowid - 1
	END

SELECT * FROM #o--WHERE	Type_Desc = 'USER_TABLE'DROP TABLE #o;