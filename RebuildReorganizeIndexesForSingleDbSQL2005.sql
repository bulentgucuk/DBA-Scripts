USE NetQuoteTechnologyOperations
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.RebuildIndexes (
	@maxfrag float = 15.0
	, @maxdensity float = 75.0
	, @databasename varchar(255))

AS 
/*

dbo.RebuildIndexes is a process which will assess
the level of fragmentation of all indexes in a 
database and reorganize those indexes which fall 
outside the specified parameters.

dbo.RebuildIndexes accepts the following parameters:
@maxfrag	The maximum level of acceptable fragmentation 
@maxdensity	The minimum level of acceptable density
@databasename	The database to assess and reorganize

This procedure assumes that a partitioned index will not
be processed ONLINE.  

Example:
EXEC dbo.RebuildIndexes @maxfrag=15.0, @maxdensity=90.0
		, @databasename='AdventureWorks'
*/

SET NOCOUNT ON;
DECLARE @schemaname sysname;
DECLARE @objectname sysname;
DECLARE @indexname sysname;
DECLARE @indexid int; 
DECLARE @currentfrag float;
DECLARE @currentdensity float;
DECLARE @partitionnum varchar(10);
DECLARE @partitioncount bigint;
DECLARE @indextype varchar(18);
DECLARE @updatecommand varchar(max);
DECLARE @command varchar(max);
DECLARE	@dbid tinyint;

-- get the db_id using passed in databasename parameter
SELECT	@dbid = DB_ID (@DATABASENAME)

-- ensure the temporary table does not exist
IF (SELECT object_id('tempdb..#work_to_do')) IS NOT NULL
	DROP TABLE #work_to_do;

CREATE TABLE #work_to_do(
	IndexID int not null
	, IndexName varchar(255) null
	, TableName varchar(255) null
	, Tableid int not null
	, SchemaName varchar(255) null
	, IndexType varchar(18) not null
	, PartitionNumber varchar(18) not null
	, PartitionCount int null
	, CurrentDensity float not null
	, CurrentFragmentation float not null
);

INSERT INTO #work_to_do(
	IndexID, Tableid,  IndexType, PartitionNumber, CurrentDensity, CurrentFragmentation
	)
	SELECT
		fi.index_id 
		, fi.object_id 
		, fi.index_type_desc AS IndexType
		, cast(fi.partition_number as varchar(10)) AS PartitionNumber
		, fi.avg_page_space_used_in_percent AS CurrentDensity
		, fi.avg_fragmentation_in_percent AS CurrentFragmentation
	FROM	sys.dm_db_index_physical_stats(@dbid, NULL, NULL, NULL, 'SAMPLED') AS fi 
	WHERE	(fi.avg_fragmentation_in_percent >= @maxfrag 
	OR		fi.avg_page_space_used_in_percent < @maxdensity)
	AND		page_count> 8
	AND		fi.index_id > 0

--Assign the index names, schema names, table names and partition counts
SET @updatecommand = 'UPDATE #work_to_do SET TableName = o.name, SchemaName = s.name, IndexName = i.Name 
	,PartitionCount = (SELECT COUNT(*) pcount
	FROM ' 
	+ QUOTENAME(@databasename) + '.sys.Partitions p
	where  p.Object_id = w.Tableid 
	AND p.index_id = w.Indexid)
	FROM ' 
	+ QUOTENAME(@databasename) + '.sys.objects o INNER JOIN '
	+ QUOTENAME(@databasename) + '.sys.schemas s ON o.schema_id = s.schema_id 
	INNER JOIN #work_to_do w ON o.object_id = w.tableid INNER JOIN '
	+ QUOTENAME(@databasename) + '.sys.indexes i ON w.tableid = i.object_id and w.indexid = i.index_id';

	EXEC(@updatecommand)

--Declare the cursor for the list of tables, indexes and partitions to be processed.
--If the index is a clustered index, rebuild all of the nonclustered indexes for the table.
--If we are rebuilding the clustered indexes for a table, we can exclude the 
--nonclustered and specify ALL instead on the table

DECLARE rebuildindex CURSOR FOR 
	SELECT	QUOTENAME(IndexName) AS IndexName
			, TableName
			, SchemaName
			, IndexType
			, PartitionNumber
			, PartitionCount
			, CurrentDensity
			, CurrentFragmentation
	FROM	#work_to_do i 
	ORDER BY TableName, IndexID;

-- Open the cursor.
OPEN rebuildindex;

-- Loop through the tables, indexes and partitions.
FETCH NEXT
   FROM rebuildindex
   INTO @indexname, @objectname, @schemaname, @indextype, @partitionnum, @partitioncount, @currentdensity, @currentfrag;

WHILE @@FETCH_STATUS = 0
	BEGIN

	SELECT @command = 'ALTER INDEX ' + @indexname + ' ON ' + QUOTENAME(@databasename) +'.' + QUOTENAME(@schemaname) + '.' + QUOTENAME(@objectname);

	-- If the index is more heavily fragmented, issue a REBUILD.  Otherwise, REORGANIZE.
			IF @currentfrag < 30
				BEGIN;
				SELECT @command = @command + ' REORGANIZE';
				IF @partitioncount > 1
					SELECT @command = @command + ' PARTITION=' + @partitionnum;
				END;

			IF @currentfrag >= 30
				BEGIN;
				SELECT @command = @command + ' REBUILD';
				IF @partitioncount > 1
					SELECT @command = @command + ' PARTITION=' + @partitionnum;
				END;
		EXEC (@command);
		PRINT 'Executed ' + @command;

		FETCH NEXT FROM rebuildindex INTO @indexname, @objectname, @schemaname, @indextype, @partitionnum, @partitioncount, @currentdensity, @currentfrag;
	END;
-- Close and deallocate the cursor.
CLOSE rebuildindex;
DEALLOCATE rebuildindex;
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
