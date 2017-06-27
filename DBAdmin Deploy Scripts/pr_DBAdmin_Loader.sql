USE [master];
IF NOT EXISTS(SELECT 1 FROM master.sys.databases WHERE name = 'DBAdmin')
BEGIN
    CREATE DATABASE [DBAdmin];
    ALTER DATABASE  [DBAdmin] MODIFY FILE (NAME = DBAdmin, SIZE = 512MB, FILEGROWTH = 256MB);
    ALTER DATABASE  [DBAdmin] MODIFY FILE (NAME = DBAdmin_log, SIZE = 256MB, FILEGROWTH = 256MB);
	ALTER DATABASE  [DBAdmin] SET RECOVERY SIMPLE;
    ALTER AUTHORIZATION ON DATABASE::[DBAdmin] TO [sa];
END
GO

USE [DBAdmin];
GO

IF (OBJECT_ID('DBAdmin_InstallParms') IS NOT NULL)
    DROP TABLE [dbo].[DBAdmin_InstallParms]

CREATE TABLE DBAdmin_InstallParms (
    ParmName            VARCHAR(256),
    ParmValue           VARCHAR(256)
)

INSERT [DBAdmin_InstallParms]
    SELECT 'InstallPath',               'F:\DBAdmin Deploy Scripts'                        -- MODIFY THIS LINE -   The path (local or Mapped drive) for the install scripts
                                                                                   --                      If necessary, copy the complete Install folder from M:.
      UNION
    SELECT 'TargetDataDomain',          'DPBACK0050'                                 -- MODIFY THIS LINE -   SPBACKUP, SPBACK0050, DPBACKUP, DPBACK0500
      UNION
    SELECT 'FullBackupFolder',          '\\DPBACK0050.web.prod\RepToBP15d\DQDBXX5300SQL_CR01'     -- MODIFY THIS LINE -   Where to put the SQL Full Backup Files
      UNION 
    SELECT 'FullBackupRetentionDays',   '15'                                       -- MODIFY THIS LINE -   How many days to keep full backup files
      UNION
    SELECT 'DiffBackupFolder',          '\\DPBACK0050.web.prod\RepToBP15d\DQDBXX5300SQL_CR01'     -- MODIFY THIS LINE -   Where to put the SQL Differential Backup Files
      UNION 
    SELECT 'DiffBackupRetentionDays',   '15'                                       -- MODIFY THIS LINE -   How many days to keep Differential backup files
      UNION
    SELECT 'TLogBackupFolder',          '\\DPBACK0050.web.prod\RepToBP15d\DQDBXX5300SQL_CR01'     -- MODIFY THIS LINE -   Where to put the SQL Transaction Log Backup Files
      UNION 
    SELECT 'TLogBackupRetentionDays',   '15'                                       -- MODIFY THIS LINE -   How many days to keep Transaction Log backup files
      UNION
    SELECT 'SystemBackupFolder',        '\\DPBACK0050.web.prod\RepToBP15d\DQDBXX5300SQL_CR01'     -- MODIFY THIS LINE -   Where to put the SQL System Backup Files
      UNION 
    SELECT 'SystemBackupRetentionDays', '15'                                       -- MODIFY THIS LINE -   How many days to keep System backup files
      UNION
    SELECT 'LogFolder',                 'F:\JobLogs\CR01'                        -- MODIFY THIS LINE -   Where to put the Agent job Log files
      UNION
    SELECT 'CreateStdBackupJobs',       '1'                                        -- MODIFY THIS LINE -   1 = YES , 0 = NO
      UNION
    SELECT 'CreateLTSPBackupJobs',      '0'                                        -- MODIFY THIS LINE -   1 = YES , 0 = NO
      UNION
    SELECT 'IsProduction',              '0'                                        -- MODIFY THIS LINE -   This Controls the Job Notifications and Alert notifications
                                                                                   --                      1 = YES , 0 = NO
      UNION
    SELECT 'FileDateFormat',            NULL                                       -- MODIFY THIS LINE -   Only specify if the local date format isn't mm/dd/yyyy
                                                                                   --                      E.g. UK : dd/mm/yyyy, FileDateFormat = 103, ref BOL, 'CONVERT' for format values.
      UNION
    SELECT 'InstallLogFolder',          'F:\DBAdmin_Loader_Log'                    --                      The log folder to store the Temporary Log Files
                                                                                   --                      NOTE - The data is written to Table after all processing is completed.
                                                                                   --                      This value is used to create a Temp folder to store log data until the end of processing.                                                               
      UNION 
    SELECT 'JobPageOperator',           'BRI QA DBA Alert MailBox'  
      UNION
    SELECT 'JobEmailOperator',          'BRI QA DBA Alert MailBox'
      UNION
    SELECT 'AlertsEnabled',             '1'                                        --                  -   1 = YES , 0 = NO

