USE MASTER
-- Connect to Data Domain
EXECUTE xp_cmdshell 'Net use \\10.0.0.140 Kv5apmENxb /USER:web.prod\IUSR_SQL_SERVICE /PERSISTENT:YES'


-- PUT DB OFFLINE AND ONLINE TO DROP ALL THE CONNECTIONS
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = 'ISNDevCut'
		)
	BEGIN
		ALTER DATABASE ISNDevCut SET OFFLINE WITH ROLLBACK IMMEDIATE
	END
	
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = 'ISNDevCut'
		)
	BEGIN
		ALTER DATABASE ISNDevCut SET ONLINE
	END
-- DROP DATABASE IF EXISTS
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = 'ISNDevCut'
		)
	BEGIN
		DROP DATABASE ISNDevCut
	END


-- FIND THE BACKUP FILE TO BE RESTORED
DECLARE @STR VARCHAR(2000),
		@BackuptobeRestored VARCHAR (1000)
SET	@BackuptobeRestored = (
		SELECT TOP 1 SUBSTRING(physical_device_name,15,100)
		FROM	[ipdbxx0000\isn01].msdb.dbo.backupmediafamily
		WHERE	physical_device_name LIKE '%ISN_db_full%.BAK%'
		ORDER BY media_set_Id DESC)

SELECT @BackuptobeRestored as BackuptobeRestored
SELECT @BackuptobeRestored = '\\10.0.0.140' + @BackuptobeRestored
SELECT @BackuptobeRestored as BackuptobeRestored

-- CREATE TEMP TABLE TO STORE BACKUP FILE METADATA
IF EXISTS (
			SELECT	NAME
			FROM	Tempdb.sys.tables
			WHERE	NAME = 'RestoreISNDevCut'
			)
	BEGIN
		DROP TABLE TempDb.dbo.RestoreISNDevCut
	END
CREATE TABLE TempDb.dbo.RestoreISNDevCut (
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
	TDEThumbprint VARCHAR(255)
 )

SELECT	@STR = 'RESTORE FILELISTONLY FROM  DISK = ' + ''''+ @BackuptobeRestored + ''''
 
INSERT INTO TempDb.dbo.RestoreISNDevCut
EXEC (@STR)

-- DECLARE VARIABLES FOR DYNAMIC RESTORE
DECLARE	@DataFileLoopDeclare TINYINT --NUMBER OF VARIABLES THAT NEED TO BE CREATED FOR DATAFILES
DECLARE	@Restore VARCHAR(MAX) -- DYNAMIC RESTORE STATEMENT
SELECT	@Restore = 'RESTORE DATABASE ISNDevCut FROM DISK = ' + ''''+ @BackuptobeRestored + ''''+' WITH'

SELECT	@DataFileLoopDeclare = MAX(RowId)
FROM	TempDb.dbo.RestoreISNDevCut
WHERE	Type = 'D'

-- CONFIGURE DATA FILES RESTORE LOCATION
WHILE	@DataFileLoopDeclare > 0
	BEGIN
		--SELECT	@Restore = @Restore + ' MOVE ' + '''' + LogicalName + '''' + ' TO ' + '''K:\DATA\BackOffice\' +
		SELECT	@Restore = @Restore + ' MOVE ' + '''' + LogicalName + '''' + ' TO ' + 
				CASE
					WHEN LogicalName = 'ISN_SYS' THEN + '''U:\DATA\' 
					WHEN LogicalName = 'ISN2' THEN + '''U:\DATA\' 
					WHEN LogicalName = 'ISN3' THEN + '''U:\DATA\'
					ELSE + '''V:\DATA\' 
				END 
				
				+ REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX('%\%',REVERSE(PhysicalName))-1)) + ''''
				+ ','
		FROM	TempDb.dbo.RestoreISNDevCut
		WHERE	RowId = @DataFileLoopDeclare

		--PRINT	@Restore
		SELECT	@DataFileLoopDeclare = @DataFileLoopDeclare - 1
	END

--CONFIGURE LOG FILE RESTORE LOCATION
SELECT	@Restore = @Restore + ' MOVE ' + '''' + LogicalName + '''' + ' TO ' + '''U:\DATA\' +
		REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX('%\%',REVERSE(PhysicalName))-1)) + ''''
		+ ','
FROM	TempDb.dbo.RestoreISNDevCut
WHERE	Type = 'L'
SELECT	@Restore = @Restore + 
	' STATS = 1, REPLACE, RECOVERY' 
SELECT	@Restore
DROP TABLE TempDb.dbo.RestoreISNDevCut
DECLARE	@ERR INT

-- RESTORE DATABASE
EXEC	(@Restore)

-- SEND ALERT IF RESTORE DATABASE PROCESS FAILS
SELECT	@ERR = @@ERROR
IF @ERR <> 0
	BEGIN
		EXEC  msdb.dbo.sp_send_dbmail
			@recipients='gucuk@netquote.com',
			@subject='ISNDevCut Full Restore Job FAILED!!!'			
	
		END
