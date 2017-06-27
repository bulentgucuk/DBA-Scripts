-- Check if the latest backup file still exists
-- If File exists there is no data returned.
SET NOCOUNT ON 
DECLARE @FileName VARCHAR(255) 
DECLARE @File_Exists INT 
DECLARE @DBname sysname 

--get list of files to check 
DECLARE FileNameCsr CURSOR 
READ_ONLY 
FOR  
   SELECT physical_device_name, sd.name 
   FROM msdb..backupmediafamily bmf 
   INNER JOIN msdb..backupset bms ON bmf.media_set_id = bms.media_set_id 
   INNER JOIN master..sysdatabases sd ON bms.database_name = sd.name 
   AND bms.backup_start_date = (SELECT MAX(backup_start_date) FROM [msdb]..[backupset] b2 
                                   WHERE bms.database_name = b2.database_name AND b2.type = 'D')
   WHERE sd.name NOT IN ('Pubs','tempdb','Northwind', 'Adventureworks') 

BEGIN TRY 
   OPEN FileNameCsr 

   FETCH NEXT FROM FileNameCsr INTO @FileName, @DBname 
   WHILE (@@fetch_status <> -1) 
   BEGIN 
       IF (@@fetch_status <> -2) 
       BEGIN 
           EXEC Master.dbo.xp_fileexist @FileName, @File_Exists OUT 
        
           --if the file is not found, print out a message 
           IF @File_Exists = 0 --0 means file is not found, 1 means it is found 
               PRINT 'File Not Found: ' + @FileName + ' -- for database: ' + @DBName 
       END 
    
   FETCH NEXT FROM FileNameCsr INTO @FileName, @DBName 
   END 
    
END TRY 

BEGIN CATCH 
    SELECT 
        ERROR_NUMBER() AS ErrorNumber 
        ,ERROR_SEVERITY() AS ErrorSeverity 
        ,ERROR_STATE() AS ErrorState 
        ,ERROR_PROCEDURE() AS ErrorProcedure 
        ,ERROR_LINE() AS ErrorLine 
        ,ERROR_MESSAGE() AS ErrorMessage; 
END CATCH 


CLOSE FileNameCsr 
DEALLOCATE FileNameCsr 
GO 