GO

-- (fn_SQLVersion) ================================================================================================
USE [DBAdmin]
GO

IF (OBJECT_ID('fn_SQLVersion') IS NOT NULL)
    BEGIN
        PRINT 'Dropping function [fn_SQLVersion]'
        DROP FUNCTION [dbo].[fn_SQLVersion]
    END

GO

CREATE FUNCTION [dbo].[fn_SQLVersion] ()
    RETURNS TINYINT
-- ***********************************************************************************
-- Author:      Simon Facer
-- Create date: 12/31/2009
-- Description: Returns the Version # for SQL. 
--              Version checking is used extensively throughout the Install process,
--              so this function is just to allow a shorter way to get the Version #.
--
--  Modification History
--  When        Who             Description
--  12/31/2009  S Facer         Original Version
-- ***********************************************************************************
    AS

    BEGIN

        DECLARE @retSQLVersionID        TINYINT

        SELECT @retSQLVersionID = CAST((LEFT(CAST(SERVERPROPERTY ('ProductVersion') AS VARCHAR(64)), CHARINDEX('.', CAST(SERVERPROPERTY ('ProductVersion') AS VARCHAR(64))) - 1)) AS TINYINT)

        RETURN @retSQLVersionID

    END
GO


IF (OBJECT_ID('fn_SQLVersion') IS NOT NULL)
    BEGIN
        PRINT 'Function Created [fn_SQLVersion]'
    END
GO
-- (fn_SQLVersion) ================================================================================================


-- (pr_LogToFile) =======================================================================================
USE [DBAdmin]
GO

IF (OBJECT_ID('pr_LogToFile') IS NOT NULL)
    BEGIN
        PRINT 'Dropping procedure [pr_LogToFile]'
        DROP PROCEDURE [dbo].[pr_LogToFile]
    END

GO

CREATE PROCEDURE [dbo].[pr_LogToFile] (
    @TextToWrite        VARCHAR(512) = NULL,
    @FileName           VARCHAR(256) = NULL,
    @IncludeDelimiters  BIT = 0)

AS
-- --------------------------------------------------------------------------------------------------
--  Procedure   :   [pr_LogToFile]
--  Description :   Write data to a log file using BCP
--                  BCP overwrites the existing file, this code assumes that this is taken care of 
--                  in the calling routing
--
--  Modification Log
--  When            Who             Description
--  12/31/2009      Simon Facer     Original Version
-- --------------------------------------------------------------------------------------------------

