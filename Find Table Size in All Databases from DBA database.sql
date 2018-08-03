use DBA
SELECT
	  CAST(LogDate AS date) AS ReportDate
	, @@SERVERNAME AS DbServer
	, DatabaseName
	, SchemaName
	, TableName
	, CAST((CAST(TotalSpaceKB AS DECIMAL (12,2)) / 1024) / 1024 AS decimal (12,2)) AS TotalSpaceGB
	, TableRowCount
FROM	dbo.TableStatistics
WHERE	LogDate > (SELECT	CAST(MAX(LogDate) AS DATE) FROM	dbo.TableStatistics)
AND		TotalSpaceKB > 1024000
--ORDER BY DatabaseName, SchemaName, TableName, TotalSpaceKB;
ORDER BY TotalSpaceGB DESC;