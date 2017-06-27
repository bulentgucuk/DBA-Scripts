--
-- SQL 2008 TDE Setup and Administration
--
-- **** INITIAL setup TDE Encryption WHEN NOT ALREADY SETUP ****
--
-- If has been setup before run RemoveTDE.sql and restart SQL Server before
-- running this script.
--
-- If you run SetupTDE again on same server YOU WILL NOT BE ABLE TO RESTORE OLD BACKUPS UNLESS YOU KEEP THE OLD CERTIFICATE BACKUPS.
--
-- Sean Elliott
-- sean_p_elliott@yahoo.co.uk
--
-- February 2011
--

declare @PassPhrase varchar(255)
declare @BackupFolder varchar(512)
declare @ExecSQL varchar(512)
declare @DateStr varchar(32)
declare @Debug int
-- Set XX_DATABASE_XX string below before running.
-- ** WHILE NOBODY ELSE CAN SEE **
-- This is to be manually set by HR
-- ** Do not save the file once set **
set @PassPhrase = '1_BRI_Supplied_PassPhrase_For_TDE'
set @BackupFolder = 'F:\SQLServer\DBAdmin\TDE\'
set @Debug = 1

print 'Creating Server Master Key'
use master
 set @ExecSQL = 'create master key encryption by password = ''' + @PassPhrase + ''''
if @Debug = 1 print @ExecSQL
exec(@ExecSQL)

print 'Creating server certificate - never expires '
use master
create certificate TDEServerCertificate with subject = 'TDEServerCertificate', expiry_date = '3500-Jan-01'


print 'Backing up Server Master Key to ' + @BackupFolder + 'TDEServerMasterKey.key'
print 'NB SQL Server service account needs write permission in ' + @BackupFolder + ' which may have been removed to avoid accidental deletion'
set @ExecSQL = 'backup master key to file = ''' + @BackupFolder + 'TDEServerMasterKey.key''' + ' encryption by password = ''' + @PassPhrase + ''''
if @Debug = 1 print @ExecSQL
exec(@ExecSQL)

print 'Backing up Server certificate to ' + @BackupFolder + 'TDEServerCertificate.cer'
print 'Backing up Server certificate private key to ' + @BackupFolder + 'TDEServerCertificate.key'
use master
set @ExecSQL =
   'backup certificate TDEServerCertificate TO FILE = ''' + @BackupFolder + 'TDEServerCertificate.cer''' + 
   ' with private key (file = ''' + @BackupFolder + 'TDEServerCertificate.key''' +
   ', encryption by password = ''' + @PassPhrase + ''')'
if @Debug = 1 print @ExecSQL
exec(@ExecSQL)

print 'Creating XX_DATABASE_XX Database Encryption Key'
use XX_DATABASE_XX
create database encryption key with algorithm = aes_128 encryption by server certificate TDEServerCertificate

print 'Switching on XX_DATABASE_XX data encryption via TDE'
use XX_DATABASE_XX
alter database XX_DATABASE_XX set encryption on

print ''
print '**********************************************************************************************************'
print 'Now change permissions so that files in ' + @BackupFolder + ' cannot be accidentally deleted'
print '**********************************************************************************************************'

-- Let user know when encryption has completed
while not exists
(  
   select encryption_state from sys.dm_database_encryption_keys
   where DB_NAME(database_id) = 'XX_DATABASE_XX' and encryption_state = 3
)
begin
   set @DateStr = convert(varchar, getdate(), 120)
   raiserror('%s Waiting 5 seconds for database encryption to complete', 0, 0, @DateStr) with nowait
   waitfor delay '00:00:05' 
end
