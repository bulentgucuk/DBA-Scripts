USE [DBAdmin]
GO

IF dbo.fn_SQLVersion() >= 9
    BEGIN
        IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_Set_CheckDB_Schedule]') AND type = N'P')
            BEGIN
                PRINT 'Dropping Procedure [pr_Set_CheckDB_Schedule] - SQL 2005'
                DROP PROCEDURE [dbo].[pr_Set_CheckDB_Schedule]
            END
    END
IF dbo.fn_SQLVersion() < 9
    BEGIN
        PRINT 'DBAdmin CheckDB processing is not written for SQL 2000. Use the Standard Maintenance Plan processing.'
        PRINT '*** Processing of this script is being aborted ***'
        RAISERROR ('DBAdmin CheckDB processing is not written for SQL 2000', 20, 1) WITH LOG
    END

GO
CREATE PROCEDURE [dbo].[pr_Set_CheckDB_Schedule]

-- --------------------------------------------------------------------------------------------------
--  Procedure   :   [pr_Set_CheckDB_Schedule]
--  Version     :   1.0
--  Description :   Set the Schedule for the CHECKDB / CHECKTABLE process
--                  On the first day of each schedule, the schedule is rebuilt. This ensure that any 
--                  recently added objects are included in the schedule.
--
--  Modification Log
--  When            Who             Description
--  12/24/2009      Simon Facer     Original Version
-- --------------------------------------------------------------------------------------------------

AS 

