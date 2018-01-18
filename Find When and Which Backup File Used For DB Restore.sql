-- Find When and Which Backup File Used For DB Restore
SELECT
	  [rs].[destination_database_name]
	, [rs].[restore_date]
	, [bs].[backup_start_date]
	, [bs].[backup_finish_date]
	, [bs].[database_name] as [source_database_name]
	, [bmf].[physical_device_name] as [backup_file_used_for_restore]
FROM	msdb.dbo.restorehistory AS rs
	INNER JOIN msdb.dbo.backupset AS bs ON [rs].[backup_set_id] = [bs].[backup_set_id]
	INNER JOIN msdb.dbo.backupmediafamily AS bmf ON [bs].[media_set_id] = [bmf].[media_set_id]
WHERE	[bs].[backup_start_date] > DATEADD(DAY,-1, GETDATE())
ORDER BY [rs].[restore_date] DESC
OPTION(RECOMPILE);