BEGIN

    SET NOCOUNT ON

    -- ******************************************************************************************
    -- Declare local variables
    DECLARE @Comment                VARCHAR(8000)
    DECLARE @SQLCmd                 VARCHAR(8000)
    DECLARE @OSCmd                  VARCHAR(8000)
    DECLARE @FileName_I1            VARCHAR(256)
    DECLARE @FileName_I2            VARCHAR(256)
    DECLARE @FileName_Ix            VARCHAR(256)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Create the Log Comment table used to push comments into the Log File using bcp
    IF dbo.fn_SQLVersion() >= 9
        BEGIN
            SELECT @SQLCmd = 'IF NOT EXISTS (SELECT * FROM tempdb.sys.objects where name = ''##AddCommentToLogFile'')
                                      CREATE TABLE ##AddCommentToLogFile (
                                          RowID                   INT IDENTITY(1,1),
                                          Comment                 VARCHAR(256) )'
        END
    ELSE
        BEGIN
            SELECT @SQLCmd = 'IF NOT EXISTS (SELECT * FROM tempdb..sysobjects where name = ''##AddCommentToLogFile'')
                                      CREATE TABLE ##AddCommentToLogFile (
                                          RowID                   INT IDENTITY(1,1),
                                          Comment                 VARCHAR(256) )'
        END

    EXEC (@SQLCmd)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Add the text to the Global Temp table, if NULL was passed in, the table was already populated.
    IF @TextToWrite IS NOT NULL
        BEGIN
            DELETE ##AddCommentToLogFile

            INSERT ##AddCommentToLogFile (Comment) 
                VALUES (' ')
                
            SELECT @Comment = CONVERT(VARCHAR(32), GETDATE(), 101) + ' ' + CONVERT(VARCHAR(32), GETDATE(), 114) + ' >> ' +  @TextToWrite

            IF @IncludeDelimiters = 1
                BEGIN
                    INSERT ##AddCommentToLogFile (Comment) 
                        VALUES (REPLICATE('-', (LEN(@Comment))))
                END
                
            INSERT ##AddCommentToLogFile (Comment) 
                VALUES (@Comment)
            IF @IncludeDelimiters = 1
                BEGIN
                    INSERT ##AddCommentToLogFile (Comment) 
                        VALUES (REPLICATE('-', (LEN(@Comment))))
                    INSERT ##AddCommentToLogFile (Comment) 
                        VALUES (' ')
                END
        END

    SELECT @OSCmd = 'bcp "SELECT Comment FROM ##AddCommentToLogFile ORDER BY RowID" queryout "' + @FileName + '" -S ' + @@ServerName + ' -T -c'
    EXECUTE master.dbo.xp_cmdshell @OSCmd
    -- ******************************************************************************************

END

GO

IF (OBJECT_ID('pr_LogToFile') IS NOT NULL)
    BEGIN
        PRINT 'Procedure Created [pr_LogToFile]'
    END
GO
-- (pr_LogToFile) ================================================================================================


-- (pr_DBAdmin_Loader) =============================================================================================
USE [DBAdmin]
GO

IF (OBJECT_ID('pr_DBAdmin_Loader') IS NOT NULL)
    BEGIN
        PRINT 'Dropping procedure [pr_DBAdmin_Loader]'
        DROP PROCEDURE [dbo].[pr_DBAdmin_Loader]
    END

GO

CREATE PROCEDURE [dbo].[pr_DBAdmin_Loader] 

AS
-- --------------------------------------------------------------------------------------------------
--  Procedure   :   [pr_DBAdmin_Loader]
--  Description :   To Compile all the DBAdmin Scripts
--
--  Modification Log
--  When            Who             Description
--  12/31/2009      Simon Facer     Original Version
-- --------------------------------------------------------------------------------------------------

BEGIN

