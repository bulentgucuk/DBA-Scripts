USE [DBAdmin]
GO
IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[lp_DeleteFiles]') AND type in (N'P', N'PC'))
            BEGIN
                PRINT 'Dropping procedure [lp_DeleteFiles] - SQL 2005'
                DROP PROCEDURE [dbo].[lp_DeleteFiles]
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'lp_DeleteFiles' AND type in (N'P', N'PC'))
            BEGIN
                PRINT 'Dropping procedure [lp_DeleteFiles] - SQL 2000'
                DROP PROCEDURE [dbo].[lp_DeleteFiles]
            END
    END

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_DeleteFiles]') AND type in (N'P', N'PC'))
            BEGIN
                PRINT 'Dropping procedure [pr_DeleteFiles] - SQL 2005'
                DROP PROCEDURE [dbo].[pr_DeleteFiles]
            END
    END
ELSE
    BEGIN
        IF  EXISTS (SELECT * FROM sysobjects WHERE name = 'pr_DeleteFiles' AND type in (N'P', N'PC'))
            BEGIN
                PRINT 'Dropping procedure [pr_DeleteFiles] - SQL 2000'
                DROP PROCEDURE [dbo].[pr_DeleteFiles]
            END
    END

GO
/****** Object:  StoredProcedure [dbo].[pr_DeleteFiles]    Script Date: 1/25/2013 1:52:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[pr_DeleteFiles]
(
    @RootFolder                 VARCHAR(128) = NULL,
    @FileSuffix                 VARCHAR(8)   = NULL,
    @ProcessSubFolders          BIT          = 0,
    @CutOffDate                 DATETIME     = NULL,
    @CutOffDays                 INT          = NULL,
    @ForceDeleteForReadonly     BIT          = 0,
    @Debug                      BIT          = 0,
    @DOSDateFormat              INT          = 101,
    @OnlyDeleteArchived         BIT          = 1
)

-- --------------------------------------------------------------------------------------------------
--  Procedure   :   [pr_DeleteFiles]
--  Description :   To scan all files in a folder and delete the files that are older than the
--                  specified date.
--                  Requires xp_cmdshell be enabled.
--  Parameters   RootFolder             The folder to search for files to delete.
--                                      REQUIRED.
--               FileSuffix             Define the files to delete by file suffix,
--                                      ALL files are processed if NULL / '*' / BLANK.
--                                      OPTIONAL - defaults to NULL
--               ProcessSubFolder       Switch to determine if the process should delete from
--                                      subfolders.
--                                      OPTIONAL - defaults to 0 (No).
--               CutOffDate             Date which files must be older than for the process to
--                                      delete.
--                                      OPTIONAL - defaults to NULL.
--               CutOffDays             Age (in days) that files must be older than for the
--                                      process to delete.
--                                      Value is always converted to 'Days Ago', whether +ve
--                                      or -ve value entered.
--                                      Value overrides CutOffDate, if both entered.
--                                      OPTIONAL - defaults to NULL.
--                                      NOTE - Either CutOffDate or CutOffDays is REQUIRED.
--               ForceDeleteForReadOnly Switch to determine if the process should delete even
--                                      if the file is READ-ONLY.
--                                      OPTIONAL - defaults to 0 (No).
--               Debug                  Switch to determine if debugging information should be output
--                                      OPTIONAL - defaults to 0 (No).
--               DOSDateFormat          Specify the Date Format for File Dates from the DIR command,
--                                      specify as per BOL / Format article.
--                                      OPTIONAL - Defaults to NULL, only sepcify if Non-US format.
--               OnlyDeleteArchived     Switch to specify whether to only delete files that have 
--                                      the Archive flag reset.
--                                      OPTIONAL - Defaults to 1 (Yes - Only delete files with Archive bit Reset)
--
--
--  Modification Log
--  When            Who             Description
--  02/27/2007      Simon Facer     Original Version
--  10/09/2007      Simon Facer     Add logic to delete files without a suffix.
--  10/16/2007      Simon Facer     Add logic to handle File Dates without a trailing 'm', as in 
--                                    '10/14/2007  06:00p          34,172,416 ATC_Nevada_Data.DIFF'
--  03/31/2008      David Creighton Added references to pr_SetCMDShell
--  06/03/2008      David Creighton Added parameter and processing to handle British DOS file dates.
--  11/25/2008      Simon Facer     Increased column sizes in #Files table.
--  06/15/2010      Derek Adams     Added the @OnlyDeleteArchived parameter to allow the deletes to be
--                                  filtered by whether the file was backed up to tape or not.
--  08/17/2010      Simon Facer     Remove entries from #Files for File Not Found condition - 
--                                  'VOLUME' and 'FILE NOT FOUND' literals
--	01/25/2013		SGB				Added OR DirResult = 'The system cannot find the path specified.' to line 183
-- --------------------------------------------------------------------------------------------------

AS

BEGIN

    DECLARE @OS_Cmd             VARCHAR(1024)
    DECLARE @FileID             INT
    DECLARE @FileIDMin          INT
    DECLARE @FileIDMax          INT
    DECLARE @Folder             VARCHAR(128)
    DECLARE @CmdShell           BIT

    CREATE TABLE #Files
        (
          FileID        INT IDENTITY(1, 1)  NOT NULL,
          Folder        VARCHAR(512)        NULL,
          FileName      VARCHAR(512)        NULL,
          FileExtension VARCHAR(512)        NULL,
          FileDate      DATETIME            NULL,
          DirResult     VARCHAR(1024)       NULL
        )

    SET NOCOUNT ON

    IF @Debug = 1
        BEGIN
            SELECT 'Parameters',
                    @RootFolder                 AS RootFolder,
                    @FileSuffix                 AS FileSuffix,
                    @ProcessSubFolders          AS ProcessSubFolders,
                    @CutOffDate                 AS CutOffDate,
                    @CutOffDays                 AS CutOffDays,
                    @ForceDeleteForReadonly     AS ForceDeleteForReadonly,
                    @Debug                      as Debug
        END


    -- ******************************************************************************************
    -- Validate the passed parameters
    IF ( @RootFolder = '' )
        OR ( @CutOffDate IS NULL
             AND @CutOffDays IS NULL
           )
        BEGIN
            SELECT  'Root Folder and CutOffDays / CutOffDate must be passed in'
            RAISERROR ('Root Folder and CutOffDays / CutOffDate must be passed in', 16, 1)
            RETURN
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Get the DIR results into the table
    SELECT  @OS_Cmd = 'DIR ' + 
                      CASE 
                          WHEN @OnlyDeleteArchived = 1 THEN '/A:-A ' 
                          ELSE '' 
                      END + 
                      '"' + @RootFolder + '" ' + 
                      CASE @ProcessSubFolders
                          WHEN 1 THEN ' /S'
                          ELSE ' '
                      END

    IF @Debug = 1
        BEGIN
            PRINT 'DIR Command ' + @OS_Cmd
        END

    EXEC pr_SetCMDShell 1, @CmdShell OUTPUT
    INSERT  #Files ( DirResult )
    EXECUTE master.dbo.xp_cmdshell @OS_Cmd
    EXEC pr_SetCMDShell @CmdShell
    -- ******************************************************************************************

    IF @Debug = 1
        BEGIN
            PRINT 'Completed DIR Command'
            SELECT 'DIR Output', *
                FROM #Files
        END

    -- ******************************************************************************************
    -- Locate the first 'Directory Of' entry
    SELECT  @FileIDMin = MIN(FileID)
        FROM    #Files
        WHERE   CHARINDEX('DIRECTORY OF', UPPER(DirResult)) > 0
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Find the last File(s) entry
    SELECT  @FileIDMax = MAX(FileID)
        FROM    #Files
        WHERE   CHARINDEX('FILE(S)', UPPER(DirResult)) > 0
                AND FileID < ( SELECT   MAX(FileID)
                                   FROM     #Files
                                   WHERE    CHARINDEX('FILE(S)', UPPER(DirResult)) > 0
                             )
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Delete the entries we dont need
    DELETE  #Files
        WHERE   FileID < @FileIDMin
                OR DirResult IS NULL
                OR CHARINDEX('<DIR>', UPPER(DirResult)) > 0
                OR CHARINDEX('FILE(S)', UPPER(DirResult)) > 0
                OR CHARINDEX('DIR(S)', UPPER(DirResult)) > 0
                OR LEFT((LTRIM(UPPER(DirResult))), 6) = 'VOLUME'
                OR LEFT((LTRIM(UPPER(DirResult))), 14) = 'FILE NOT FOUND'
                OR FileID > @FileIDMax
				OR DirResult = 'The system cannot find the path specified.'  -- SGB 01/25/2013 
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Find the Folders in the remaining output
    UPDATE  #Files
        SET     Folder = LTRIM(RTRIM(REPLACE(DirResult, 'Directory of ', ''))),
                DirResult = NULL
        WHERE   CHARINDEX('DIRECTORY OF', UPPER(DirResult)) > 0
    -- ******************************************************************************************

    IF @Debug = 1
        BEGIN
            PRINT 'About to Start Loop to Populate Folders '
            SELECT 'Populate Folders Loop Processing Start', *
                FROM #Files
        END

    -- ******************************************************************************************
    -- Loop through the output to populate the Folders
    WHILE EXISTS ( SELECT   *
                       FROM     #Files
                       WHERE    Folder IS NULL )
        BEGIN
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Find the first Folder entry
            SELECT  @FileIDMin = MIN(FileID)
                FROM    #Files
                WHERE   Folder IS NULL
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Find the next folder entry, or a dummy entry past the end of the table
            SELECT  @FileIDMax = COALESCE(MIN(FileID), 999999)
                FROM    #Files
                WHERE   Folder IS NOT NULL
                  AND   FileID > @FileIDMin
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Get the folder value for this loop
            SELECT  @Folder = Folder
                FROM    #Files
                WHERE   FileID = ( SELECT   MAX(FileID)
                                       FROM     #Files
                                       WHERE    FileID < @FileIDMin
                                 )
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Set the folder value for the files in this group
            UPDATE  #Files
                SET     Folder = @Folder
                WHERE   FileID BETWEEN @FileIDMin AND @FileIDMax
                  AND   Folder IS NULL
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- End of the loop
        END
    -- ******************************************************************************************

    IF @Debug = 1
        BEGIN
            PRINT 'Completed Loop to Populate Folders '
            SELECT 'Populate Folders Loop Processing Completed', *
                FROM #Files
        END

    -- ******************************************************************************************
    -- Delete the Folder rows
    DELETE  #Files
        WHERE   DirResult IS NULL
    -- ******************************************************************************************

    IF @Debug = 1
        BEGIN
            PRINT 'DOS File Date Format: ' + CAST(@DOSDateFormat AS VARCHAR)
            SELECT 'DOS File Date Format', *
                FROM #Files
        END

    -- ******************************************************************************************
    -- Get the OS File Date/Time
    UPDATE  #Files
        SET     FileDate = CONVERT(DATETIME, (LTRIM(RTRIM(SUBSTRING(DirResult, 1, 20))) +
                                 CASE 
                                     WHEN UPPER(RIGHT((LTRIM(RTRIM(SUBSTRING(DirResult, 1, 20)))), 1)) = 'A'
                                         THEN 'M'
                                     WHEN UPPER(RIGHT((LTRIM(RTRIM(SUBSTRING(DirResult, 1, 20)))), 1)) = 'P'
                                         THEN 'M'
                                     ELSE ''
                                 END), @DOSDateFormat),
                DirResult = LTRIM(RTRIM(SUBSTRING(DirResult, 21, 512)))
    -- ******************************************************************************************


    -- ******************************************************************************************
    -- Get the filename from the DirResult field
    UPDATE  #Files
        SET     FileName = LTRIM(RTRIM(SUBSTRING(DirResult,
                                                 ( CHARINDEX(' ', DirResult) ), 512)))
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Delete the entries without a file extension
    DELETE #Files
        WHERE CHARINDEX('.', FileName) = 0
    -- ******************************************************************************************

    IF @Debug = 1
        BEGIN
            PRINT 'Pre-Extract File Extensions '
            SELECT 'Pre-Extract File Extensions', 
                    FileExtension = SUBSTRING(FileName,
                                          ( LEN(FileName) - ( CHARINDEX('.', ( REVERSE(FileName) )) - 2 ) ),
                                          ( CHARINDEX('.', ( REVERSE(FileName) )) - 1 )),
                    FileExtensionLen = LEN(SUBSTRING(FileName,
                                          ( LEN(FileName) - ( CHARINDEX('.', ( REVERSE(FileName) )) - 2 ) ),
                                          ( CHARINDEX('.', ( REVERSE(FileName) )) - 1 ))),
                    *
                FROM #Files
                ORDER BY LEN(SUBSTRING(FileName,
                                          ( LEN(FileName) - ( CHARINDEX('.', ( REVERSE(FileName) )) - 2 ) ),
                                          ( CHARINDEX('.', ( REVERSE(FileName) )) - 1 ))) DESC,
                         SUBSTRING(FileName,
                                          ( LEN(FileName) - ( CHARINDEX('.', ( REVERSE(FileName) )) - 2 ) ),
                                          ( CHARINDEX('.', ( REVERSE(FileName) )) - 1 )) ASC
        END

    -- ******************************************************************************************
    -- Get the file extension from the filename
    UPDATE  #Files
        SET     FileExtension = SUBSTRING(FileName,
                                          ( LEN(FileName) - ( CHARINDEX('.', ( REVERSE(FileName) )) - 2 ) ),
                                          ( CHARINDEX('.', ( REVERSE(FileName) )) - 1 ))
    -- ******************************************************************************************

    IF @Debug = 1
        BEGIN
            PRINT 'Extracted File Extensions '
            SELECT 'Extracted File Extensions', *
                FROM #Files
        END

    -- ******************************************************************************************
    -- If a File Extension was passed in, delete the file names we aren't interested in
    IF @FileSuffix IS NOT NULL
        AND @FileSuffix != '*'
        AND LTRIM(RTRIM(@FileSuffix)) != ''
        BEGIN
            DELETE  #Files
                WHERE   FileExtension != @FileSuffix
        END
    -- ******************************************************************************************

    IF @Debug = 1
        BEGIN
            PRINT 'Final File List With Extensions'
            SELECT 'Final File List With Extensions', *
                FROM #Files
        END

    -- ******************************************************************************************
    -- Default the DirResult to NULL
    UPDATE  #Files
        SET     DirResult = NULL
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If there is a Date/Time value in the file name, extract it
    -- Regular expression for '20YYMMDD HHNN', where YY Between 00 AND 19
    UPDATE  #Files
        SET     DirResult = '~1~' + SUBSTRING(FileName,
                                              PATINDEX('%20[01][0123456789][01][0123456789][0123][0123456789][ _][012][0123456789][012345][0123456789]%',
                                                       FileName), 13)
        WHERE   PATINDEX('%20[01][0123456789][01][0123456789][0123][0123456789][ _][012][0123456789][012345][0123456789]%',
                         FileName) > 0
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If there is a Date/Time value in the file name, extract it
    -- Regular expression for 'MMDD20YY HHNN', where YY Between 00 AND 19
    UPDATE  #Files
        SET     DirResult = '~2~' + SUBSTRING(FileName,
                                              PATINDEX('%[01][0123456789][0123][0123456789]20[01][0123456789][ _][012][0123456789][012345][0123456789]%',
                                                       FileName), 13)
        WHERE   PATINDEX('%[01][0123456789][0123][0123456789]20[01][0123456789][ _][012][0123456789][012345][0123456789]%',
                         FileName) > 0
          AND   DirResult IS NULL
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If there is a Date value in the file name, extract it
    -- Regular expression for '20YYMMDD', where YY Between 00 AND 19
    UPDATE  #Files
        SET     DirResult = '~3~' + SUBSTRING(FileName,
                                              PATINDEX('%20[01][0123456789][01][0123456789][0123][0123456789]%',
                                                       FileName), 8)
        WHERE   PATINDEX('%20[01][0123456789][01][0123456789][0123][0123456789]%',
                         FileName) > 0
          AND   DirResult IS NULL
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If there is a Date value in the file name, extract it
    -- Regular expression for 'MMDD20YY', where YY Between 00 AND 19
    UPDATE  #Files
        SET     DirResult = '~4~' + SUBSTRING(FileName,
                                              PATINDEX('%[01][0123456789][0123][0123456789]20[01][0123456789]%',
                                                       FileName), 8)
        WHERE   PATINDEX('%[01][0123456789][0123][0123456789]20[01][0123456789]%',
                         FileName) > 0
          AND   DirResult IS NULL
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Reformat the dates to include / and : characters (1)
    UPDATE  #Files
        SET     DirResult = SUBSTRING(DirResult, 4, 4) + '/' + SUBSTRING(DirResult, 8, 2)
                + '/' + SUBSTRING(DirResult, 10, 2) + ' ' + SUBSTRING(DirResult, 13, 2)
                + ':' + SUBSTRING(DirResult, 15, 2)
        WHERE   SUBSTRING(DirResult, 1, 3) = '~1~'
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Reformat the dates to include / and : characters (2)
    UPDATE  #Files
        SET     DirResult = SUBSTRING(DirResult, 4, 2) + '/' + SUBSTRING(DirResult, 6, 2)
                + '/' + SUBSTRING(DirResult, 8, 4) + ' ' + SUBSTRING(DirResult, 13, 2)
                + ':' + SUBSTRING(DirResult, 15, 2)
        WHERE   SUBSTRING(DirResult, 1, 3) = '~2~'
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Reformat the dates to include / and : characters (3)
    UPDATE  #Files
        SET     DirResult = SUBSTRING(DirResult, 4, 4) + '/' + SUBSTRING(DirResult, 8, 2)
                + '/' + SUBSTRING(DirResult, 10, 2)
        WHERE   SUBSTRING(DirResult, 1, 3) = '~3~'
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Reformat the dates to include / and : characters (4)
    UPDATE  #Files
        SET     DirResult = SUBSTRING(DirResult, 4, 2) + '/' + SUBSTRING(DirResult, 6, 2)
                + '/' + SUBSTRING(DirResult, 8, 4)
        WHERE   SUBSTRING(DirResult, 1, 3) = '~4~'
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- The File Date overrides the OS File date
    UPDATE  #Files
        SET     FileDate = CAST(DirResult AS DATETIME)
        WHERE   ISDATE(DirResult) = 1
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Calculate the CutOffDate, if CutOffDays was passed in
    IF @CutOffDays IS NOT NULL
        AND @CutOffDays != 0
        BEGIN
            IF @CutOffDays > 0
                BEGIN
                    SELECT  @CutOffDays = -1 * @CutOffDays
                END
            SELECT  @CutOffDate = DATEADD(DAY, @CutOffDays, GETDATE())
        END
    -- ******************************************************************************************

    IF @Debug = 1
        BEGIN
            PRINT 'CutOff Date' + CONVERT(VARCHAR(32), @CutOffDate)
            SELECT 'CutOff Date', @CutOffDate AS CutOffDate
        END

    -- ******************************************************************************************
    -- Get rid of the rows where the FileDate isn't outside the cutoff
    IF @Debug = 1
        BEGIN
            PRINT 'File List before CutOff date applied'
            SELECT 'File List before CutOff date applied', *
                FROM #Files
        END

    DELETE  #Files
        WHERE   FileDate !< @CutOffDate

    IF @Debug = 1
        BEGIN
            PRINT 'File List with CutOff date applied'
            SELECT 'File List with CutOff date applied', *
                FROM #Files
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Loop through the files to be deleted
    WHILE EXISTS ( SELECT   *
                       FROM     #Files )
        BEGIN
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Generate the DELETE command for the current file
            SET ROWCOUNT 1
            SELECT  @OS_Cmd = 'DEL /Q' +
                        CASE @ForceDeleteForReadonly
                            WHEN 0 THEN ' '
                            ELSE ' /F '
                        END +
                        '"' + Folder + '\' + FileName + '" ',
                    @FileID = FileID
            FROM    #Files
            SET ROWCOUNT 0
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Delete the file
            IF @Debug = 1
                BEGIN
                    PRINT 'Delete Command ' + @OS_Cmd
                    SELECT 'Delete Command', @OS_Cmd
                END

            EXEC pr_SetCMDShell 1, @CmdShell OUTPUT
            EXECUTE master.dbo.xp_cmdshell @OS_Cmd
            EXEC pr_SetCMDShell @CmdShell
            --PRINT @OS_Cmd

            IF @Debug = 1
                BEGIN
                    PRINT 'Delete Completed'
                END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Delete the row just processed
            DELETE  #Files
               WHERE   FileID = @FileID
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- End of WHILE loop
        END
    -- ******************************************************************************************

END


GO


