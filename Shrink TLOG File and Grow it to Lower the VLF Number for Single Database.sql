USE YourDatabaseNameHere;
/*
    Summary:            Reduce the number of Virtual Log Files without
                        altering the size of the transaction log.
 
    By:                 Max Vernon
    Original Source:    https://www.sqlserverscience.com/recovery/fix-high-vlf-count
*/
SET NOCOUNT ON;
DECLARE @RecoveryModel          nvarchar(max);
DECLARE @BlockingVLFStartOffset bigint;
DECLARE @ShrinkCmd              nvarchar(max);
DECLARE @GrowCmd                nvarchar(max);
DECLARE @LogFileName            nvarchar(128);
DECLARE @LogFileCount           int;
DECLARE @msg                    varchar(2047);
DECLARE @VersionMajor           int;
DECLARE @VersionMinor           int;
DECLARE @cmd                    nvarchar(max);
DECLARE @cmdi                   nvarchar(max);
DECLARE @VLFCountBefore         int;
DECLARE @VLFCountAfter          int;
DECLARE @LogFileSizeMB          int;
DECLARE @LogFileSizeMBEnd       int;
DECLARE @InitialSize            int;
DECLARE @MaxSize                int;
DECLARE @Growth                 int;
 
SET @VersionMajor = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
SET @VersionMinor = CONVERT(int, SERVERPROPERTY('ProductMinorVersion'));
 
/******************************** validation checks ******************************/
IF SERVERPROPERTY('EngineEdition') < 2 OR SERVERPROPERTY('EngineEdition') > 4 /* Standard, Enterprise, Express */
BEGIN
    --only run on "normal" SQL Server Engines
    SET @msg = 'This script only runs on Express, Standard, or Enterprise Edition engines.';
    RAISERROR (@msg, 14, 1);
    GOTO end_of_script;
END
--simple recovery means we don't need to take log backups, we just need to wait for the last VLF to be truncated
--full (and bulk_logged) recovery means we need to take log backups until the last VLF is truncated, with a pause between
SET @LogFileCount = (SELECT COUNT(1) FROM sys.database_files df WHERE df.type_desc = N'LOG');
IF @LogFileCount > 1
BEGIN
    SET @msg = CONVERT(nvarchar(11), @LogFileCount) +  N' log files detected.  This code only works with databases with a single log file.';
    RAISERROR (@msg, 14, 1);
    GOTO end_of_script;
END
 
/****************************** initialize variables *****************************/
SET @RecoveryModel = (SELECT d.recovery_model_desc FROM sys.databases d WHERE d.database_id = DB_ID());
SET @LogFileName = (SELECT df.name FROM sys.database_files df WHERE df.type_desc = N'LOG');
SET @ShrinkCmd = N'DBCC SHRINKFILE (' + @LogFileName + N', TRUNCATEONLY) WITH NO_INFOMSGS;';
SET @LogFileSizeMB = COALESCE((SELECT CONVERT(bigint, df.size) FROM sys.database_files df WHERE df.type_desc = N'LOG'), 0) * 8192 / 1048576;
 
IF OBJECT_ID(N'tempdb..#sizes', N'U') IS NOT NULL
DROP TABLE #sizes;
CREATE TABLE #sizes
(
    initial_log_size int NOT NULL
    , max_log_size int NOT NULL
    , growth int NOT NULL
    , PRIMARY KEY CLUSTERED (initial_log_size, max_log_size)
);
 
 --these values come from https://www.sqlserverscience.com/recovery/optimal-log-file-growth-and-virtual-log-files/
INSERT INTO #sizes (initial_log_size, max_log_size, growth)
VALUES 
      (16,     16,      16)
    , (32,     32,      32)
    , (32,     64,      32)
    , (64,     128,     64)
    , (64,     256,     64)
    , (128,    512,     128)
    , (128,    1024,    128)
    , (256,    2048,    256)
    , (256,    4096,    256)
    , (512,    8192,    512)
    , (512,    16384,   512)
    , (1024,   32768,   1024)
    , (1024,   65536,   1024)
    , (2048,   131072,  2048)
    , (2048,   262144,  2048)
    , (4096,   524288,  4096)
    , (4096,   1048576, 4096);
 
;WITH src AS 
(
SELECT InitialSize = s.initial_log_size
    , MaxSize = s.max_log_size
    , Growth = s.growth
    , PriorMax = LAG(s.max_log_size, 1) OVER (ORDER BY s.initial_log_size, s.max_log_size)
FROM #sizes s
)
SELECT @InitialSize = src.InitialSize
    , @MaxSize = src.MaxSize
    , @Growth = src.growth
FROM src 
WHERE src.PriorMax <= @LogFileSizeMB
    AND src.MaxSize >= @LogFileSizeMB;
 
IF OBJECT_ID(N'tempdb..##LogInfo_CD43A587', N'U') IS NOT NULL
BEGIN
    DROP TABLE ##LogInfo_CD43A587;
END
CREATE TABLE ##LogInfo_CD43A587 
(
    DatabaseId    int          NULL
);
IF @VersionMajor >= 11
BEGIN
    ALTER TABLE ##LogInfo_CD43A587
    ADD RecoveryUnitId int     NOT NULL --available in SQL Server 2012+;
END
ALTER TABLE ##LogInfo_CD43A587
ADD
      FileId      smallint     NOT NULL
    , FileSize    float        NOT NULL
    , StartOffset bigint       NOT NULL
    , FSeqNo      bigint       NOT NULL
    , Status      int          NOT NULL
    , Parity      tinyint      NOT NULL
    , CreateLSN   nvarchar(24) NOT NULL;
 
