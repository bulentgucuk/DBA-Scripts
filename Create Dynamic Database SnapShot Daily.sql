----------------------------------------------------------
-- Create Snapshot of a Source database in the same folder
----------------------------------------------------------
SET NOCOUNT ON;
DECLARE @SourceDBName SYSNAME,
		@SnapShotDBName SYSNAME,
		@InitRowId INT,
		@MaxRowId INT,
		@SqlCmd NVARCHAR(MAX)

SELECT	@SourceDBName = DB_NAME()
SELECT	@SnapShotDBName = @SourceDBName + '_SnapShot_' + CONVERT(VARCHAR(10), GETDATE(), 112)


SELECT	@InitRowId = 1,
		@SqlCmd = ''

DECLARE @T TABLE (
	RowId INT IDENTITY (1,1),
	Name VARCHAR(256),
	FileName VARCHAR(512)
	)

INSERT INTO @T (Name, FileName)
SELECT	'(name = ' + name + ',' ,
		'Filename = ''' + REPLACE(REPLACE(physical_name, '.mdf','.SS'),'.ndf','.SS') + '''),'
FROM	sys.database_files
WHERE	type = 0

-- Get the max row to loop
SELECT	@MaxRowId = MAX(RowId)
FROM	@T

-- Remove the comma at the last file for command to execute
UPDATE @T
SET FileName = REPLACE([FileName], ',' , '')
WHERE	RowId = @MaxRowId

-- Build SQL Command to be executed
WHILE @InitRowId <= @MaxRowId
	BEGIN
		SELECT	@SqlCmd = @SqlCmd + Name + [FileName] + CHAR(13)
		FROM	@T
		WHERE	RowId = @InitRowId;
		
		SELECT	@InitRowId = @InitRowId + 1;
	END

SELECT	@SqlCmd = 'CREATE DATABASE ' + @SnapShotDBName + ' ON ' + CHAR(13)+@SqlCmd + 'AS SNAPSHOT OF ' + @SourceDBName + ';'

PRINT @SqlCmd;
EXEC (@SqlCmd);
