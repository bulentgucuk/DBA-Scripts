
DECLARE @RowId INT,
		@Str VARCHAR(512)

DECLARE @DisableFK TABLE (
	RowId INT IDENTITY(1,1),
	FKName VARCHAR(255) NOT NULL,
	FKTableName VARCHAR(100) NOT NULL,
	ReferencedTable VARCHAR(100) NOT NULL,
	Is_Disabled BIT NOT NULL
	)
INSERT INTO @DisableFK
SELECT	Name AS FKName,
		OBJECT_NAME(Parent_Object_id) AS FKTableName,
		OBJECT_NAME(Referenced_Object_id) AS ReferencedTable,
		Is_Disabled
FROM	SYS.FOREIGN_KEYS
WHERE	OBJECT_NAME(Referenced_Object_id) = 'Applications'
ORDER BY OBJECT_NAME(Parent_Object_id)

SELECT	@RowId = MAX(RowId) FROM @DisableFK

WHILE @RowId > 0
	BEGIN
		SELECT	@Str = ''
		SELECT	@Str = 'ALTER TABLE ' + FKTableName + ' NOCHECK CONSTRAINT ' + FKName -- Disable foreign key constraint
		--SELECT	@Str = 'ALTER TABLE ' + FKTableName + ' CHECK CONSTRAINT ' + FKName -- Enable foreign key constraint
		FROM	@DisableFK
		WHERE	RowId = @RowId
		
		PRINT	@Str
		--EXEC	(@Str)
		UPDATE	@DisableFK
		SET		Is_Disabled = 1
		WHERE	RowId = @RowId
		SELECT	@RowId = @RowId - 1
	END

SELECT * FROM @DisableFK
