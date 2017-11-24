USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DatabaseRestoreUtility]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[sp_DatabaseRestoreUtility]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[sp_DatabaseRestoreUtility]

/*************************************************************************************
** proc name:           sp_DatabaseRestoreUtility
**
**                      SQL 2005+
**
** Version:             11
**
** Description:         Procedure to restore database backups
**
** Output Parameters:   Default output is a PRINT out of database and logfile restores.
**
** Dependent On:        function master.dbo.Lsn2Numeric (function HexToInt)
**                      function msdb.dbo.fn_encrpt_key
**
** Example:             master..sp_DatabaseRestoreUtility
**                       @path             = ''               -- path to backup files
**                      ,@srce_db          = ''               -- database name FROM which the backup files were taken
**                      ,@db_name          = ''               -- database name TO restore or update with logfiles (can be completely new)
**                      ,@file_ext         = ''               -- bkp LiteSpeed Files
**                      ,@bkp_type         = ''               -- L(itespeed), S(QL Native)
**                      ,@data_drive       = ''               -- path for data file, Assumes datafiles are saved to the same location
**                      ,@log_drive        = ''               -- path for log file,  Assumes logfiles are saved to the same location
**                      ,@phys_filename    = ''               -- Name.mdf, Name_log.ldf database name is default use this to override physical filename.
**                      ,@client_abbrv     = ''               -- if '' pulled from backup header
**                      ,@rstr_standby     = 1                -- 0 = will recover restore, 1 = restores to standby state
**                      ,@updt_standby     = 1                -- 0 = Restore DB backup and all logfiles, 1 = Apply logfiles > DB LSN, 2 = Restore only DB backup
**                      ,@stopat           = NULL             -- Stop restore at point in time '2007-01-22 21:00:00.000'
**                      ,@print_restore    = 1                -- Default is to PRINT restore commands not execute them
**                      ,@all              = 0                -- 0 = only those since last database backup; 1 = all backups in folder
**                      
** History:
**      Name            Date            Pr Number       Description
**      ----------      -----------     ---------       ---------------
**      B. Jones        10/13/2010      n/a             Creation of inital script
**      
**      
**      
**
*************************************************************************************/

        @path                varchar(260)      = ''        -- path to backup files
       ,@srce_db             sysname           = ''        -- database name FROM which the backup files were taken
       ,@db_name             sysname           = ''        -- database name TO restore or update with logfiles (can be completely new)
       ,@file_ext            varchar(3)        = ''        -- bkp LiteSpeed Files
       ,@bkp_type            char(1)           = ''        -- L(itespeed), S(QL Native)
       ,@data_drive          varchar(260)      = ''        -- path for data file, Assumes datafiles are saved to the same location
       ,@log_drive           varchar(260)      = ''        -- path for log file,  Assumes logfiles are saved to the same location
       ,@phys_filename       sysname           = ''        -- Name.mdf, Name_log.ldf database name is default use this to override physical filename.
       ,@client_abbrv        char(4)           = ''        -- 
       ,@rstr_standby        bit               = 1         -- 0 = will recover restore, 1 = restores to standby state
       ,@updt_standby        int               = 0         -- 0 = Restore DB backup and all logfiles, 1 = Apply logfiles > DB LSN, 2 = Restore only DB backup
       ,@stopat              datetime          = NULL      -- Stop restore at point in time '2007-01-22 21:00:00.000'
       ,@history             bit               = 1         -- 0 scan all files each run (slower), 1 use history tables for file header info (faster)
       ,@print_restore       bit               = 1         -- Default is to PRINT restore commands not execute them
       ,@all                 bit               = 0         -- 0 = only those since last database backup; 1 = all backups in folder
	   ,@SBX				bit					= 0
--with encryption

as
begin -- proc start

set nocount on

declare @sql_version         varchar(20)                   -- sql server version: 8(2000), 9(2005), 10(2008)
       ,@sls_version         varchar(20)                   -- lightspeed version: 4.8.3.00025, , 6.0.1.1007, 6.1.0.1324 (4.8, 5.0.0, 5.0.1, 5.0.2,  5.1,  5.2,  6.0, 6.1)
       ,@cmd                 varchar(8000)                 --
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
       ,@FileId       
       bigint                        -- 

