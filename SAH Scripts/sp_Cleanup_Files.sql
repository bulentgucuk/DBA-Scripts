USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_Cleanup_Files]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[sp_Cleanup_Files]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




create procedure [dbo].[sp_Cleanup_Files]

/*************************************************************************************
** proc name:			sp_Cleanup_Files
**
**                      SQL 2005+
**
** Description:			
**						
**
** Output Parameters:	
**
** Dependent On:		
**
** Run Script:          exec master..sp_Cleanup_Files
**                       @DbExclusions  = ''
**                      ,@DbInclusions  = ''
**                      ,@path          = 'c:\backup'
**                      ,@file_ext      = ''
**                      ,@bkp_type      = 'L'
**                      ,@retention     = 0
**                      ,@print_restore = 1
**
** History:             Name            Date            Pr Number       Description
**                      ----------      -----------     ---------       ---------------
**                      M. Horton       Implement       n/a				Creation of inital script
**                      B. Jones        10/14/2010      n/a             
**                      B. Jones        02/10/2010      n/a             modified to work like sp_DatabaseBackupUtility retention
**                      B. Jones        02/25/2010      n/a             
**                      
**                      
*************************************************************************************/

 @DbExclusions               varchar(max)  = ''            -- names of databases to not Archive
,@DbInclusions               varchar(max)  = ''            -- names of databases to Archive
,@path                       varchar(max)  = ''            -- path to files
,@file_ext                   char(3)       = ''            -- 
,@bkp_type                   varchar(1)    = ''            -- L(itespeed), S(QL Native)
,@retention                  int           = 0             -- number of backup sets to keep per database
,@print_restore              bit           = 1             -- 

as
begin -- proc start

set nocount on

declare @cmd                 varchar(max)
       ,@sql                 varchar(20)                   -- sql server version: 2000, 2005, 2008
       ,@sls                 varchar(20)                   -- lightspeed version: 4(.8.3.00025), 6(.0.1.1007)
       ,@id                  int
       ,@ErrorNumber         int                           -- Error Handling
       ,@ErrorFile           varchar(255)                  -- File name of first bad backup file
       ,@FileName            varchar(255)                  -- filename of backup
       ,@separator           char(1)                       -- 
       ,@separator_pos       int                           -- 
       ,@DbExclusion         sysname                       -- 
       ,@DbInclusion         sysname                       -- 
       ,@DbExIn              varchar(max)                  -- 
       ,@DBName              sysname                       -- 

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
set @sql = left((select cast(serverproperty('productversion') as varchar(20))), patindex('%[.]%', (select cast(serverproperty('productversion') as varchar(20))))-1)

-- get lightspeed version
if exists(select [name] from master.sys.objects where type = 'X' and name = 'xp_sqllitespeed_version')
 begin
	declare @sqllitespeed table ([name] [nvarchar](25) null, [value] [nvarchar](25) null)
	insert @sqllitespeed
	exec ('master.dbo.xp_sqllitespeed_version')
	select top 1 @sls = [value] from @sqllitespeed where [name] = 'Engine Version' or [name] = 'xpSLS.dll'
 end
 
 
if @DbExclusions <> '' and @DbInclusions <> ''
 begin
	print 'Only @DbExclusions or @DbInclusions can be used at a time, not both!'
	return
 end

-- get file list insert into @FileNames
declare @FileNames table ([FileOrder] int identity(1,1), [FileName] varchar(255) null)
set @cmd = 'master..xp_cmdshell ''dir /b /o:dn /a:-d "' + @path + '*.' + @file_ext + '"'''
insert @FileNames 
exec (@cmd)
set @cmd = ''

delete @FileNames
where [FileName] = 'File Not Found' 
   or [FileName] = 'Access is denied.' 
   or [FileName] = 'The system cannot find the path specified.' 
   or [FileName] is null

if @DbInclusions <> ''
 begin
	set @DbExIn = @DbInclusions
 end
else
 begin
	set @DbExIn = @DbExclusions
 end

