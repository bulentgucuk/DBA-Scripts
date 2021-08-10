
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




--https://blog.dbi-services.com/sql-server-fixing-another-huge-msdb-database-80gb/

select CAST(MIN(send_request_date) AS DATE) AS oldestEmail, Count(*) AS nbRows
from msdb.dbo.sysmail_allitems

select Count(*) AS nbRows, AVG(DATALENGTH(body))/1048576 AS avgSizeMB
from msdb.dbo.sysmail_allitems
where DATALENGTH(body) > 1048576 -- 1MB

select SUM(IIF(sent_status='failed', 0, 1)) AS emailsSent
from msdb.dbo.sysmail_allitems
where DATALENGTH(body) > 1048576 -- 1MB

use msdb
go
declare @retentionDate datetime = DATEADD(MONTH, -6, getdate())
declare @oldest_date datetime = (select min(send_request_date) from msdb.dbo.sysmail_allitems)
 
while (@oldest_date  < @retentionDate)
begin
    print 'sysmail_delete_mailitems_sp ' + CAST(@oldest_date AS varchar)
    exec msdb.dbo.sysmail_delete_mailitems_sp @oldest_date
 
    --  Delete by 1 week increments
    set @oldest_date = DATEADD(WEEK, 1, @oldest_date)
 
    checkpoint
	WAITFOR DELAY '00:00:10'
end