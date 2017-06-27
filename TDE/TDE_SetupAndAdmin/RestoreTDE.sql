--
-- SQL 2008 TDE Setup and Administration
--
-- Restore/setup TDE certificates and keys from backup files ready to switch on TDE for a DB 
-- or restore a backup already encrypted by TDE.
--
-- Use RemoveTDE.sql first if the server has previously been configured for TDE.
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

-- ** WHILE NOBODY ELSE CAN SEE **
-- This is to be manually set by HR
-- ** Do not save the file once set **
set @PassPhrase = '1_HR_Supplied_PassPhrase_For_TDE'
set @BackupFolder = 'I:\Program Files\MSSQL\MSSQL10.HR\MSSQL\TDE\'
set @Debug = 1

print 'Restoring master key from file'
use master
set @ExecSQL = 'restore master key from file = ''' + @BackupFolder + 'TDEServerMasterKey.key''' +
' decryption by password = ''' + @PassPhrase + '''' + 
' encryption by password = ''' + @PassPhrase + ''''
if @Debug = 1 print @ExecSQL
exec(@ExecSQL)

/*
restore master key from file = 'I:\Program Files\MSSQL\MSSQL10.HR\MSSQL\TDE\TDEServerMasterKey.key' 
decryption by password = '1_HR_Supplied_PassPhrase_For_TDE' 
encryption by password = '1_HR_Supplied_PassPhrase_For_TDE'
*/

print 'Encrypting master key with service master key'
use master
set @ExecSQL = 'open master key decryption by password = ''' + @PassPhrase + ''''
if @Debug = 1 print @ExecSQL
exec(@ExecSQL)

alter master key add encryption by service master key

/*
open master key decryption by password = '1_HR_Supplied_PassPhrase_For_TDE'
*/

print 'Restoring certificate from file'
use master
set @ExecSQL = 
   'create certificate TDEServerCertificate from file = ''' + @BackupFolder + 'TDEServerCertificate.cer''' +
   ' with private key (file = ''' + @BackupFolder + 'TDEServerCertificate.key''' +
   ', decryption by password = ''' + @PassPhrase + ''')'
if @Debug = 1 print @ExecSQL
exec(@ExecSQL)

/*
create certificate TDEServerCertificate
from file = 'I:\Program Files\MSSQL\MSSQL10.HR\MSSQL\TDE\TDEServerCertificate.cer'
with private key
(
   file = 'I:\Program Files\MSSQL\MSSQL10.HR\MSSQL\TDE\TDEServerCertificate.key',
   decryption by password = '1_HR_Supplied_PassPhrase_For_TDE'
)
*/

print 'Creating XX_DATABASE_XX Database Encryption Key'
use XX_DATABASE_XX
create database encryption key with algorithm = aes_128 encryption by server certificate TDEServerCertificate

print ''
print 'SQL Server is now ready to restore an encrypted XX_DATABASE_XX backup or encrypt an existing unencrypted database via TurnOnTDE'
