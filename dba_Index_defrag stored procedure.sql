USE [NetQuoteTechnologyOperations]
GO

/****** Object:  StoredProcedure [dbo].[dba_Index_defrag]    Script Date: 07/22/2010 16:12:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-------------------------------------------------------------------------------------------
-- OBJECT NAME           : dba_Index_defrag
--
--
-- INPUTS                : @dbName         - name of the database
--                         @statsMode      - LIMITED, SAMPLED or DETAILED
--                         @defragType     - REORGANIZE (INDEXDEFRAG) or REBUILD (DBREINDEX)
--                         @minFragPercent - minimum fragmentation level
--                         @maxFragPercent - maximum fragmentation level
--                         @minRowCount    - minimum row count
--						   @logHistory	   - whether or not to log what got defragmented
--						   @sortInTempdb   - whether or not to sort the index in tempdb;
--											 recommended if your tempdb is optimized (see BOL for details)
--
-- OUTPUTS               : None
--
-- DEPENDENCIES          : DefragmentIndexes, sys.dm_db_index_physical_stats, sys.objects, sys.schemas, 
--						   sys.indexes, sys.partitions, sys.indexes, sys.index_columns, INFORMATION_SCHEMA.COLUMNS
--
-- DESCRIPTION           : Defragments indexes
/*
                           EXEC dba_Index_defrag 
							 @dbName = 'NetQuoteWebSite', 
						     @statsMode = 'SAMPLED', 
							 @defragType = 'REBUILD', 
							 @minFragPercent = 10,
							 @maxFragPercent = 100,
							 @minRowCount = 1000,
							 @logHistory = 1,
							 @sortInTempdb = 1
*/

-------------------------------------------------------------------------------------------
CREATE PROC [dbo].[dba_Index_defrag]
(
    @dbName sysname, 
    @statsMode varchar(8) = 'SAMPLED', 
    @defragType varchar(10) = 'REORGANIZE', 
    @minFragPercent int = 25, 
    @maxFragPercent int = 100, 
    @minRowCount int = 0,
	@logHistory bit = 0,
	@sortInTempdb bit = 0
)
AS

SET NOCOUNT ON

IF @statsMode NOT IN ('LIMITED', 'SAMPLED', 'DETAILED')
BEGIN
	RAISERROR('@statsMode must be LIMITED, SAMPLED or DETAILED', 16, 1)
	RETURN
END

IF @defragType NOT IN ('REORGANIZE', 'REBUILD')
BEGIN
	RAISERROR('@defragType must be REORGANIZE or REBUILD', 16, 1)
	RETURN
END

DECLARE 
    @i int, @objectId int, @objectName sysname, @indexId int, @indexName sysname, 
    @schemaName sysname, @partitionNumber int, @partitionCount int,
    @sql nvarchar(4000), @edition int, @parmDef nvarchar(500), @allocUnitType nvarchar(60),
	@indexType nvarchar(60), @online bit, @disabled bit, @dataType nvarchar(128),
	@charMaxLen int, @allowPageLocks bit, @lobData bit, @fragPercent float

SELECT @edition = CONVERT(int, SERVERPROPERTY('EngineEdition'))

SELECT 
    IDENTITY(int, 1, 1) AS FragIndexId, 
    [object_id] AS ObjectId, 
    index_id AS IndexId, 
    avg_fragmentation_in_percent AS FragPercent, 
    record_count AS RecordCount, 
    partition_number AS PartitionNumber,
	index_type_desc AS IndexType,
	alloc_unit_type_desc AS AllocUnitType
INTO #FragIndex
FROM sys.dm_db_index_physical_stats (DB_ID(@dbName), NULL, NULL, NULL, @statsMode)
WHERE 
    avg_fragmentation_in_percent > @minFragPercent AND 
    avg_fragmentation_in_percent < @maxFragPercent AND 
    index_id > 0
ORDER BY ObjectId

-- LIMITED does not include data for record_count
IF @statsMode IN ('SAMPLED', 'DETAILED')
	DELETE FROM #FragIndex
	WHERE RecordCount < @minRowCount