BEGIN

    SET NOCOUNT ON

    -- ******************************************************************************************
    -- Declare local variables
    DECLARE @SQLVersion             INT 
    DECLARE @SQLCmd                 VARCHAR(MAX)
    DECLARE @ScheduleID             INT
    DECLARE @SplitOverDays          INT
    DECLARE @DBName                 SYSNAME
    DECLARE @TableName              SYSNAME
    DECLARE @DBGroup                VARCHAR(16)
    DECLARE @IncludeDBs             VARCHAR(2048)
    DECLARE @ExcludeDBs             VARCHAR(2048)
    DECLARE @REservedPC             BIGINT
    DECLARE @ScheduleDay            INT
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Create the # temp tables used in the proc
    CREATE TABLE #SchedulesToProcess
        (ScheduleID                 INT)

    -- Create the # temp table to identify the databases to be processed
    CREATE TABLE #Databases
        (DBName                     SYSNAME,
         StateDesc                  VARCHAR(60))

    -- Candidate Tables for processing
    CREATE TABLE #PoolOfTables (
        DatabaseName                SYSNAME,
        TableName                   SYSNAME,
        ObjectID                    INT,
        ReservedPC                  BIGINT)

    -- Info for tables with XML or Fulltext Indexes
    CREATE TABLE #TablesOtherPages  (
        ObjectID                    INT,
        ReservedPC                  BIGINT)

    -- Tables parsed into Multiple days
    CREATE TABLE #CHECKDB_Schedule (
        ScheduleDay                 INT,
        DatabaseName                SYSNAME     NULL,
        TableName                   SYSNAME     NULL,
        ReservedPC                  BIGINT      NULL,)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Determine the target SQL Server's version,
    --      8 = 2000        NOT Supported by this proc
    --      9 = 2005
    --      10 = 2008 
    SELECT @SQLVersion = dbo.fn_SQLVersion()
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Identify any Schedules that need to have the Schedule recalculated.
    --  All split-day Schedules are recalculated at day 0. This allows for any newly-added
    --      tables to be included in the next cycle, and also re-apportions based on changing
    --      table sizes.
    --  Any split-day Schedule that doesnt have any Schedule records is calculated .
    INSERT #SchedulesToProcess
        SELECT ScheduleID
            FROM CHECKDB_Parms
            WHERE dbo.fn_CheckDB_ScheduleDay (ScheduleID, GETDATE()) = 0
             AND  SplitOverDays > 1
          UNION
        SELECT t.ScheduleID
            FROM (SELECT  p.ScheduleID,
                          COUNT(s.ScheduleID) AS ScheduleRows
                      FROM CHECKDB_Parms p
                          LEFT OUTER JOIN CHECKDB_Schedule s
                              ON p.ScheduleID = s.ScheduleID
                      WHERE SplitOverDays > 1
                      GROUP BY p.ScheduleID
                      HAVING COUNT(s.ScheduleID) = 0) AS t
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Delete the existing Schedules
    DELETE dbo.CHECKDB_Schedule
        WHERE ScheduleID IN (SELECT ScheduleID
                                 FROM #SchedulesToProcess)
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
            SELECT  @DBGroup = DBGroup,
                    @IncludeDBs = IncludeDBs,
                    @ExcludeDBs = ExcludeDBs,
                    @SplitOverDays = SplitOverDays
                FROM dbo.CHECKDB_Parms
                WHERE ScheduleID = @ScheduleID
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Clear #temp tables 
            DELETE #Databases
            DELETE #PoolOfTables
            DELETE #TablesOtherPages
            DELETE #CHECKDB_Schedule
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
            -- Insert Base records into the CheckDB_Schedule table for each day
            INSERT #CHECKDB_Schedule
                SELECT  Number,
                        NULL,
                        NULL,
                        0
                    FROM dbo.fn_GenerateNumbers (1, @SplitOverDays)
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Loop through all the databases to be processed:
            WHILE EXISTS (SELECT *
                              FROM #Databases)
                BEGIN
            -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Identify the next database to process, and remove that record
                    SELECT @DBName = t.DBName
                        FROM (SELECT TOP 1 DBName
                                  FROM #Databases
                                  ORDER BY DBName) as t

                    DELETE #Databases
                        WHERE DBName = @DBName
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Identify all the tables and Reserved Page Counts in each database
                    IF  @SQLVersion = 10
                        BEGIN
                            -- User Tables, System Base Table, Indexed Views, Internal Tables
                            SELECT @SQLCmd = 
                                    N'USE [' + @DBName + N'];' +
                                    N'SELECT ''' + @DBName + N''', SCHEMA_NAME(o.schema_id) + N''.'' + o.name, ' +
                                    N'       o.object_id, SUM(ps.reserved_page_count)' +
                                    N'    FROM [' + @DBName + N'].sys.objects o WITH (NOLOCK)' +
                                    N'        INNER JOIN [' + @DBName + N'].sys.dm_db_partition_stats ps WITH (NOLOCK)' +
                                    N'            ON o.object_id = ps.object_id' +
                                    N'    WHERE o.[type] IN (N''U'', N''S'', N''V'', N''IT'')' +
                                    N'    GROUP BY SCHEMA_NAME(o.schema_id) + N''.'' + o.name, o.object_id'
                        END
                    ELSE 
                        BEGIN
                            -- User Tables, Indexed Views, Internal Tables
                            SELECT @SQLCmd = 
                                    N'USE [' + @DBName + N'];' +
                                    N'SELECT ''' + @DBName + N''', SCHEMA_NAME(o.schema_id) + N''.'' + o.name, ' +
                                    N'       o.object_id, SUM(ps.reserved_page_count)' +
                                    N'    FROM [' + @DBName + N'].sys.objects o WITH (NOLOCK)' +
                                    N'        INNER JOIN [' + @DBName + N'].sys.dm_db_partition_stats ps WITH (NOLOCK)' +
                                    N'            ON o.object_id = ps.object_id' +
                                    N'    WHERE o.[type] IN (N''U'', N''V'', N''IT'')' +
                                    N'    GROUP BY SCHEMA_NAME(o.schema_id) + N''.'' + o.name, o.object_id'
                        END 

                    INSERT INTO #PoolOfTables EXEC (@SQLCmd)
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Check if tables have XML Indexes or Fulltext Indexes which use internal tables tied to this table
                    -- Row counts in these internal tables don't contribute towards row count of original table.  
                    SELECT @SQLCmd = 
                            N'USE [' + @DBName + N'];' +
                            N'SELECT    it.object_id, sum(ps.reserved_page_count)' +
                            N'    FROM [' + @DBName + N'].sys.dm_db_partition_stats ps WITH (NOLOCK)' +
                            N'        INNER JOIN [' + @DBName + N'].sys.internal_tables it WITH (NOLOCK)' +
                            N'            ON ps.object_id = it.object_id' +
                            N'    WHERE it.internal_type IN (202,204)' +
                            N'    GROUP BY it.object_id'

                    INSERT INTO #TablesOtherPages EXEC (@SQLCmd)
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Check if tables have XML Indexes or Fulltext Indexes which use internal tables tied to this table
                    UPDATE #PoolOfTables
                        SET ReservedPC = p.ReservedPC + COALESCE(op.ReservedPC, 0)
                        FROM #PoolOfTables p
                            INNER JOIN #TablesOtherPages op
                        ON p.ObjectID = op.ObjectID
                    -- ******************************************************************************************

            -- ******************************************************************************************
                END
            -- End Database Loop
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- The previous Loop collected Reserved Page counts for all tables in all databases for the
            -- Schedule currently being processed.
            -- This loop will apportion those tables over the specified number of days, this processing
            -- will even out the processing by day, as much as possible.
            WHILE EXISTS (SELECT *
                              FROM #PoolOfTables)
                BEGIN
            -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Retrieve the next largest Table
                    SELECT  @DBName = t.DatabaseName,
                            @TableName = t.TableName,
                            @ReservedPC = t.ReservedPC
                        FROM (  SELECT TOP 1
                                        DatabaseName,
                                        TableName,
                                        ReservedPC
                                    FROM #PoolOfTables
                                    ORDER BY ReservedPC DESC) AS t

                    DELETE #PoolOfTables
                        WHERE DatabaseName = @DBName
                         AND  TableName = @TableName
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Identify the ScheduleDay with the smallest total PageCount allocated
                    SELECT @ScheduleDay = t.ScheduleDay 
                        FROM (  SELECT TOP 1
                                        ScheduleDay, 
                                        (SUM(ReservedPC) + @ReservedPC) AS Total_ReservedPC
                                    FROM #CHECKDB_Schedule
                                    GROUP BY ScheduleDay
                                    ORDER BY (SUM(ReservedPC) + @ReservedPC),
                                             ScheduleDay) AS t
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Insert the record into the #CHECKDB_Schedule table
                    INSERT #CHECKDB_Schedule
                        VALUES (@ScheduleDay,
                                @DbName,
                                @TableName,
                                @ReservedPC)
                    -- ******************************************************************************************

            -- ******************************************************************************************
                END
            -- End Table Scheduling Loop
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Load the Schedule Data into the permanent table
            INSERT dbo.CHECKDB_Schedule
                SELECT  @ScheduleID,
                        ScheduleDay,
                        DatabaseName,
                        TableName
                    FROM #CHECKDB_Schedule
                    WHERE DatabaseName IS NOT NULL
                    ORDER BY DatabaseName,
                             TableName
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

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pr_Set_CheckDB_Schedule]') AND type = N'P')
    BEGIN
        PRINT 'Procedure [pr_Set_CheckDB_Schedule] Created - SQL 2005'
    END

