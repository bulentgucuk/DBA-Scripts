USE master;
GO
SELECT
	  @@SERVERNAME AS 'ServerName'
	, d.name AS 'DatabaseName'
	, CAST(SUM(mf.size) AS bigint) * 8 / 1024 AS 'DatabaseSizeMB'
	, CAST(CAST((CAST(SUM(mf.size) AS bigint) * 8 / 1024) AS numeric(10,2)) / 1024 AS NUMERIC(10,2)) AS 'DatabaseSizeGB'
FROM	sys.master_files AS mf
	INNER JOIN sys.databases AS d ON d.database_id = mf.database_id
WHERE	d.database_id > 4 -- Skip system databases
GROUP BY d.name
ORDER BY DatabaseSizeGB DESC;
