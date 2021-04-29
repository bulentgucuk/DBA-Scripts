-- <Migration ID="1e32253f-b981-456c-9e4e-5b22e6d326bf" />
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_EnableDisableIndexes] 
	@Enable INT, 
	@TableName VARCHAR(500), 
	@ViewCurrentIndexState BIT = 0
	, @IndexCompressionType NVARCHAR(16) = 'PAGE'
	, @ForceIndexRebuildOffline BIT = 0 --Force index to rebuild offline 0 = Offline 1 = Allow Online Rebuild if possible
	, @Sort_In_Tempdb BIT = 0 --Rebuild using tempdb to sort index values 1 = ON = , 0 = Of uses local database
	, @Debug BIT = 0 --For debugging 1 = prints the command only, 0 = executes the command
AS
/***********************************************************
2019-12-03 Bulent Gucuk - Added 4 parameters to extend the proc and used SERVERPROPERTY('EngineEdition')
		Database Engine edition of the instance of SQL Server installed on the server.
		1 = Personal or Desktop Engine (Not available in SQL Server 2005 (9.x) and later versions.)
		2 = Standard (This is returned for Standard, Web, and Business Intelligence.)
		3 = Enterprise (This is returned for Evaluation, Developer, and Enterprise editions.)
		4 = Express (This is returned for Express, Express with Tools, and Express with Advanced Services)
		5 = SQL Database
		6 = SQL Data Warehouse
		8 = Managed Instance
		Base data type: int
2019-11-15 Kristine Wyss - change to handle standard edition of sql server
*************************************************************/
--dbo.sp_EnableDisableIndexes 0, 'dbo.DimCustomer', 1

-- ENABLE
-- 1 or 0 = True/False -- WILL EXCLUDE CLUSTERED
-- -1 or -2 True/False -- WILL INCLUDE CLUSTERED

--SET @TableName = 'dbo.DimCustomer';
--SET @Enable = 0;
--SET @ViewCurrentIndexState = 1;

SET NOCOUNT ON;
IF @IndexCompressionType NOT IN('NONE', 'PAGE', 'ROW')
	BEGIN
		PRINT 'The value for the @IndexCompressionType can be one of the following ''NONE'',''PAGE'',''ROW''.';
		RETURN;
	END
DECLARE @SchemaName NVARCHAR(128)
	, @TblName NVARCHAR(128)
	, @Loops SMALLINT
	, @LoopCounter SMALLINT
	, @SQL NVARCHAR(1024)
	, @IndexID SMALLINT
	, @IndexName NVARCHAR(128)
	, @IsDisabled BIT;
SET @LoopCounter = 1;
--Get the schema name and table name and use quotename()
SELECT
	  @SchemaName = SUBSTRING(@TableName,1,CHARINDEX('.', @TableName) -1)
	, @TblName = SUBSTRING(@TableName, CHARINDEX('.', @TableName) + 1, 128);

DECLARE @RebuildOnlineOrOffline NVARCHAR(3);
--If index rebuild is being forced in offline then set to off
IF @ForceIndexRebuildOffline = 1
	BEGIN
		SELECT	@RebuildOnlineOrOffline = 'OFF';
	END
--If index rebuild is not being forced then see if the edition allows it for online operation
--https://docs.microsoft.com/en-us/sql/t-sql/functions/serverproperty-transact-sql?view=sql-server-ver15
ELSE
	BEGIN
		SELECT	@RebuildOnlineOrOffline =
					CASE WHEN SERVERPROPERTY('EngineEdition') IN (3, 5, 6, 8) THEN 'ON'
						 ELSE 'OFF'
					END;
	END

DECLARE @idxtbl TABLE (
  RowId SMALLINT IDENTITY(1,1) PRIMARY KEY
, FullTblName NVARCHAR(256) NOT NULL
, IndexId SMALLINT NOT NULL
, IndexName NVARCHAR(128) NOT NULL
, IdxType NVARCHAR(128) NOT NULL
, IsDisabled BIT NOT NULL
, data_compression_desc VARCHAR(128) NULL
)
INSERT INTO @idxtbl
        ( [FullTblName] ,
          [IndexId] ,
          [IndexName] ,
          [IdxType] ,
		  [IsDisabled] ,
		  [data_compression_desc]
        )
SELECT QUOTENAME(sch.name) + '.' + QUOTENAME(tbl.Name) FullTable, idx.[index_id], QUOTENAME(idx.[name]), idx.type_desc, idx.[is_disabled], p.data_compression_desc
FROM sys.indexes idx
	INNER JOIN sys.tables tbl ON idx.[object_id] = tbl.[object_id]
	INNER JOIN sys.schemas sch ON tbl.[schema_id] = sch.[schema_id]
	LEFT OUTER JOIN sys.partitions AS p ON p.object_id = tbl.object_id AND p.index_id = idx.index_id
WHERE	idx.[index_id] > 0
and     sch.name = @SchemaName
AND		tbl.Name = @TblName
ORDER BY CASE WHEN @Enable IN (0, -1) THEN idx.index_id END ASC,
		CASE WHEN @Enable IN (1, -2) THEN idx.index_id END DESC;

SET @Loops = @@ROWCOUNT;

IF @ViewCurrentIndexState = 1
	SELECT * FROM @idxtbl;


WHILE @Loops >= @LoopCounter
BEGIN
	
	--Set index name and other parameters
	SELECT @IndexName = IndexName
		, @IndexID = IndexId
		, @IsDisabled = IsDisabled
		, @TableName = FullTblName
	FROM	@idxtbl
	WHERE	RowId = @LoopCounter;

	--Disable index statement
	IF ((@Enable = 0 AND @IndexID > 1) OR ABS(@Enable) = 2) AND @IsDisabled = 0
		BEGIN
			SET @SQL = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' DISABLE;';
		END
	--If index is disabled, and it's clustered index or forced to rebuild offline (clustered index cannnot be rebuild online) with compression
	IF ABS(@Enable) = 1 AND @IsDisabled = 1 AND (@RebuildOnlineOrOffline = 'OFF' OR @IndexID = 1)
		BEGIN
			SET @SQL = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REBUILD  WITH (ONLINE = OFF, DATA_COMPRESSION = ' + @IndexCompressionType + ');'
		END
	--If index disabled, it's nonclustered index rebuild online with compression
	ELSE IF ABS(@Enable) = 1 AND @IsDisabled = 1 AND @IndexID > 1
		BEGIN
		SET @SQL = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + ' REBUILD  WITH (ONLINE = ON, DATA_COMPRESSION = ' + @IndexCompressionType + ');'
		END

	--If sort_in_tempdb is on and index is non clustered rebuild using sort_in_tempdb = on
	IF @Sort_In_Tempdb = 1 AND @IndexID <> 1
		BEGIN
			SET @SQL = REPLACE(@SQL, ');', ', SORT_IN_TEMPDB = ON);')
		END
	--Else sort_in_tempdb is off then rebuild using sort_in_tempdb = off
	ELSE
		BEGIN
			SET @SQL = REPLACE(@SQL, ');', ', SORT_IN_TEMPDB = OFF);')
		END

	PRINT (@SQL);
	IF @Debug = 0
		BEGIN
			EXEC sys.sp_executeSQL @stmt = @SQL;
		END

	SET @LoopCounter = @LoopCounter + 1;
END

GO
