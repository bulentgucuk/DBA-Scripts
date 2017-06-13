USE DBAdmin
GO
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OpenDPBack0050_RepToBP60d]') AND type in (N'P', N'PC'))
BEGIN
    EXEC( 'CREATE PROCEDURE [dbo].[OpenDPBack0050_RepToBP60d] AS' )
END
GO


ALTER PROCEDURE dbo.OpenDPBack0050_RepToBP60d ( 
    @Status int =0 OUTPUT)
WITH ENCRYPTION, RECOMPILE --, execute as 'webprod\iusr_sql_service'
AS
/*
Procedure: openSPBackup_RepToBP15d
Purpose:  Opens connection to backup domian & path \\DPBACK0050.web.prod\RepToBP15d

Sample Call:
BEGIN
DECLARE @status INT =0
EXEC dbadmin.dbo.OpenDPBack0050_RepToBP60d @status=@status OUTPUT
END
IF (SELECT @status ) <> 0 
 BEGIN
   RAISERROR('50005 Connection to DataDomain Failed',16, -1, @@SERVERNAME )
   GOTO EXITT
 END
 ELSE
 BEGIN
 EXECUTE dbadmin.dbo.[pr_DatabaseBackup]
        @DBGroup = NULL,                           -- OPTIONAL. User / System / All / [NULL]. Over-rides @IncludeDBs
        @IncludeDBs = 'dbadmin',                            -- OPTIONAL. Comma-separated list of database to include. @DBGroup *or* @IncludeDBs must be entered.
        @ExcludeDBs = NULL,                            -- OPTIONAL. Comma-separated list of database to exclude, operates in conjunction with @DBGroup.
        @BackupFolder = '\\DPBACK0050.web.prod\RepToBP60d\SERVERNAME',     -- REQUIRED. Target Folder, should NOT include DB specific folder - use @CreateSubFolder.
        @FileSuffix = NULL,                            -- OPTIONAL. BAK / DIF / TRN / [NULL], will default based on @BackupType if omitted.
        @BackupType = 'TLog',                        -- OPTIONAL. Full / Diff / TLog, will default to Full if omitted.
        @CreateSubFolder = 1,                          -- OPTIONAL. Create sub-folders for each database, defaults to 1 (Yes).
        @VerifyBackup = 1,                             -- OPTIONAL. Should the Backups be verified.
        @Debug = 0,                                    -- OPTIONAL. Display Debug information, defaults to 0 (No).
        @NativeCompression = 1                         -- OPTIONAL. For SQL 2008 ONLY, use Compression for Native Backups
 END
 
 EXITT:
*/

SET NOCOUNT ON
DECLARE @cmdline VARCHAR(500),
        @ReturnCode INT,
        @ErrorMessage varchar(500)
 
--Command to execute
SELECT @cmdline ='Net use \\DPBACK0050.web.prod\RepToBP60d Fr0Ntr@nG3!! /USER:web.prod\svc_SQL_DD /PERSISTENT:YES';
 
--Create temp table to hold result
CREATE TABLE #CmdShellLog (CmdShellMessage VARCHAR(500) NULL)
 
--dump result into temp table
INSERT #CmdShellLog
EXEC @ReturnCode = master.dbo.xp_cmdshell @cmdline

-- If we have an error populate variable
IF @ReturnCode <> 0
    BEGIN
        SELECT @ErrorMessage = CmdShellMessage  
        FROM #CmdShellLog
        WHERE CmdShellMessage IS NOT NULL
     
        --Display error message and return code
        --SELECT @ErrorMessage as ErrorMessage  ,@ReturnCode as ReturnCode
        
        RAISERROR(@ErrorMessage,16,1)
        SELECT @Status=@ReturnCode
    END
ELSE
    BEGIN
        -- statement to run
        --PRINT 'IF XP_CMDSHELL IS SUCCESS YOU SHOULD SEE THIS'
        SELECT @Status=@ReturnCode
    END

-- drop temp table
DROP TABLE #CmdShellLog
GO
