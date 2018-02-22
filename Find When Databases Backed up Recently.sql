SELECT
	  @@SERVERNAME AS 'server_name'
	, sdb.Name AS 'database_name'
	, sdb.recovery_model_desc
	, CASE
		WHEN bus.type = 'D' THEN 'Full Backup'
		WHEN bus.type = 'I' THEN 'Differential Backup'
		ELSE 'T-Log Backup'
		END AS 'backup_type'
	, bus.backup_start_date
	, bus.backup_finish_date
	, DATEDIFF(minute, bus.backup_start_date, bus.backup_finish_date) AS 'MinutesTookToBackup'
	, Bf.physical_device_name
FROM	sys.databases sdb
	LEFT OUTER JOIN msdb.dbo.backupset bus ON bus.database_name = sdb.name
	--LEFT OUTER JOIN msdb.dbo.backupfile AS BF ON bus.backup_set_id = bf.backup_set_id
	LEFT OUTER JOIN msdb.dbo.backupmediafamily as bf on bus.backup_set_id = bf.media_set_id
WHERE	sdb.Name NOT IN ('TempDb')
AND		bus.backup_finish_date > '20180218'
AND		bf.physical_device_name NOT LIKE '{%'
--AND		bus.type = 'D'
ORDER BY sdb.Name, bus.backup_finish_date DESC
OPTION(RECOMPILE);