CREATE CLUSTERED INDEX LogInfo_pk
ON ##LogInfo_CD43A587 (FileId, FSeqNo);
 
SET @cmd = N'DBCC LOGINFO(' + CONVERT(nvarchar(11), DB_ID()) + N') WITH NO_INFOMSGS'
IF @VersionMajor >= 11 
BEGIN
    SET @cmdi = N'TRUNCATE TABLE ##LogInfo_CD43A587;
INSERT INTO ##LogInfo_CD43A587 WITH (TABLOCKX) (RecoveryUnitId, FileId, FileSize, StartOffset, FSeqNo, Status, Parity, CreateLSN)
EXEC (''' + @cmd + N''');'
END
ELSE
BEGIN
    SET @cmdi = N'TRUNCATE TABLE ##LogInfo_CD43A587;
INSERT INTO ##LogInfo_CD43A587 WITH (TABLOCKX) (FileId, FileSize, StartOffset, FSeqNo, Status, Parity, CreateLSN)
EXEC (''' + @cmd + N''');'
END
 
/****************************** the action starts here ****************************/
EXEC sys.sp_executesql @cmdi; --get VLF details from DBCC LOGINFO
/* [Status] column:
    0 - VLF is inactive
    1 - VLF is initialized but unused
    2 - VLF is active.
*/
SET @VLFCountBefore = (SELECT COUNT(1) FROM ##LogInfo_CD43A587 li);
PRINT N'This script will shrink the log file, then grow it back to the original size with an efficient growth increment.  This is done to lower VLF count.';
PRINT N'Current VLF Count is: ' + CONVERT(nvarchar(11), @VLFCountBefore);
SET @BlockingVLFStartOffset = (SELECT MAX(StartOffset) FROM ##LogInfo_CD43A587 li WHERE li.Status = 2); --status "2" is "active"
--Shrink the Log File to its smallest possible size
EXEC (@ShrinkCmd);
--get the DBCC LOGINFO details after the shrink
EXEC sys.sp_executesql @cmdi;
--wait until VLF truncation marks the @BLockVLFFSeqNo as unused.
IF @RecoveryModel IN (N'FULL', 'BULK_LOGGED')
BEGIN
    DECLARE @BackupCommand nvarchar(max);
    --pipe a log backup to NUL: and warn the user about broken log chain.
    SET @BackupCommand = N'CHECKPOINT;
BACKUP LOG ' + QUOTENAME(DB_NAME()) + N' TO DISK = N''NUL:'' WITH NO_COMPRESSION, NO_CHECKSUM;';
    EXEC (@BackupCommand);
END
IF @BlockingVLFStartOffset > (SELECT MIN(StartOffset) FROM ##LogInfo_CD43A587 li)
BEGIN
    WHILE @BlockingVLFStartOffset = (SELECT MAX(StartOffset) FROM ##LogInfo_CD43A587 li WHERE li.Status = 2) --status "2" is "active"
    BEGIN
        SET @msg = CONVERT(varchar(30), GETDATE(), 120) + ': Waiting for VLF truncation.';
        RAISERROR (@msg, 0, 1) WITH NOWAIT;
        WAITFOR DELAY '00:00:10'; --10 seconds before we check again
        IF @RecoveryModel IN (N'FULL', N'BULK_LOGGED') EXEC (@BackupCommand) ELSE CHECKPOINT;
        EXEC (@ShrinkCmd);
        EXEC sys.sp_executesql @cmdi;
    END
END
EXEC (@ShrinkCmd); -- shrink one more time to get the log as small as possible.
EXEC sys.sp_executesql @cmdi;
DECLARE @CurrentSize int;
SET @CurrentSize = COALESCE((SELECT SUM(li.FileSize) FROM ##LogInfo_CD43A587 li), 0) / 1048576;
WHILE @InitialSize < @CurrentSize
BEGIN
    SET @InitialSize = @InitialSize + @Growth;
END
WHILE @InitialSize <= @LogFileSizeMB
BEGIN
    SET @GrowCmd = N'ALTER DATABASE ' + QUOTENAME(DB_NAME()) + N' MODIFY FILE (NAME = N''' + @LogFileName + ''', SIZE = ' + CONVERT(nvarchar(11), @InitialSize) + N', FILEGROWTH = ' + CONVERT(nvarchar(11), @Growth) + N', MAXSIZE = ' + CONVERT(nvarchar(11), @LogFileSizeMB) + N')';
    EXEC (@GrowCmd);
    SET @InitialSize = @InitialSize + @Growth;
END
EXEC sys.sp_executesql @cmdi;
SET @VLFCountAfter = COALESCE((SELECT COUNT(1) FROM ##LogInfo_CD43A587), 0);
SET @LogFileSizeMBEnd = COALESCE((SELECT CONVERT(bigint, df.size) FROM sys.database_files df WHERE df.type_desc = N'LOG'), 0) * 8192 / 1048576;
SET @msg = 'Log has been shrunk and re-grown back to its original size.  VLF Count is now: ' + CONVERT(varchar(11), @VLFCountAfter);
PRINT @msg;
SET @msg = 'Original size: ' + CONVERT(varchar(11), @LogFileSizeMB) + N' MB, Current Size: ' + CONVERT(varchar(11), @LogFileSizeMBEnd) + ' MB';
PRINT @msg;
IF @RecoveryModel IN (N'FULL', N'BULK_LOGGED')
BEGIN
    RAISERROR (N'THIS IS A WARNING: A fake log backup has been taken in order to reduce the size of the active portion of the transaction log.
Please ensure you immediately take a full backup of the database, along with a log backup to re-establish an appropriate recovery chain.', 14, 1) WITH NOWAIT;
END
end_of_script: