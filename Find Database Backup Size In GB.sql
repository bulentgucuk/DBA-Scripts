-- If database name changed or database dropped the query most like will not return any info for that database
USE master;
GO
SELECT
	  CAST(b.backup_start_date AS DATE) AS 'BackupDate'
	, b.database_name AS 'DatabaseName'
	, CAST(b.backup_size/1024000 AS DECIMAL (19,2)) AS 'SizeInMegaByte'
	, CAST(b.backup_size/1024000000 AS DECIMAL (19,2)) AS 'SizeInGigaByte'
FROM	msdb.dbo.backupset AS b
	INNER JOIN sys.databases AS d ON b.database_name = d.name
WHERE	b.Type = 'D'
AND		d.database_id > 4
AND		b.backup_start_date > '20170617'
ORDER BY b.database_name, b.backup_start_date DESC