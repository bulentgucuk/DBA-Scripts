-- Find object name exist in user databases
SET   NOCOUNT ON;
DECLARE	@t TABLE (rowid TINYINT IDENTITY,
			NAME VARCHAR(128)
			)

INSERT INTO		@t (NAME)
SELECT name FROM sys.databases
WHERE database_id > 4


DECLARE @str varchar(2048),
		@rowid TINYINT,
		@DBname VARCHAR(128),
		@TableName VARCHAR(128) = '%Termination%';

SELECT	@rowid = MAX(rowid)
FROM	@t

WHILE	@rowid > 0
	BEGIN
		SELECT	@DBname = name
		FROM	@t
		WHERE	rowid = @rowid

		SELECT @str = 'IF EXISTS ( SELECT '+ '''' + (@DBname) +'''' +  ' AS DBNAME, * FROM ' + @DBname + '.SYS.TABLES WHERE NAME LIKE ''' + @TableName + ''')' + CHAR(13) + '
		BEGIN
		SELECT '+ '''' + (@TableName) +'''' + ' AS [Table],' + '''' + (@DBname) +'''' + ' AS ExistInDB' + CHAR(13) +
		'END';

		PRINT @str
		EXEC (@STR);
		
		SET	@rowid = @rowid - 1
	END
