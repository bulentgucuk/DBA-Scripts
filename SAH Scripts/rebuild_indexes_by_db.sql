USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[rebuild_indexes_by_db]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[rebuild_indexes_by_db]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[rebuild_indexes_by_db]
  @DBName NVARCHAR(128)        -- Name of the db
, @ReorgLimit TINYINT = 15     -- Minimum fragmentation % to use Reorg method
, @RebuildLimit TINYINT = 30   -- Minimum fragmentation % to use Rebuild method
, @PageLimit SMALLINT = 10     -- Minimum # of Pages before you worry about it
, @SortInTempdb TINYINT = 0    -- 1 = Sort in tempdb option
, @OnLine TINYINT = 0          -- 1 = Online Rebuild, Reorg is ignored
, @ByPartition TINYINT = 1     -- 1 = Treat each partition separately
, @LOBCompaction TINYINT = 1   -- 1 = Always do LOB compaction
, @DoCIOnly TINYINT = 0        -- 1 = Only do Clustered indexes
, @UpdateStats TINYINT = 1     -- 1 = Update the statistics after the Reorg process
, @MaxDOP TINYINT = 0          -- 0 = Default so omit this from the statement
, @ExcludedTables NVARCHAR(MAX) = '' -- Comma delimited list of tables (DB.schema.Table) to exclude from processing

AS 

SET NOCOUNT ON ;
/********************************************************************************************************************************************************************************************************
INSTRUCTIONS:								You must create fn [dbo].[fn_split_inline_cte] within the DB you are creating this proc. It is used for paramater @ExcludedTables to exclude comma
											delimited list of tables to exclude. 
											
											Example:
											EXEC [dbo].[rebuild_indexes_by_db] 
											@DBName = 'AdventureWorksDW2008'	-- Name of the db   
											, @ReorgLimit = 15					-- Minimum fragmentation % to use Reorg method  
											, @RebuildLimit = 20				-- Minimum fragmentation % to use Rebuild method
											, @PageLimit  = 1000				-- Minimum # of Pages before you worry about it
											, @SortInTempdb  = 1				-- 1 = Sort in tempdb option  
											, @OnLine  = 1						-- 1 = Online Rebuild, Reorg is ignored     
											, @ByPartition  = 1					-- 1 = Treat each partition separately 
											, @LOBCompaction  = 1				-- 1 = Always do LOB compaction
											, @DoCIOnly  = 0					-- 1 = Only do Clustered indexes    
											, @UpdateStats  = 1					-- 1 = Update the statistics on Reorgs   
											, @MaxDOP = 0						-- 0 = Default so omit this from the statement  
											, @ExcludedTables = ''				-- Comma delimited list of tables (DB.Schema.Table) to exclude from processing
											
						
DATE:			INITIALS:					REMARKS:
09/18/10		LINK						This smart proc is taken from SQLMAG Issues 07/2008 "Rebuild Only the Indexes that Need Help" ID #99019 (Author:  Andrew J. Kelly).

09/18/10		LINK						I had to add [] around index names in the genereated ALTER INDEX and UPDATE STATISTICS 
											to get around indexes with white spaces in the name:
											SET @Rebuild = N'ALTER INDEX [' + @IndexName + N'] ON ' + @FullName + N' REORGANIZE' ;
											
											Yes, this proc uses a static cursor. It can be modified for a table variable loop with time. Since this cursor is
											accessing a temp table (#FragLevels) I am leaving it for now. 
											
											
										    NOTES:
										    For print out statements (Rebuild/Reorg) ONLY search for:
										     "123 If you only want print out statement Rebuild/Reorg 123 comment out below "EXEC(@Rebuild)" 123".
										     
										    For print out statements (Updating Stats on Reorg Tables) ONLY search for:
										    "456 If you only want Print out for the stats statement comment out below "EXEC('UPDATE STATISTICS ' + @FullName + ' (' + @IndexName + ') WITH FULLSCAN' )" 456"
										    
											To find any/all tables fo the 7 data types that can not be online rebuilt run the following:
											EXEC sp_MSforeachdb 
											'SELECT @@SERVERNAME AS SERVERNAME, ''?'' as [DB_NAME], [?].[sys].[tables].[NAME] FROM [?].[sys].[tables] where type = ''u'' and [lob_data_space_id] = 1'
											
											This does not take into account off line file or file groups. This does not 
											check to see if Indexed Views have LOB  data types or if the index is Disabled.
********************************************************************************************************************************************************************************************************/

