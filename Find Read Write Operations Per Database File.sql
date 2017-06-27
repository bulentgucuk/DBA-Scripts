-- Find Database Read Write Operations Per Databas File
-- Change the database name to get the database id
USE SOCPlatform
DECLARE @DbID TINYINT = Db_ID()

SELECT	
		DB_NAME(vfs.database_id) AS DatabaseName,
		df.name as DatabaseFileName,
		df.Physical_name as PhysicalFilePath,
		*
FROM	sys.dm_io_virtual_file_stats(@DbID, NULL) AS vfs
	INNER JOIN sys.database_files as df
		ON df.file_id = vfs.file_id
ORDER BY vfs.num_of_writes DESC
