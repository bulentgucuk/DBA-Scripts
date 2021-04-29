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
	, Bmf.physical_device_name
	, CAST(((bus.backup_size / 1024) / 1024) AS NUMERIC(20,2)) AS backup_size_in_MB
	, CAST(((bus.compressed_backup_size / 1024) / 1024) AS NUMERIC(20,2)) AS compressed_backup_size_in_MB
FROM	sys.databases sdb
	LEFT OUTER JOIN msdb.dbo.backupset bus ON bus.database_name = sdb.name
	LEFT OUTER JOIN msdb.dbo.backupmediafamily as bmf on bus.media_set_id = bmf.media_set_id
	LEFT OUTER JOIN msdb.dbo.backupmediaset AS bms ON bmf.media_set_id = bms.media_set_id
WHERE	bus.backup_finish_date > '20210217'
AND		bus.type = 'D'
ORDER BY sdb.Name, bus.backup_finish_date DESC
OPTION(RECOMPILE);
