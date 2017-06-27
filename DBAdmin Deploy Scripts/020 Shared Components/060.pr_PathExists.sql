USE DBAdmin
GO

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[lp_PathExists]') AND type = N'P')
            BEGIN
                PRINT 'Dropping procedure [lp_PathExists] - SQL 2005'
                DROP PROCEDURE [dbo].[lp_PathExists]
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'lp_PathExists' AND type = N'P')
            BEGIN
                PRINT 'Dropping procedure [lp_PathExists] - SQL 2000'
                DROP PROCEDURE [dbo].[lp_PathExists]
            END
    END

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_PathExists]') AND type = N'P')
            BEGIN
                PRINT 'Dropping procedure [pr_PathExists] - SQL 2005'
                DROP PROCEDURE [dbo].[pr_PathExists]
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'pr_PathExists' AND type = N'P')
            BEGIN
                PRINT 'Dropping procedure [pr_PathExists] - SQL 2000'
                DROP PROCEDURE [dbo].[pr_PathExists]
            END
    END

GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[pr_PathExists] (
        @PathValue      AS VARCHAR(256),
        @CreateFolder   AS BIT = 1)

AS
-- --------------------------------------------------------------------------------------------------
--  Procedure   :   [pr_PathExists]
--  Description :   To verify if the given path exists,
--                  Create the path if necessary
--  Parameters   PathValue              The folder path to verify,
--                                      REQUIRED.
--               CreateFolder           Create the folder if it doesnt exist.
--                                      OPTIONAL - defaults to 1 (Yes).
--
--  Modification Log
--  When            Who             Description
--  10/09/2007      Simon Facer     Original Version
--  03/31/2008      David Creighton Added call to pr_SetCMDShell
--  09/23/2012      David Creighton Added some checks for issues relative to network paths.
-- --------------------------------------------------------------------------------------------------

