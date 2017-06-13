SET NOCOUNT ON;
DECLARE	@SnapshotDbName VARCHAR(128),
		@SnapShotTime VARCHAR(20),
		@Date VARCHAR(10),
		@Hour VARCHAR(2),
		@Minute VARCHAR(2)

SELECT	@SnapshotDbName = DB_NAME();

SELECT	@Date = CONVERT (VARCHAR(8),GETDATE(),112),
		@Hour = DATEPART(HH,GETDATE()),
		@Minute = DATEPART(MI,GETDATE());
-- Set length of the hour to 2 digit if it's 1 digit
IF LEN (@Hour) = 1
	BEGIN
		SET	@Hour = '0'+ @Hour;
	END

-- Set length of the minute to 2 digit if it's 1 digit
IF LEN (@Minute) = 1
	BEGIN
		SET	@Minute = '0'+ @Minute;
	END

-- Concatenate the values
SELECT	@SnapShotTime = '_'+@Date + '_' + @Hour + @Minute;


DECLARE @T TABLE (
	RowId INT IDENTITY (1,1),
	Name VARCHAR(256),
	FileName VARCHAR(512)
	)

INSERT INTO @T (Name, FileName)
SELECT	'(name = ' + name + ', ' ,
		--'Filename = ''' + REPLACE(REPLACE(physical_name, '.mdf','.SS'),'.ndf','.SS') + '''),'
		'Filename = ''' + REPLACE(REPLACE(physical_name, '.mdf', @SnapShotTime + '.SS'),'.ndf', @SnapShotTime +'.SS') + '''),'
FROM	sys.database_files
WHERE	type = 0 ;

DECLARE	@RowId INT,
		@MaxRowID INT,
		@Str VARCHAR(MAX)

SELECT	@MaxRowID = MAX(RowId),
		@RowId = 1
FROM	@T ;

-- Replace the  last comma with with space
UPDATE @T
SET		FileName = REPLACE(FileName, '),' , ') ')
WHERE	RowId = @MaxRowID ;

-- START BUILDING THE DYNAMIC STRING TO EXECUTE
SELECT	@Str = 'CREATE DATABASE ' + @SnapshotDbName + '_SnapShot' + @SnapShotTime + ' ON ' + CHAR(13);

WHILE	@RowId <= @MaxRowID
	BEGIN
		SELECT	@Str = @Str + Name + FileName + CHAR(13)
		FROM	@T
		WHERE	RowId = @RowId ;
		SELECT	@RowId = @RowId + 1 ;
	END

SELECT	@Str = @Str + 'AS SNAPSHOT OF ' + @SnapshotDbName ;

PRINT @STR ;
EXEC (@STR) ;
