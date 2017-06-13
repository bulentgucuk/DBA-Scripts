--
-- SQL 2008 TDE Setup and Administration
--
-- Backup the TDE certificate and keys. Done as part of SetupTDE but can be redone by this script
-- if the backup files are lost.
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

print 'Backing up Server Master Key to ' + @BackupFolder + 'TDEServerMasterKey.key'
print 'NB SQL Server service account needs write permission in ' + @BackupFolder + ' which may have been removed to avoid accidental deletion'
use master
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
