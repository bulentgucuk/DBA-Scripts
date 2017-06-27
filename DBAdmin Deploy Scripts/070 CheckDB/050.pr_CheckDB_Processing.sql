USE [DBAdmin]
GO

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_CheckDB_Processing]') AND type = N'P')
            BEGIN
                PRINT 'Dropping Procedure [pr_CheckDB_Processing] - SQL 2005'
                DROP PROCEDURE [dbo].[pr_CheckDB_Processing]
            END
    END
IF dbo.fn_SQLVersion() < 9
    BEGIN
        PRINT 'DBAdmin CheckDB processing is not written for SQL 2000. Use the Standard Maintenance Plan processing.'
        PRINT '*** Processing of this script is being aborted ***'
        RAISERROR ('DBAdmin CheckDB processing is not written for SQL 2000', 20, 1) WITH LOG
    END

GO
CREATE PROCEDURE [dbo].[pr_CheckDB_Processing]

-- --------------------------------------------------------------------------------------------------
--  Procedure   :   [pr_CheckDB_Processing]
--  Version     :   1.0
--  Description :   Process the CheckDB Processing as defined in the CHECKDB_Parms and CHECKDB_Schedule
--                  tables. 
--                  The processing can be to execute a single CHECKDB statement, or to execute 
--                  multiple CHECKTABLE statements
--
--  Modification Log
--  When            Who             Description
--  01/07/2010      Simon Facer     Original Version
--  02/23/2010      Simon Facer     Corrected typo in a temp table name.
-- --------------------------------------------------------------------------------------------------

AS 

