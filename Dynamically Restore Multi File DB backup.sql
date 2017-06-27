USE MASTER
-- PUT DB OFFLINE AND ONLINE TO DROP ALL THE CONNECTIONS
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = 'SOCPlatform_BETA'
		)
	BEGIN
		ALTER DATABASE SOCPlatform_BETA SET OFFLINE WITH ROLLBACK IMMEDIATE
	END
	
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = 'SOCPlatform_BETA'
		)
	BEGIN
		ALTER DATABASE SOCPlatform_BETA SET ONLINE
	END

DECLARE @STR VARCHAR (255)
IF EXISTS (
			SELECT	NAME
			FROM	Tempdb.sys.tables
			WHERE	NAME = 'RestoreDb'
			)
	BEGIN
		DROP TABLE TempDb.dbo.RestoreDb
	END
CREATE TABLE TempDb.dbo.RestoreDb (
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
	BackupSizeInBytes INT,
	SourceBlockSize INT,
	FileGroupId INT,
	LogGroupGUID VARCHAR(128),
	DifferentialBaseLSN NUMERIC(25,0) ,
	DifferentialBaseGUID UNIQUEIDENTIFIER,
	IsReadOnly BIT,
	IsPresent BIT,
	TDEThumbprint VARBINARY(32) 
 )

SELECT	@STR = 'RESTORE FILELISTONLY FROM  DISK = ''D:\Temp\SOCPLATFORM_BETA_db_full_201202290345.bak'''
 
INSERT INTO TempDb.dbo.RestoreDb
EXEC (@STR)
	
SELECT	RowId,
		LogicalName,
		PhysicalName,
		Type,
		FileGroupName,
		PATINDEX('%\%',REVERSE(PhysicalName)),
		REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX('%\%',REVERSE(PhysicalName))-1))
FROM	TempDb.dbo.RestoreDb


-- DECLARE VARIABLES DYNAMICALLY
DECLARE	@DataFileLoopDeclare TINYINT --NUMBER OF VARIABLES THAT NEED TO BE CREATED FOR DATAFILES
DECLARE	@Restore VARCHAR (4000) -- DYNAMIC RESTORE STATEMENT
SELECT	@Restore = 'RESTORE DATABASE SOCPlatform_BETA FROM DISK = ''D:\Temp\SOCPLATFORM_BETA_db_full_201202290345.bak'''+' WITH'

SELECT	@DataFileLoopDeclare = MAX(RowId)
FROM	TempDb.dbo.RestoreDb

WHILE	@DataFileLoopDeclare > 0
	BEGIN
	
		SELECT	@Restore = @Restore + ' MOVE ' + '''' + LogicalName + '''' + ' TO ' + '''D:\Temp\Databases\' +
				REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX('%\%',REVERSE(PhysicalName))-1)) + ''''
				+ ','
		FROM	TempDb.dbo.RestoreDb
		WHERE	RowId = @DataFileLoopDeclare
		
		SELECT	@DataFileLoopDeclare = @DataFileLoopDeclare - 1
	END
SELECT	@Restore = @Restore + ' STATS = 1, REPLACE, RECOVERY'
SELECT	@Restore
EXEC	(@Restore)
DROP TABLE TempDb.dbo.RestoreDb