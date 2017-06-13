/**
SELECT	*
FROM	sys.schemas
**/

DECLARE	@SQL VARCHAR (512),
		@MAXID TINYINT

DECLARE	@T TABLE (
	RowID TINYINT IDENTITY (1,1),
	SchemaName VARCHAR (32) NOT NULL,
	TableName VARCHAR(128) NOT NULL)

INSERT INTO @T
SELECT	S.NAME AS SchemaName,
		t.NAME AS TableName
FROM	sys.tables AS T
	INNER JOIN sys.schemas AS S
		ON t.schema_id = s.schema_id
WHERE	s.name = 'dbo'
ORDER	BY t.name DESC	

--SELECT	* FROM	@T
DECLARE	@T2 TABLE (
	RecordCount INT NOT NULL,
	TableName VARCHAR(128)
	)
SELECT	@MAXID = MAX(ROWID)
FROM	@T

WHILE	@MAXID > 0
	BEGIN
		SELECT	@SQL = 'SELECT COUNT(*) AS RecordCount, ' + '''' + SchemaName + '.' +TableName + '''' + ' AS TableName FROM ' +
				QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName)
		FROM	@T
		WHERE	RowID = @MAXID
	PRINT	@SQL
	INSERT INTO @T2
	EXECUTE (@SQL)
	SELECT	@MAXID = @MAXID	- 1
	
	END
	
SELECT * FROM @T2	