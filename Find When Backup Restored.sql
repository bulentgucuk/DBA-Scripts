USE DBA;
GO
SET NOCOUNT ON;
-- Find and save last diff backup restored
IF OBJECT_ID('tempdb..#LastRestoredBackup') IS NOT NULL
	BEGIN
		DROP TABLE #LastRestoredBackup;
	END
SELECT	*
INTO	#LastRestoredBackup
FROM	(
		SELECT	[rs].[destination_database_name],
				[rs].[restore_date],
				[bs].[backup_start_date],
				[bs].[backup_finish_date],
				[bs].[database_name] as [source_database_name],
				[bmf].[physical_device_name] as [backup_file_used_for_restore],
				 Ordinal = ROW_NUMBER() OVER( PARTITION BY bs.database_name ORDER BY bs.backup_start_date DESC )

		FROM	msdb.dbo.restorehistory AS rs
			INNER JOIN msdb.dbo.backupset AS bs
				ON [rs].[backup_set_id] = [bs].[backup_set_id]
			INNER JOIN msdb.dbo.backupmediafamily AS bmf
				ON [bs].[media_set_id] = [bmf].[media_set_id]
		WHERE	[bmf].[physical_device_name] LIKE '%LOG%'
		OR		[bmf].[physical_device_name] LIKE '%DIFF%'
		OR		[bmf].[physical_device_name] LIKE '%FULL%'
		) X
WHERE	X.Ordinal = 1
AND		destination_database_name IN ('CentralIntelligence', 'MDM', 'Shubert_PROD')

-- ABOVE LINE NEEDS TO BE UPDATED OR COMMENTTED OUT FOR INCLUSION OF OTHER DATABASES

SELECT * FROM #LastRestoredBackup
