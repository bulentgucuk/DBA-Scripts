SELECT  DatabaseName = x.database_name,
        LastBackupFileName = x.physical_device_name,
        LastBackupSartDatetime = x.backup_start_date,
		LastBackupEndDateTime = x.backup_finish_date,
		BackupDurationInMinutes = DATEDIFF(MINUTE, x.backup_start_date, x.backup_finish_date),
		BackupSizeInGB = CAST((backup_size/1024/1024/1024) AS DECIMAL(10,2))
FROM (  SELECT  bs.database_name,
                bs.backup_start_date,
                bmf.physical_device_name,
				bs.backup_finish_date,
				bs.backup_size,
                  Ordinal = ROW_NUMBER() OVER( PARTITION BY bs.database_name ORDER BY bs.backup_start_date DESC )
          FROM  msdb.dbo.backupmediafamily bmf
                  JOIN msdb.dbo.backupmediaset bms ON bmf.media_set_id = bms.media_set_id
                  JOIN msdb.dbo.backupset bs ON bms.media_set_id = bs.media_set_id
          WHERE   bs.[type] = 'D' -- I Diff backup -- L Log backup
		  --AND	  bs.database_name IN ('AdventureWorks')
          --AND	  bs.is_copy_only = 0
		  ) x
WHERE x.Ordinal <= 2
ORDER BY DatabaseName, LastBackupSartDatetime desc;