--labelonly
declare @FamilyCount         int                           -- 
       ,@FamilySeqNum        int                           -- 
       ,@MediaDate           datetime                      -- 

-- @tables
declare @headeronly table (
        [FileOrder]          int                 identity(1,1)
       ,[bkp_type]           varchar(1)          null
       ,[FileName]           varchar(255)        null
       ,[DatabaseName]       sysname             null
       ,[FamilyCount]        int                 null
       ,[FamilySeq]          int                 null
       ,[Position]           smallint            null
       ,[BackupType]         smallint            null
       ,[BackupStartDate]    datetime            null
       ,[dbLSN]              numeric(25,0)       null
       ,[PrevLSN]            numeric(25,0)       null
       ,[FirstLSN]           numeric(25,0)       null
       ,[LastLsn]            numeric(25,0)       null
       ,[NextLSN]            numeric(25,0)       null
       ,[BackupDescription]  nvarchar(255)       null
       ,[Encryption]         bit                 null
)
declare @filelistonly table (
        [FileName]           varchar(255)        null
       ,[LogicalName]        varchar(128)        null
       ,[PhysicalName]       varchar(128)        null
       ,[Type]               char(1)             null
       ,[FileGroupName]      varchar(128)        null
       ,[FileId]             int                 null
)
declare @header table (
        [FileOrder]          int                 null
       ,[bkp_type]           char(1)             null
       ,[FileName]           varchar(255)        null
       ,[DatabaseName]       sysname             null
       ,[Position]           smallint            null
       ,[BackupType]         smallint            null
       ,[BackupStartDate]    datetime            null
       ,[dbLSN]              numeric(25,0)       null
       ,[Prev_Mode]          smallint            null
       ,[PrevdbLSN]          numeric(25,0)       null
       ,[PrevLSN]            numeric(25,0)       null
       ,[FirstLSN]           numeric(25,0)       null
       ,[LastLsn]            numeric(25,0)       null
       ,[NextLSN]            numeric(25,0)       null
       ,[BackupDescription]  nvarchar(255)       null
       ,[Encryption]         bit                 null
)
declare @databases table (
        [id]                 int                 identity(1,1)
       ,[DatabaseName]       sysname             null
       ,[LastLsn]            numeric(25,0)       null
       ,[BackupStartDate]    datetime            null
)

declare @sqllitespeed table (
        [name]               nvarchar(25)        null
       ,[value]              nvarchar(25)        null
)