BEGIN

    SET NOCOUNT ON

    -- ******************************************************************************************
    -- Declare local variables
    DECLARE @SQLCmd                 VARCHAR(MAX)
    DECLARE @ScheduleID             INT
    DECLARE @SplitOverDays          INT
    DECLARE @DBName                 SYSNAME
    DECLARE @TableName              SYSNAME
    DECLARE @DBGroup                VARCHAR(16)
    DECLARE @IncludeDBs             VARCHAR(2048)
    DECLARE @ExcludeDBs             VARCHAR(2048)
    DECLARE @ScheduleDay            INT
    DECLARE @ErrMsg                 VARCHAR(MAX)
    DECLARE @CurrentDate            DATETIME

    SELECT @CurrentDate = GETDATE()
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Create the # temp tables used in the proc
    CREATE TABLE #SchedulesToProcess
        (ScheduleID                 INT)

    -- Create the # temp table to identify the databases to be processed
    CREATE TABLE #Databases
        (DBName                     SYSNAME,
         StateDesc                  VARCHAR(60))

    -- Create the # temp table to identify the databases / tables to be processed
    CREATE TABLE #DatabaseTables
        (DBName                     SYSNAME,
         TableName                  SYSNAME)

    -- Create the # temp table to identify the databases processed with CHECKDB
    CREATE TABLE #Databases_Processed
        (DBName                     SYSNAME)

    -- Create the # temp table to identify the databases processed with CHECKALLOC / CHECKCATALOG
    CREATE TABLE #Databases_Processed2
        (DBName                     SYSNAME)

    -- Create the # temp table to identify the databases / tables processed with CHECKTABLE
    CREATE TABLE #DatabaseTables_Processed
        (DBName                     SYSNAME,
         TableName                  SYSNAME)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Identify the Schedules to be processed today
    INSERT #SchedulesToProcess
        SELECT ScheduleID
            FROM CHECKDB_Parms
            WHERE (dbo.fn_CheckDB_ScheduleDay (ScheduleID, GETDATE()) < SplitOverDays AND
                   SplitOverDays > 1)
              OR  (dbo.fn_CheckDB_ScheduleDay (ScheduleID, GETDATE()) = 0 AND
                   SplitOverDays = 1)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Loop through all the Schedules To Process
    DECLARE csrSchedule CURSOR FOR
        SELECT  ScheduleID
            FROM #SchedulesToProcess
   -- ******************************************************************************************

    -- ******************************************************************************************
    -- Open and retrieve the first value from the cursor
    OPEN csrSchedule
    FETCH NEXT FROM csrSchedule
        INTO @ScheduleID
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Loop through Schedules
    WHILE @@FETCH_STATUS = 0
        BEGIN
    -- + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +

            -- ******************************************************************************************
            -- Identify the Schedule Day
            SELECT @ScheduleDay = dbo.fn_CheckDB_ScheduleDay (@ScheduleID, GETDATE())
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Log the start of the Schedule processing
            PRINT REPLICATE('=', 100)
            SELECT @ErrMsg = 'Processing Schedule ' + CAST(@ScheduleID AS VARCHAR(6)) + ', Day ' + CAST(@ScheduleDay AS VARCHAR(2))
            PRINT @ErrMsg
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Clear Temp tables
            DELETE #Databases
            DELETE #DatabaseTables
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Retrieve the processng parameters for the current Schedule
            SELECT  @DBGroup        = DBGroup,
                    @IncludeDBs     = IncludeDBs,
                    @ExcludeDBs     = ExcludeDBs,
                    @SplitOverDays  = SplitOverDays
                FROM dbo.CHECKDB_Parms
                WHERE ScheduleID = @ScheduleID
            -- ******************************************************************************************
 
            -- ******************************************************************************************
            -- Populate the #Databases table with all the databases on the server
            INSERT #Databases
                SELECT DBName, StateDesc
                    FROM [dbo].[fn_DatabaseDetails] ()
            -- ******************************************************************************************
            
            -- ******************************************************************************************
            -- Remove offline databases from the list
            DELETE #Databases
                WHERE UPPER(StateDesc) != 'ONLINE'
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Process the IncludeDBs parameter to add '[' and ']' values.
            SELECT @IncludeDBs = '[' + REPLACE(@IncludeDBs, ',', '],[') + ']'
            WHILE CHARINDEX('[ ', @IncludeDBs) > 0 
                BEGIN
                    SELECT @IncludeDBs = REPLACE(@IncludeDBs, '[ ', '[')
                END
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Process the ExcludeDBs parameter to add '[' and ']' values.
            SELECT @ExcludeDBs = '[' + REPLACE(@ExcludeDBs, ',', '],[') + ']'
            WHILE CHARINDEX('[ ', @ExcludeDBs) > 0 
                BEGIN
                    SELECT @ExcludeDBs = REPLACE(@ExcludeDBs, '[ ', '[')
                END
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- If a Group was specified, filter the database names
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

                    IF @ExcludeDBs IS NOT NULL AND
                       LTRIM(RTRIM(@ExcludeDBs)) != ''
                        BEGIN
                            DELETE #Databases
                                WHERE CHARINDEX(('[' + DBName + ']'), @ExcludeDBs) > 0
                        END
                END
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- If a list of databases to include was specified and a DBGroup wasn't, process the 
            -- include list.
            IF @DBGroup IS NULL AND
               (LTRIM(RTRIM(@IncludeDBs)) != '')
                BEGIN
                    DELETE #Databases
                        WHERE CHARINDEX(('[' + DBName + ']'), @IncludeDBs) = 0
                END
            -- ******************************************************************************************
 
            -- ******************************************************************************************
            -- If this record is for non Split-Day processing
            -- Execute a CheckDB against the database(s)
            IF @SplitOverDays = 1
                BEGIN
                    PRINT REPLICATE('-', 100)
                    PRINT '>> Schedule is non Split-Day, CHECKDB processing will be used' 
            -- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

                    -- ******************************************************************************************
                    -- For each database in the Schedule, execute a DBCC CHECKDB
                    WHILE EXISTS (SELECT * 
                                      FROM #Databases)
                        BEGIN
                    -- Retrieve the next DBName
                            SELECT @DBName = MIN(DBName)
                                FROM #Databases
                            DELETE #Databases
                                WHERE DBName = @DBName

                    -- If the database has already been CHECKDB'd, skip it
                            IF EXISTS (SELECT *
                                           FROM #Databases_Processed
                                           WHERE DBName = @DBName)
                                BEGIN
                                    PRINT '~~~~ Processing [' + @DBName + '] skipped - already processed this run'
                                END
                            ELSE
                    -- Format the SQLCmd, and execute it. Save the Database name as processed.
                                BEGIN
                                    PRINT '>>>> Processing [' + @DBName + '] CHECKDB ' + dbo.[fn_FormatDateTime_100_WithSeconds](GETDATE())
                                
                                    INSERT #Databases_Processed
                                        VALUES(@DBName)

                                    SET @SQLCmd = 'DBCC CHECKDB ([' + @DBName + ']) WITH NO_INFOMSGS'
                                    BEGIN TRY
                                        EXEC (@SQLCmd)
                                    END TRY
                                    BEGIN CATCH 
                                        PRINT REPLICATE('#', 100)
                                        PRINT 'Error Encountered in processing CHECKDB'
                                        PRINT @SQLCmd
                                        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(32))
                                        PRINT 'Error Message: "' + ERROR_MESSAGE() + '"'
                                        PRINT REPLICATE('#', 100)
                                    END CATCH
                                    PRINT '>>>>            [' + @DBName + '] CHECKDB ' + dbo.[fn_FormatDateTime_100_WithSeconds](GETDATE()) + ' Completed'
                                END
                            
                        END
                    -- ******************************************************************************************

            -- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
                END
            -- End of non Split-day processing
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- If this record is for a Split-Day schedule
            IF @SplitOverDays > 1 AND
               @ScheduleDay <= @SplitOverDays
                BEGIN

                    PRINT REPLICATE('-', 100)
                    PRINT '>> Schedule is Split-Day, CHECKALLOC / CHECKCATALOG / CHECKTABLE processing will be used' 
            -- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 

                    -- ******************************************************************************************
                    -- For each database in the Schedule, execute DBCC CHECKALLOC and CHECKCATALOG
                    WHILE EXISTS (SELECT * 
                                      FROM #Databases)
                        BEGIN
                    -- Retrieve the next DBName
                            SELECT @DBName = MIN(DBName)
                                FROM #Databases
                            DELETE #Databases
                                WHERE DBName = @DBName

                    -- If the database has already been CHECKDB'd, skip it
                            IF EXISTS (SELECT *
                                           FROM #Databases_Processed
                                           WHERE DBName = @DBName)
                                BEGIN
                                    PRINT '~~~~ Processing [' + @DBName + '] skipped - already processed by CHECKDB this run'
                                END
                            ELSE
                    -- If the database has already been CHECKDB'd, skip it
                                BEGIN
                                    IF EXISTS (SELECT *
                                                   FROM #Databases_Processed2
                                                   WHERE DBName = @DBName)
                                        BEGIN
                                            PRINT '~~~~ Processing [' + @DBName + '] skipped - already processed by CHECKALLOC / CHECKCATALOG this run'
                                        END
                                    ELSE
                    -- Format the SQLCmd, and execute it. Save the Database name as processed.
                                        BEGIN
                                            PRINT '>>>> Processing [' + @DBName + '] CHECKALLOC / CHECKCATALOG ' + dbo.[fn_FormatDateTime_100_WithSeconds](GETDATE())

                                            INSERT #Databases_Processed2
                                                VALUES(@DBName)

                                            SET @SQLCmd = 'DBCC CHECKALLOC ([' + @DBName + ']) WITH ALL_ERRORMSGS, NO_INFOMSGS;' +
                                                          'DBCC CHECKCATALOG ([' + @DBName + ']) WITH NO_INFOMSGS;' 
                                            BEGIN TRY
                                                EXEC (@SQLCmd)
                                            END TRY
                                            BEGIN CATCH 
                                                PRINT REPLICATE('#', 100)
                                                PRINT 'Error Encountered in processing CHECKALLOC / CHECKCATALOG'
                                                PRINT @SQLCmd
                                                PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(32))
                                                PRINT 'Error Message: "' + ERROR_MESSAGE() + '"'
                                                PRINT REPLICATE('#', 100)
                                            END CATCH
                                            PRINT '>>>>            [' + @DBName + '] CHECKALLOC / CHECKCATALOG ' + dbo.[fn_FormatDateTime_100_WithSeconds](GETDATE()) + ' Completed'
                                        END
                                END
                            
                        END
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Retrieve all the tables to be processed for the Current Schedule and Day
                    INSERT #DatabaseTables
                        SELECT  DatabaseName,
                                TableName
                            FROM CHECKDB_Schedule
                            WHERE ScheduleID = @ScheduleID
                             AND  Schedule_Day = @ScheduleDay
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- For each Database / Table in the Schedule, execute DBCC CHECKTABLE
                    WHILE EXISTS (SELECT * 
                                      FROM #DatabaseTables)
                        BEGIN
                    -- Retrieve the next DBName
                    SELECT  @DBName = t.DBName,
                            @TableName = t.TableName
                        FROM (SELECT TOP 1 *
                                  FROM #DatabaseTables
                                  ORDER BY DBName,
                                           TableName) AS t
                    DELETE #DatabaseTables
                        WHERE DBName = @DBName
                         AND  TableName = @TableName

                    -- If the database has already been CHECKDB'd, skip it
                            IF EXISTS (SELECT *
                                           FROM #Databases_Processed
                                           WHERE DBName = @DBName)
                                BEGIN
                                    PRINT '~~~~ Processing [' + @DBName + '].[' + @TableName + '] skipped - Database already processed by CHECKDB this run'
                                END
                            ELSE
                    -- If the database / table has already been CHECKTABLE'd, skip it
                                BEGIN
                                    IF EXISTS (SELECT *
                                                   FROM #DatabaseTables_Processed
                                                   WHERE DBName = @DBName
                                                    AND  TableName = @TableName)
                                        BEGIN
                                            PRINT '~~~~ Processing [' + @DBName + '].[' + @TableName + '] skipped - Table already processed by CHECKTABLE this run'
                                        END
                                    ELSE
                        -- Format the SQLCmd, and execute it. Save the Database name as processed.
                                        BEGIN
                                            PRINT '>>>> Processing [' + @DBName + '].[' + @TableName + '] ' + dbo.[fn_FormatDateTime_100_WithSeconds](GETDATE())

                                            INSERT #DatabaseTables_Processed
                                                VALUES(@DBName, @TableName)

                                            SET @SQLCmd = 'USE [' + @DBName + ']; DBCC CHECKTABLE ([' + @TableName + ']) WITH ALL_ERRORMSGS, NO_INFOMSGS;' 
                                            BEGIN TRY
                                                EXEC (@SQLCmd)
                                            END TRY
                                            BEGIN CATCH 
                                                PRINT REPLICATE('#', 100)
                                                PRINT 'Error Encountered in processing CHECKTABLE'
                                                PRINT @SQLCmd
                                                PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(32))
                                                PRINT 'Error Message: "' + ERROR_MESSAGE() + '"'
                                                PRINT REPLICATE('#', 100)
                                            END CATCH
                                            PRINT '>>>>            ' + @DBName + ' ' + dbo.[fn_FormatDateTime_100_WithSeconds](GETDATE()) + ' Completed'
                                        END
                                END
                        END
                    -- ******************************************************************************************

            -- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
                END
            -- End of Split-day processing
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Retrieve the next value from the cursor
            FETCH NEXT FROM csrSchedule
                INTO @ScheduleID
            -- ******************************************************************************************

    -- + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
        END
    -- End of the Cursor loop (ScheduleID)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Close and Deallocate the Cursor
    CLOSE csrSchedule
    DEALLOCATE csrSchedule    
    -- ******************************************************************************************

END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_CheckDB_Processing]') AND type = N'P')
    BEGIN
        PRINT 'Procedure [pr_CheckDB_Processing] Created - SQL 2005'
    END

