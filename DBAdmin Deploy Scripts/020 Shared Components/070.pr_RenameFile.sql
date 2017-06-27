USE [DBAdmin]
GO
IF dbo.fn_SQLVersion()  >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[lp_RenameFile]') AND type in (N'P', N'PC'))
            BEGIN
                PRINT 'Dropping procedure [lp_RenameFile] - SQL 2005'
                DROP PROCEDURE [dbo].[lp_RenameFile]
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'lp_RenameFile' AND type in (N'P', N'PC'))
            BEGIN
                PRINT 'Dropping procedure [lp_RenameFile] - SQL 2000'
                DROP PROCEDURE [dbo].[lp_RenameFile]
            END
    END

IF dbo.fn_SQLVersion()  >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_RenameFile]') AND type in (N'P', N'PC'))
            BEGIN
                PRINT 'Dropping procedure [pr_RenameFile] - SQL 2005'
                DROP PROCEDURE [dbo].[pr_RenameFile]
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'pr_RenameFile' AND type in (N'P', N'PC'))
            BEGIN
                PRINT 'Dropping procedure [pr_RenameFile] - SQL 2000'
                DROP PROCEDURE [dbo].[pr_RenameFile]
            END
    END

GO
/****** Object:  StoredProcedure [dbo].[pr_RenameFile]    Script Date: 02/27/2007 14:28:15 ******/

CREATE PROCEDURE [dbo].[pr_RenameFile]
(
    @Folder                     VARCHAR(128) = NULL,
    @FileName                   VARCHAR(64)  = NULL,
    @NewFileName                VARCHAR(256) = NULL,
    @Debug                      BIT          = 0
)

-- --------------------------------------------------------------------------------------------------
--  Procedure   :   [pr_RenameFile]
--  Description :   To rename a file.
--                  Requires xp_cmdshell be enabled.
--  Parameters   Folder                 The folder where the file exists.
--                                      REQUIRED.
--               FileName               The file to be renamed.
--                                      REQUIRED.
--               NewFileName            The new file name
--                                      OPTIONAL - If not specified (NULL or empty / space) -
--                                      add a DateTime literal (_yyyymmddhhnnss) to the filename,
--                                      as in filename.ext becomes filename_yyyymmddhhnnss.ext
--               Debug                  Switch to determine if debugging information should be output
--                                      OPTIONAL - defaults to 0 (No).
--
--  Modification Log
--  When            Who             Description
--  03/31/2008      Simon Facer     Original Version
--  07/12/2010      Simon Facer     Increased @NewFileName length to 256 characters, to prevent file
--                                  name truncation.
-- --------------------------------------------------------------------------------------------------

AS

BEGIN

    DECLARE @ExtIdx             INT
    DECLARE @OS_Cmd             VARCHAR(1024)
    DECLARE @xpShellStatus      INT

    SET NOCOUNT ON

    IF @Debug = 1
        BEGIN
            SELECT 'Parameters',
                    @Folder                     AS Folder,
                    @FileName                   AS [FileName],
                    @NewFileName                AS NewFileName,
                    @Debug                      as Debug
        END


    -- ******************************************************************************************
    -- Validate the passed parameters
    IF ( @Folder IS NULL ) OR
       ( LTRIM(RTRIM(@Folder)) = '' )
        BEGIN
            SELECT  'Folder must be passed in'
            RAISERROR ('Folder must be passed in', 16, 1)
            RETURN
        END
    IF ( @FileName IS NULL ) OR
       ( LTRIM(RTRIM(@FileName)) = '' )
        BEGIN
            SELECT  'File Name must be passed in'
            RAISERROR ('File Name must be passed in', 16, 1)
            RETURN
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Add a trailing '\' to the Folder Name if necessary.
    IF RIGHT(@Folder, 1) != '\'
        BEGIN
            SELECT @Folder = @Folder + '\'
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If the NewFileName waasn't passed, construct the value to include the DATETIME literal
    IF ( @NewFileName IS NULL) OR
       ( LTRIM(RTRIM(@NewFileName)) = '' ) 
        BEGIN
            SELECT @NewFileName = @FileName

            SELECT @ExtIdx = LEN(@NewFileName) - CHARINDEX('.', (REVERSE(@NewFileName)))
            SELECT @NewFileName = SUBSTRING(@NewFileName, 1, @ExtIdx) + '_' + SUBSTRING((REPLACE(REPLACE(REPLACE((CONVERT(VARCHAR(32), GETDATE(), 120)), '-', ''), ' ', ''), ':', '')), 1, 12) + SUBSTRING(@NewFileName, (@ExtIdx + 1), 999)

        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Rename the file
    SELECT @OS_Cmd = 'RENAME "' + @Folder + @FileName + '" "' + @NewFileName + '"'

    IF @Debug = 1
        BEGIN
            PRINT 'Rename Command ' + @OS_Cmd
            SELECT @OS_Cmd AS [Rename Command]
        END

    EXECUTE dbo.pr_SetCMDShell 1, @xpShellStatus OUTPUT
    EXECUTE master.dbo.xp_cmdshell @OS_Cmd
    EXECUTE dbo.pr_SetCMDShell @xpShellStatus

    IF @Debug = 1
        BEGIN
            PRINT 'Rename Completed'
            SELECT 'Rename Completed' AS Message
        END
    -- ******************************************************************************************


END

GO

IF dbo.fn_SQLVersion()  >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_RenameFile]') AND type in (N'P', N'PC'))
            BEGIN
                PRINT 'Procedure Created [pr_RenameFile] - SQL 2005'
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'pr_RenameFile' AND type in (N'P', N'PC'))
            BEGIN
                PRINT 'Procedure Created [pr_RenameFile] - SQL 2000'
            END
    END

GO