declare @PreviousLSN table (
        [DatabaseName]       sysname             null
       ,[PreviousLSN]        numeric(25,0)       null
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

if @data_drive != ''
 begin
    if left(reverse(@data_drive), 1) != '\'
     begin
        set @data_drive = @data_drive + '\'
     end
 end
else
 begin
        print '@data_drive not specified!'
        return
 end
 
if @log_drive != ''
 begin
    if left(reverse(@log_drive), 1) != '\'
     begin
        set @log_drive = @log_drive + '\'
     end
 end
else
 begin
        print '@log_drive not specified!'
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
set @sql_version = left((select cast(serverproperty('productversion') as varchar(20))), patindex('%[.]%', (select cast(serverproperty('productversion') as varchar(20))))-1)

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
        if @sls_version not in ('6.1.0.1324','6.1.1.1011', '6.5.0.1460')
         begin
            print 'litespeed version supported: 6.1.0.1324, 6.1.1.1011 or 6.5.0.1460'
            print 'litespeed version installed: ' + @sls_version + ' '
            return
         end
     end
 end
 
set @cmd = ''
 
--
exec sp_DatabaseRestoreUtility_FileInfo
 @path = @path
,@file_ext = @file_ext
,@bkp_type = @bkp_type
,@history = @history

--
if @updt_standby = 1
 begin
    if exists (select top 1 * from DatabaseRestoreUtility_headeronly where DatabaseName in (select name from sys.databases where state = 1 and [path] = @path))
     begin
        select distinct @cmd = @cmd + DatabaseName + char(10) from DatabaseRestoreUtility_headeronly where DatabaseName in (select name from sys.databases where state = 1 and [path] = @path)
        print 'The following database(s) were found in "Restoring" mode with logs trying to be applied:' + char(10) + @cmd
        raiserror ('Database(s) were found in "Restoring" mode with logs trying to be applied' , 16, -1);
        return
     end
 end

-- get Previous LSN from all databases on server
if @db_name = ''
 begin
    select @cmd = @cmd + 'use ' + quotename([name], ']') + '; select top 1 db_name(), master.dbo.Lsn2Numeric([Previous LSN]) from ::fn_dblog(null,null) Order by  master.dbo.Lsn2Numeric([Current LSN]) desc '
      from master..sysdatabases 
     where isnull(databaseproperty([name],'isReadOnly'),0) = 1
       and isnull(databaseproperty([name],'IsInStandBy'),0) = 1
       and name in (select distinct [DatabaseName] from DatabaseRestoreUtility_headeronly where [path] = @path)
       and [dbid] > 0
    insert @PreviousLSN
    exec (@cmd)
    set @cmd = ''
 end
else
 begin
    if exists (select name from master..sysdatabases where name = @db_name)
     begin
       set @cmd = 'use ' + quotename(@db_name, ']') + '; select top 1 db_name(), master.dbo.Lsn2Numeric([Previous LSN]) from ::fn_dblog(null,null) Order by  master.dbo.Lsn2Numeric([Current LSN]) desc '
       insert @PreviousLSN
       exec (@cmd)
       set @cmd = ''
     end
 end

-- 
if @db_name = ''
 begin
    insert into @headeronly ([bkp_type],   [FileName],    [DatabaseName], [Position], [FamilyCount], [FamilySeq],            [BackupType], [BackupStartDate], [dbLSN],       [FirstLSN], [LastLsn], [BackupDescription], [Encryption])
    select                   @bkp_type, ho.[filename], ho.[DatabaseName], [Position], [FamilyCount], [FamilySequenceNumber], [BackupType], [BackupStartDate], [PreviousLSN], [FirstLSN], [LastLsn], [BackupDescription], [Encryption]
    from [DatabaseRestoreUtility_headeronly] ho
    left join [DatabaseRestoreUtility_labelonly] lo on lo.[filename] = ho.[filename] and lo.[path] = ho.[path] 
    left join @PreviousLSN p on p.[DatabaseName] = ho.[DatabaseName]
    where ho.[path] = @path
    order by [BackupStartDate]
 end
else
 begin
 
    select @dbLSN = [PreviousLSN] from @PreviousLSN where [DatabaseName] = @db_name
 
    insert into @headeronly ([bkp_type],   [Fi
leName],    [DatabaseName], [Position], [FamilyCount], [FamilySeq],            [BackupType], [BackupStartDate], [dbLSN], [FirstLSN], [LastLsn], [BackupDescription], [Encryption])
    select                   @bkp_type, ho.[filename], ho.[DatabaseName], [Position], [FamilyCount], [FamilySequenceNumber], [BackupType], [BackupStartDate], @dbLSN,  [FirstLSN], [LastLsn], [BackupDescription], [Encryption]
    from [DatabaseRestoreUtility_headeronly] ho
    left join [DatabaseRestoreUtility_labelonly] lo on lo.[filename] = ho.[filename] and lo.[path] = ho.[path] 
    where ho.[path] = @path
    order by [BackupStartDate]
 end    


insert into @filelistonly ([FileName], [LogicalName], [PhysicalName], [Type], [FileGroupName], [FileId])
select [FileName], [LogicalName], [PhysicalName], [Type], [FileGroupName], [FileId]
  from [master].[dbo].[DatabaseRestoreUtility_filelistonly]
 where [path] = @path
 
if @updt_standby = 0 -- 0 Restore DB backup and all logfiles
 begin
    insert into @header ([FileOrder],   [bkp_type],   [FileName],   [DatabaseName],   [Position],   [BackupType],   [BackupStartDate],   [Prev_Mode],                 [PrevdbLSN],              [PrevLSN],                 [FirstLSN],   [LastLsn], [NextLSN],                  [BackupDescription],   [Encryption])
    select distinct    a.[FileOrder], a.[bkp_type], a.[FileName], a.[DatabaseName], a.[Position], a.[BackupType], a.[BackupStartDate],    Prev_Mode = pm.[BackupType], PrevdbLSN = p1.[LastLsn], PrevLSN = p2.[LastLsn], a.[FirstLSN], a.[LastLsn],  NextLSN = n2.[FirstLSN], a.[BackupDescription], a.[Encryption]
    from @headeronly a 
    left join @headeronly p1 on a.[DatabaseName] = p1.[DatabaseName] 
                             and p1.[BackupType] in (1,5) 
                        and p1.[BackupStartDate] = (select max(pd.[BackupStartDate]) 
                                                      from @headeronly pd 
                                                     where p1.[DatabaseName] = pd.[DatabaseName] 
                                                   and (pd.[BackupStartDate] < a.[BackupStartDate]) 
                                                        and (pd.[BackupType] in (1,5))) -- previous lsn for full & dif backups
    left join @headeronly p2 on a.[DatabaseName] = p2.[DatabaseName] 
                              and p2.[BackupType] = 2 
                         and p2.[BackupStartDate] = (select max(pt.[BackupStartDate]) 
                                                       from @headeronly pt 
                                                      where p2.[DatabaseName] = pt.[DatabaseName] 
                                                    and (pt.[BackupStartDate] < a.[BackupStartDate]) 
                                                         and (pt.[BackupType] = 2)) -- previous lsn for log backups
    left join @headeronly pm on a.[DatabaseName] = pm.[DatabaseName] 
                        and pm.[BackupStartDate] = (select max(pt2.[BackupStartDate]) 
                                                      from @headeronly pt2 
                                                     where pm.[DatabaseName] = pt2.[DatabaseName] 
                                                  and (pt2.[BackupStartDate] < a.[BackupStartDate])) -- previous backup type for log backups
    left join @headeronly n2 on a.[DatabaseName] = n2.[DatabaseName]
                             and n2.[BackupType] = 2
                        and n2.[BackupStartDate] = (select min(c.[BackupStartDate])
                                                      from @headeronly c
                                                     where n2.[DatabaseName] = c.[DatabaseName]
                                                    and (c.[BackupStartDate] > a.[BackupStartDate])
                                                         and (c.[BackupType] = 2))
    where (@all=1) or (@all=0 and a.[FileOrder] >= (select min(e.[FileOrder])
                                                      from @headeronly e
                                                     where a.[DatabaseName] = e.[DatabaseName]
                                                      and e.BackupStartDate = (select MAX(d.BackupStartDate)
                                                                                 from @headeronly d
                                                                                where d.[DatabaseName] = e.[DatabaseName]
                                                                                   and  d.[BackupType] = 1
                                                                                  and d.[DatabaseName] = e.[DatabaseName])))
    order by a.[DatabaseName], a.[BackupStartDate]
 end
 
if @updt_standby = 1 -- 1 Apply logfiles > DB LSN
 begin
    insert into @header ([FileOrder],   [bkp_type],   [FileName],   [DatabaseName],   [Position],   [BackupType],   [BackupStartDate], [Prev_Mode],                 [PrevdbLSN],              [PrevLSN],                 [FirstLSN],   [LastLsn], [NextLSN],                  [BackupDescription],   [Encryption])
    select distinct    a.[FileOrder], a.[bkp_type], a.[FileName], a.[DatabaseName], a.[Position], a.[BackupType], a.[BackupStartDate],  Prev_Mode = pm.[BackupType], PrevdbLSN = p1.[LastLsn], PrevLSN = p2.[LastLsn], a.[FirstLSN], a.[LastLsn],  NextLSN = n2.[FirstLSN], a.[BackupDescription], a.[Encryption]
    from @headeronly a 
    left join @headeronly p1 on a.[DatabaseName] = p1.[DatabaseName]
                             and p1.[BackupType] in (1,5)
                        and p1.[BackupStartDate] = (select max(pd.[BackupStartDate])
                                                      from @headeronly pd
                                                     where p1.[DatabaseName] = pd.[DatabaseName]
                                                   and (pd.[BackupStartDate] < a.[BackupStartDate])
                                                        and (pd.[BackupType] in (1,5)))
    left join @headeronly p2 on a.[DatabaseName] = p2.[DatabaseName] 
                               and p2.BackupType = 2 
                        and p2.[BackupStartDate] = (select max(pt.[BackupStartDate]) 
                                                      from @headeronly pt 
                                                     where p2.[DatabaseName] = pt.[DatabaseName] 
                                                   and (pt.[BackupStartDate] < a.[BackupStartDate]) 
                                                          and (pt.BackupType = 2))
    left join @headeronly pm on a.[DatabaseName] = pm.[DatabaseName] 
                        and pm.[BackupStartDate] = (select max(pt2.[BackupStartDate]) 
                                                      from @headeronly pt2 
                                                     where pm.[DatabaseName] = pt2.[DatabaseName] 
                                                  and (pt2.[BackupStartDate] < a.[BackupStartDate]))
    left join @headeronly n2 on a.[DatabaseName] = n2.[DatabaseName]
                             and n2.[BackupType] = 2
                        and n2.[BackupStartDate] = (select min(c.[BackupStartDate])
                                                      from @headeronly c
                                                     where n2.[DatabaseName] = c.[DatabaseName]
                                                    and (c.[BackupStartDate] > a.[BackupStartDate])
                                                         and (c.[BackupType] = 2))
    where a.[BackupType] <> 1
         and a.[LastLsn] > a.[dbLSN]
    order by a.[DatabaseName], a.[BackupStartDate]
 end
  
 
if @updt_standby = 2 -- 2 = Restore only DB backup
 begin
    insert into @header ([FileOrder],   [bkp_type],   [FileName],   [DatabaseName],   [Position],   [BackupType],   [BackupStartDate], [Prev_Mode],               
   [PrevdbLSN],              [PrevLSN],                 [FirstLSN],   [LastLsn], [NextLSN],                  [BackupDescription],   [Encryption])
    select distinct    a.[FileOrder], a.[bkp_type], a.[FileName], a.[DatabaseName], a.[Position], a.[BackupType], a.[BackupStartDate], Prev_Mode = p1.[BackupType],  PrevdbLSN = p1.[LastLsn], PrevLSN = p1.[LastLsn], a.[FirstLSN], a.[LastLsn],  NextLSN = n1.[FirstLSN], a.[BackupDescription], a.[Encryption]
    from @headeronly a 
    left join @headeronly p1 on a.[DatabaseName] = p1.[DatabaseName] 
                             and p1.[BackupType] in (1,5)
                        and p1.[BackupStartDate] = (select max(pd.[BackupStartDate])
                                                      from @headeronly pd
                                                     where p1.[DatabaseName] = pd.[DatabaseName]
                                                   and (pd.[BackupStartDate] < a.[BackupStartDate])
                                                        and (pd.[BackupType] in (1,5)))
    left join @headeronly n1 on a.[DatabaseName] = n1.[DatabaseName]
                             and n1.[BackupType] in (1,5)
                        and n1.[BackupStartDate] = (select  min(c.[BackupStartDate])
                                                       from @headeronly  c
                                                      where n1.[DatabaseName] =  c.[DatabaseName]
                                                     and (c.[BackupStartDate] > a.[BackupStartDate])
                                                          and (c.[BackupType] in (1,5)))
    where (@all=1 and a.[BackupType] <> 2)
       or (@all=0 and a.[BackupType] <> 2
                   and a.[FileOrder] >= (select min(e.FileOrder)
                                           from @headeronly e
                                          where a.[DatabaseName] = e.[DatabaseName]
                                         and e.[BackupStartDate] = (select MAX(d.[BackupStartDate])
                                                                      from @headeronly d
                                                                     where d.[DatabaseName] = e.[DatabaseName]
                                                                        and  d.[BackupType] = 1
                                                                       and d.[DatabaseName] = e.[DatabaseName])))
    order by a.[DatabaseName], a.[BackupStartDate]
 end
 
if @srce_db = '' -- restore all databases
 begin
    set @restore_all = 1

    insert @databases
    select [DatabaseName], [LastLsn], [BackupStartDate]
    from @header
    where [BackupStartDate] < isnull(@stopat, '12/31/9999') and [DatabaseName] not in ('master', 'model', 'msdb', 'tempdb')
    group by [DatabaseName], [LastLsn], [BackupStartDate]
 end
else -- restore single database
 begin
    set @restore_all = 0

    insert @databases
    select [DatabaseName], [LastLsn], [BackupStartDate]
    from @header
    where [BackupStartDate] < isnull(@stopat, '12/31/9999') and [DatabaseName] = @srce_db
    group by [DatabaseName], [LastLsn], [BackupStartDate]
  end

--select * from @FileNames
--select * from @PreviousLSN
--select * from @headeronly
--select * from @filelistonly
--select * from @header
--select * from @databases

--
select @id = min([id]) from @databases where [id] > 0 -- get first id of database to backup

if @id is null 
 begin
    print 'No New files found to be applied to database'
 end
 
set @dblsn = null
 
while @id is not null
begin -- while loop start
select @DatabaseName = [DatabaseName], @LastLsn = [LastLsn], @BackupStartDate = [BackupStartDate] from @databases where [id] = @id 

select @FileOrder = [FileOrder], @bkp_type = [bkp_type], @FileName = [FileName], @Position = [Position], @backup_mode = [BackupType], @Prev_Mode = [Prev_Mode], @PrevdbLSN = [PrevdbLSN], @PrevLSN = [PrevLSN], @FirstLSN = [FirstLSN], @NextLSN = [NextLSN], @BackupDescription = [BackupDescription], @Encryption = [Encryption]
from @header
where [DatabaseName] = @DatabaseName and [BackupStartDate] = @BackupStartDate and [LastLsn] = @LastLsn
Declare @getDate date = GetDate()
    If @restore_all = 1
     begin
         set @srce_db = @DatabaseName
         if @SBX = 0
			begin
			 set @db_name = @DatabaseName
			 set @phys_filename = @DatabaseName
			end
		if @SBX = 1
			begin

			set @db_name =  @DatabaseName + '_'+ Convert(varchar(50), @getDate, 112)
			set @phys_filename =  @DatabaseName + '_'+ Convert(varchar(50), @getDate, 112)
		
			end	
     end
     
    if @db_name = ''
     begin
		if @SBX = 0
			begin
			set @db_name = @srce_db
			end
		if @SBX = 1
			begin
			
			set @db_name = @srce_db
			set @db_name = @db_name + '_'+ Convert(varchar(50), @getDate, 112)
			end	
     end
     
    If @phys_filename = ''
     begin
         set @phys_filename = @db_name
     end
     
     set @cmd = ''
     
    if @bkp_type = 'L' and @Encryption = 1
     begin -- Get litespeed encryption key start
        set @client_abbr = ''
        set @backup_type = ''
        set @eff_dt = ''
        
		if @client_abbrv = ''
		 begin
			set @client_abbr = right(@BackupDescription, patindex('%[-]%', reverse(@BackupDescription))-1)
		 end
		else
		 begin
			set @client_abbr = @client_abbrv
		 end

        set @backup_type = left(@BackupDescription, 1)
        set @eff_dt = case when isdate(substring(@BackupDescription, 2, 23)) = 1 then cast(substring(@BackupDescription, 2, 23) as datetime) else cast('12/31/9999' as datetime) end
    
        select @EncryptionKey = isnull([encrpt_key], '') from msdb.dbo.fn_encrpt_key(@client_abbr, @backup_type, @eff_dt)
        
     end -- Get litespeed encryption key end


if (@updt_standby <> 1) or (@updt_standby = 1 and (@db_name in (select distinct [name] from master..sysdatabases where isnull(databaseproperty([name],'isReadOnly'),0)  = 1 and isnull(databaseproperty([name],'IsInStandBy'),0)  = 1)))
begin

    IF @backup_mode in (1, 5)
     begin -- full database restore start
    
        if @bkp_type = 'L'
         begin -- create litespeed restore database script
                
                
              set @cmd =        'exec master.dbo.xp_restore_database' + char(13)
              set @cmd = @cmd + ' @database = ' + char(39) + @db_name + char(39) + char(13)
				
            select @cmd = @cmd + ',@FileName = ' + char(39) + @path + [FileName] + char(39) + char(13)
            from @header
            where [DatabaseName] = @DatabaseName and [BackupStartDate] = @BackupStartDate and [LastLsn] = @LastLsn
               set @cmd = @cmd + ',@filenumber = ' + cast(@Position as varchar(2)) + char(13)
               set @cmd = @cmd + ',@with = ' + char(39) + 'standby = N' + char(39) + char(39) + @data_drive + @phys_filename + '_undo.dat' + char(39) + char(39) + char(39) + char(13)
               set @cmd = @cmd + ',@with = ' + char(39) + 'nounload' + char(39) + char(13)
               set @cmd = @cmd + ',@with = ' + char(39) + 'stats = 10' + char(39) + char(13)
               set @cmd = @cmd + ',@with = ' + char(39) + 'replace' + char(39) + char(13)
            select @cmd = @cmd + ',@with = ' + char(39) + 'move N' + char(39) + char(39) + [LogicalName] + char(39) + char(39) + ' TO N' + char(39) + char(39) + @data_drive + @phys_filename + '_data_' + cast(row_number() over(order by [FileName]) as varchar(5)) + right([PhysicalName], patindex('%[.]%', reverse([PhysicalName]))) + char(39) + char(39) + char(39) + char(13)
            from @filelistonly
            where [FileName] = @FileName and Type = 'D'
            order by [FileId]
            select @cmd = @cmd + ',@with = ' + char(39) + 'move N' + char(39) + char(39) + [LogicalName] + char(39) + char(39) + ' TO N' + char(39) + char(39) + @log_drive + @phys_filename + '_log_' + cast(row_
number() over(order by [FileName]) as varchar(5)) + right([PhysicalName], patindex('%[.]%', reverse([PhysicalName]))) + char(39) + char(39) + char(39) + char(13)
            from @filelistonly
            where [FileName] = @FileName and Type = 'L'
            order by [FileId]
            if @Encryption = 1
             begin
               set @cmd = @cmd + ',@EncryptionKey = ' + char(39) + isnull(@EncryptionKey,'') + char(39) + char(13)
             end
         end -- create litespeed restore database script

        if @bkp_type = 'S'
         begin -- create sql native restore database script start
               set @cmd =        'restore database [' + @db_name + ']' + char(13)
            select @cmd = @cmd + case when row_number() over(order by [FileName]) = 1 then 'from disk = ' else ',    disk = ' end + char(39) + @path + [FileName] + char(39) + char(13) 
            from @header 
            where [DatabaseName] = @DatabaseName and [BackupStartDate] = @BackupStartDate and [LastLsn] = @LastLsn
               set @cmd = @cmd + ' with file = ' + cast(@Position as varchar(2)) + char(13)
               set @cmd = @cmd + ',standby = ' + char(39) + @data_drive + @phys_filename + '_undo.dat' + char(39) + char(13)
               set @cmd = @cmd + ',nounload' + char(13)
               set @cmd = @cmd + ',stats = 10' + char(13)
               set @cmd = @cmd + ',replace' + char(13)
               set @cmd = @cmd + ',restart' + char(13)
            select @cmd = @cmd + ',move N' + char(39) + [LogicalName] + char(39) + ' to N' + char(39) + @data_drive + @phys_filename + '_data_' + cast(row_number() over(order by [FileName]) as varchar(5)) + right([PhysicalName], patindex('%[.]%', reverse([PhysicalName]))) + char(39) + char(13)
            from @filelistonly
            where [FileName] = @FileName and Type = 'D'
            order by [FileId]
            select @cmd = @cmd + ',move N' + char(39) + [LogicalName] + char(39) + ' to N' + char(39) + @log_drive + @phys_filename + '_log_' + cast(row_number() over(order by [FileName]) as varchar(5)) + right([PhysicalName], patindex('%[.]%', reverse([PhysicalName]))) + char(39) + char(13)
            from @filelistonly
            where [FileName] = @FileName and Type = 'L'
            order by [FileId]
         end -- create sql native restore database script end

     end -- full database restore start

    if @backup_mode = 2
     begin -- transaction log restore start
         
            if @bkp_type = 'L'
             begin -- create litespeed restore log script start
                    set @cmd =        'exec master.dbo.xp_restore_log' + char(13) 
                    set @cmd = @cmd + ' @database = ' + char(39) + @db_name + char(39) + char(13) 
                 select @cmd = @cmd + ',@FileName = ' + char(39) + @path + [FileName] + char(39) + char(13)
                 from @header
                 where [DatabaseName] = @DatabaseName and [BackupStartDate] = @BackupStartDate and [LastLsn] = @LastLsn
                    set @cmd = @cmd + ',@filenumber = ' + cast(@Position as varchar(2)) + char(13) 
                    set @cmd = @cmd + ',@with = ' + char(39) + 'restart'+ char(39) + char(13)
                if @stopat < @BackupStartDate
                 begin
                    set @cmd = @cmd + ',@with = ' + char(39) + 'stopat = ' + char(39) + char(39) + convert(char(23), @stopat, 121) + char(39) + char(39) + char(39) + char(13)
                 end
                else
                 begin
                    set @cmd = @cmd + ',@with = ' + char(39) + 'standby = N'+ char(39) + char(39) + @data_drive  + @phys_filename + '_undo.dat' + char(39) + char(39) + char(39) + char(13)
                 end
                if @Encryption = 1
                 begin
                    set @cmd = @cmd + ',@EncryptionKey = ' + char(39) + @EncryptionKey + char(39) + char(13)
                 end
             end -- create litespeed restore log script end
               
            if @bkp_type = 'S'
             begin -- create sql native restore log script start
                    set @cmd =        'restore log [' + @db_name + ']' + char(13) 
                 select @cmd = @cmd + case when row_number() over(order by [FileName]) = 1 then 'from disk = ' else ',    disk = ' end + char(39) + @path + [FileName] + char(39) + char(13) 
                 from @header 
                 where [DatabaseName] = @DatabaseName and [BackupStartDate] = @BackupStartDate and [LastLsn] = @LastLsn
                    set @cmd = @cmd + ' with file = ' + cast(@Position as varchar(2)) + char(13)
                if @stopat < @BackupStartDate
                 begin
                    set @cmd = @cmd + ',stopat = ' + char(39) + convert(char(23), @stopat, 121) + char(39) + char(13)
                 end
                else
                 begin
                    set @cmd = @cmd + ',standby = N' + char(39) + @data_drive + @phys_filename + '_undo.dat' + char(39) + char(13)
                 end
             end -- create sql native restore log script end

     end --transaction log restore start end

-- add recover database command to end if its the final set of db files
if (@stopat is null) AND (@rstr_standby = 0) and @FileOrder = (select max([FileOrder]) from @header where [DatabaseName] = @DatabaseName)
 begin
    set @cmd = @cmd + char(13) + 'restore database [' + @db_name + '] with recovery'+ char(13)
 end

end

if @print_restore = 1
 begin -- print start
  if @cmd <> ''
   begin
     if (@backup_mode = 1) -- full backup
     or (@backup_mode = 2 and @Prev_Mode is null and @dbLSN is null and @FirstLSN <= @PrevdbLSN) -- first lsn backup in chain 
     or (@backup_mode = 2 and @Prev_Mode is null and @dbLSN is not null and @FirstLSN <= @dbLSN) -- first lsn backup in chain
     or (@backup_mode = 2 and @Prev_Mode = 1 and @PrevLSN is null) -- first log after full backup with no previous log backups
     or (@backup_mode = 2 and @Prev_Mode = 1 and @PrevLSN <= @FirstLSN) -- lsn backup chain in order
     or (@backup_mode = 2 and @Prev_Mode = 2 and @PrevLSN = @FirstLSN) -- lsn backup chain in order
     or (@backup_mode = 5) -- diff backup
        begin -- lsn good
        print @cmd
        print 'go' + char(13)
     end -- lsn good
     else
       begin -- lsn chain broken start
        print '-----------------------------------'
        print '-- Missing Transaction Log File for: ' + @DatabaseName + ''
        print '-----------------------------------' + char(13)
        print 'go' + char(13)
        print @cmd
        print 'go' + char(13)
        end -- lsn chain broken end
   end
 end  -- print end
else
 begin -- exec begin
        exec (@cmd)
 end -- exec end

select @id = min([id]) from @databases where [id] > 0 and [id] > @id
end -- while loop end
--

end -- proc end






GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
