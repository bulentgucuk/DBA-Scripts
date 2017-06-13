USE master
GO

IF (OBJECT_ID('sp__DBAdmin_Startup') IS NOT NULL)
    BEGIN
        EXEC master..sp_procoption @ProcName = 'sp__DBAdmin_Startup', @OptionName = 'Startup',  @OptionValue = 'FALSE'
        DROP PROCEDURE [dbo].[sp__DBAdmin_Startup]

        PRINT 'Dropping procedure master.dbo.[sp__DBAdmin_Startup]'
    END
GO

CREATE PROCEDURE [dbo].[sp__DBAdmin_Startup]
-- ****************************************************************************************
-- Author:      Simon Facer
-- Create date: 10/01/2010
-- Description: Performs DBAdmin functions at startup. 
--  (1) Log startup event to the SQL And Windows Logs. This is used by the 
--      [DBAdmin: SQL Server Startup] SQL Agent Alert to send notification to DBAdmin.
--  (2) Read the Log file to identify the volume where the SQL Log file is located.
--      This is used in procedure [DBAdmin].[dbo].[pr_MetricsCollection3_VolumeInformation].
--  (3) Write an entry into [DBAdmin].[dbo].[MC8_ServerRestartHistory]. This replace the
--      functionality in [DBAdmin].[dbo].[pr_MetricsCollection8_ServerRestarts].
--
--  Modification History
--  When        Who             Description
--  10/01/2010  S Facer         Original Version
--  10/25/2010  S Facer         Add funcionality to read the Log File (2) and (3) above.
--                              This avoids the necessity of having to read potentially
--                              large log files in the Monitoring code.
-- ****************************************************************************************

AS

