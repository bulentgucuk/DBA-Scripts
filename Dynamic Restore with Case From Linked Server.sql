USE MASTER

-- PUT DB OFFLINE AND ONLINE TO DROP ALL THE CONNECTIONS
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = 'Survey_128763'
		)
	BEGIN
		ALTER DATABASE Survey_128763 SET OFFLINE WITH ROLLBACK IMMEDIATE
	END
	
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = 'Survey_128763'
		)
	BEGIN
		ALTER DATABASE Survey_128763 SET ONLINE
	END
-- DROP DATABASE IF EXISTS
IF EXISTS(	SELECT	NAME
			FROM	SYS.DATABASES
			WHERE	NAME = 'Survey_128763'
		)
	BEGIN
		DROP DATABASE Survey_128763
	END


-- FIND THE BACKUP FILE TO BE RESTORED
DECLARE @STR VARCHAR(2000),
		@BackuptobeRestored VARCHAR (1000)
SET	@BackuptobeRestored = (
		SELECT TOP 1 SUBSTRING(physical_device_name,25,100)
		FROM	[SQLCLR03-P].msdb.dbo.backupmediafamily
		WHERE	physical_device_name LIKE '%128763_%.BAK%'
		ORDER BY media_set_Id DESC)

SELECT @BackuptobeRestored as BackuptobeRestored
SELECT @BackuptobeRestored = '\\sqlclr03-p\I$\Backup\UserDatabases\' + @BackuptobeRestored
SELECT @BackuptobeRestored as BackuptobeRestored

-- CREATE TEMP TABLE TO STORE BACKUP FILE METADATA
IF EXISTS (
			SELECT	NAME
			FROM	Tempdb.sys.tables
			WHERE	NAME = 'RestoreSurvey_128763'
			)
	BEGIN
		DROP TABLE TempDb.dbo.RestoreSurvey_128763
	END
CREATE TABLE TempDb.dbo.RestoreSurvey_128763 (
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
 
INSERT INTO TempDb.dbo.RestoreSurvey_128763
EXEC (@STR)

-- DECLARE VARIABLES FOR DYNAMIC RESTORE
DECLARE	@DataFileLoopDeclare TINYINT --NUMBER OF VARIABLES THAT NEED TO BE CREATED FOR DATAFILES
DECLARE	@Restore VARCHAR(MAX) -- DYNAMIC RESTORE STATEMENT
SELECT	@Restore = 'RESTORE DATABASE Survey_128763 FROM DISK = ' + ''''+ @BackuptobeRestored + ''''+' WITH'

SELECT	@DataFileLoopDeclare = MAX(RowId)
FROM	TempDb.dbo.RestoreSurvey_128763
WHERE	Type = 'D'

-- CONFIGURE DATA FILES RESTORE LOCATION
WHILE	@DataFileLoopDeclare > 0
	BEGIN
		SELECT	@Restore = @Restore + ' MOVE ' + '''' + LogicalName + '''' + ' TO ' + '''H:\Data\Survey_128763\' +
		--SELECT	@Restore = @Restore + ' MOVE ' + '''' + LogicalName + '''' + ' TO ' + 
		--		CASE
		--			WHEN LogicalName = 'ISN_SYS' THEN + '''U:\DATA\' 
		--			WHEN LogicalName = 'ISN2' THEN + '''U:\DATA\' 
		--			WHEN LogicalName = 'ISN3' THEN + '''U:\DATA\'
		--			ELSE + '''V:\DATA\' 
		--		END 
				
				+ REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX('%\%',REVERSE(PhysicalName))-1)) + ''''
				+ ','
		FROM	TempDb.dbo.RestoreSurvey_128763
		WHERE	RowId = @DataFileLoopDeclare

		--PRINT	@Restore
		SELECT	@DataFileLoopDeclare = @DataFileLoopDeclare - 1
	END

--CONFIGURE LOG FILE RESTORE LOCATION
SELECT	@Restore = @Restore + ' MOVE ' + '''' + LogicalName + '''' + ' TO ' + '''G:\Log\Survey_128763\' +
		REVERSE(SUBSTRING(REVERSE(PhysicalName),1,PATINDEX('%\%',REVERSE(PhysicalName))-1)) + ''''
		+ ','
FROM	TempDb.dbo.RestoreSurvey_128763
WHERE	Type = 'L'
SELECT	@Restore = @Restore + 
	' STATS = 1, REPLACE, RECOVERY' 
SELECT	@Restore
DROP TABLE TempDb.dbo.RestoreSurvey_128763
DECLARE	@ERR INT

-- RESTORE DATABASE
EXEC	(@Restore)

-- SEND ALERT IF RESTORE DATABASE PROCESS SUCCEEDS
SELECT	@ERR = @@ERROR
IF @ERR = 0
	BEGIN
		EXEC  msdb.dbo.sp_send_dbmail
			@recipients='bulent.gucuk@troppussoftware.com',
			@subject='Survey_128763 Full Restore Job SUCCEEDED!!!'			
	
		END

-- SEND ALERT IF RESTORE DATABASE PROCESS FAILS
IF @ERR <> 0
	BEGIN
		EXEC  msdb.dbo.sp_send_dbmail
			@recipients='bulent.gucuk@troppussoftware.com',
			@subject='Survey_128763 Full Restore Job FAILED!!!'			
	
		END
GO
-- ENABLE NEW SERVICE BROKER
ALTER DATABASE Survey_128763 SET NEW_BROKER WITH ROLLBACK IMMEDIATE
		
GO		
-- CHANGE THE OWNER, SET RECOVERY TO SIMPLE
USE Survey_128763
ALTER AUTHORIZATION ON DATABASE::Survey_128763 TO SA;
ALTER DATABASE Survey_128763 SET RECOVERY SIMPLE

-- SET DB COMPATIBILITY LEVEL TO 100
USE [master]
GO
ALTER DATABASE [Survey_128763] SET COMPATIBILITY_LEVEL = 100
GO
