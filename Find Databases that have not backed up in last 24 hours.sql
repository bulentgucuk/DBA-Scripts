--Find Databases that have not been backed up in last 24 hours
SELECT
	  name AS database_name
	, backup_finish_date
	, coalesce(type,'NO BACKUP') AS   last_backup_type FROM (SELECT   database_name
	, backup_finish_date
	, CASE
		WHEN  type = 'D' THEN 'Full'    
		WHEN  type = 'I' THEN 'Differential'                
		WHEN  type = 'L' THEN 'Transaction Log'                
		WHEN  type = 'F' THEN 'File'                
		WHEN  type = 'G' THEN 'Differential File'                
		WHEN  type = 'P' THEN 'Partial'                
		WHEN  type = 'Q' THEN 'Differential partial'
	  END AS type 
FROM	msdb.dbo.backupset AS x
WHERE	backup_finish_date = (SELECT	max(backup_finish_date) 
							  FROM		msdb.dbo.backupset 
							  WHERE		database_name =   x.database_name
							  )
		 ) a
	RIGHT OUTER JOIN sys.databases AS b ON a.database_name = b.name
WHERE	b.name <>   'tempdb' -- Exclude   tempdb 
AND		(backup_finish_date   < dateadd(d,-1,getdate())  )
AND		a.type = 'Full'
ORDER BY backup_finish_date
OPTION(RECOMPILE);
