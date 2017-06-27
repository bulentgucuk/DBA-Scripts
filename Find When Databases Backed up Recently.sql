SELECT
	  sdb.Name AS DatabaseName
	, bus.backup_finish_date
	, Bf.physical_device_name
FROM	sys.sysdatabases sdb
	LEFT OUTER JOIN msdb.dbo.backupset bus ON bus.database_name = sdb.name
	--LEFT OUTER JOIN msdb.dbo.backupfile AS BF ON bus.backup_set_id = bf.backup_set_id
	LEFT OUTER JOIN msdb.dbo.backupmediafamily as bf on bus.backup_set_id = bf.media_set_id
WHERE	sdb.Name != 'TempDb'
AND		bus.backup_finish_date > '20160509'
--AND		bus.type = 'D'
ORDER BY sdb.Name, bus.backup_finish_date DESC
