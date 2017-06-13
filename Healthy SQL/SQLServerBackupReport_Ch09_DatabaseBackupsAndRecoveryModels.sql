SELECT          A.database_name  as 'DBName', 
A.backup_finish_date as 'Backup Finished',A.backup_start_date, 
RIGHT('00'+RTRIM(CONVERT(CHAR(2),DATEDIFF(second,a.backup_start_date,a.backup_finish_date)%86400/3600)),2) + ':' + 
RIGHT('00'+RTRIM(CONVERT(CHAR(2),DATEDIFF(second,a.backup_start_date,a.backup_finish_date)%86400%3600/60)),2) + ':' + 
RIGHT('00'+RTRIM(CONVERT(CHAR(2),DATEDIFF(second,a.backup_start_date,a.backup_finish_date)%86400%3600%60)),2) AS 'Run Time', 
B.physical_device_name as 'Backup Filename', 
(a.backup_size/1024/1024) as backup_size_mb 
FROM      msdb.dbo.backupset A, msdb.dbo.backupmediafamily B, 
(SELECT database_name, 
MAX(backup_finish_date) as 'maxfinishdate' 
FROM     msdb.dbo.backupset 
WHERE Type = 'D' 
GROUP BY database_name) C 
WHERE A.media_set_id = B.media_set_id AND 
A.backup_finish_date = C.maxfinishdate AND 
A.type = 'D' 
ORDER BY DBName