SET NOCOUNT ON

    -- ******************************************************************************************
    -- Declare local variables
    DECLARE @InstallPath            VARCHAR(256)
    DECLARE @SQLCmdBase             VARCHAR(8000)
    DECLARE @OSCmd                  VARCHAR(8000)
    DECLARE @SQLCmd                 VARCHAR(8000)
    DECLARE @xp_CmdShell            BIT
    DECLARE @Adv_Options            BIT
    DECLARE @BCPCmd                 VARCHAR(256)
    DECLARE @InstallLogFile         VARCHAR(256)
    DECLARE @InstallLogTempFile     VARCHAR(256)
    DECLARE @InstallLogTempFile1    VARCHAR(256)
    DECLARE @InstallLogTempFile2    VARCHAR(256)
    DECLARE @InstallLogTempFile3    VARCHAR(256)
    DECLARE @InstallLogTempFolder   VARCHAR(256)
    DECLARE @InstallLogFileID       INT
    DECLARE @LogTableName           VARCHAR(256)
    DECLARE @RowID                  INT
    DECLARE @FileName               VARCHAR(256)
    DECLARE @SubFolder              VARCHAR(256)
    DECLARE @Msg                    VARCHAR(256)
    DECLARE @FullBackupFolder       VARCHAR(256)
    DECLARE @DiffBackupFolder       VARCHAR(256)
    DECLARE @TlogBackupFolder       VARCHAR(256)
    DECLARE @LogFolder              VARCHAR(256)
    DECLARE @FileNameStart          INT
    -- ******************************************************************************************

    -- ******************************************************************************************
    CREATE TABLE #Files (
            RowID               INT IDENTITY(1, 1)  NOT NULL,
            Folder              VARCHAR(512)        NULL,
            SubFolder           VARCHAR(512)        NULL,
            FileName            VARCHAR(512)        NULL,
            FileExtension       VARCHAR(512)        NULL,
            DirResult           VARCHAR(1024)       NULL)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Turn ON xp_cmdshell if needed
    IF dbo.fn_SQLVersion() >= 9
        BEGIN
            SELECT @Adv_Options = CAST(value_in_use AS bit)
                FROM master.sys.configurations
                WHERE name = 'show advanced options'

            SELECT @xp_CmdShell = CAST(value_in_use AS bit)
                FROM master.sys.configurations
                WHERE name = 'xp_cmdshell'

            IF (@xp_CmdShell != 1)
                BEGIN

                    IF (@Adv_Options = 0)
                        BEGIN
                            EXEC sp_configure 'show advanced options', 1
                            RECONFIGURE
                        END

                    EXEC sp_configure 'xp_cmdshell', 1
                    RECONFIGURE

                    IF (@Adv_Options = 0)
                        BEGIN
                            EXEC sp_configure 'show advanced options', 0
                            RECONFIGURE
                        END

                END
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Retrieve the Log File Name, prepare the Temp log file folder
    SELECT  @InstallLogTempFolder = ParmValue
        FROM DBAdmin_InstallParms
        WHERE ParmName = 'InstallLogFolder'

    IF RIGHT (@InstallLogTempFolder, 1) = '\'
        BEGIN
            SELECT @InstallLogTempFolder = LEFT(@InstallLogTempFolder, (LEN(@InstallLogTempFolder) - 1))
        END
PRINT 'InstallLogTempFolder: ' + @InstallLogTempFolder;

    SELECT  @InstallLogTempFile1 = @InstallLogTempFolder + '\DBAdmin_Loader_Log_~id~.txt',
            @InstallLogFileID = 0

    SELECT @OSCmd = 'DEL ' + @InstallLogTempFolder + '\*.* /Q'
    EXECUTE master.dbo.xp_cmdshell @OSCmd

PRINT @OSCmd;

    SELECT @OSCmd = 'RD ' + @InstallLogTempFolder
    EXECUTE master.dbo.xp_cmdshell @OSCmd

PRINT @OSCmd;

    SELECT @OSCmd = 'MD ' + @InstallLogTempFolder
    EXECUTE master.dbo.xp_cmdshell @OSCmd

PRINT @OSCmd;

    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Create the Log Comment - used to push comment into the Log File using bcp
    IF dbo.fn_SQLVersion() >= 9
        BEGIN
            SELECT @SQLCmd = 'IF NOT EXISTS (SELECT * FROM tempdb.sys.objects where name = ''##AddCommentToLogFile'')
                                      CREATE TABLE ##AddCommentToLogFile (
                                          RowID                   INT IDENTITY(1,1),
                                          Comment                 VARCHAR(256) )'
        END
    ELSE
        BEGIN
            SELECT @SQLCmd = 'IF NOT EXISTS (SELECT * FROM tempdb..sysobjects where name = ''##AddCommentToLogFile'')
                                      CREATE TABLE ##AddCommentToLogFile (
                                          RowID                   INT IDENTITY(1,1),
                                          Comment                 VARCHAR(256) )'
        END

