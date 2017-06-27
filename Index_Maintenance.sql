-- SCRIPT WORKS WITH TABLE THAT DOES NOT HAVE LARGE OBJECT DATA TYPE LIKE TEXT, VARCHAR(MAX)
-- DROP THE TEMP TABLE IF IT EXISTS
SET NOCOUNT ON
IF OBJECT_ID(N'Tempdb.dbo.LobTemp') IS NOT NULL
	BEGIN
		DROP TABLE Tempdb.dbo.LobTemp
		PRINT ''
		PRINT 'Table has been dropped'
		PRINT ''
	END

-- TABLES WITH TEXT OR LOB DATA TYPES MUST BE EXCLUDED BECAUSE NOT SUPPORTED FOR ONLINE OPERATION
SELECT	OBJECT_NAME(OBJECT_ID) as TableName
		--,*
INTO	Tempdb.dbo.LobTemp
FROM	SYS.COLUMNS
WHERE	OBJECT_ID > 100
AND		(MAX_LENGTH = -1 OR	MAX_LENGTH = 16)
AND		OBJECT_NAME(OBJECT_ID) <> 'dtproperties'
AND		OBJECT_NAME(OBJECT_ID) NOT LIKE 'queue_messages_%'

-- CREATE TABLE VARIABLE TO STORE TABLES TO BE REINDEXEC

DECLARE	@IndexMaint TABLE (
	RowId SMALLINT IDENTITY (1,1),
	TableName VARCHAR (100),
	DBName VARCHAR (30),
	IndexName VARCHAR (100),
	AverageFragmentation NUMERIC --DECIMAL(4,2)
	)

INSERT INTO @IndexMaint

-- TABLE TO RUN INDEX MAINTENANCE
SELECT	object_name(DM_IND.object_Id) as TableName,
		db_name(DM_IND.database_id) AS DBName,
		(SELECT	QUOTENAME(name)
			FROM	sys.indexes ind
			WHERE	ind.object_id = dm_ind.object_id
			AND		ind.index_id = dm_ind.index_id) AS IndexName,
		CAST(DM_IND.avg_fragmentation_in_percent as numeric(10,2)) AS AverageFragmentation
FROM	sys.dm_db_index_physical_stats  
	(DB_ID(), NULL, NULL, NULL, 'LIMITED') dm_ind

	LEFT OUTER JOIN Tempdb.dbo.LobTemp as Lob
		ON Lob.TableName = object_name(DM_IND.object_Id)

WHERE	DM_IND.avg_fragmentation_in_percent > 10
AND		DM_IND.Index_id > 0 -- No heap
AND		Lob.TableName IS NULL


IF EXISTS	(SELECT	1
			 FROM	@IndexMaint
			 WHERE	AverageFragmentation > 10)
	BEGIN
		PRINT 'START INDEX OPERATION'
		DECLARE	@RowId SMALLINT
		SELECT	@RowId = MAX(RowId)
		FROM	@IndexMaint
		
		WHILE	@RowId > 0
			BEGIN
				DECLARE	@IndexName VARCHAR (100),
						@TableName VARCHAR (100),
						@AverageFragmentation NUMERIC,--DECIMAL (4,2),
						@Sql VARCHAR (500)
				SELECT	@IndexName = IndexName,
						@TableName = TableName,
						@AverageFragmentation = AverageFragmentation
				FROM	@IndexMaint
				WHERE	RowId = @RowId

				IF	@AverageFragmentation > 25
					BEGIN
						SELECT	@Sql = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REBUILD WITH (FILLFACTOR = 80, ONLINE = ON)'
						EXEC	(@SQL)
						PRINT	@Sql
						SET	@RowId = @RowId - 1
					END
				IF	@AverageFragmentation < 25 AND @AverageFragmentation > 5
					BEGIN
						SELECT	@Sql = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REORGANIZE'
						EXEC	(@SQL)
						PRINT	@Sql
						SET	@RowId = @RowId - 1
					END	
			END

	END

SELECT	* FROM @INDEXMAINT
DROP TABLE Tempdb.dbo.LobTemp


