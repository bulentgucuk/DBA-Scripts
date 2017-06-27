USE master;
GO
SELECT
	  d.name AS 'DbName'
	, CAST(SUM(mf.size) AS bigint) * 8 / 1024 AS 'DbSizeMB'
FROM	sys.master_files AS mf
	INNER JOIN sys.databases AS d ON d.database_id = mf.database_id
WHERE	d.database_id > 4 -- Skip system databases
GROUP BY d.name
ORDER BY d.name;