BEGIN

    -- ******************************************************************************************
    -- Declare local variables
    DECLARE @SQLCmd                 NVARCHAR(2048)     
    DECLARE @SQLVersion             INT 
    DECLARE @CutOffDate             DATETIME
    DECLARE @LogFileDrive           VARCHAR(256)

    DECLARE @SPEX_BitFlag           BIT
    DECLARE @SPEX_ParmStr           NVARCHAR(256)
    DECLARE @SPEX_SQLCmd            NVARCHAR(1024)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Create the # Temp tables used in the proc.
    CREATE TABLE #ErrorLog (
                LogDate             DATETIME        NULL,
                ProcessInfo         VARCHAR(50)     NULL,
                LogText             VARCHAR(7900)   NULL,
                ContRow             INT             NULL) 
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Determine the target SQL Server's version,
    --      8 = 2000
    --      9 = 2005
    --      10 = 2008 
    SELECT @SQLVersion = [DBAdmin].[dbo].[fn_SQLVersion]()
    -- ******************************************************************************************

    -- ****************************************************************************************
    -- Pause for 30 seconds, to allow SQL Agent to start before writing the Log file entry.
    WAITFOR DELAY '00:00:30'
    -- ****************************************************************************************

    -- ****************************************************************************************
    -- (1) Log startup event to the SQL And Windows Logs.
    DECLARE @EventLogMessage        NVARCHAR(256)
    SELECT @EventLogMessage = 'DBAdmin: SQL Has Started (' + @@SERVERNAME + ')'

    RAISERROR(@EventLogMessage, 1, 1) WITH LOG
    -- ****************************************************************************************

    -- ****************************************************************************************
    -- (2) Read the Log file to identify the volume where the SQL Log file is located.

       -- ******************************************************************************************
        -- Verify that the table MC3_VolumeInformation_LogVolume exists.
        SET @SPEX_ParmStr = N'@p_BitFlag BIT OUTPUT'

        IF @SQLVersion = 8
            BEGIN
                SELECT @SPEX_SQLCmd = 'IF EXISTS (SELECT * FROM [DBAdmin].[dbo].[sysobjects] WHERE [name] = ''MC3_VolumeInformation_LogVolume'') SELECT @p_BitFlag = 1 ELSE SELECT @p_BitFlag = 0 '
            END
        ELSE
            BEGIN
                SELECT @SPEX_SQLCmd = 'IF EXISTS (SELECT * FROM [DBAdmin].[sys].[objects] WHERE [name] = ''MC3_VolumeInformation_LogVolume'') SELECT @p_BitFlag = 1 ELSE SELECT @p_BitFlag = 0 '
            END

        EXECUTE sp_executesql @SPEX_SQLCmd, @SPEX_ParmStr, @p_BitFlag = @SPEX_BitFlag OUTPUT

        IF @SPEX_BitFlag = 0
            BEGIN
                CREATE TABLE [DBAdmin].[dbo].[MC3_VolumeInformation_LogVolume] (
                    Drive               VARCHAR(3)      NULL)
            END
        -- ******************************************************************************************

        -- ******************************************************************************************
        -- Only read the current log file - as the server has just started, the information we need
        -- will be in this file.
        -- sp_readerrorlog is different for SQL 2000 / SQL 2005 +
        -- SQL 2000
        IF @SQLVersion = 8
            BEGIN
                INSERT INTO #ErrorLog (LogText, ContRow) EXEC sp_readerrorlog 

                UPDATE #ErrorLog 
                    SET LogDate = CASE 
                                      WHEN ISDATE(LTRIM(RTRIM(SUBSTRING(LogText, 1, CHARINDEX(' ', LogText, (CHARINDEX(' ', LogText) + 2)))))) = 1
                                          THEN CAST(LTRIM(RTRIM(SUBSTRING(LogText, 1, CHARINDEX(' ', LogText, (CHARINDEX(' ', LogText) + 2))))) AS DATETIME)
                                      ELSE
                                          CAST('01/01/1900' AS DATETIME)
                                  END 
            END
        -- SQL 2005 +
        ELSE
            BEGIN
                INSERT INTO #ErrorLog (LogDate, ProcessInfo, LogText) EXEC sp_readerrorlog 
            END
        -- ******************************************************************************************

        -- ******************************************************************************************
        -- Identify the 'Logging...' message, and save the Log File Drive to table MC3_VolumeInformation_LogVolume
        SELECT @LogFileDrive = (SELECT TOP 1 LogText
                                   FROM #ErrorLog
                                   WHERE LogText LIKE 'Logging%')
        SELECT @LogFileDrive = SUBSTRING(@LogFileDrive, (CHARINDEX (':\', @LogFileDrive) -1), 2)

        IF @LogFileDrive IS NOT NULL
            BEGIN
                DELETE [DBAdmin].[dbo].[MC3_VolumeInformation_LogVolume]
                INSERT [DBAdmin].[dbo].[MC3_VolumeInformation_LogVolume]
                    VALUES (@LogFileDrive)

            END              
        -- ******************************************************************************************

    -- ****************************************************************************************

    -- ****************************************************************************************
    --(3) Write an entry into [DBAdmin].[dbo].[MC8_ServerRestartHistory.

        -- ******************************************************************************************
        -- Verify that the permanent results table exists.
        SET @SPEX_ParmStr = N'@p_BitFlag BIT OUTPUT'

        IF @SQLVersion = 8
            BEGIN
                SELECT @SPEX_SQLCmd = 'IF EXISTS (SELECT * FROM [DBAdmin].[dbo].[sysobjects] WHERE [name] = ''MC8_ServerRestartHistory'') SELECT @p_BitFlag = 1 ELSE SELECT @p_BitFlag = 0 '
            END
        ELSE
            BEGIN
                SELECT @SPEX_SQLCmd = 'IF EXISTS (SELECT * FROM [DBAdmin].[sys].[objects] WHERE [name] = ''MC8_ServerRestartHistory'') SELECT @p_BitFlag = 1 ELSE SELECT @p_BitFlag = 0 '
            END

        EXECUTE sp_executesql @SPEX_SQLCmd, @SPEX_ParmStr, @p_BitFlag = @SPEX_BitFlag OUTPUT

        IF @SPEX_BitFlag = 0
            BEGIN
                CREATE TABLE [DBAdmin].[dbo].[MC8_ServerRestartHistory] (
                    Row_ID              INT     IDENTITY(1,1),
                    InstanceName        VARCHAR(128)    NULL,
                    CollectionTime      DATETIME        NULL,
                    RestartDateTime     DATETIME        NULL)  
            END
        -- ******************************************************************************************

        -- ******************************************************************************************
        -- Insert the data
        INSERT [DBAdmin].[dbo].[MC8_ServerRestartHistory] (
                    InstanceName,
                    CollectionTime,
                    RestartDateTime)
            SELECT  CAST(SERVERPROPERTY ('ServerName') AS VARCHAR(128)),
                    GETDATE(),
                    GETDATE()
        -- ******************************************************************************************

    -- ****************************************************************************************

END

GO

EXEC master..sp_procoption @ProcName = 'sp__DBAdmin_Startup', @OptionName = 'Startup',  @OptionValue = 'TRUE'
GO

IF (OBJECT_ID('sp__DBAdmin_Startup') IS NOT NULL)
    BEGIN
        PRINT 'Procedure created master.dbo.[sp__DBAdmin_Startup]'
    END
GO

PRINT 'Executing procedure master.dbo.[sp__DBAdmin_Startup]'

EXECUTE [master].[dbo].[sp__DBAdmin_Startup]
GO

