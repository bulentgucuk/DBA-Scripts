SET NOCOUNT ON;
-- Get Table Statistics (Row Count, total space used)
IF OBJECT_ID('tempdb..#TableStatistics') IS NOT NULL
	BEGIN
		DROP TABLE #TableStatistics;
	END
CREATE TABLE #TableStatistics (DatabaseName SYSNAME, SchemaName SYSNAME, TableName VARCHAR(128), TableRowCount BIGINT, TotalSpaceKB VARCHAR(20), UsedSpaceKB VARCHAR(20), UnusedSpaceKB VARCHAR(20));

EXEC sp_msforeachdb 'USE [?];
	INSERT INTO #TableStatistics 
	SELECT
		  ''?'' as DatabaseName
		, s.Name AS SchemaName
		, t.NAME AS TableName
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
	GROUP BY	t.Name, s.Name, p.Rows 
	ORDER BY s.name,  t.name' ;

SELECT	*
FROM	#TableStatistics;

DROP TABLE #TableStatistics;
