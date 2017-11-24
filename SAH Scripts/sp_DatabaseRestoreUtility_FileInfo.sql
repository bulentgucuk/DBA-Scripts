USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DatabaseRestoreUtility_FileInfo]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[sp_DatabaseRestoreUtility_FileInfo]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



create procedure [dbo].[sp_DatabaseRestoreUtility_FileInfo]

/*************************************************************************************
** proc name:           sp_DatabaseRestoreUtility_FileInfo
**
**                      SQL 2005+
**
** Version:             1
**
** Description:         Procedure to restore database backups
**
** Output Parameters:   Default output is a PRINT out of database and logfile restores.
**
** Dependent On:        function master.dbo.Lsn2Numeric (function HexToInt)
**                      function msdb.dbo.fn_encrpt_key
**
** Example:             master..sp_DatabaseRestoreUtility_FileInfo
**                       @path             = ''               -- path to backup files
**                      ,@file_ext         = ''               -- bkp LiteSpeed Files
**                      ,@bkp_type         = ''               -- L(itespeed), S(QL Native)
**                      ,@history          = 1                -- 0 scan all files each run (slower), 1 use history tables for file header info (faster)
**                      
** History:
**      Name            Date            Pr Number       Description
**      ----------      -----------     ---------       ---------------
**      B. Jones        05/20/2011      n/a             Creation of inital script
**      
**      
**      
**
*************************************************************************************/

        @path                varchar(260)      = ''        -- path to backup files
       ,@file_ext            varchar(3)        = ''        -- bkp LiteSpeed Files
       ,@bkp_type            char(1)           = ''        -- L(itespeed), S(QL Native)
       ,@history             bit               = 1         -- 0 scan all files each run (slower), 1 use history tables for file header info (faster)

--with encryption

as
begin -- proc start

set nocount on

declare @sql_version         varchar(20)                   -- sql server version: 8(2000), 9(2005), 10(2008)
       ,@sls_version         varchar(20)                   -- lightspeed version: 6.1.1.1011
       ,@cmd                 varchar(max)                  --
       ,@id                  int                           --
       ,@FileName            varchar(255)                  -- filename of backup
       ,@restore_all         bit                           -- 
       ,@backup_mode         smallint                      -- 1 Full, 2 Log
       ,@db_name_lsn         sysname                       -- DB name to check for LSN
       ,@dbLSN               numeric(25,0)                 -- DB LSN converted to numeric for comparison to RESTORE HEADERONLY RESULTS
       ,@Prev_Mode           smallint                      -- End LSN for previous backup file
       ,@PrevdbLSN           numeric(25,0)                 -- End LSN for previous backup file
       ,@PrevLSN             numeric(25,0)                 -- End LSN for previous backup file
       ,@NextLSN             numeric(25,0)                 -- Start LSN for next backup file
       ,@FileOrder           int                           --
       ,@lastdb              int                           -- FileOrder number of last backup file for database
       ,@model               tinyint                       -- 1 = FULL, 2 = BULK_LOGGED, 3 = SIMPLE
       ,@model_desc          nvarchar(60)                  -- FULL, BULK_LOGGED, SIMPLE
       ,@readonly            bit                           -- 0 = Database is READ_WRITE, 1 = Database is READ_ONLY
       ,@standby             bit                           -- 1 = Database is read-only for restore log. 

-- Encrption Key
declare @client_abbr         char(4)                       -- Encryption Key Clent Abbr
       ,@backup_type         char(1)                       -- L is for LiteSpeed in the encryption table.
       ,@eff_dt              datetime                      -- Encryption Key effective date
       ,@EncryptionKey       varchar(36)                   -- Encrption Key to be fetched FROM the encryption function

-- headeronly
declare @ServerName          nvarchar(128)                 -- 
       ,@DatabaseName        nvarchar(128)                 -- 
       ,@BackupType          smallint                      -- 
       ,@Position            smallint                      -- 
       ,@BackupStartDate     datetime                      -- 
       ,@BackupDescription   nvarchar(255)                 -- 
       ,@FirstLSN            numeric(25,0)                 -- 
       ,@LastLsn             numeric(25,0)                 -- 
       ,@Encryption          bit                           -- 

-- filelistonly
declare @LogicalName         nvarchar(128)                 -- 
       ,@PhysicalName        nvarchar(260)                 -- 
       ,@Type                char(1)                       -- 
       ,@FileGroupName       nvarchar(128)                 -- 
       ,@FileId              bigint                        -- 

