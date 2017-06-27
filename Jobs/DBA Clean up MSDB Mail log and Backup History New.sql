DECLARE @backupdate DATE = '2009-06-15'
WHILE @backupdate < DATEADD(d, -30, @backupdate)
    BEGIN
        EXEC sp_delete_backuphistory @backupdate
        SELECT @backupdate = DATEADD(d, 15, @backupdate)
    END

DECLARE @maildate DATE = '2009-06-15'
WHILE @maildate < DATEADD(d, -14, GETDATE())
    BEGIN
        EXEC msdb.dbo.sysmail_delete_mailitems_sp @sent_before = @maildate
        SELECT @maildate = DATEADD(d, 5, @maildate)
    END

USE msdb
go
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE OBJECT_ID = OBJECT_ID('[dbo].[backupset]') AND name = 'NCIX_BackupSet_BackupFinishDate_MediaSetID')
CREATE NONCLUSTERED INDEX NCIX_BackupSet_BackupFinishDate_MediaSetID ON dbo.backupset(backup_finish_date) include (media_set_id)
 
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE OBJECT_ID = OBJECT_ID('[dbo].[backupset]') AND name = 'NCIX_BackupSet_BackupStartDate_MediaSetID')
CREATE NONCLUSTERED INDEX NCIX_BackupSet_BackupStartDate_MediaSetID ON dbo.backupset(backup_start_date) include (media_set_id)
    
    




DECLARE @DeleteDate DATE = '2011-10-01'
WHILE @DeleteDate < DATEADD(d, -30, GETDATE())
    BEGIN
		PRINT @DeleteDate
        DELETE FROM dbo.sysssislog
        WHERE	endtime < @DeleteDate
        SELECT @DeleteDate = DATEADD(d, 5, @DeleteDate)
    END