PRINT @SQLCmd;

    EXEC (@SQLCmd)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Log the start of the processing
    SELECT @InstallLogFileID = @InstallLogFileID + 1
    SELECT @InstallLogTempFile = REPLACE(@InstallLogTempFile1, '~id~', (RIGHT(('000' + CAST(@InstallLogFileID AS VARCHAR(4))), 4)))

    EXEC pr_LogToFile
            @TextToWrite = 'Beginning Install',
            @FileName = @InstallLogTempFile,
            @IncludeDelimiters = 1
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Validate the contents of the Install Parameter Table
    SELECT @InstallPath = ParmValue
        FROM DBAdmin_InstallParms
        WHERE ParmName = 'InstallPath';
        
    SELECT @FullBackupFolder = ParmValue
        FROM DBAdmin_InstallParms
        WHERE ParmName = 'FullBackupFolder';
        
    SELECT @DiffBackupFolder = ParmValue
        FROM DBAdmin_InstallParms
        WHERE ParmName = 'DiffBackupFolder';
        
    SELECT @TLogBackupFolder = ParmValue
        FROM DBAdmin_InstallParms
        WHERE ParmName = 'TLogBackupFolder';
        
    SELECT @LogFolder = ParmValue
        FROM DBAdmin_InstallParms
        WHERE ParmName = 'LogFolder';

PRINT 'InstallPath: ' + @InstallPath;
PRINT 'FullBackupFolder: ' + @FullBackupFolder;
PRINT 'DiffBackupFolder: ' + @DiffBackupFolder;
PRINT 'TLogBackupFolder: ' + @TlogBackupFolder;
PRINT 'LogFolder: ' + @LogFolder;

    IF @InstallPath IS NULL OR 
       LTRIM(RTRIM(@InstallPath)) = ''
        BEGIN
            SELECT @InstallLogFileID = @InstallLogFileID + 1
            SELECT @InstallLogTempFile = REPLACE(@InstallLogTempFile1, '~id~', (RIGHT(('000' + CAST(@InstallLogFileID AS VARCHAR(4))), 4)))
            EXEC pr_LogToFile
                @TextToWrite = 'InstallPath must be entered',
                @FileName = @InstallLogTempFile,
                @IncludeDelimiters = 1
            RAISERROR ('InstallPath must be entered', 16, 1)
            RETURN
        END

    IF @FullBackupFolder IS NULL OR 
       LTRIM(RTRIM(@FullBackupFolder)) = ''
        BEGIN
            SELECT @InstallLogFileID = @InstallLogFileID + 1
            SELECT @InstallLogTempFile = REPLACE(@InstallLogTempFile1, '~id~', (RIGHT(('000' + CAST(@InstallLogFileID AS VARCHAR(4))), 4)))
            EXEC pr_LogToFile
                @TextToWrite = 'FullBackupFolder must be entered',
                @FileName = @InstallLogTempFile,
                @IncludeDelimiters = 1
            RAISERROR ('FullBackupFolder must be entered', 16, 1)
            RETURN
        END

    IF @DiffBackupFolder IS NULL OR 
       LTRIM(RTRIM(@DiffBackupFolder)) = ''
        BEGIN
            SELECT @InstallLogFileID = @InstallLogFileID + 1
            SELECT @InstallLogTempFile = REPLACE(@InstallLogTempFile1, '~id~', (RIGHT(('000' + CAST(@InstallLogFileID AS VARCHAR(4))), 4)))
            EXEC pr_LogToFile
                @TextToWrite = 'DiffBackupFolder must be entered',
                @FileName = @InstallLogTempFile,
                @IncludeDelimiters = 1
            RAISERROR ('DiffBackupFolder must be entered', 16, 1)
            RETURN
        END

    IF @TLogBackupFolder IS NULL OR 
       LTRIM(RTRIM(@TLogBackupFolder)) = ''
        BEGIN
            SELECT @InstallLogFileID = @InstallLogFileID + 1
            SELECT @InstallLogTempFile = REPLACE(@InstallLogTempFile1, '~id~', (RIGHT(('000' + CAST(@InstallLogFileID AS VARCHAR(4))), 4)))
            EXEC pr_LogToFile
                @TextToWrite = 'TLogBackupFolder must be entered',
                @FileName = @InstallLogTempFile,
                @IncludeDelimiters = 1
            RAISERROR ('TLogBackupFolder must be entered', 16, 1)
            RETURN
        END

    IF @LogFolder IS NULL OR 
       LTRIM(RTRIM(@LogFolder)) = ''
        BEGIN
            SELECT @InstallLogFileID = @InstallLogFileID + 1
            SELECT @InstallLogTempFile = REPLACE(@InstallLogTempFile1, '~id~', (RIGHT(('000' + CAST(@InstallLogFileID AS VARCHAR(4))), 4)))
            EXEC pr_LogToFile
                @TextToWrite = 'LogFolder must be entered',
                @FileName = @InstallLogTempFile,
                @IncludeDelimiters = 1
            RAISERROR ('LogFolder must be entered', 16, 1)
            RETURN
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Set the Base SQLCmd string
    IF dbo.fn_SQLVersion() >= 9
        BEGIN
       SELECT @SQLCmdBase = 'SQLCmd ' +
                             '-E ' +                                    -- Use Trusted Connection
                             '-S ' + @@ServerName + ' ' +               -- Execute on this server
                             '-i "' + @InstallPath + '\~sp~\~fn~" ' +   -- The file to be executed
                                                                        -- Tokens : ~sp~: SubPath from Install Path
                                                                        --          ~fn~: FileName 
                             '-o "~o~"'                                 -- The Output File, everything gets put into one file
                                                                        -- Tokens : ~o~:  Fully Qualified Output File Name
        END
    ELSE
        BEGIN
       SELECT @SQLCmdBase = 'oSQL ' +
                             '-E ' +                                    -- Use Trusted Connection
                             '-S ' + @@ServerName + ' ' +               -- Execute on this server
                             '-i "' + @InstallPath + '\~sp~\~fn~" ' +   -- The file to be executed
                                                                        -- Tokens : ~sp~: SubPath from Install Path
                                                                        --          ~fn~: FileName 
                             '-o "~o~"'                                 -- The Output File, everything gets put into one file
                                                                        -- Tokens : ~o~:  Fully Qualified Output File Name
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Identify the Files and Folders names under the Install Path
    SELECT  @OSCmd = 'DIR "' + @InstallPath + '"  /S'

