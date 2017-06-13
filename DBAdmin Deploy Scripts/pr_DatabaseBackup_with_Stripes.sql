USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[pr_DatabaseBackup]    Script Date: 05/21/2013 14:25:35 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_DatabaseBackup]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[pr_DatabaseBackup]
GO

USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[pr_DatabaseBackup]    Script Date: 05/21/2013 14:25:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE PROCEDURE [dbo].[pr_DatabaseBackup]
(

    @DBGroup                    VARCHAR(16)   = NULL,
    @IncludeDBs                 VARCHAR(2048) = NULL,
    @ExcludeDBs                 VARCHAR(2048) = NULL,
    @BackupFolder               VARCHAR(256),
    @MirrorToFolder             VARCHAR(1024)  = NULL,
    @StripeToFolder             VARCHAR(1024)  = NULL,
    @StripeCPUBased				BIT			  = 0,
    @RemoveTimeStampFromFileName BIT		  = 0,
    @FileSuffix                 VARCHAR(8)    = NULL,
    @BackupType                 VARCHAR(8)    = 'FULL',
    @CreateSubFolder            BIT           = 1,
    @VerifyBackup               BIT           = 1,
    @Debug                      BIT           = 0,
    @LTSPBackup                 BIT           = 0,
    @LTSPCompressionLevel       INT           = 1,
    @LTSPThreads                INT           = 3,
    @LTSPThrottle               INT           = 75,
    @NativeCompression          BIT           = 1
)

AS
-- ------------------------------------------------------------------------------------------------------------------
--  Procedure   :   [pr_DatabaseBackup]
--  Description :   To backup the specified databases.
--  Parameters   DBGroup                The group of dataabses to backup - System or User
--                                      OPTIONAL - defaults to NULL.
--               IncludeDBs             Databases to be included, Ignored if DBGroup set.
--                                      MUST be comma-separated.
--                                      OPTIONAL - defaults to NULL.
--                                      NOTE - Either DBGroup or IncludeDBs is REQUIRED.
--               ExcludeDBs             Databases to Exclude from DBGroup, ignored if IncludeDBs set.
--                                      MUST be comma-separated.
--                                      OPTIONAL - defaults to NULL.
--               BackupFolder           Where to put the Backups.
--                                      REQUIRED.
--				 MirrorToFolder			OPTIONAL - It's used to create mirror copies of the backup file, and list of path can be provided as
--										comma seperated values with no space in between.  The proc will exist if both MirrorToFolder
--										and @StripeToFolder parameters have values passed in.  This makes building the backup command
--										harder.
--				 @StripeToFolder		OPTIONAL - It's used to create striped set of backups based on the list of folders, and the list can 
--										be provided as comma seperated values with no space in between.  The proc will exit if both MirrorToFolder
--										and @StripeToFolder parameters have values passed in.  This makes building the backup command
--										harder.
--				 @StripeCPUBased		OPTIONAL - It's used to create striped set of backups based on the logical number of CPUs, the proc will exit
--										if both @StripeCPUBased and @StripeToFolder parameters have values passed in.  This makes building the backup command
--										harder.
--				 RemoveTimeStampFromFileName	OPTIONAL - Being used to remove the time stamp from the backup file name.
--										DEFAULT 0 retains the time stamp and if value 1 passed in it removes the time stamp.
--               FileSuffix             Suffix to apply to the file, if this is missing, the suffix
--                                      will be set based  on the backup type.
--                                      Defaulted values :
--                                          Full backup : BAK
--                                          Diff backup : DIF
--                                          TLog backup : TRN
--                                      OPTIONAL - defaults to NULL.
--               BackupType             What kind of backup to process.
--                                      Possible values (case-insensitive):
--                                          Full
--                                          Diff
--                                          TLog
--                                      OPTIONAL - defaults to 'Full'.
--               CreateSubFolder        Should each backup be placed in its own folder under BackupFolder.
--                                      OPTIONAL - defaults to 1 (Yes).
--               VerifyBackup           Should the Backups be verified.
--                                      OPTIONAL - defaults to 1 (Yes).
--               Debug                  Switch to determine if debugging information should be output
--                                      OPTIONAL - defaults to 0 (No).
--               LSBackup               Switch to indicate Litespeed should be used for backup
--                                      OPTIONAL - defaults to 0 (No)
--               LSCompressionLevel     Compression level for Litespeed backup
--                                      Set the compression level for the backup. Valid values are 0 through 11, 
--                                      where 0 bypasses the compression routines, 1 is the default value, and 
--                                      increasing values represent more aggressive compression.
--                                      OPTIONAL - defaults to 5. Ignored unless LSBackup is 1 (true)
--               LSThreads              Number of threads to use for Litespeed backup
--                                      Determines the number of threads used for the backup. 
--                                      Best results have been identified at 2-3 for a multi processor server.
--                                      Use n-1 threads for n processors.
--                                      OPTIONAL - defaults to 3. Ignored unless LSBackup is 1 (true)
--               LSThrottle             The throttle value 
--                                      Specifies, as a percentage, the maximum CPU usage allowed.
--                                      It is an integer value between 1 and 100. Default value is 100%
--                                      OPTIONAL - defaults to 50. Ignored unless LSBackup is 1 (true)
--               NativeCompression      Switch for Compression, for Native Backups under SQL 2008 only
--                                      OPTIONAL - defaults to 1 (Yes).
--
-- ------------------------------------------------------------------------------------------------------------------
--  Modification Log
--  When            Who             Description
--  10/01/2007      Simon Facer     Original Version
--  10/19/2007      Simon Facer     Added '[' and ']' brackets to database name in the BACKUP commands
--  11/07/2007      Simon Facer     Added Verify Backup option
--  12/14/2007      Simon Facer     Added logic to check for a previous Full Backup if a Differential
--                                  backup was requested, and default to a Full backup if no previous
--                                  Full backup exists.
--  03/31/2008      David Creighton Added a filter to remove offline databases from the backup list.
--  04/04/2008      David Creighton Added support for Litespeed backups.
--  04/07/2008      David Creighton Modified the way the backup path if specified for detection of existence
--  06/15/2008      David Creighton Changed filter to remove offline databases so that it would remove
--                                  any database that is not ONLINE.
--  12/18/2008      Simon Facer     Abstracted the 'EXEC @SQLCmd' to a Function to allow for version
--                                  specific error handling.
--                                  Added logic to force a Full backup if a T-Log is requested
--                                  without a prior Full.
--  02/01/2009      Simon Facer     Changed LTSP defaults to:
--                                    @LTSPCompressionLevel       1     was 2
--                                    @LTSPThrottle               80    was 50
--  05/26/2009      Simon Facer     Changed the code to check for Simple database mode to be Case-Insensitive.
--  10/16/2009      Simon Facer     Added Compression option for SQL 2008
--  11/23/2009      Simon Facer     Changed NativeCompression default to 1
--  01/12/2010      Simon Facer     Changed NativeCompression to OFF for Edition <> Enterprise / Developer
--  04/28/2010      David Creighton Changed the value of the description column for backups to be the filename.
--  07/23/2010      Simon Facer     Changed how @IncludeDBs and @ExcludeDBs are processed to allow wildcards.
--                                  This requires pivoting the data into a table, and using LIKE predicates
--                                  to process the lists. ~ is used as an Escape character.
--                                  This changes how @ExcludeDBs works, it is now applied to @IncludeDBs as well as
--                                  to @DBGroup.
--  07/26/2010      Simon Facer     BUG FIX - If a database name has a space at the end, the path\file name 
--                                  generated will break the processing. TRIM the substituted value to resolve
--                                  the bug.
--  10/20/2010      Derek Adams     If "User" or "System" were specified for @DBGroup, @IncludeDBs was ignored 
--                                  by design. Changed to use @DBGroup as an additional filter.
--  09/27/2011      Derek Adams     Extended the maximum database size to 128 characters 
--                                  
--  09/23/2012      David Creighton Fixed a but regarding output from pr_PathExists and added a RAISERROR condition.
--	05/21/2013		Bulent Gucuk	Enhanced the process to create mirrored or striped backup files
-- ------------------------------------------------------------------------------------------------------------------

