SELECT	BackupDate = CONVERT(varchar(10),backup_start_date, 111),
		SizeInGigaByte = FLOOR( backup_size/1024000000)
FROM	msdb.dbo.backupset
WHERE	Database_Name = 'ODS' -- CHANGE DB NAME
AND		Type = 'D'
ORDER BY backup_start_date DESC