SET NOCOUNT ON ;

SET DEADLOCK_PRIORITY LOW ;

BEGIN TRY

    DECLARE @FullName NVARCHAR(400), @SQL NVARCHAR(1000), @Rebuild NVARCHAR(1000), @DBID SMALLINT ;
    DECLARE @Error INT, @TableName NVARCHAR(128), @SchemaName NVARCHAR(128), @HasLobs TINYINT ;
    DECLARE @object_id INT, @index_id INT, @partition_number INT, @AvgFragPercent TINYINT ;
    DECLARE @IndexName NVARCHAR(128), @Partitions INT, @Print NVARCHAR(1000) ;
    DECLARE @PartSQL NVARCHAR(600), @ReOrgFlag TINYINT, @IndexTypeDesc NVARCHAR(60) ;

    -- If this isn't capable of doing online rebuilds then don't bother trying
    IF SERVERPROPERTY('EngineEdition') <> 3 -- Enterprise, EE EVAL or Developer
        SET @OnLine = 0 ;

    SET @DBID = DB_ID(@DBName) ;

    CREATE TABLE #FragLevels (
        [SchemaName] NVARCHAR(128) NULL, [TableName] NVARCHAR(128) NULL, [HasLOBs] TINYINT NULL,
	    [ObjectID] [int] NOT NULL, [IndexID] [int] NOT NULL, [PartitionNumber] [int] NOT NULL, 
        [AvgFragPercent] [tinyint] NOT NULL, [IndexName] NVARCHAR(128) NULL, [IndexTypeDesc] NVARCHAR(60) NOT NULL ) ;

    -- Get the initial list of indexes and partitions to work on filtering out heaps and meeting the specified thresholds
    -- and any excluded fully qualified table names.
    INSERT INTO #FragLevels
       ([ObjectID], [IndexID], [PartitionNumber], [AvgFragPercent], [IndexTypeDesc])
    SELECT a.[object_id], a.[index_id], a.[partition_number], CAST(a.[avg_fragmentation_in_percent] AS TINYINT) AS [AvgFragPercent], a.[index_type_desc]
        FROM sys.dm_db_index_physical_stats(@DBID, NULL, NULL, NULL , 'LIMITED') AS a 
            WHERE a.[avg_fragmentation_in_percent] >= @ReorgLimit AND a.[page_count] >= @PageLimit 
                  AND (a.[index_id] < CASE WHEN @DoCIOnly = 1 THEN 2 ELSE 999999999 END AND a.[index_id] >0)
                  AND a.[object_id] NOT IN (SELECT ISNULL(OBJECT_ID(p.[ParsedValue]),1) FROM [dbo].[fn_split_inline_cte](@ExcludedTables,N',') AS p) 
                  AND a.[partition_number] < CASE WHEN @ByPartition = 1 THEN 33000 ELSE 2 END ;

    -- Create an index to make some of the updates & lookups faster
    CREATE INDEX [IX_#FragLevels_OBJECTID] ON #FragLevels([ObjectID]) ;

    -- Get the Schema and Table names for each
    UPDATE #FragLevels WITH (TABLOCK) 
        SET [SchemaName] = OBJECT_SCHEMA_NAME([ObjectID],@DBID),
            [TableName] = OBJECT_NAME([ObjectID],@DBID) ;

    --  Determine if the index has a LOB datatype so we know if we can do online stuff or not
    SET @SQL = N'UPDATE #FragLevels WITH (TABLOCK) SET [HasLOBs] = (SELECT TOP 1 CASE WHEN t.[lob_data_space_id] = 0 THEN 0 ELSE 1 END ' +
            N' FROM [' + @DBName  + N'].[sys].[tables] AS t WHERE t.[type] = ''U'' AND t.[object_id] = #FragLevels.[ObjectID])' ;

    EXEC(@SQL) ;

    --  Get the index name
    SET @SQL = N'UPDATE #FragLevels SET [IndexName] = (SELECT TOP 1 t.[name] FROM [' + @DBName  + N'].[sys].[indexes] AS t WHERE t.[object_id] = #FragLevels.[ObjectID] ' +
                        ' AND t.[index_id] = #FragLevels.[IndexID] )'  ;

    EXEC(@SQL) ;
	--select * from #FragLevels

    --  Get a list of the Indexes to Rebuild.  
    DECLARE curIndexes CURSOR STATIC
    FOR 
    SELECT [SchemaName], [TableName], [HasLOBs], [ObjectID], [IndexID], [PartitionNumber], [AvgFragPercent], [IndexNam
e], [IndexTypeDesc]
        FROM #FragLevels ORDER BY [ObjectID], [IndexID] ASC ;

    OPEN curIndexes ;
    FETCH NEXT FROM curIndexes INTO @SchemaName, @TableName, @HasLobs, @object_id, @index_id, @partition_number, @AvgFragPercent, @IndexName, @IndexTypeDesc ;

    WHILE (@@fetch_status = 0)
    BEGIN
       
        SET @FullName = N'[' + @DBName + N'].[' + @SchemaName + N'].[' + @TableName + N']' ;


        --  Rebuild all the eligable indexes on the table. If the table contains a LOB then we won't attempt to rebuild online.
        --  If it has more than 1 partition we will do them by partition number unless @ByPartition parameter is turned off. 
        SET @PartSQL = N'SELECT @Partitions = COUNT(*) FROM [' + @DBName + N'].[sys].[partitions] WHERE [object_id] = @object_id AND [index_id] = @index_id'
        EXEC sp_executesql @PartSQL, N'@Partitions INT OUTPUT, @object_id INT, @index_id INT', @Partitions = @Partitions OUTPUT, @object_id = @object_id, @index_id = @index_id ;

        -- If the frag level is below the minimum just loop around
        IF @AvgFragPercent < @ReorgLimit
            CONTINUE

        IF @AvgFragPercent < @RebuildLimit  -- REORG
        BEGIN

            SET @Print = 'Reorganizing ' + @FullName + '(' + @IndexName + ')' ;

            SET @Rebuild = N'ALTER INDEX [' + @IndexName + N'] ON ' + @FullName + N' REORGANIZE' ;


            IF @Partitions > 1 AND @ByPartition = 1
            BEGIN
                SET @Rebuild = @Rebuild + N' PARTITION = ' + CAST(@partition_number AS NVARCHAR(10))  ;
                SET @Print = @Print +   ' PARTITION #: ' + CAST(@partition_number AS VARCHAR(10)) ;
            END ;

            SET @Rebuild = @Rebuild + ' WITH (,' ;

            SET @ReOrgFlag = 1

        END
        ELSE  -- REBUILD & options
        BEGIN
            SET @Print = 'Rebuilding ' + @FullName + '(' + @IndexName + ')' ;

            SET @Rebuild = N'ALTER INDEX [' + @IndexName + N'] ON ' + @FullName + N' REBUILD' ;

            IF @Partitions > 1 AND @ByPartition = 1
            BEGIN
                SET @Rebuild = @Rebuild + N' PARTITION = ' + CAST(@partition_number AS NVARCHAR(10))  ;
                SET @Print = @Print +   ' PARTITION #: ' + CAST(@partition_number AS VARCHAR(10)) ;
            END ;

            SET @Rebuild = @Rebuild + ' WITH (,' ;

            --  ONLINE is only valid if there are NO LOBS and no Partitions
            IF @Partitions < 2 AND @OnLine = 1 AND @HasLobs = 0
            BEGIN
            SET @Rebuild = @Rebuild + N', ONLINE = ON ' ;
            END ;

            SET @Rebuild = @Rebuild + CASE WHEN @MaxDOP <> 0 THEN N', MAXDOP = ' + CAST(@MaxDOP AS NVARCHAR(2)) ELSE N'' END ;
            SET @Rebuild = @Rebuild + CASE WHEN @SortInTempdb = 1 THEN N', SORT_IN_TEMPDB = ON ' ELSE N'' END ;

            SET @ReOrgFlag = 0
        END ;


        SET @Rebuild = @Rebuild + CASE WHEN @LOBCompaction = 0 THEN N', LOB_COMPACTION = OFF ' ELSE N'' END ;

        SET @Rebuild = @Rebuild + N')' ;

        -- Remove the WITH if there are no options
        SET @Rebuild = REPLACE(@Rebuild,N'WITH (,)',N'') ;
        -- Remove the extra comma if any
        SET @Rebuild = REPLACE(@Rebuild,N'(,,',N'(') ;

        SET @Print = @Print + ' at: ' + CONVERT(VARCHAR(26),GETDATE(),109) + ' ***' + CHAR(13) + CHAR(10) ;
        PRINT @Print 

        --  Catch any individual errors so we can rebuild the others
        /*123 If you only want print out statement Rebuild/Reorg 123 comment out below "EXEC(@Rebuild)" 123*/
        BEGIN TRY
			PRINT @Rebuild ;
			EXEC(@Rebuild);
            

            --  If we are doing a Reorg and the UpdateStats flag is on Update the Statistics for this index
            --  Update the stats after the Reorg since they are not automatically done. Statistics on XML indexes can not be updated
            --  XML or Invalid indexes will have a NULL IndexDepth property
            IF @UpdateStats = 1 AND @ReOrgFlag = 1  AND @IndexTypeDesc NOT LIKE N'%XML%' 
            BEGIN
                PRINT '*** Updating the stats for ' + @FullName + '(' + @IndexName + ') at: ' + CONVERT(VARCHAR(26),GETDATE(),109) + ' ***' + CHAR(13) + CHAR(10) ;
                
                /*"456 If you only want Print out for the stats statement comment out below "EXEC('UPDATE STATISTICS ' + @FullName + ' (' + @IndexName + ') WITH FULLSCAN' )" 456"*/
				PRINT 'UPDATE STATISTICS ' + @FullName + ' (' + @IndexName + ') WITH FULLSCAN'
                EXEC('UPDATE STATISTICS ' + @FullName + ' (' + @IndexName + ') WITH FULLSCAN' )
            END ;  

        END TRY
        BEGIN CATCH
            SET @Error = 1 ;
            PRINT '------>  There was an error rebuilding ' + @FullName + ' (' + @IndexName + ')' ;
            Print '';
            SELECT 
                ERROR_NUMBER() AS ErrorNumber,
                ERROR_SEVERITY() AS ErrorSeverity,
                ERROR_STATE() AS ErrorState,
                ERROR_PROCEDURE() AS ErrorProcedure,
                ERROR_LINE() AS ErrorLine,
                ERROR_MESSAGE() AS ErrorMessage;

        END CATCH ;

        FETCH NEXT FROM curIndexes INTO @SchemaName, @TableName, @HasLobs, @object_id, @index_id, @partition_number, @AvgFragPercent, @IndexName, @IndexTypeDesc ;

    END ;

    CLOSE curIndexes ;
    DEALLOCATE curIndexes ;

END TRY 
BEGIN CATCH

    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage;

    -- Raise an error so the sp that called this one catches it.;
    PRINT '' ;
    RAISERROR('Error attempting to rebuild one or more indexes for: "%s"',16,1,@DBName) ;

END CATCH ;

IF @Error = 1
BEGIN
    PRINT '' ;
    RAISERROR('There was one or more errors while attempting to rebuild the indexes for: "%s"',16,1,@DBName) ;
    RETURN -1 ;
END ;



GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