--labelonly
declare @FamilyCount         int                           -- 
       ,@FamilySeqNum        int                           -- 
       ,@MediaDate           datetime                      -- 

-- @tables used for fileinfo
declare @headeronly2005 table (
        [BackupName]         nvarchar(128)       null
       ,[BackupDescription]  nvarchar(255)       null
       ,[BackupType]         smallint            null
       ,[ExpirationDate]     datetime            null
       ,[Compressed]         tinyint             null
       ,[Position]           smallint            null
       ,[DeviceType]         tinyint             null
       ,[UserName]           nvarchar(128)       null
       ,[ServerName]         nvarchar(128)       null
       ,[DatabaseName]       nvarchar(128)       null
       ,[DatabaseVersion]    int                 null
       ,[CreationDate]       datetime            null
       ,[BackupSize]         numeric(20,0)       null
       ,[FirstLSN]           numeric(25,0)       null
       ,[LastLsn]            numeric(25,0)       null
       ,[CheckpointLSN]      numeric(25,0)       null
       ,[DatabaseBackupLSN]  numeric(25,0)       null
       ,[BackupStartDate]    datetime            null
       ,[BackupFinishDate]   datetime            null
       ,[SortORDER]          smallint            null
       ,[CodePage]           smallint            null
       ,[UnicodeLocaleId]    int                 null
       ,[UnicodeStyle]       int                 null
       ,[CompatibilityLevel] tinyint             null
       ,[SoftwareVENDorId]   int                 null
       ,[VersionMajor]       int                 null
       ,[VersionMinor]       int                 null
       ,[VersionBuild]       int                 null
       ,[MachineName]        nvarchar(128)       null
       ,[Flags]              int                 null
       ,[BindingID]          uniqueidentifier    null
       ,[RecoveryForkID]     uniqueidentifier    null
       ,[Collation]          nvarchar(128)       null
       ,[FamilyGUID]         uniqueidentifier    null
       ,[HasBulkLoggedData]  bit                 null
       ,[IsSnapshot]         bit                 null
       ,[IsReadOnly]         bit                 null
       ,[IsSingleUser]       bit                 null
       ,[HasBackupChecksums] bit                 null
       ,[IsDamaged]          bit                 null
       ,[BEGINsLogChain]     bit                 null
       ,[IncompleteMetaData] bit                 null
       ,[IsForceOffline]     bit                 null
       ,[IsCopyOnly]         bit             
    null
       ,[FirstForkID]        uniqueidentifier    null
       ,[ForkPointLSN]       numeric(25,0)       null
       ,[RecoveryModel]      nvarchar(60)        null
       ,[DIFBaseLSN]         numeric(25,0)       null
       ,[DIFBaseGUID]        uniqueidentifier    null
       ,[BackupTypeDesc]     nvarchar(60)        null
       ,[BackupSetGUID]      uniqueidentifier    null
)
declare @filelistonly2005 table (
        [LogicalName]        varchar(128)        null
       ,[PhysicalName]       varchar(128)        null
       ,[Type]               char(1)             null
       ,[FileGroupName]      varchar(128)        null
       ,[Size]               numeric(20,0)       null
       ,[MaxSize]            numeric(20,0)       null
       ,[FileId]             int                 null
       ,[CreateLSN]          numeric(25,0)       null
       ,[DropLSN]            numeric(25,0)       null
       ,[UniqueID]           uniqueidentifier    null
       ,[ReadOnlyLSN]        numeric(25,0)       null
       ,[ReadWriteLSN]       numeric(25,0)       null
       ,[BackupSizeInBytes]  bigint              null
       ,[SourceBlockSize]    bigint              null
       ,[FileGroupID]        int                 null
       ,[LogGroupGUID]       uniqueidentifier    null
       ,[DifBaseLSN]         numeric(25,0)       null
       ,[DifBaseGUID]        uniqueidentifier    null
       ,[IsReadOnly]         bit                 null
       ,[IsPresent]          bit                 null
)
declare @labelonly2005 table (
        [MediaName]          nvarchar(128)       null
       ,[MediaSetId]         uniqueidentifier    null
       ,[FamilyCount]        int                 null
       ,[FamilySeqNumber]    int                 null
       ,[MediaFamilyId]      uniqueidentifier    null
       ,[MediaSeqNumber]     int                 null
       ,[MediaLabelPresent]  tinyint             null
       ,[MediaDescription]   nvarchar(255)       null
       ,[SoftwareName]       nvarchar(128)       null
       ,[SoftwareVendorId]   int                 null
       ,[MediaDate]          datetime            null
       ,[MirrorCount]        int                 null
)