SELECT @i = MIN(FragIndexId) 
FROM #FragIndex

SELECT 
    @objectId = ObjectId, 
    @indexId = IndexId, 
	@fragPercent = FragPercent,
	@partitionNumber = PartitionNumber,
	@indexType = IndexType,
	@allocUnitType = AllocUnitType
FROM #FragIndex
WHERE FragIndexId = @i

WHILE @@ROWCOUNT <> 0
BEGIN
	-- get the table and schema names for the index
    SET @sql = '
        SELECT @objectName = o.[name], @schemaName = s.[name]
        FROM ' + QUOTENAME(@dbName) + '.sys.objects o
        JOIN ' + QUOTENAME(@dbName) + '.sys.schemas s 
			ON s.schema_id = o.schema_id
        WHERE o.[object_id] = @objectId'

    SET @parmDef = N'@objectId int, @objectName sysname OUTPUT, @schemaName sysname OUTPUT'

    EXEC sp_executesql 
        @sql, @parmDef, @objectId = @objectId, 
        @objectName = @objectName OUTPUT, @schemaName = @schemaName OUTPUT

	-- get index information
    SET @sql = '
        SELECT @indexName = [name], @disabled = is_disabled, @allowPageLocks = allow_page_locks
        FROM ' + QUOTENAME(@dbName) + '.sys.indexes
        WHERE [object_id] = @objectId AND index_id = @indexId'

    SET @parmDef = N'
			@objectId int, @indexId int, @indexName sysname OUTPUT, 
			@disabled bit OUTPUT, @allowPageLocks bit OUTPUT'

    EXEC sp_executesql 
        @sql, @parmDef, @objectId = @objectId, @indexId = @indexId, 
        @indexName = @indexName OUTPUT, @disabled = @disabled OUTPUT, 
		@allowPageLocks = @allowPageLocks OUTPUT
	
	SET @lobData = 0

	-- for clustered indexes, check for columns in the table that use a LOB data type
	IF @indexType = 'CLUSTERED INDEX'
	BEGIN
		-- CHARACTER_MAXIMUM_LENGTH column will equal -1 for max size or xml
		SET @sql = '
			SELECT @lobData = 1
			FROM ' + QUOTENAME(@dbName) + '.INFORMATION_SCHEMA.COLUMNS c
			WHERE	TABLE_SCHEMA = @schemaName AND
					TABLE_NAME = @objectName AND
					(DATA_TYPE IN (''text'', ''ntext'', ''image'') OR 
					CHARACTER_MAXIMUM_LENGTH = -1)'

		SET @parmDef = N'@schemaName sysname, @objectName sysname, @lobData bit OUTPUT'

		EXEC sp_executesql 
			@sql, @parmDef, @schemaName = @schemaName, @objectName = @objectName, 
			@lobData = @lobData OUTPUT
	END
	-- for non-clustered indexes, check for LOB data type in the included columns
	ELSE IF @indexType = 'NONCLUSTERED INDEX'
	BEGIN
		SET @sql = '
			SELECT @lobData = 1
			FROM ' + QUOTENAME(@dbName) + '.sys.indexes i
			JOIN ' + QUOTENAME(@dbName) + '.sys.index_columns ic
				ON i.object_id = ic.object_id
			JOIN ' + QUOTENAME(@dbName) + '.INFORMATION_SCHEMA.COLUMNS c
				ON ic.column_id = c.ORDINAL_POSITION
			WHERE	c.TABLE_SCHEMA = @schemaName AND
					c.TABLE_NAME = @objectName AND
					i.name = @indexName AND
					ic.is_included_column = 1 AND
					(c.DATA_TYPE IN (''text'', ''ntext'', ''image'') OR c.CHARACTER_MAXIMUM_LENGTH = -1)'
				
		SET @parmDef = N'@schemaName sysname, @objectName sysname, @indexName sysname, @lobData bit OUTPUT'

		EXEC sp_executesql 
			@sql, @parmDef, @schemaName = @schemaName, @objectName = @objectName, 
			@indexName = @indexName, @lobData = @lobData OUTPUT
	END
	
	-- get partition information for the index
    SET @sql = '
        SELECT @partitionCount = COUNT(*)
        FROM ' + QUOTENAME(@dbName) + '.sys.partitions
        WHERE [object_id] = @objectId AND index_id = @indexId'

    SET @parmDef = N'@objectId int, @indexId int, @partitionCount int OUTPUT'

    EXEC sp_executesql 
        @sql, @parmDef, @objectId = @objectId, @indexId = @indexId, 
        @partitionCount = @partitionCount OUTPUT

	-- Developer and Enterprise have the ONLINE = ON option for REBUILD.
	-- Indexes, including indexes on global temp tables, can be rebuilt online with the following exceptions:
	-- disabled indexes, XML indexes, indexes on local temp tables, partitioned indexes,
	-- clustered indexes if the underlying table contains LOB data types (text, ntext, image, varchar(max), 
	-- nvarchar(max), varbinary(max) or xml), and
	-- nonclustered indexes that are defined with LOB data type columns.
	-- When reoganizing and page locks is disabled for the index, we'll switch to rebuild later on, 
	-- so we need to get setup with the proper online option.
	IF @edition = 3 AND (@defragType = 'REBUILD' OR (@defragType = 'REORGANIZE' AND @allowPageLocks = 0))
	BEGIN
		SET @online = 
				CASE
					WHEN @indexType = 'XML INDEX' THEN 0
					WHEN @indexType = 'NONCLUSTERED INDEX' AND @allocUnitType = 'LOB_DATA' THEN 0
					WHEN @lobData = 1 THEN 0
					WHEN @disabled = 1 THEN 0
					WHEN @partitionCount > 1 THEN 0
					ELSE 1
				END
	END
	ELSE
		SET @online = 0

	-- build the ALTER INDEX statement
    SET @sql = 'ALTER INDEX ' + QUOTENAME(@indexName) + ' ON ' + QUOTENAME(@dbName) + '.' + 
        QUOTENAME(@schemaName) + '.' + QUOTENAME(@objectName) + 
		CASE
			WHEN @defragType = ' REORGANIZE' AND @allowPageLocks = 0 THEN ' REBUILD'
			ELSE ' ' + @defragType
		END


	-- SET PARTITION NUMBER IF THE INDEX IS PARTITIONED
	IF @partitionCount > 1 AND @disabled = 0 AND @indexType <> 'XML INDEX'
		SET @sql = @sql + ' PARTITION = ' + CAST(@partitionNumber AS varchar(10))

	-- WITH options
    IF @online = 1 OR @sortInTempdb = 1
	BEGIN	
		SET @sql = @sql + ' WITH (' + 
			CASE
				WHEN @online = 1 AND @sortInTempdb = 1 THEN 'ONLINE = ON, SORT_IN_TEMPDB = ON'
				WHEN @online = 1 AND @sortInTempdb = 0 THEN 'ONLINE = ON'
				WHEN @online = 0 AND @sortInTempdb = 1 THEN 'SORT_IN_TEMPDB = ON'
			END + ')'
	END

--    IF @partitionCount > 1 AND @disabled = 0 AND @indexType <> 'XML INDEX'
--        SET @sql = @sql + ' PARTITION = ' + CAST(@partitionNumber AS varchar(10))

	-- RUN THE ALTER INDEX statement
	PRINT @SQL
    EXEC (@SQL)

	-- log some information into a history table
	IF @logHistory = 1
		INSERT INTO DefragmentIndexes (DatabaseName, SchemaName, TableName, IndexName, DefragmentDate, PercentFragmented)
		VALUES(@dbName, @schemaName, @objectName, @indexName, GETDATE(), @fragPercent)

	SELECT @i = MIN(FragIndexId) 
	FROM #FragIndex
	WHERE FragIndexId > @i

    SELECT 
        @objectId = ObjectId, 
        @indexId = IndexId, 
		@fragPercent = FragPercent,
		@partitionNumber = PartitionNumber,
		@indexType = IndexType,
		@allocUnitType = AllocUnitType
    FROM #FragIndex
    WHERE FragIndexId = @i
END


GO


