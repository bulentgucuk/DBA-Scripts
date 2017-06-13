USE MASTER
GO
DECLARE @BackuptobeRestored VARCHAR (1000),
		@DataFileRestorePath VARCHAR (512),
		@LogFileRestorePath VARCHAR (512),
		@DBname VARCHAR(128),
		@Sql VARCHAR(1024)
SELECT	@BackuptobeRestored = '\\nq.corp\shared\Devcuts\InstrumentationDevCut.Bak',
		@DBname = 'InstrumentationLocal',
		@DataFileRestorePath = 'C:\Temp\',
		@LogFileRestorePath = 'C:\Temp\'


-- PUT DB OFFLINE AND ONLINE TO DROP ALL THE CONNECTIONS
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = @DBname
		)
	BEGIN
		SET @Sql = 'ALTER DATABASE ' + @DBname + ' SET OFFLINE WITH ROLLBACK IMMEDIATE'
		PRINT @Sql
		EXEC (@Sql)
	END
	
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = @DBname
		)
	BEGIN
		SET @Sql = 'ALTER DATABASE ' + @DBname + ' SET ONLINE'
		PRINT @Sql
		EXEC (@Sql)
	END

-- DROP DATABASE IF EXISTS
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = @DBname
		)
	BEGIN
		SET @Sql = 'DROP DATABASE ' + @DBname
		PRINT @Sql
		EXEC (@Sql)
	END


DECLARE @STR VARCHAR (255)
IF EXISTS (
			SELECT	NAME
			FROM	Tempdb.sys.tables
			WHERE	NAME = 'RestoreInstrDb'
			)
	BEGIN
		DROP TABLE TempDb.dbo.RestoreInstrDb
	END
CREATE TABLE TempDb.dbo.RestoreInstrDb (
	RowId TINYINT IDENTITY(1,1),
	LogicalName VARCHAR (128),
	PhysicalName VARCHAR (512),
	Type CHAR(1),
	FileGroupName VARCHAR (128),
	Size numeric(20,0) ,
	MaxSize numeric(20,0) ,
	FileId BIGINT,
	CreatLSN numeric(25,0),
	DropLSN numeric(25,0),
	UniqeId VARCHAR (255),
	ReadOnlyLSN NUMERIC(25,0),
	ReadWriteLSN NUMERIC(25,0),
	BackupSizeInBytes BIGINT,
	SourceBlockSize INT,
	FileGroupId INT,
	LogGroupGUID VARCHAR(128),
	DifferentialBaseLSN NUMERIC(25,0) ,
	DifferentialBaseGUID UNIQUEIDENTIFIER,
	IsReadOnly BIT,
	IsPresent BIT,
	TDEThumbprint VARCHAR(128)
 )

SELECT	@STR = 'RESTORE FILELISTONLY FROM  DISK = ''' + @BackuptobeRestored + ''''
--PRINT @STR
 
INSERT INTO TempDb.dbo.RestoreInstrDb
EXEC (@STR)
	
--SELECT	RowId,
--		LogicalName,
--		PhysicalName,
--		Type,
--		FileGroupName,
--		PATINDEX('%\%',REVERSE(PhysicalName)),
--		REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX('%\%',REVERSE(PhysicalName))-1))
--FROM	TempDb.dbo.RestoreInstrDb


-- DECLARE VARIABLES DYNAMICALLY
DECLARE	@DataFileLoopDeclare TINYINT --NUMBER OF VARIABLES THAT NEED TO BE CREATED FOR DATAFILES
DECLARE	@Restore VARCHAR (4000) -- DYNAMIC RESTORE STATEMENT
SELECT	@Restore = 'RESTORE DATABASE ' + @DBname + ' FROM DISK = ''' + @BackuptobeRestored + ''''+' WITH'

SELECT	@DataFileLoopDeclare = MAX(RowId)
FROM	TempDb.dbo.RestoreInstrDb
WHERE	Type = 'D'

-- CONFIGURE DATA FILES RESTORE LOCATION
WHILE	@DataFileLoopDeclare > 0
	BEGIN
		SELECT	@Restore = @Restore + ' MOVE ' + '''' + LogicalName + '''' + ' TO ' + '''' + @DataFileRestorePath  +
				REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX('%\%',REVERSE(PhysicalName))-1)) + ''''
				+ ','
		FROM	TempDb.dbo.RestoreInstrDb
		WHERE	RowId = @DataFileLoopDeclare

		
		SELECT	@DataFileLoopDeclare = @DataFileLoopDeclare - 1
	END
--CONFIGURE LOG FILE RESTORE LOCATION
SELECT	@Restore = @Restore + ' MOVE ' + '''' + LogicalName + '''' + ' TO ' + '''' + @LogFileRestorePath +
		REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX('%\%',REVERSE(PhysicalName))-1)) + ''''
		+ ','
FROM	TempDb.dbo.RestoreInstrDb
WHERE	Type = 'L'
SELECT	@Restore = @Restore + 
	' STATS = 1, REPLACE, RECOVERY' 
SELECT	@Restore
DROP TABLE TempDb.dbo.RestoreInstrDb

-- Restore database
EXEC	(@Restore)