declare @headeronly2008 table (
        [BackupName]         nvarchar(128)       null
       ,[BackupDescription]  nvarchar(255)       null
       ,[BackupType]         smallint            null
       ,[ExpirationDate]     datetime            null
       ,[Compressed]         tinyint             null
       ,[Position]           smallint            null
       ,[DeviceType]         tinyint             null
       ,[UserName]           nvarchar(128)       null
       ,[ServerName]         nvarchar(128)       null
       ,[DatabaseName]       nvarchar(128)       null
       ,[DatabaseVersion]    int                 null
       ,[CreationDate]       datetime            null
       ,[BackupSize]         numeric(20,0)       null
       ,[FirstLSN]           numeric(25,0)       null
       ,[LastLsn]            numeric(25,0)       null
       ,[CheckpointLSN]      numeric(25,0)       null
       ,[DatabaseBackupLSN]  numeric(25,0)       null
       ,[BackupStartDate]    datetime            null
       ,[BackupFinishDate]   datetime            null
       ,[SortORDER]          smallint            null
       ,[CodePage]           smallint            null
       ,[UnicodeLocaleId]    int                 null
       ,[UnicodeStyle]       int                 null
       ,[CompatibilityLevel] tinyint             null
       ,[SoftwareVENDorId]   int                 null
       ,[VersionMajor]       int                 null
       ,[VersionMinor]       int                 null
       ,[VersionBuild]       int                 null
       ,[MachineName]        nvarchar(128)       null
       ,[Flags]              int                 null
       ,[BindingID]          uniqueidentifier    null
       ,[RecoveryForkID]     uniqueidentifier    null
       ,[Collation]          nvarchar(128)       null
       ,[FamilyGUID]         uniqueidentifier    null
       ,[HasBulkLoggedData]  bit                 null
       ,[IsSnapshot]         bit                 null
       ,[IsReadOnly]         bit                 null
       ,[IsSingleUser]       bit                 null
       ,[HasBackupChecksums] bit                 null
       ,[IsDamaged]          bit                 null
       ,[BEGINsLogChain]     bit                 null
       ,[IncompleteMetaData] bit                 null
       ,[IsForceOffline]     bit                 null
       ,[IsCopyOnly]         bit                 null
       ,[FirstForkID]        uniqueidentifier    null
       ,[ForkPointLSN]       numeric(25,0)       null
       ,[RecoveryModel]      nvarchar(60)        null
       ,[DIFBaseLSN]         numeric(25,0)       null
       ,[DIFBaseGUID]        uniqueidentifier    null
       ,[BackupTypeDesc]     nvarchar(60)        null
       ,[BackupSetGUID]      uniqueidentifier    null
       ,[CompressedSize]     numeric(20,0)       null
)
declare @filelistonly2008 table (
        [LogicalName]        varchar(128)        null
       ,[PhysicalName]       varchar(128)        null
       ,[Type]               char(1)             null
       ,[FileGroupName]      varchar(128)        null
       ,[Size]               numeric(20,0)       null
       ,[MaxSize]            numeric(20,0)       null
       ,[FileId]             int                 null
       ,[CreateLSN]          numeric(25,0)       null
       ,[DropLSN]            numeric(25,0)       null
       ,[UniqueID]           uniqueidentifier    null
       ,[ReadOnlyLSN]        numeric(25,0)       null
       ,[ReadWriteLSN]       numeric(25,0)       null
       ,[BackupSizeInBytes]  bigint              null
       ,[SourceBlockSize]    bigint              null
       ,[FileGroupID]        int                 null
       ,[LogGroupGUID]       uniqueidentifier    null
       ,[DifBaseLSN]         numeric(25,0)       null
       ,[DifBaseGUID]        uniqueidentifier    null
       ,[IsReadOnly]         bit                 null
       ,[IsPresent]          bit                 null
       ,[TDEThumbprint]      varbinary(32)       null
)
declare @labelonly2008 table (
        [MediaName]          nvarchar(128)       null
       ,[MediaSetId]         uniqueidentifier    null
       ,[FamilyCount]        int                 null
       ,[FamilySeqNumber]    int                 null
       ,[MediaFamilyId]      uniqueidentifier    null
       ,[MediaSeqNumber]     int                 null
       ,[MediaLabelPresent]  tinyint             null
       ,[MediaDescription]   nvarchar(255)       null
       ,[SoftwareName]       nvarchar(128)       null
       ,[SoftwareVendorId]   int                 null
       ,[MediaDate]          datetime            null
       ,[MirrorCount]        int                 null
       ,[IsCompressed]       bit                 null
)

