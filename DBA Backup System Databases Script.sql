SET NOCOUNT ON
-- Declare variable
DECLARE	@DbName VARCHAR (100),
		@Str VARCHAR (1000),
		@RowId TINYINT,
		@BackupDate VARCHAR(8), -- Sets the date
		@BackupHour VARCHAR(2), -- Sets the hour
		@BackupMinute VARCHAR (2), -- Sets the minute
		@BackupTime VARCHAR (12), -- Stores above info for backup time
		@BackupFolder VARCHAR(128) -- Stores the location of the folder for backups

SELECT	@BackupFolder = 'J:\Backups\SystemDatabases\' -- backslah necessary

-- Declare table variable
DECLARE	@Table TABLE (
			RowId TINYINT IDENTITY (1,1),
			DbName VARCHAR (100)
		)
-- Insert databases to be backed up to table variable
INSERT INTO @Table
SELECT	NAME
FROM	SYS.Databases
WHERE	database_id <= 4
AND	Name <> 'tempdb'

--select * from @Table

-- Set @RowId and go into while loop to backup
SELECT	@RowId = MAX(RowId)
FROM	@Table
WHILE	@RowId > 0
	BEGIN
		-- Set the date part of the backup file name
		SELECT	@BackupDate = CONVERT (VARCHAR(8),GETDATE(),112)
		SELECT	@BackupHour = DATEPART(HH,GETDATE())
		SELECT	@BackupMinute = DATEPART(MI,GETDATE())
		-- Set length of the hour to 2 digit if it's 1 digit
		IF LEN (@BackupHour) = 1
			BEGIN
				SET	@BackupHour = '0'+ @BackupHour
			END

		-- Set length of the minute to 2 digit if it's 1 digit
		IF LEN (@BackupMinute) = 1
			BEGIN
				SET	@BackupMinute = '0'+ @BackupMinute
			END

		SELECT	@BackupTime = @BackupDate + @BackupHour + @BackupMinute
		--  Start backup database
		SELECT	@Str = ''
		SELECT	@Str = 'BACKUP DATABASE '+ QUOTENAME(DbName) + ' TO DISK = '''+ @BackupFolder + DbName +
				'_db_full_' + @BackupTime +'.bak'''
				+ ' WITH STATS = 5, COMPRESSION'
		FROM	@Table
		WHERE	RowId = @RowId
		PRINT	@Str
		EXEC	(@Str)
		SELECT	@RowId = @RowId - 1		
	END