declare @headeronly2005 table ([BackupName] [nvarchar](128) null, [BackupDescription] [nvarchar](255) null, [BackupType] [smallint] null, [ExpirationDate] [datetime] null, [Compressed] [tinyint] null, [Position] [smallint] null, [DeviceType] [tinyint] null, [UserName] [nvarchar](128) null, [ServerName] [nvarchar](128) null,[DatabaseName] [nvarchar](128) null, [DatabaseVersion] [int] null, [DatabaseCreationDate] [datetime] null, [BackupSize] [numeric](20, 0) null, [FirstLSN] [numeric](25, 0) null, [LastLsn] [numeric](25, 0) null, [CheckpointLSN] [numeric](25, 0) null, [DatabaseBackupLSN] [numeric](25,0) null, [BackupStartDate] [datetime] null, [BackupFinishDate] [datetime] null, [SortORDER] [smallint] null, [CodePage] [smallint] null, [UnicodeLocaleId] [int] null, [UnicodeComparisonStyle] [int] null, [CompatibilityLevel] [tinyint] null, [SoftwareVENDorId] [int] null, [SoftwareVersionMajor] [int] null, [SoftwareVersionMinor] [int] null, [SoftwareVersionBuild] [int] null, [MachineName] [nvarchar](128) null, [Flags] [int] null, [BindingID] [uniqueidentifier] null, [RecoveryForkID] [uniqueidentifier] null, [Collation] [nvarchar](128) null, [FamilyGUID] [uniqueidentifier] null, [HasBulkLoggedData] [bit] null, [IsSnapshot] [bit] null, [IsReadOnly] [bit] null, [IsSingleUser] [bit] null, [HasBackupChecksums] [bit] null, [IsDamaged] [bit] null, [BEGINsLogChain] [bit] null, [HasIncompleteMetaData] [bit] null, [IsForceOffline] [bit] null, [IsCopyOnly] [bit] null, [FirstRecoveryForkID] [uniqueidentifier] null, [ForkPointLSN] [numeric](25,0) null, [RecoveryModel] [nvarchar](60) null, [DIFferentialBaseLSN] [numeric](25,0) null, [DIFferentialBaseGUID] [uniqueidentifier] null, [BackupTypeDescription] [nvarchar](60) null, [BackupSetGUID] [uniqueidentifier] null)
declare @headeronly2008 table ([BackupName] [nvarchar](128) null, [BackupDescription] [nvarchar](255) null, [BackupType] [smallint] null, [ExpirationDate] [datetime] null, [Compressed] [tinyint] null, [Position] [smallint] null, [DeviceType] [tinyint] null, [UserName] [nvarchar](128) null, [ServerName] [nvarchar](128) null, [DatabaseName] [nvarchar](128) null, [DatabaseVersion] [int] null, [DatabaseCreationDate] [datetime] null, [BackupSize] [numeric](20,0) null, [FirstLSN] [numeric](25,0) null, [LastLsn] [numeric](25,0) null, [CheckpointLSN] [numeric](25,0) null, [DatabaseBackupLSN] [numeric](25,0) null, [BackupStartDate] [datetime] null, [BackupFinishDate] [datetime] null, [SortORDER] [smallint] null, [CodePage] [smallint] null, [UnicodeLocaleId] [int] null, [UnicodeComparisonStyle] [int] null, [CompatibilityLevel] [tinyint] null, [SoftwareVENDorId] [int] null, [SoftwareVersionMajor] [int] null, [SoftwareVersionMinor] [int] null, [SoftwareVersionBuild] [int] null, [MachineName] [nvarchar](128) null, [Flags] [int] null, [BindingID] [uniqueidentifier] null, [RecoveryForkID] [uniqueidentifier] null, [Collation] [nvarc
har](128) null, [FamilyGUID] [uniqueidentifier] null, [HasBulkLoggedData] [bit] null, [IsSnapshot] [bit] null, [IsReadOnly] [bit] null, [IsSingleUser] [bit] null, [HasBackupChecksums] [bit] null, [IsDamaged] [bit] null, [BEGINsLogChain] [bit] null, [HasIncompleteMetaData] [bit] null, [IsForceOffline] [bit] null, [IsCopyOnly] [bit] null, [FirstRecoveryForkID] [uniqueidentifier] null, [ForkPointLSN] [numeric](25,0) null, [RecoveryModel] [nvarchar](60) null, [DIFferentialBaseLSN] [numeric](25,0) null, [DIFferentialBaseGUID] [uniqueidentifier] null, [BackupTypeDescription] [nvarchar](60) null, [BackupSetGUID] [uniqueidentifier] null, [CompressedBackupSize] [numeric](20,0) null)
declare @headeronly2011 table ([BackupName] [nvarchar](128) null, [BackupDescription] [nvarchar](255) null, [BackupType] [smallint] null, [ExpirationDate] [datetime] null, [Compressed] [tinyint] null, [Position] [smallint] null, [DeviceType] [tinyint] null, [UserName] [nvarchar](128) null, [ServerName] [nvarchar](128) null, [DatabaseName] [nvarchar](128) null, [DatabaseVersion] [int] null, [DatabaseCreationDate] [datetime] null, [BackupSize] [numeric](20,0) null, [FirstLSN] [numeric](25,0) null, [LastLsn] [numeric](25,0) null, [CheckpointLSN] [numeric](25,0) null, [DatabaseBackupLSN] [numeric](25,0) null, [BackupStartDate] [datetime] null, [BackupFinishDate] [datetime] null, [SortORDER] [smallint] null, [CodePage] [smallint] null, [UnicodeLocaleId] [int] null, [UnicodeComparisonStyle] [int] null, [CompatibilityLevel] [tinyint] null, [SoftwareVENDorId] [int] null, [SoftwareVersionMajor] [int] null, [SoftwareVersionMinor] [int] null, [SoftwareVersionBuild] [int] null, [MachineName] [nvarchar](128) null, [Flags] [int] null, [BindingID] [uniqueidentifier] null, [RecoveryForkID] [uniqueidentifier] null, [Collation] [nvarchar](128) null, [FamilyGUID] [uniqueidentifier] null, [HasBulkLoggedData] [bit] null, [IsSnapshot] [bit] null, [IsReadOnly] [bit] null, [IsSingleUser] [bit] null, [HasBackupChecksums] [bit] null, [IsDamaged] [bit] null, [BEGINsLogChain] [bit] null, [HasIncompleteMetaData] [bit] null, [IsForceOffline] [bit] null, [IsCopyOnly] [bit] null, [FirstRecoveryForkID] [uniqueidentifier] null, [ForkPointLSN] [numeric](25,0) null, [RecoveryModel] [nvarchar](60) null, [DIFferentialBaseLSN] [numeric](25,0) null, [DIFferentialBaseGUID] [uniqueidentifier] null, [BackupTypeDescription] [nvarchar](60) null, [BackupSetGUID] [uniqueidentifier] null, [CompressedBackupSize] [numeric](20,0) null, [Containment] [varchar](255) null)
declare @headeronly4 table ([FileNumber] [nvarchar](128) null, [BackupFormat] [nvarchar](128) null, [Guid] [nvarchar](128) null, [BackupName] [nvarchar](128) null, [BackupDescription] [nvarchar](255) null, [BackupType] [smallint] null, [ExpirationDate] [datetime] null, [Compressed] [tinyint] null, [Position] [smallint] null, [DeviceType] [tinyint] null, [UserName] [nvarchar](128) null, [ServerName] [nvarchar](128) null, [DatabaseName] [nvarchar](128) null, [DatabaseVersion] [int] null, [DatabaseCreationDate] [datetime] null, [BackupSize] [numeric](20,0) null, [FirstLSN] [numeric](25,0) null, [LastLsn] [numeric](25,0) null, [CheckpointLSN] [numeric](25,0) null, [DIFferentialBaseLsn] [numeric](25,0) null, [BackupStartDate] [datetime] null, [BackupFinishDate] [datetime] null, [SortORDER] [smallint] null, [CodePage] [smallint] null, [CompatibilityLevel] [tinyint] null, [SoftwareVENDorId] [int] null, [SoftwareVersionMajor] [int] null, [SoftwareVersionMinor] [int] null, [SoftwareVersionBuild] [int] null, [MachineName] [nvarchar](128) null, [BindingId] [uniqueidentifier] null, [RecoveryForkId] [uniqueidentifier] null, [Encryption] [nvarchar](128) null)
declare @headeronly6 table ([FileNumber] [nvarchar](128) null, [BackupFormat] [nvarchar](128) null, [Guid] [nvarchar](128) null, [BackupName] [nvarchar](128) null, [BackupDescription] [nvarchar](255) null, [BackupType] [smallint] null, [ExpirationDate] [datetime] null, [Compressed] [tinyint] null, [Position] [smallint] null, [DeviceType] [tinyint] null, [UserName] [nvarchar](128) null, [ServerName] [nvarchar](128) null, [DatabaseName] [nvarchar](128) null, [DatabaseVersion] [int] null, [DatabaseCreationDate] [datetime] null, [BackupSize] [numeric](20,0) null, [FirstLSN] [numeric](25,0) null, [LastLsn] [numeric](25,0) null, [CheckpointLSN] [numeric](25,0) null, [DIFferentialBaseLsn] [numeric](25,0) null, [BackupStartDate] [datetime] null, [BackupFinishDate] [datetime] null, [SortORDER] [smallint] null, [CodePage] [smallint] null, [CompatibilityLevel] [tinyint] null, [SoftwareVENDorId] [int] null, [SoftwareVersionMajor] [int] null, [SoftwareVersionMinor] [int] null, [SoftwareVersionBuild] [int] null, [MachineName] [nvarchar](128) null, [BindingId] [uniqueidentifier] null, [RecoveryForkId] [uniqueidentifier] null, [Encryption] [nvarchar](128) null, [IsCopyOnly] [nvarchar](128) null)
create table #headeronly ([id] int null, [FileName] varchar(255) null, [DatabaseName] varchar(255) null)