declare @headeronly2011 table (
        [BackupName]         nvarchar(128)       null
       ,[BackupDescription]  nvarchar(255)       null
       ,[BackupType]         smallint            null
       ,[ExpirationDate]     datetime            null
       ,[Compressed]         tinyint             null
       ,[Position]           smallint            null
       ,[DeviceType]         tinyint             null
       ,[UserName]           nvarchar(128)       null
       ,[ServerName]         nvarchar(128)       null
       ,[DatabaseName]       nvarchar(128)       null
       ,[DatabaseVersion]    int                 null
       ,[CreationDate]       datetime            null
       ,[BackupSize]         numeric(20,0)       null
       ,[FirstLSN]           numeric(25,0)       null
       ,[LastLsn]            numeric(25,0)       null
       ,[CheckpointLSN]      numeric(25,0)       null
       ,[Data
baseBackupLSN]  numeric(25,0)       null
       ,[BackupStartDate]    datetime            null
       ,[BackupFinishDate]   datetime            null
       ,[SortORDER]          smallint            null
       ,[CodePage]           smallint            null
       ,[UnicodeLocaleId]    int                 null
       ,[UnicodeStyle]       int                 null
       ,[CompatibilityLevel] tinyint             null
       ,[SoftwareVENDorId]   int                 null
       ,[VersionMajor]       int                 null
       ,[VersionMinor]       int                 null
       ,[VersionBuild]       int                 null
       ,[MachineName]        nvarchar(128)       null
       ,[Flags]              int                 null
       ,[BindingID]          uniqueidentifier    null
       ,[RecoveryForkID]     uniqueidentifier    null
       ,[Collation]          nvarchar(128)       null
       ,[FamilyGUID]         uniqueidentifier    null
       ,[HasBulkLoggedData]  bit                 null
       ,[IsSnapshot]         bit                 null
       ,[IsReadOnly]         bit                 null
       ,[IsSingleUser]       bit                 null
       ,[HasBackupChecksums] bit                 null
       ,[IsDamaged]          bit                 null
       ,[BEGINsLogChain]     bit                 null
       ,[IncompleteMetaData] bit                 null
       ,[IsForceOffline]     bit                 null
       ,[IsCopyOnly]         bit                 null
       ,[FirstForkID]        uniqueidentifier    null
       ,[ForkPointLSN]       numeric(25,0)       null
       ,[RecoveryModel]      nvarchar(60)        null
       ,[DIFBaseLSN]         numeric(25,0)       null
       ,[DIFBaseGUID]        uniqueidentifier    null
       ,[BackupTypeDesc]     nvarchar(60)        null
       ,[BackupSetGUID]      uniqueidentifier    null
       ,[CompressedSize]     numeric(20,0)       null
       ,[Containment]        varchar(255)        null
)
declare @filelistonly2011 table (
        [LogicalName]        varchar(128)        null
       ,[PhysicalName]       varchar(128)        null
       ,[Type]               char(1)             null
       ,[FileGroupName]      varchar(128)        null
       ,[Size]               numeric(20,0)       null
       ,[MaxSize]            numeric(20,0)       null
       ,[FileId]             int                 null
       ,[create tableLSN]    numeric(25,0)       null
       ,[DropLSN]            numeric(25,0)       null
       ,[UniqueID]           uniqueidentifier    null
       ,[ReadOnlyLSN]        numeric(25,0)       null
       ,[ReadWriteLSN]       numeric(25,0)       null
       ,[BackupSizeInBytes]  bigint              null
       ,[SourceBlockSize]    bigint              null
       ,[FileGroupID]        int                 null
       ,[LogGroupGUID]       uniqueidentifier    null
       ,[DifBaseLSN]         numeric(25,0)       null
       ,[DifBaseGUID]        uniqueidentifier    null
       ,[IsReadOnly]         bit                 null
       ,[IsPresent]          bit                 null
       ,[[TDEThumbprint]     varbinary(32)       null
)
declare @labelonly2011 table (
        [MediaName]          nvarchar(128)       null
       ,[MediaSetId]         uniqueidentifier    null
       ,[FamilyCount]        int                 null
       ,[FamilySeqNumber]    int                 null
       ,[MediaFamilyId]      uniqueidentifier    null
       ,[MediaSeqNumber]     int                 null
       ,[MediaLabelPresent]  tinyint             null
       ,[MediaDescription]   nvarchar(255)       null
       ,[SoftwareName]       nvarchar(128)       null
       ,[SoftwareVendorId]   int                 null
       ,[MediaDate]          datetime            null
       ,[MirrorCount]        int                 null
       ,[IsCompressed]       bit                 null
)

declare @headeronly6 table (
        [FileNumber]         nvarchar(128)       null
       ,[BackupFormat]       nvarchar(128)       null
       ,[Guid]               nvarchar(128)       null
       ,[BackupName]         nvarchar(128)       null
       ,[BackupDescription]  nvarchar(255)       null
       ,[BackupType]         smallint            null
       ,[ExpirationDate]     datetime            null
       ,[Compressed]         tinyint             null
       ,[Position]           smallint            null
       ,[DeviceType]         tinyint             null
       ,[UserName]           nvarchar(128)       null
       ,[ServerName]         nvarchar(128)       null
       ,[DatabaseName]       nvarchar(128)       null
       ,[DatabaseVersion]    int                 null
       ,[CreationDate]       datetime            null
       ,[BackupSize]         numeric(20,0)       null
       ,[FirstLSN]           numeric(25,0)       null
       ,[LastLsn]            numeric(25,0)       null
       ,[CheckpointLSN]      numeric(25,0)       null
       ,[DIFBaseLsn]         numeric(25,0)       null
       ,[BackupStartDate]    datetime            null
       ,[BackupFinishDate]   datetime            null
       ,[SortORDER]          smallint            null
       ,[CodePage]           smallint            null
       ,[CompatibilityLevel] tinyint             null
       ,[VENDorId]           int                 null
       ,[VersionMajor]       int                 null
       ,[VersionMinor]       int                 null
       ,[VersionBuild]       int                 null
       ,[MachineName]        nvarchar(128)       null
       ,[BindingId]          uniqueidentifier    null
       ,[RecoveryForkId]     uniqueidentifier    null
       ,[Encryption]         nvarchar(128)       null
       ,[IsCopyOnly]         nvarchar(128)       null
)
declare @filelistonly6 table (
        [LogicalName]        varchar(128)        null
       ,[PhysicalName]       varchar(128)        null
       ,[Type]               char(1)             null
       ,[FileGroupName]      varchar(128)        null
       ,[Size]               numeric(20,0)       null
       ,[MaxSize]            numeric(20,0)       null
       ,[FileId]             int                 null
       ,[BackupSizeInBytes]  numeric(20,0)       null
       ,[FileGroupId]        int                 null
)
declare @setinfo6 table (
        [FormatVersion]      int                 null
       ,[StripeGUID]         uniqueidentifier    null
       ,[StripeNumber]       int                 null
       ,[StripeCount]        int                 null
)

declare @FileNames table (
        [id]                 int                 identity(1,1)
       ,[FileName]           varchar(255)        null
)

declare @ho_FileNames table (
        [id]                 int                 null
       ,[FileName]           varchar(255)        null
)
declare @lo_FileNames table (
        [id]                 int                 null
       ,[FileName]           varchar(255)        null
)
declare @fo_FileNames table (
        [id]                 int null
       ,[FileName]           varchar(255)        null
)

declare @sqllitespeed table (
        [name]               nvarchar(25)        null
       ,[value]              nvarchar(25)        null
)
--

if @path != ''
 begin
    if left(reverse(@path), 1) != '\'
     begin
        set @path = @path + '\'
     end
 end
else
 begin
    print '@path not specified!'
    return
 end

set @bkp_type = UPPER(@bkp_type)
if @bkp_type != 'L' and @bkp_type != 'S' -- L(itespeed), S(QL Native)
 begin
    print @bkp_type + ' is not a valid backup type!'
    return
 end

if @file_ext = ''
 begin
  if @bkp_type = 'L' -- L(itespeed) = bkp
   begin
    set @file_ext = 'bkp'
   end
  if @bkp_type = 'S' -- S(QL Native) = bak
   begin
    set @file_ext = 'bak'
   end
 end
 
-- get mssql version
set @sql_ve
rsion = left((select cast(serverproperty('productversion') as varchar(20))), patindex('%[.]%', (select cast(serverproperty('productversion') as varchar(20))))-1)

-- get lightspeed version
if exists(select [name] from master.sys.objects where type = 'X' and name = 'xp_sqllitespeed_version')
 begin
    insert @sqllitespeed
    exec ('master.dbo.xp_sqllitespeed_version')
    select top 1 @sls_version = [value] from @sqllitespeed where [name] = 'Engine Version' or [name] = 'xpSLS.dll'
 end
 
if @bkp_type = 'L' -- L(itespeed)
 begin
    if not exists(select [name] from master.sys.objects where type = 'X' and name = 'xp_sqllitespeed_version')
     begin
          print 'litespeed not installed'
          return
     end
    else
     begin
        if @sls_version not in ('6.1.0.1324','6.1.1.1011','6.5.0.1460')
         begin
            print 'litespeed version supported: 6.1.0.1324, 6.1.1.1011 or 6.5.0.1460'
            print 'litespeed version installed: ' + @sls_version + ' '
            return
         end
     end
 end
 
set @cmd = ''

-- get file list insert into @FileNames
set @cmd = 'master..xp_cmdshell ''dir /b /o:dn /a:-d "' + @path + '*.' + @file_ext + '"'''
insert @FileNames 
exec (@cmd)
set @cmd = ''

delete @FileNames
where [FileName] = 'File Not Found' 
   or [FileName] = 'Access is denied.' 
   or [FileName] = 'The system cannot find the path specified.' 
   or [FileName] is null
--

insert @ho_FileNames 
select [id], [FileName] from @FileNames order by [id]

insert @lo_FileNames 
select [id], [FileName] from @FileNames order by [id]

insert @fo_FileNames 
select [id], [FileName] from @FileNames order by [id]

--
delete from [DatabaseRestoreUtility_HeaderOnly] where [lst_updt_tmestmp] < getdate() - 90
delete from [DatabaseRestoreUtility_FilelistOnly] where [lst_updt_tmestmp] < getdate() - 90
delete from [DatabaseRestoreUtility_LabelOnly] where [lst_updt_tmestmp] < getdate() - 90

--clean up fileinfo tables
if @history = 0
 begin
    delete from DatabaseRestoreUtility_headeronly where [path] = @path
    delete from DatabaseRestoreUtility_labelonly where [path] = @path
    delete from DatabaseRestoreUtility_filelistonly where [path] = @path
 end
else
 begin
    delete from DatabaseRestoreUtility_headeronly where [path] = @path and [filename] not in (select [FileName] from @FileNames)
    delete from DatabaseRestoreUtility_labelonly where [path] = @path and [filename] not in (select [FileName] from @FileNames)
    delete from DatabaseRestoreUtility_filelistonly where [path] = @path and [filename] not in (select [FileName] from @FileNames)

    delete from @ho_FileNames where [FileName] in (select [filename] from DatabaseRestoreUtility_headeronly where [path] = @path)
    delete from @lo_FileNames where [FileName] in (select [filename] from DatabaseRestoreUtility_labelonly where [path] = @path)
    delete from @fo_FileNames where [FileName] in (select [filename] from DatabaseRestoreUtility_filelistonly where [path] = @path)
 end
--

-- update headeronly fileinfo table
select @FileOrder = min([id]) from @ho_FileNames where [id] > 0 -- get first id of files to read
while @FileOrder is not null
begin -- while loop start
select @FileName = [FileName] from @ho_FileNames where [id] = @FileOrder 

if @bkp_type = 'S'
begin -- sql
 if @sql_version = '9'
  begin -- sql 2005
    set @cmd = 'restore headeronly from disk = ' + char(39) + @path + @FileName + char(39)
    insert @headeronly2005
    exec (@cmd)
  end -- sql 2005
 if @sql_version = '10'
  begin -- sql 2008
    set @cmd = 'restore headeronly from disk = ' + char(39) + @path + @FileName + char(39)
    insert @headeronly2008
    exec (@cmd)
  end  -- sql 2008
 if @sql_version = '11'
  begin -- sql 2011
    set @cmd = 'restore headeronly from disk = ' + char(39) + @path + @FileName + char(39)
    insert @headeronly2011
    exec (@cmd)
  end -- sql 2011
end -- sql

if @bkp_type = 'L' 
begin -- litespeed
 if @sls_version in ('6.1.0.1324','6.1.1.1011','6.5.0.1460')
  begin  -- litespeed
     set @cmd = 'master.dbo.xp_restore_headeronly @FileName = ''' + @path + '' + @FileName + ''''
     insert @headeronly6
     exec (@cmd)
  end  -- litespeed
end -- litespeed

set @cmd = ''

if not exists (select * from DatabaseRestoreUtility_headeronly with (nolock) where [path] = @path and [filename] = @FileName)
 begin
     insert into DatabaseRestoreUtility_headeronly (
                   [path], [filename], [ServerName], [DatabaseName], [BackupType], [Position], [BackupStartDate], [BackupDescription], [FirstLSN], [LastLsn], [Encryption]
     )
           select  @path,  @fileName,  [ServerName], [DatabaseName], [BackupType], [Position], [BackupStartDate], [BackupDescription], [FirstLSN], [LastLsn], 0            from @headeronly2005
     union select  @path,  @fileName,  [ServerName], [DatabaseName], [BackupType], [Position], [BackupStartDate], [BackupDescription], [FirstLSN], [LastLsn], 0            from @headeronly2008
     union select  @path,  @fileName,  [ServerName], [DatabaseName], [BackupType], [Position], [BackupStartDate], [BackupDescription], [FirstLSN], [LastLsn], 0            from @headeronly2011
     union select  @path,  @fileName,  [ServerName], [DatabaseName], [BackupType], [Position], [BackupStartDate], [BackupDescription], [FirstLSN], [LastLsn], [Encryption] from @headeronly6
 end

delete @headeronly2005
delete @headeronly2008
delete @headeronly2011
delete @headeronly6

select @FileOrder = min([id]) from @ho_FileNames where [id] > 0 and [id] > @FileOrder
end -- while loop end

-- update labelonly fileinfo table
select @FileOrder = min([id]) from @lo_FileNames where [id] > 0 -- get first id of files to read
while @FileOrder is not null
begin -- while loop start
select @FileName = [FileName] from @lo_FileNames where [id] = @FileOrder 

if @bkp_type = 'S'
begin -- sql
 if @sql_version = '9'
  begin -- sql 2005
    set @cmd = 'restore labelonly from disk = ' + char(39) + @path + @FileName + char(39)
    insert @labelonly2005
    exec (@cmd)
  end -- sql 2005
 if @sql_version = '10'
  begin -- sql 2008
    set @cmd = 'restore labelonly from disk = ' + char(39) + @path + @FileName + char(39)
    insert @labelonly2008
    exec (@cmd)
  end  -- sql 2008
 if @sql_version = '11'
  begin -- sql 2011
    set @cmd = 'restore labelonly from disk = ' + char(39) + @path + @FileName + char(39)
    insert @labelonly2011
    exec (@cmd)
  end -- sql 2011
end -- sql

if @bkp_type = 'L' 
begin -- litespeed
 if @sls_version in ('6.1.0.1324','6.1.1.1011','6.5.0.1460')
  begin  -- litespeed 
     set @cmd = 'master.dbo.xp_restore_setinfo @FileName = ''' + @path + '' + @FileName + ''''
     insert @setinfo6
     exec (@cmd)
  end  -- litespeed 
end -- litespeed

set @cmd = ''

if not exists (select * from DatabaseRestoreUtility_labelonly with (nolock) where [path] = @path and [filename] = @FileName)
 begin
     insert into DatabaseRestoreUtility_labelonly (
                   [path], [filename], [FamilyCount], [FamilySequenceNumber]
     )
           select  @path,  @fileName,  [FamilyCount], [FamilySeqNumber]      from @labelonly2005
     union select  @path,  @fileName,  [FamilyCount], [FamilySeqNumber]      from @labelonly2008
     union select  @path,  @fileName,  [FamilyCount], [FamilySeqNumber]      from @labelonly2011
     union select  @path,  @fileName,  [StripeCount], [StripeNumber]         from @setinfo6
 end
         
delete @labelonly2005
delete @labelonly2008
delete @labelonly2011
delete @setinfo6

select @FileOrder = min([id]) from @lo_FileNames where [id] > 0 and [id] > @FileOrder
end -- while loop end

-- do not get fileingfo for log files
delete from @fo_FileNames where [FileName] in (select filename from [DatabaseRestoreUtility_headeronly] where BackupType = 2)
 
-- update filelistonly fileinfo table
se
lect @FileOrder = min([id]) from @fo_FileNames where [id] > 0 -- get first id of files to read
while @FileOrder is not null
begin -- while loop start
select @FileName = [FileName] from @fo_FileNames where [id] = @FileOrder 

if @bkp_type = 'S'
begin -- sql
 if @sql_version = '9'
  begin -- sql 2005
    set @cmd = 'restore filelistonly from disk = ' + char(39) + @path + @FileName + char(39)
    insert @filelistonly2005
    exec (@cmd)
  end -- sql 2005
 if @sql_version = '10'
  begin -- sql 2008
    set @cmd = 'restore filelistonly from disk = ' + char(39) + @path + @FileName + char(39)
    insert @filelistonly2008
    exec (@cmd)
  end  -- sql 2008
 if @sql_version = '11'
  begin -- sql 2011
    set @cmd = 'restore filelistonly from disk = ' + char(39) + @path + @FileName + char(39)
    insert @filelistonly2011
    exec (@cmd)
  end -- sql 2011
end -- sql

if @bkp_type = 'L' 
begin -- litespeed
 if @sls_version in ('6.1.0.1324','6.1.1.1011','6.5.0.1460')
  begin  -- litespeed
     set @cmd = 'master.dbo.xp_restore_filelistonly @FileName = ''' + @path + '' + @FileName + ''''
     insert @filelistonly6
     exec (@cmd)
  end  -- litespeed
end -- litespeed

set @cmd = ''

if not exists (select * from DatabaseRestoreUtility_filelistonly with (nolock) where [path] = @path and [filename] = @FileName)
 begin
     insert into DatabaseRestoreUtility_filelistonly (
                   [path], [filename], [LogicalName], [PhysicalName], [Type], [FileGroupName], [FileId]
     )
           select  @path,  @fileName,  [LogicalName], [PhysicalName], [Type], [FileGroupName], [FileId] from @filelistonly2005
     union select  @path,  @fileName,  [LogicalName], [PhysicalName], [Type], [FileGroupName], [FileId] from @filelistonly2008
     union select  @path,  @fileName,  [LogicalName], [PhysicalName], [Type], [FileGroupName], [FileId] from @filelistonly2011
     union select  @path,  @fileName,  [LogicalName], [PhysicalName], [Type], [FileGroupName], [FileId] from @filelistonly6
 end
             
delete @filelistonly2005
delete @filelistonly2008
delete @filelistonly2011
delete @filelistonly6

select @FileOrder = min([id]) from @fo_FileNames where [id] > 0 and [id] > @FileOrder
end -- while loop end

if exists (select * from @ho_FileNames)
 begin
    set           @cmd = '-- Updated header info for the following files:' + char(13) + char(10)
    select @cmd = @cmd + '--   ' + [fileName] + char(13) + char(10) from @ho_FileNames
    set    @cmd = @cmd + '' + char(13) + char(10)
 end
else
 begin
    set    @cmd = @cmd + '-- No header info was updated' + char(13) + char(10) + char(13) + char(10)
 end
if exists (select * from @lo_FileNames)
 begin
    set    @cmd = @cmd + '-- Updated label info for the following files:' + char(13) + char(10)
    select @cmd = @cmd + '--   ' + [fileName] + char(13) + char(10) from @lo_FileNames
    set    @cmd = @cmd + '' + char(13) + char(10)
 end
else
 begin
    set    @cmd = @cmd + '-- No label info was updated' + char(13) + char(10) + char(13) + char(10)
 end
if exists (select * from @fo_FileNames)
 begin
    set    @cmd = @cmd + '-- Updated filelist info for the following files:' + char(13) + char(10)
    select @cmd = @cmd + '--   ' + [fileName] + char(13) + char(10) from @fo_FileNames
    set    @cmd = @cmd + '' + char(13) + char(10)
 end
else
 begin
    set    @cmd = @cmd + '-- No filelist info was updated' + char(13) + char(10) + char(13) + char(10)
 end

while datalength(@cmd) > 8000
begin
 if patindex('%'+char(13)+'%',@cmd) > 0
  begin
    print replace(replace(left(@cmd, patindex('%'+char(13)+'%',@cmd)), char(13),''), char(10),'')
    set @cmd = substring(@cmd, patindex('%'+char(13)+'%',@cmd)+1, len(@cmd) - patindex('%'+char(13)+'%',@cmd))
  end
 else
  begin
    print @cmd
    set @cmd = substring(@cmd, 8001, len(@cmd)-8000)
  end
end
print @cmd

end -- proc end



GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