BEGIN

SET NOCOUNT ON
	-- IF BOTH MIRROR TO AND STRIPE TO PASSED IN EXIST AND DO NOT BACKUP BUILDING THE COMMAND IS COMPLICATED
	-- AND REQUIRES TIME TO INVEST FOR THE ENHANCEMENT
    IF @MirrorToFolder IS NOT NULL AND @StripeToFolder IS NOT NULL
        BEGIN
            RAISERROR ('Can not create mirrored copies and Stripe Backup at the same time', 16, 1)
            RETURN
        END

    IF @StripeToFolder IS NOT NULL AND @StripeCPUBased = 1
        BEGIN
            RAISERROR ('Choose only one method of backup striping either stripecpubases or stripetofolder', 16, 1)
            RETURN
        END


    IF @Debug = 1
        BEGIN
            SELECT 'Parameters',
                    @DBGroup                    AS DBGroup,
                    @IncludeDBs                 AS IncludeDBs,
                    @ExcludeDBs                 AS ExcludeDBs,
                    @BackupFolder               AS BackupFolder,
                    @FileSuffix                 AS FileSuffix,
                    @BackupType                 AS BackupType,
                    @CreateSubFolder            AS CreateSubFolder,
                    @VerifyBackup               AS VerifyBackup,
                    @Debug                      AS Debug,
                    @LTSPBackup                 AS LSBackup,
                    @LTSPCompressionLevel       AS LSCompressionLevel,
                    @LTSPThreads                AS LSThreads,
                    @LTSPThrottle               AS LSThrottle,
                    @NativeCompression          AS NativeCompression
        END

    -- ******************************************************************************************
    -- Declare local variables
    DECLARE @SQLVersion             INT
    DECLARE @SQL_Cmd                VARCHAR(1024)
    DECLARE @OS_Cmd                 VARCHAR(1024)
    DECLARE @FileID                 INT
    DECLARE @FileIDMin              INT
    DECLARE @FileIDMax              INT
    DECLARE @Folder                 VARCHAR(128)
    DECLARE @TimeStamp              VARCHAR(32)
    DECLARE @DBName                 VARCHAR(128)
    DECLARE @FullBackupDate         DATETIME
    DECLARE @FileSuffix_Work        VARCHAR(8)
    DECLARE @RC                     INT
    DECLARE @ProcName               VARCHAR(128)
    DECLARE @StrEnd                 INT
    ---------------------------------------------
    -- Added by DJC on 9/23/2012
    DECLARE @PathExists INT
    DECLARE @ErrorMsg VARCHAR(1024)
    ---------------------------------------------

    DECLARE @CompressionOption      VARCHAR(32)
    
    DECLARE @FullBackupBase         VARCHAR(1024)
    DECLARE @DiffBackupBase         VARCHAR(1024)
    DECLARE @TLogBackupBase         VARCHAR(1024)
    DECLARE @VerifyBase             VARCHAR(1024)
    DECLARE @LTSPBase               VARCHAR(1024)
    DECLARE @LTSPFullBase           VARCHAR(1024)
    DECLARE @LTSPDiffBase           VARCHAR(1024)
    DECLARE @LTSPTLogBase           VARCHAR(1024)
    DECLARE @LTSPVerifyBase         VARCHAR(1024)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Create the # temp table to identify the databases to be backed up
    IF OBJECT_ID('Tempdb..#Databases') IS NOT NULL
		BEGIN
			DROP TABLE #Databases
		END
    CREATE TABLE #Databases
        (DBName                     VARCHAR(128),
         StateDesc                  VARCHAR(128),
         Recovery_Model_Desc        VARCHAR(128),
         LastFullBackupDate         DATETIME
        )
        
    -- Create the # temp table to identify the databases to be Included
    IF OBJECT_ID('Tempdb..#IncludeDBs') IS NOT NULL
		BEGIN
			DROP TABLE #IncludeDBs
		END
    CREATE TABLE #IncludeDBs (
        DatabaseName                VARCHAR(128) )        
        
    -- Create the # temp table to identify the databases to be Excluded
    IF OBJECT_ID('Tempdb..#ExcludeDBs') IS NOT NULL
	BEGIN
		DROP TABLE #ExcludeDBs
	END
    CREATE TABLE #ExcludeDBs (
        DatabaseName                VARCHAR(128) )        
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Determine the target SQL Server's version,
    --      8 = 2000
    --      9 = 2005
    --      10 = 2008 
    SELECT @SQLVersion = dbo.fn_SQLVersion()
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Validate the passed parameters
    -- (1) Required parameters
    IF ( LTRIM(RTRIM(@BackupFolder)) = '' )
        OR (     (@DBGroup IS NULL    OR LTRIM(@DBGroup) = '')
             AND (@IncludeDBs IS NULL OR LTRIM(@IncludeDBs) = '')
           )
        BEGIN
            SELECT  'Backup Folder and DBGroup / IncludeDBs must be passed in'
            RAISERROR ('Backup Folder and DBGroup / IncludeDBs must be passed in', 16, 1)
            RETURN
        END

    -- (2) Valid DBGroup
    IF @DBGroup IS NOT NULL
        BEGIN
            IF @DBGroup != 'System' AND
               @DBGroup != 'User' AND
               @DBGroup != 'All' AND
               LTRIM(@DBGroup) != ''
                BEGIN
                    SELECT  'DBGroup must be System, User or All'
                    RAISERROR ('DBGroup must be either System, User or All', 16, 1)
                    RETURN
                END
        END

    -- (3) Valid BackupType
    IF @DBGroup IS NOT NULL
        BEGIN
            IF @BackupType != 'Full' AND
               @BackupType != 'Diff' AND
               @BackupType != 'TLog'
                BEGIN
                    SELECT  'BackupType must be one of Full / Diff / TLog'
                    RAISERROR ('BackupType must be one of Full / Diff / TLog', 16, 1)
                    RETURN
                END
        END
    
    -- (4) Litespeed parameters
    IF (@LTSPBackup = 1)
        BEGIN
            IF (@LTSPCompressionLevel NOT BETWEEN 0 AND 11)
            BEGIN
                SELECT 'Litespeed Compression Level must be between 0 and 11 inclusive'
                RAISERROR ('Litespeed Compression Level must be between 0 and 11 inclusive', 16, 1)
                RETURN
            END
            
            IF (@LTSPThreads NOT BETWEEN 1 AND 32)
                BEGIN
                    SELECT 'Litespeed Threads value must be between 1 and 32 inclusive'
                    RAISERROR ('Litespeed Threads value must be between 1 and 32 inclusive', 16, 1)
                    RETURN
                END
            
            IF (@LTSPThrottle NOT BETWEEN 1 AND 100)
                BEGIN
                    SELECT 'Litespeed Throttle value must be between 1 and 100'
                    RAISERROR('Litespeed Throttle value must be between 1 and 100', 16, 1)
                    RETURN
                END
        END
    
    -- ******************************************************************************************
    
    -- ******************************************************************************************
    -- If a FileSuffix wasnt passed in, default it based on the backup type
    IF @FileSuffix IS NULL OR
       LTRIM(RTRIM(@FileSuffix)) = ''
        BEGIN

            SELECT @FileSuffix = 
                CASE
                    WHEN @BackupType = 'Full'
                        THEN 'BAK'
                    WHEN @BackupType = 'Diff'
                        THEN 'DIF'
                    WHEN @BackupType = 'TLog'
                        THEN 'TRN'
                    ELSE 'RAISERROR (''Invalid Backup Type Specified'', 16, 1)'
                END
        END
    -- ******************************************************************************************
    
    -- ******************************************************************************************
    -- Add a trailing '\' to the backup path if necessary
    IF RIGHT(@BackupFolder, 1) != '\'
        BEGIN
            SELECT @BackupFolder = @BackupFolder + '\'
        END

	-- Add a trailing '\' to the mirror backup folder path if necessary
	IF @MirrorToFolder IS NOT NULL
		BEGIN
			-- Parse comma delimited text into table
			DECLARE @StrToMirrorFolder VARCHAR(4000)
			SELECT	@StrToMirrorFolder = @MirrorToFolder

			DECLARE	@xMirrorFolder XML

			DECLARE	@MTF TABLE (
				RowId TINYINT IDENTITY(1,1),
				MirrorToFolderValue VARCHAR(512)
				)

			SELECT	@xMirrorFolder = cast('<A>'+ REPLACE(@StrToMirrorFolder,',','</A><A>')+ '</A>' AS XML)

			INSERT INTO @MTF (MirrorToFolderValue)
			SELECT	t.value('.', 'VARCHAR(512)')
			FROM	@xMirrorFolder.nodes('/A') AS x(t)
			
			UPDATE	@MTF
			SET		MirrorToFolderValue = MirrorToFolderValue + '\'
			WHERE	RIGHT(MirrorToFolderValue, 1) != '\'
			
			-- DECLARE AND ASSIGN PARAMETES TO BUILD BACKUP COMMAND IN THE LOOP
			DECLARE	@StrToMirrorFolderMaxRowId TINYINT
			SELECT	@StrToMirrorFolderMaxRowId = MAX(RowId)
			FROM	@MTF
			
		END

    -- Add a trailing '\' to the stripe backup folder path if necessary
	IF @StripeToFolder IS NOT NULL
		BEGIN
			-- Parse comma delimited text into table
			DECLARE @StrToStripeFolder VARCHAR(4000)
			SELECT	@StrToStripeFolder = @StripeToFolder

			DECLARE	@xStripeFolder XML

			DECLARE	@STF TABLE (
				RowId TINYINT IDENTITY(1,1),
				StripeToFolderValue VARCHAR(512)
				)

			SELECT	@xStripeFolder = cast('<A>'+ REPLACE(@StrToStripeFolder,',','</A><A>')+ '</A>' AS XML)

			INSERT INTO @STF (StripeToFolderValue)
			SELECT	t.value('.', 'VARCHAR(512)')
			FROM	@xStripeFolder.nodes('/A') AS x(t)

			UPDATE	@STF
			SET		StripeToFolderValue = StripeToFolderValue + '\'
			WHERE	RIGHT(StripeToFolderValue, 1) != '\'
			
			-- DECLARE AND ASSIGN PARAMETES TO BUILD BACKUP COMMAND IN THE LOOP
			DECLARE	@StrToStripeFolderMaxRowId TINYINT
			SELECT	@StrToStripeFolderMaxRowId = MAX(RowId)
			FROM	@STF

		END

    -- ******************************************************************************************
    
    -- ******************************************************************************************
    -- If this SQL 2008 AND Enterprise or Developer Edition 
    -- and the Compression Flag if set, set the COMPRESSION option
    IF @SQLVersion = 10 AND
       (CHARINDEX('Developer', CAST(SERVERPROPERTY ('Edition') AS VARCHAR(64))) > 0 
     OR CHARINDEX('Enterprise', CAST(SERVERPROPERTY ('Edition') AS VARCHAR(64))) > 0) AND
       @NativeCompression = 1
        BEGIN
            SELECT @CompressionOption = ', COMPRESSION'
        END
    ELSE
        BEGIN
            SELECT @CompressionOption = ''
        END
    -- ******************************************************************************************
    
    -- ******************************************************************************************
    -- Define the base SQL Command strings for each backup type.
    -- Token replacement is used to build the strings to be executed. All tokens are delimted by 
    -- '~' characters. E.g. ~d~ is the token for the database name.
    -- Removing the time stamp from backup file name
    IF @RemoveTimeStampFromFileName = 0
		BEGIN
			SELECT @TimeStamp = '_' + SUBSTRING(REPLACE(REPLACE((REPLACE((CONVERT(VARCHAR(32), GETDATE(), 120)), '-', '')), ':', ''), ' ', ''), 1, 12)
		END
	ELSE
		BEGIN
			SELECT @TimeStamp = ''
		END


	SELECT @FullBackupBase = 'BACKUP DATABASE [~d~] TO DISK=''' + @BackupFolder + '~sf~' + '~d~' + @TimeStamp + '.~s~'''
	SELECT @DiffBackupBase = 'BACKUP DATABASE [~d~] TO DISK=''' + @BackupFolder + '~sf~' + '~d~' + @TimeStamp + '.~s~'''
	SELECT @TLogBackupBase = 'BACKUP LOG [~d~] TO DISK=''' + @BackupFolder + '~sf~' + '~d~' + @TimeStamp + '.~s~'''

	-- Build Mirror to Folder Backup command
	IF @MirrorToFolder IS NOT NULL AND @StripeToFolder IS NULL
		BEGIN
			WHILE @StrToMirrorFolderMaxRowId > 0
				BEGIN
					SELECT	@MirrorToFolder = MirrorToFolderValue
					FROM	@MTF
					WHERE	RowId = @StrToMirrorFolderMaxRowId
					
					SELECT @FullBackupBase = @FullBackupBase + ' MIRROR TO DISK =''' + @MirrorToFolder + '~sf~' + '~d~' + @TimeStamp + '.~s~'''
					SELECT @DiffBackupBase = @DiffBackupBase + ' MIRROR TO DISK =''' + @MirrorToFolder + '~sf~' + '~d~' + @TimeStamp + '.~s~'''
					SELECT @TLogBackupBase = @TLogBackupBase + ' MIRROR TO DISK =''' + @MirrorToFolder + '~sf~' + '~d~' + @TimeStamp + '.~s~'''
					
					SELECT	@StrToMirrorFolderMaxRowId = @StrToMirrorFolderMaxRowId - 1
				END
		END

	-- Build Stripe to Folder Backup command
	IF @StripeToFolder IS NOT NULL AND @MirrorToFolder IS NULL
		BEGIN
			WHILE @StrToStripeFolderMaxRowId > 0
				BEGIN
					SELECT	@StripeToFolder = StripeToFolderValue
					FROM	@STF
					WHERE	RowId = @StrToStripeFolderMaxRowId
					
					SELECT @FullBackupBase = @FullBackupBase + ' ,DISK =''' + @StripeToFolder + '~sf~' + '~d~' + @TimeStamp + '_' + CAST(@StrToStripeFolderMaxRowId AS VARCHAR(2)) +'.~s~'''
					SELECT @DiffBackupBase = @DiffBackupBase + ' ,DISK =''' + @StripeToFolder + '~sf~' + '~d~' + @TimeStamp + '_' + CAST(@StrToStripeFolderMaxRowId AS VARCHAR(2)) +'.~s~'''
					SELECT @TLogBackupBase = @TLogBackupBase + ' ,DISK =''' + @StripeToFolder + '~sf~' + '~d~' + @TimeStamp + '_' + CAST(@StrToStripeFolderMaxRowId AS VARCHAR(2)) +'.~s~'''
					
					SELECT	@StrToStripeFolderMaxRowId = @StrToStripeFolderMaxRowId - 1
				END
		END

	-- Build  Stripe command based on cpu count to the same backup folder path
	IF @StripeCPUBased = 1 AND @StripeToFolder IS NULL
		BEGIN
			DECLARE	@LogicalCPUCount SMALLINT
			SELECT	@LogicalCPUCount = cpu_count
			FROM	sys.dm_os_sys_info WITH (NOLOCK) OPTION (RECOMPILE);
			
			-- LOOP TO ADD ADDITIONAL STRIPE FILE NAMES TO BACKUP COMMAND
			WHILE	@LogicalCPUCount > 2
				BEGIN				
					SELECT @FullBackupBase = @FullBackupBase + ' ,DISK =''' + @BackupFolder + '~sf~' + '~d~' + @TimeStamp + '_' + CAST(@LogicalCPUCount AS VARCHAR(2)) +'.~s~'''
					SELECT @DiffBackupBase = @DiffBackupBase + ' ,DISK =''' + @BackupFolder + '~sf~' + '~d~' + @TimeStamp + '_' + CAST(@LogicalCPUCount AS VARCHAR(2)) +'.~s~'''
					SELECT @TLogBackupBase = @TLogBackupBase + ' ,DISK =''' + @BackupFolder + '~sf~' + '~d~' + @TimeStamp + '_' + CAST(@LogicalCPUCount AS VARCHAR(2)) +'.~s~'''
									
					SELECT	@LogicalCPUCount = @LogicalCPUCount - 1
				END
		
		END
 
    
    -- COMPLETE BUILDING BACKUP COMMAND
    SELECT @FullBackupBase = @FullBackupBase + ' WITH STATS =5,INIT, FORMAT, NAME=''~d~_SQLServer_' + @BackupType + ''', DESCRIPTION=''~d~' + @TimeStamp + '.~s~''' + @CompressionOption
    SELECT @DiffBackupBase = @DiffBackupBase + ' WITH STATS =5,INIT, FORMAT, DIFFERENTIAL, NAME=''~d~_SQLServer_' + @BackupType + ''', DESCRIPTION=''~d~' + @TimeStamp + '.~s~''' + @CompressionOption
    SELECT @TLogBackupBase = @TLogBackupBase + ' WITH STATS =5,INIT, FORMAT, NAME=''~d~_SQLServer_' + @BackupType + ''', DESCRIPTION=''~d~' + @TimeStamp + '.~s~''' + @CompressionOption
    
    SELECT @VerifyBase = 'RESTORE VERIFYONLY FROM DISK=''' + @BackupFolder + '~sf~' + '~d~_' + @TimeStamp + '.~s~'' '
    
    SELECT @LTSPBase = '@database=[~d~], @filename=''' + @BackupFolder + '~sf~' + '~d~_' + @TimeStamp + '_Litespeed.~s~'', @threads=' + CAST(@LTSPThreads AS VARCHAR) + ', @throttle= ' + CAST(@LTSPThrottle AS VARCHAR) + ', @compressionlevel= ' + CAST(@LTSPCompressionLevel AS VARCHAR) + ', @init=1, @with=N''skip'', @with=N''STATS=10'', @desc=''~d~_' + @TimeStamp + '_Litespeed.~s~'', @backupname=''~d~_Litespeed_' + @BackupType + ''''
    SELECT @LTSPFullBase = 'EXEC master.dbo.xp_backup_database ' + @LTSPBase
    SELECT @LTSPDiffBase = @LTSPFullBase + ', @with=N''DIFFERENTIAL'''
    SELECT @LTSPTLogBase = 'EXEC master.dbo.xp_backup_log ' + @LTSPBase
    SELECT @LTSPVerifyBase = 'EXEC master.dbo.xp_restore_verifyonly @filename=''' + @BackupFolder + '~sf~' + '~d~_' + @TimeStamp + '_Litespeed.~s~'''
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Process the @IncludeDBs to pivot the data into a table
    SELECT @IncludeDBs = LTRIM(RTRIM(@IncludeDBs))
    IF RIGHT(@IncludeDBs, 1) != ','
        BEGIN
            SELECT @IncludeDBs = @IncludeDBs + ','
        END
 
    WHILE LEN(@IncludeDBs) > 0
        BEGIN
            SELECT @StrEnd = CHARINDEX(',', @IncludeDBs)
          
            INSERT #IncludeDBs
                VALUES (LEFT(@IncludeDBs, (@StrEnd - 1)))
            IF LEN(@IncludeDBs) > @StrEnd
                BEGIN
                    SELECT @IncludeDBs = SUBSTRING(@IncludeDBs, (@StrEnd + 1), 8000)
                END
            ELSE
                BEGIN
                    SELECT @IncludeDBs = ''
                END
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Process the @ExcludeDBs to pivot the data into a table
    SELECT @ExcludeDBs = LTRIM(RTRIM(@ExcludeDBs))
    IF RIGHT(@ExcludeDBs, 1) != ','
        BEGIN
            SELECT @ExcludeDBs = @ExcludeDBs + ','
        END
 
    WHILE LEN(@ExcludeDBs) > 0
        BEGIN
            SELECT @StrEnd = CHARINDEX(',', @ExcludeDBs)
          
            INSERT #ExcludeDBs
                VALUES (LEFT(@ExcludeDBs, (@StrEnd - 1)))
            IF LEN(@ExcludeDBs) > @StrEnd
                BEGIN
                    SELECT @ExcludeDBs = SUBSTRING(@ExcludeDBs, (@StrEnd + 1), 8000)
                END
            ELSE
                BEGIN
                    SELECT @ExcludeDBs = ''
                END
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Populate the #Databases table with all the databases on the server.
    -- If the User Group was specified, ignore any IncludeDBs list
    -- NOTE - [fn_DatabaseDetails] is specific to the SQL Version.
    IF EXISTS (SELECT *
                   FROM #IncludeDBs)
/* 2010-10-20 - removed by Derek Adams
    AND (@DBGroup IS NULL OR   
         LTRIM(@DBGroup) = '')
*/
        BEGIN
            INSERT #Databases
                SELECT d.*
                    FROM [dbo].[fn_DatabaseDetails] () d
                        INNER JOIN #IncludeDBs i
                            ON d.DBName LIKE i.DatabaseName ESCAPE '~'
        END
    ELSE
        BEGIN
            INSERT #Databases
                SELECT *
                    FROM [dbo].[fn_DatabaseDetails] ()
        END
    -- ******************************************************************************************
    
    -- ******************************************************************************************
    -- List the offline databases for the log and then filter them out
    SELECT DBName + ' is ' + StateDesc AS [OFFLINE DATABASES]
        FROM #Databases
        WHERE UPPER(StateDesc) != 'ONLINE'
    
    -- The next statement is for formatting output file only - it doesn't mean anything.
    SELECT '---------------------------------------------------------------------------'
    
    -- Now remove offline databases from the list
    DELETE #Databases
        WHERE UPPER(StateDesc) != 'ONLINE'
    -- ******************************************************************************************
    
    -- ******************************************************************************************
    -- If a Group was specified, filter the databases on Type
    IF @DBGroup IS NOT NULL
        BEGIN
            IF @DBGroup = 'System'
                BEGIN
                    DELETE #Databases
                        WHERE DBName NOT IN ('master', 'model', 'msdb')
                END

            ELSE  
                BEGIN
                    IF @DBGroup = 'User'
                        BEGIN
                            DELETE #Databases
                                WHERE DBName IN ('master', 'model', 'msdb')
                        END
                END
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If an Exclude list was specified, filter the databases 
    IF EXISTS (SELECT *
                   FROM #ExcludeDBs)
        BEGIN
            DELETE #Databases
                FROM #Databases d
                    INNER JOIN #ExcludeDBs e
                        ON d.DBName LIKE e.DatabaseName ESCAPE '~'
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If the backup type is TLOG, we dont want to try to backup databses in SIMPLE recovery mode
    IF @BackupType = 'TLog'
        BEGIN
            DELETE #Databases
                WHERE UPPER(Recovery_Model_Desc) = 'SIMPLE'
        END
    -- ******************************************************************************************

    IF @Debug = 1
        BEGIN
            SELECT *    
                FROM #Databases
        END

    -- ******************************************************************************************
    -- Define the Cursor to loop through the databases and back them up.
    DECLARE csrDatabases CURSOR FOR
        SELECT DBName,
               LastFullBackupDate
            FROM #Databases
            ORDER BY DBName
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Open the Cursor, and retrieve the first value
    OPEN csrDatabases
    FETCH NEXT FROM csrDatabases
        INTO @DBName,
             @FullBackupDate
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If Differential or T-Log Backups have been requested, and no previous Full backup 
    -- was completed, the requested backup will fail.
    -- If the date of the last full backup is missing, a Differential or T-Log backup is 
    -- switched to a Full backup instead.
    -- [fn_DatabaseDetails] pulls the last Full backup date from table [msdb].[dbo].[backupset],
    -- this is not infallible - if a database is deleted and then recreated with the same name,
    -- the data will still be in [msdb].[dbo].[backupset], showing (falsely) that there was a
    -- previous Full backup.
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Loop through the databases
    WHILE @@FETCH_STATUS = 0
        BEGIN

Retry_WithFullBackup:
            IF @Debug = 1
                BEGIN
                    PRINT 'Processing ' + @DBName 
                    PRINT '  Full Backup Date:' + CONVERT(VARCHAR(32), COALESCE(@FullBackupDate, '01/01/1900'), 109)
                    PRINT '  Backup Requested: ' + @BackupType

                    IF (@BackupType = 'Diff' OR  @BackupType = 'TLog') AND
                       @FullBackupDate IS NULL
                        BEGIN
                            PRINT '  ++ Defaulting to Full backup'
                        END
                END

            -- ******************************************************************************************
            -- Set the File Suffix ...
            IF (@BackupType = 'Diff' OR @BackupType = 'TLog') AND
               @FullBackupDate IS NULL
                BEGIN
                    SELECT @FileSuffix_Work = 'BAK'
                END
            ELSE
                BEGIN
                    SELECT @FileSuffix_Work = @FileSuffix
                END
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Set the SQL Command appropriately
            SELECT @SQL_Cmd = 
                    CASE 
                        WHEN @BackupType = 'Diff' AND
                             @FullBackupDate IS NULL
                            THEN CASE
                                    WHEN @LTSPBackup = 1
                                        THEN REPLACE(@LTSPFullBase, 'Diff', 'Full')
                                        ELSE REPLACE(@FullBackupBase, 'Diff', 'Full')
                                 END
                        WHEN @BackupType = 'TLog' AND
                             @FullBackupDate IS NULL
                            THEN CASE
                                    WHEN @LTSPBackup = 1
                                        THEN REPLACE(@LTSPFullBase, 'Tlog', 'Full')
                                        ELSE REPLACE(@FullBackupBase, 'Tlog', 'Full')
                                 END
                        WHEN @BackupType = 'Full'
                            THEN CASE
                                    WHEN @LTSPBackup = 1
                                        THEN @LTSPFullBase
                                        ELSE @FullBackupBase
                                 END
                        WHEN @BackupType = 'Diff'
                            THEN CASE
                                    WHEN @LTSPBackup = 1
                                        THEN @LTSPDiffBase
                                        ELSE @DiffBackupBase
                                 END
                        WHEN @BackupType = 'TLog'
                            THEN CASE
                                    WHEN @LTSPBackup = 1
                                        THEN @LTSPTLogBase
                                        ELSE @TLogBackupBase
                                 END

                        ELSE 'RAISERROR (''Invalid Backup Type Specified'', 16, 1)'
                    END
            -- ******************************************************************************************

            -- ******************************************************************************************
            --  Replace the substitution values for the current database
            SELECT @SQL_Cmd = REPLACE((REPLACE((REPLACE(@SQL_Cmd, '~d~', LTRIM(RTRIM(@DBName)))), '~d~', LTRIM(RTRIM(@DBName)))), '~s~', @FileSuffix_Work)
          
            IF @CreateSubFolder = 1
                BEGIN
                    SELECT @SQL_Cmd = REPLACE(@SQL_Cmd, '~sf~', LTRIM(RTRIM(@DBName)) + '\')
                    SET @Folder = @BackupFolder + LTRIM(RTRIM(@DBName))
                END
            ELSE
                BEGIN
                    SELECT @SQL_Cmd = REPLACE(@SQL_Cmd, '~sf~', '')
                    SET @Folder = @BackupFolder
                END
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Make sure the target folder exists
			-------------------------------------------------------
			-- Modified 9/23/2012 by DJC
            -- EXEC pr_PathExists @PathValue = @Folder
            EXEC @PathExists = pr_PathExists @PathValue = @Folder
            IF @PathExists = 0
            BEGIN
				SET @ErrorMsg = 'Unable to create or verify existence of folder "' + @Folder + '".'
				RAISERROR (@ErrorMsg, 16, 1)
				RETURN ---1
            END
            -- Modified 05/16/2013 by BG
            IF @MirrorToFolder IS NOT NULL
				BEGIN
					EXEC @PathExists = pr_PathExists @PathValue = @MirrorToFolder
					IF @PathExists = 0
						BEGIN
							SET @ErrorMsg = 'Unable to create or verify existence of folder "' + @MirrorToFolder + '".'
							RAISERROR (@ErrorMsg, 16, 1)
							RETURN 1
						END
				END
            
            -- ******************************************************************************************

            IF @Debug = 1
                BEGIN
                    PRINT @SQL_Cmd
                END

            -- ******************************************************************************************
            -- Execute the backup command
            SELECT @ProcName = CAST(OBJECT_NAME(@@PROCID) AS VARCHAR(128))

            EXEC [pr_ExecSQLCmd]    @SQLCmd         = @SQL_Cmd,
                                    @Source         = @ProcName,
                                    @rc             = @RC OUTPUT

            IF @RC != 0 AND
               (@BackupType = 'Diff' OR @BackupType = 'TLog') AND
               @FullBackupDate IS NOT NULL
               
                BEGIN
                    SELECT @FullBackupDate = NULL

                    GOTO Retry_WithFullBackup
                END
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- If VerifyBackup was specified, execute the verify command
            IF @VerifyBackup = 1
                BEGIN

                    SELECT @SQL_Cmd = 
                        CASE
                            WHEN @LTSPBackup = 1
                                THEN @LTSPVerifyBase
                                ELSE @VerifyBase
                        END

                    SELECT @SQL_Cmd = REPLACE((REPLACE((REPLACE(@SQL_Cmd, '~d~', LTRIM(RTRIM(@DBName)))), '~d~', LTRIM(RTRIM(@DBName)))), '~s~', @FileSuffix_Work)

                    IF @CreateSubFolder = 1
                        BEGIN
                            SELECT @SQL_Cmd = REPLACE(@SQL_Cmd, '~sf~', LTRIM(RTRIM(@DBName)) + '\')
                            SET @Folder = @BackupFolder + LTRIM(RTRIM(@DBName))
                        END
                    ELSE
                        BEGIN
                            SELECT @SQL_Cmd = REPLACE(@SQL_Cmd, '~sf~', '')
                            SET @Folder = @BackupFolder
                        END

                    IF @Debug = 1
                        BEGIN
                            SELECT @SQL_Cmd AS RestoreVerifyCommand
                        END

                     EXEC [pr_ExecSQLCmd]   @SQLCmd         = @SQL_Cmd,
                                            @Source         = @ProcName,
                                            @rc             = @RC OUTPUT

                END
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Retrieve the next value from the Cursor
            FETCH NEXT FROM csrDatabases
                INTO @DBName,
                     @FullBackupDate
            -- ******************************************************************************************

        END
    -- End of the Loop
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Close and Deallocate the Cursor
    CLOSE csrDatabases
    DEALLOCATE csrDatabases
    -- ******************************************************************************************

END





GO