select @id = min([FileOrder]) from @FileNames where [FileOrder] > 0 -- get first id of database to backup

while @id is not null
begin -- while loop start
select @FileName = [FileName] from @FileNames where [FileOrder] = @id 

if @bkp_type = 'S'
begin -- sql

set @cmd = 'RESTORE HEADERONLY FROM DISK = ' + char(39) + @path + @FileName + char(39)
 
 	 IF @sql = '9'
	  BEGIN
		INSERT @headeronly2005
		EXEC (@cmd)
	  END
	  
	 IF @sql = '10'
	  BEGIN
		INSERT @headeronly2008
		EXEC (@cmd)
	  END
	  
	 IF @sql = '11'
	  BEGIN
		INSERT @headeronly2011
		EXEC (@cmd)
	  END
	  
set @cmd = ''

end -- sql

if @bkp_type = 'L' 
begin -- litespeed
 
set @cmd = 'master.dbo.xp_restore_headeronly @FileName = '+ CHAR(39) + @path + @FileName + CHAR(39)

	 IF left(@sls, patindex('%[.]%', @sls)-1) = '4'
	  BEGIN
		INSERT @headeronly4
		EXEC (@cmd)
	  END
	  
	 IF left(@sls, patindex('%[.]%', @sls)-1) = '6'
	  BEGIN
		INSERT @headeronly6
		EXEC (@cmd)
	  END
	  	  
