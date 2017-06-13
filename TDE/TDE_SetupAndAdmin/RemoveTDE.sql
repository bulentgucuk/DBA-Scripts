--
-- SQL 2008 TDE Setup and Administration
--
-- Remove TDE configuration
--
-- Can be run multiple times - ignore the errors
-- If has been setup before run RemoveTDE.sql and restart SQL Server before
-- running this script.
--
-- Sean Elliott
-- sean_p_elliott@yahoo.co.uk
--
-- February 2011
--

declare @DateStr varchar(32)

print 'Switching off database encryption via TDE'
use XX_DATABASE_XX
alter database XX_DATABASE_XX set encryption off

if exists
(
   select 1 from sys.dm_database_encryption_keys
   where DB_NAME(database_id) = 'XX_DATABASE_XX'
)
begin
   while not exists
   (  
      select encryption_state from sys.dm_database_encryption_keys
      where DB_NAME(database_id) = 'XX_DATABASE_XX' and encryption_state = 1
   )
   begin
      set @DateStr = convert(varchar, getdate(), 120)
      raiserror('%s Waiting 5 seconds for database encryption to complete', 0, 0, @DateStr) with nowait
      waitfor delay '00:00:05' 
   end
end

print 'Dropping existing XX_DATABASE_XX database encryption key'
use XX_DATABASE_XX
drop database encryption key

print 'Dropping existing server certificate and key'
use master
drop certificate TDEServerCertificate
drop master key

print ''
print 'XX_DATABASE_XX database is now unencrypted and SQL Server cannot use TDE. Use RestoreTDE.sql or SetupTDE.sql to reconfigure'
print '** RestoreTDE.sql will allow old backups to be restored. **'
print '**** Re-running SetupTDE.sql will NOT allow old backups to be restored. ****'
print 'Restart SQL to clear tempdb encryption status in sys.dm_database_encryption_keys.'
