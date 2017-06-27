
-- this deletes the backup history in msdb database
-- link http://msdn.microsoft.com/en-us/library/ms188328.aspx
USE msdb;
GO
-- Backup, maintenenace task cleanup
DECLARE	@DeleteBeforeDate DateTime
SELECT	@DeleteBeforeDate = DATEADD(DAY, DATEDIFF(DAY, 0, GetDate()) - 60, 0)
--SELECT	@DeleteBeforeDate


-- Backup, maintenenace task cleanup
EXEC sp_delete_backuphistory @oldest_date = @DeleteBeforeDate;
EXEC sp_maintplan_delete_log @oldest_time= @DeleteBeforeDate;


-- Mail item cleanup
EXEC sysmail_delete_mailitems_sp @sent_before = @DeleteBeforeDate;
EXEC sysmail_delete_log_sp @logged_before = @DeleteBeforeDate;