set @cmd = ''

end -- litespeed

-- add each headeronly data into single stage table
insert into #headeronly ([id], [FileName], [DatabaseName])
                   select @id, @FileName,  [DatabaseName] from @headeronly2005
             union select @id, @FileName,  [DatabaseName] from @headeronly2008
             union select @id, @FileName,  [DatabaseName] from @headeronly2011
             union select @id, @FileName,  [DatabaseName] from @headeronly4
             union select @id, @FileName,  [DatabaseName] from @headeronly6

delete @headeronly2005
delete @headeronly2008
delete @headeronly2011
delete @headeronly4
delete @headeronly6

select @id = min([FileOrder]) from @FileNames where [FileOrder] > 0 and [FileOrder] > @id
end

if @DbInclusions <> ''
 begin
	delete from #headeronly where DatabaseName not in (select ltrim(rtrim(item)) from fn_ParseString (@DbExIn,','))
 end
else
 begin
	delete from #headeronly where DatabaseName in (select ltrim(rtrim(item)) from fn_ParseString (@DbExIn,','))
 end

declare @databases table ([id] int null, [DatabaseName] varchar(255) null)
insert @databases 
select min([id]), [DatabaseName] from #headeronly where [id] > 0 group by [DatabaseName]

select @id = min([id]) from @databases where [id] > 0
while @id is not null
begin

select @DBName = [DatabaseName] from @databases where [id] = @id

--set @cmd = 'select distinct top ' + cast(@retention as varchar(8000)) + ' left(FileName, len(DatabaseName) + 13) from #headeronly where DatabaseName = ' + char(39) + @DBName + char(39) + ' order by left(FileName, len(DatabaseName) + 13) desc'
--exec (@cmd)
--set @cmd = ''

set @cmd = 'delete #headeronly where left([FileName], len([DatabaseName]) + 13) in (select distinct top ' + cast(@retention as varchar(8000)) + ' left([FileName], len([DatabaseName]) + 13) from #headeronly where [DatabaseName] = ' + char(39) + @DBName + char(39) + ' order by left([FileName], len([DatabaseName]) +
 13) desc) and [DatabaseName] = ' + char(39) + @DBName + char(39) + ''
exec (@cmd)
set @cmd = ''

select @id = min([id]) from @databases where [id] > 0 and [id] > @id
end

select @cmd = @cmd + 'exec master..xp_cmdshell ' + char(39) + 'del "' + @path + [FileName] + '"' + char(39) + ', no_output;' + char(13) from #headeronly 

if @print_restore = 1
 begin
  if @cmd <> ''
   begin
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
   end
  else
   begin
    print 'No files found that need removed.'
   end
 end
else
 begin
	exec (@cmd)
 end

set @cmd = ''

drop table #headeronly

end -- proc end




GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