BEGIN

    SET NOCOUNT ON 

    DECLARE @FolderPath         VARCHAR(256)
    DECLARE @PathComponent      VARCHAR(64)
    DECLARE @Idx                INT
    DECLARE @PathLen            INT
    DECLARE @OS_Cmd             VARCHAR(1024)
    DECLARE @PathExists         INT
    DECLARE @CmdShell           BIT
    


    CREATE TABLE #PathComponents (
        FolderPath              VARCHAR(256),
        PathComponent           VARCHAR(64))

    CREATE TABLE #OS_CMD_Results (
        OS_Output               VARCHAR(1024) )


    -- ******************************************************************************************
    -- Set the PathExists value to 1, it will be reset to 0 as necessary
    SELECT @PathExists = 1
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Check if the path exists, if so, exit the proc
    SELECT @OS_Cmd = 'DIR "' + @PathValue + '" '

    EXEC pr_SetCMDShell 1, @CmdShell OUTPUT
    INSERT #OS_CMD_Results 
        EXEC master.dbo.xp_cmdshell @OS_Cmd
    EXEC pr_SetCMDShell @CmdShell

    IF NOT EXISTS (SELECT *
                       FROM #OS_CMD_Results
                       WHERE OS_Output LIKE '%File Not Found%' 
                         OR  OS_Output LIKE '%The system cannot find the path specified.%'
                         OR  OS_Output LIKE '%The system cannot find the file specified.%'
                         -------------------------------------------------------
                         -- Added by DJC on 9/23/2012
                         OR  OS_Output LIKE '%The network path was not found.%')
                         -------------------------------------------------------
        BEGIN
            SELECT @PathExists = 1
            GOTO TheEnd
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Parse the path into it's components
    SELECT @Idx = 0

    SELECT @PathValue = LTRIM(RTRIM(@PathValue))

    WHILE CHARINDEX('\', @PathValue, (@Idx + 1)) > 0
        BEGIN
            SELECT @Idx = CHARINDEX('\', @PathValue, (@Idx + 1)) 
            SELECT @FolderPath = SUBSTRING(@PathValue, 1, (@Idx - 1))
            SELECT @PathComponent = SUBSTRING(@FolderPath, (@PathLen + 2), 999)
            SELECT @PathLen = LEN(@FolderPath)
            INSERT #PathComponents
                VALUES(@FolderPath, @PathComponent)
        END

    SELECT @PathComponent = SUBSTRING(@PathValue, (@PathLen + 2), 999)
    INSERT #PathComponents
        VALUES (@PathValue, @PathComponent)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Declare the cursor to loop through the path components
    DECLARE csrPath CURSOR FOR
        SELECT  FolderPath,
                PathComponent
            FROM #PathComponents
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Open and retrieve the first values from the cursor
    OPEN csrPath
    FETCH NEXT FROM csrPath
        INTO @FolderPath,
             @PathComponent
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Loop through the Path components, and verify the existence of each
    WHILE @@FETCH_STATUS = 0
        BEGIN

        -- ******************************************************************************************
        -- If the path component doesnt exist,
        -- (1) Create it if @CreateFolder = 1, OR
        -- (2) Exit the proc with the return value (@PathExists) set to 0.
        SELECT @OS_Cmd = 'DIR "' + @FolderPath + '" '

        DELETE #OS_CMD_Results

        EXEC pr_SetCMDShell 1, @CmdShell OUTPUT
        INSERT #OS_CMD_Results EXEC master.dbo.xp_cmdshell @OS_Cmd
        EXEC pr_SetCMDShell @CmdShell

        IF EXISTS (SELECT *
                       FROM #OS_CMD_Results
                       WHERE OS_Output LIKE '%File Not Found%'
                         OR  OS_Output LIKE '%The system cannot find the path specified.%'
                         OR  OS_Output LIKE '%The system cannot find the file specified.%'
                         -------------------------------------------------------
                         -- Added by DJC on 9/23/2012
                         OR  OS_Output LIKE '%The filename, directory name, or volume label syntax is incorrect.%'
                         OR  OS_Output LIKE '%The network path was not found.%')
                         -------------------------------------------------------
            BEGIN
                IF @CreateFolder = 1
                    BEGIN
                        SELECT @OS_Cmd = 'MD "' + @FolderPath + '" '
						EXEC pr_SetCMDShell 1, @CmdShell OUTPUT
						DELETE #OS_CMD_Results
                        INSERT #OS_CMD_Results
	                        EXEC master.dbo.xp_cmdshell @OS_Cmd
                        EXEC pr_SetCMDShell @CmdShell

						------------------------------------------------------------------------
						-- Added by DJC on 9/23/2012
                        IF EXISTS (SELECT *
							FROM #OS_CMD_Results
							WHERE OS_Output LIKE '%The system cannot find the drive specified.%'
							OR    OS_Output LIKE '%The network path was not found.%')
						BEGIN
							SET @PathExists = 0
							GOTO TheEnd
						END
						-------------------------------------------------------------------------
                    END
                ELSE
                    BEGIN
                        SELECT @PathExists = 0
                        GOTO TheEnd
                    END                
            END
        -- ******************************************************************************************

        -- ******************************************************************************************
        -- Retrieve the next values from the cursor
        FETCH NEXT FROM csrPath
            INTO @FolderPath,
                 @PathComponent
        -- ******************************************************************************************

        END
    -- End of the loop
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Close and Deallocate the Cursor
    CLOSE csrPath
    DEALLOCATE csrPath    
    -- ******************************************************************************************

TheEnd:
    RETURN @PathExists

END

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_PathExists]') AND type = N'P')
            BEGIN
                PRINT 'Procedure Created [pr_PathExists] - SQL 2005'
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'pr_PathExists' AND type = N'P')
            BEGIN
                PRINT 'Procedure Created [pr_PathExists] - SQL 2000'
            END
    END

GO
