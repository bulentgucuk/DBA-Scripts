SET NOCOUNT ON;
-- Get Table Statistics (Row Count, total space used)
IF OBJECT_ID('tempdb..#TableStatistics') IS NOT NULL
	BEGIN
		DROP TABLE #TableStatistics;
	END
CREATE TABLE #TableStatistics (DatabaseName SYSNAME, SchemaName SYSNAME, TableName VARCHAR(128), is_ms_shipped BIT, TableRowCount BIGINT, TotalSpaceKB BIGINT, UsedSpaceKB BIGINT, UnusedSpaceKB BIGINT);

EXEC sp_msforeachdb 'USE [?];
	INSERT INTO #TableStatistics 
	SELECT
		  ''?'' as DatabaseName
		, s.Name AS SchemaName
		, t.NAME AS TableName
		, t.is_ms_shipped
		, p.rows AS TableRowCount
		, SUM(a.total_pages) * 8 AS TotalSpaceKB
		, SUM(a.used_pages) * 8 AS UsedSpaceKB
		, (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
	FROM	sys.tables AS t
		INNER JOIN sys.indexes AS i ON t.OBJECT_ID = i.object_id
		INNER JOIN sys.partitions AS p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
		INNER JOIN sys.allocation_units AS a ON p.partition_id = a.container_id
		LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
	--WHERE    p.rows > 0 AND t.is_ms_shipped = 0    AND i.OBJECT_ID > 255 
	GROUP BY	t.Name, s.Name, p.Rows, t.is_ms_shipped
	ORDER BY s.name,  t.name' ;

WITH CTE_Tables AS (
	SELECT	ROW_NUMBER () OVER (PARTITION BY DatabaseName ORDER BY DatabaseName, TotalSpaceKB  desc) AS RowNumber, *
	FROM	#TableStatistics
	)
SELECT
	  DatabaseName
	, SchemaName
	, TableName
	, TableRowCount
	--, TotalSpaceKB
	--, CAST(TotalSpaceKB AS DECIMAL(19,2))
	, CAST(CAST(TotalSpaceKB AS DECIMAL(19,2)) / 1024 AS DECIMAL (19,2)) AS 'TotalSpaceInMB'
FROM	CTE_Tables
WHERE	DatabaseName NOT IN ('master', 'tempdb','msdb', 'model')
AND		is_ms_shipped = 0
AND		TotalSpaceKB > 0
--AND		RowNumber <= 10;
ORDER BY DatabaseName, TotalSpaceInMB DESC

DROP TABLE #TableStatistics;