PRINT @OSCmd;

    INSERT  #Files (DirResult)
        EXECUTE master.dbo.xp_cmdshell @OSCmd
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Remove Leading / Trailing spaces from the results
    UPDATE #Files
        SET DirResult = LTRIM(RTRIM(DirResult))
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Identify the start of the file name, using file 
    SELECT @FileNameStart = CHARINDEX('~~', DirResult)
        FROM #Files
        WHERE DirResult like '%~~%'
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Remove the entries we dont want
    DELETE  #Files
        WHERE   RowID < (SELECT MIN(RowID)
                             FROM #Files
                             WHERE CHARINDEX('DIRECTORY OF', UPPER(DirResult)) > 0)
          OR    DirResult IS NULL
          OR    CHARINDEX('<DIR>', UPPER(DirResult)) > 0
          OR    CHARINDEX('FILE(S)', UPPER(DirResult)) > 0
          OR    CHARINDEX('DIR(S)', UPPER(DirResult)) > 0
          OR    RowID > (SELECT MAX(RowID)
                             FROM #Files
                             WHERE CHARINDEX('FILE(S)', UPPER(DirResult)) > 0
                              AND  RowID < ( SELECT MAX(RowID)
                                                 FROM #Files
                                                 WHERE CHARINDEX('FILE(S)', UPPER(DirResult)) > 0 ))
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Identify the Folder Paths
    SELECT  RowID,
            REPLACE(DirResult, 'Directory of ', '') AS FolderPath
        INTO #Folders_wk
        FROM #Files
        WHERE DirResult LIKE 'Directory of %'

    SELECT  f1.RowID,
            MIN(COALESCE(f2.RowID, 8000)) AS Next_RowID,
            f1.FolderPath
        INTO #Folders
        FROM #Folders_wk f1
            LEFT OUTER JOIN #Folders_wk f2
                ON f1.RowID < f2.RowID
        GROUP BY f1.RowID, f1.FolderPath
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Add the folder paths to the file rows
    UPDATE #Files
        SET Folder = fol.FolderPath
        FROM #Files fil
            INNER JOIN #Folders fol
                ON  fil.RowID > fol.RowID 
                AND fil.RowID < fol.Next_RowID
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Remove the Directory Of ... entries and anything in the base Deployment folder
    DELETE #Files
        WHERE Folder IS NULL
          OR  Folder = @InstallPath
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Identify the SubFolder
    UPDATE #Files
        SET SubFolder = REPLACE(Folder, (@InstallPath + '\'), '')
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Get the filename from the DirResult field
    UPDATE #Files
        SET [FileName] = LTRIM(RTRIM(SUBSTRING(DirResult, @FileNameStart, 8000)))
    -- ******************************************************************************************

   -- ******************************************************************************************
    -- Get the file extension from the filename
    UPDATE  #Files
        SET     FileExtension = SUBSTRING(FileName,
                                          ( LEN(FileName) - ( CHARINDEX('.', ( REVERSE(FileName) )) - 2 ) ),
                                          ( CHARINDEX('.', ( REVERSE(FileName) )) - 1 ))
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Remove any Commented Folders (all files) or individual Files
    -- Any Folder or File starting with # is considered Commented
    DELETE #Files
        WHERE LEFT(SubFolder, 1) = '#'
          OR  LEFT([FileName], 1) = '#'
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Only files with .SQL suffix are processed
    DELETE #Files
        WHERE FileExtension != 'sql'
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Verify if there are duuplicate files - stop processing if so
    SELECT FileName, COUNT(SubFolder) AS Duplicates
        INTO #Duplicates
        FROM #Files
        GROUP BY FileName
        HAVING COUNT(SubFolder) > 1

    IF @@ROWCOUNT > 0
        BEGIN
            INSERT ##AddCommentToLogFile (Comment) 
                        VALUES (REPLICATE('-', 80))
            INSERT ##AddCommentToLogFile (Comment)
                        VALUES('Duplicate File Entries found in the Install Folders:')
            INSERT ##AddCommentToLogFile (Comment)
                SELECT ' ' + FileName + ' - ' + Folder
                    FROM #Files
                    WHERE FileName IN (SELECT FileName 
                                           FROM #Duplicates)
                    ORDER BY FileName, Folder
            INSERT ##AddCommentToLogFile (Comment) 
                        VALUES (REPLICATE('-', 80))
            INSERT ##AddCommentToLogFile (Comment) 
                        VALUES ('The installation is being stopped')
            INSERT ##AddCommentToLogFile (Comment) 
                        VALUES (REPLICATE('-', 80))

            SELECT @InstallLogFileID = @InstallLogFileID + 1
            SELECT @InstallLogTempFile = REPLACE(@InstallLogTempFile1, '~id~', (RIGHT(('000' + CAST(@InstallLogFileID AS VARCHAR(4))), 4)))
            EXEC pr_LogToFile
                @TextToWrite = NULL,
                @FileName = @InstallLogTempFile,
                @IncludeDelimiters = 1

            RAISERROR ('Duplicate File Entries found in the Install Folders', 16, 1)
            RETURN
        END
    -- ******************************************************************************************
SELECT * FROM #Files
    -- ******************************************************************************************
    -- Create and execute the SQLCMD command.
    WHILE EXISTS (SELECT *
                      FROM #Files)
        BEGIN
            SELECT @RowID = MIN(RowID)
                FROM #Files

            SELECT @FileName = FileName,
                   @SubFolder = SubFolder
                FROM #Files
                WHERE RowID = @RowID

            SELECT @InstallLogFileID = @InstallLogFileID + 1
            SELECT @InstallLogTempFile = REPLACE(@InstallLogTempFile1, '~id~', (RIGHT(('000' + CAST(@InstallLogFileID AS VARCHAR(4))), 4)))
            SELECT @Msg = '-- Processing ' + @InstallPath + '\' + @SubFolder + '\' + @FileName
            PRINT @Msg
            EXEC pr_LogToFile
                @TextToWrite = @Msg,
                @FileName = @InstallLogTempFile,
                @IncludeDelimiters = 1

            SELECT @InstallLogFileID = @InstallLogFileID + 1
            SELECT @InstallLogTempFile = REPLACE(@InstallLogTempFile1, '~id~', (RIGHT(('000' + CAST(@InstallLogFileID AS VARCHAR(4))), 4)))
            SELECT @OSCmd = REPLACE((REPLACE((REPLACE (@SQLCmdBase, '~sp~', @SubFolder)), '~fn~', @FileName)), '~o~', @InstallLogTempFile)
            EXECUTE master.dbo.xp_cmdshell @OSCmd

            DELETE #Files
                WHERE RowID = @RowID
        END    
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Compile the Temporary Log files into a table
    SELECT @OSCmd = 'DIR ' + REPLACE(@InstallLogTempFile1, '~id~', '*') + ' '
PRINT @OSCmd;

    INSERT  #Files (DirResult)
        EXECUTE master.dbo.xp_cmdshell @OSCmd

    SELECT  @InstallLogTempFile2 = (REPLACE((REPLACE((@InstallLogTempFile1), '~id~', '%')), (@InstallLogTempFolder + '\'), '%') + '%'),
            @InstallLogTempFile3 = LEFT((REPLACE(@InstallLogTempFile1, (@InstallLogTempFolder + '\'), '')), (CHARINDEX('~', (REPLACE(@InstallLogTempFile1, (@InstallLogTempFolder + '\'), ''))) - 1))

    DELETE #Files
        WHERE DirResult NOT LIKE @InstallLogTempFile2
          OR  DirResult IS NULL

    UPDATE #Files   
        SET [FileName] = SUBSTRING(DirResult, (CHARINDEX(@InstallLogTempFile3, DirResult)), 999)
    
    SELECT @LogTableName = 'DBAdmin_Loader_Log_' + REPLACE(REPLACE(REPLACE((CONVERT(VARCHAR(32), GETDATE(), 120)), '-', ''), ' ', '_'), ':', '')
    SELECT @SQLCmd = 'CREATE TABLE [DBAdmin].[dbo].[' + @LogTableName + '] ' +
                     '(Loader_Log       VARCHAR(8000) NULL)'
    EXEC (@SQLCmd)
PRINT @SQLCmd;

    WHILE EXISTS (SELECT *
                      FROM #Files)
        BEGIN
            SELECT @InstallLogTempFile1 = MIN([FileName])
                FROM #Files

            DELETE #Files   
                WHERE [FileName] = @InstallLogTempFile1
                
            SELECT @InstallLogTempFile1 = @InstallLogTempFolder + '\' + @InstallLogTempFile1
            
            SELECT @SQLCmd = 'BULK INSERT [DBAdmin].[dbo].[' + @LogTableName + '] ' +
                             'FROM ''' + @InstallLogTempFile1 + ''''
PRINT @SQLCmd;
            EXEC (@SQLCmd)
        END                 
    -- ******************************************************************************************
    
    -- ******************************************************************************************
    -- Turn OFF xp_cmdshell if needed
    IF dbo.fn_SQLVersion() >= 9
        BEGIN
            IF (@xp_CmdShell != 1)
                BEGIN

                    IF (@Adv_Options = 0)
                        BEGIN
                            EXEC sp_configure 'show advanced options', 1
                            RECONFIGURE
                        END

                    EXEC sp_configure 'xp_cmdshell', 0
                    RECONFIGURE

                    IF (@Adv_Options = 0)
                        BEGIN
                            EXEC sp_configure 'show advanced options', 0
                            RECONFIGURE
                        END

                END
        END
    -- ******************************************************************************************
END

GO

IF (OBJECT_ID('pr_DBAdmin_Loader') IS NOT NULL)
    BEGIN
        PRINT 'Procedure created [pr_DBAdmin_Loader]'
    END
GO
-- (pr_DBAdmin_Loader) =============================================================================================



-- Execute (pr_DBAdmin_Loader) ======================================================================================
PRINT '========================================'
PRINT '===   Executing [pr_DBAdmin_Loader]   ==='
PRINT '========================================'

EXEC [pr_DBAdmin_Loader]
-- Execute (pr_DBAdmin_Loader) ======================================================================================
