USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_DatabaseBackupUtility]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[sp_DatabaseBackupUtility]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[sp_DatabaseBackupUtility]

/**********************************************************************************************************************
proc name:           sp_DatabaseBackupUtility

                     SQL 2005+

Version:             6

Description:         Procedure to create database backups

Output Parameters:   Default output is a PRINT out of backup statements.

Dependent On:        function msdb.dbo.fn_encrpt_key


Example:             exec master..sp_DatabaseBackupUtility
                      @DbExclusions     = 'NorthWind, Pubs'  -- names of databases to not backup
                     ,@DbInclusions     = 'NorthWind, Pubs'  -- names of databases to backup
                     ,@device_name      = '\\.\tape01'       -- backup to tape or device
                     ,@path             = 'C:\backup'        -- path to backup files
                     ,@Files            = ''                 -- logical filenames to backup
                     ,@FileGroups       = ''                 -- FileGroup names to backup
                     ,@bkp_type         = 'L'                -- L(itespeed), S(QL Native)
                     ,@bkp_mode         = 'F'                -- F(ull), T(ransaction Log), D(iff)
                     ,@print_restore    = 1                  -- 1 Print, 0 Execute
                     ,@file_count       = 3                  -- number of files to split the backup into (1-99)
                     ,@encryption       = 1                  -- 1 encrypt litespeed file, 0 do not encrypt
                     ,@verify           = 1                  -- 1 verify the backup, 0 do not verify
                     ,@retention        = 0                  -- number of files to keep
                     ,@client_abbrv     = 'NLNT'             -- client abbrv for encryption key
                     ,@BufferCount      =                    -- 2008r2 specifies the total number of I/O buffers to be used for the backup operation
                     ,@maxtransfersize  =                    -- 2008r2 specifies the largest unit of transfer in bytes to be used between SQL Server and the backup media
                     ,@blocksize        =                    -- 2008r2 specifies the physical block size, in bytes. Supported sizes: 512, 1024, 2048, 4096, 8192, 16384, 32768, and 65536 bytes. default is 65536 for tape devices and 512 otherwise. 
                     ,@compressionlevel = 2                  -- litespeed compression level 0-8, sql compression 0-1
                     ,@threads          = 0                  -- litespeed threads - number of processors-1
                     ,@priority         = 0                  -- litespeed priority - 0-Normal, 1-Above Normal, 2-High
                     ,@init             = 0                  -- 1 over write backup file, 0 append to backup file, over rides @retention setting
                     ,@logging          = 0                  -- 0 off | 1 logging on, log file removed on success | 2 logging on
                     ,@throttle         = 100                -- default 100% of enabled processors values (1-100)
                     ,@cryptlevel       = 8                  -- litespeed encryption mode (1-8)
                                                                0 - 40-bit  RC2, 1 - 56 bit  RC2,  2 - 112 bit RC2
                                                                3 - 128 bit RC2, 4 - 168 bit 3DES, 5 - 128 bit RC4
                                                                6 - 128 bit AES, 7 - 192 bit AES,  8 - 256 bit AES
                     ,@stats            = 0                  -- 0-100
                     ,@retries          = 3                  -- 0-10 number of times to retry a backup if it errors out
                     ,@resume           = 1                  -- 0 backup all databases, 1 start where backup failed

History:
                     Name            Date            Pr Number       Description
                     ----------      -----------     ---------       ---------------
                     B. Jones        09/20/2010      n/a             Creation of inital script
                     B. Jones        10/01/2010      n/a             Added client_abbrv functionality 
                     B. Jones        10/25/2010      n/a             Added @DbExclusions and @DbInclusions functionality
                     B. Jones        10/25/2010      n/a             Added backup to tape options
                     B. Jones        01/27/2011      n/a             Fixed logging and retries
                     B. Jones        02/14/2011      n/a             replaced cursor loop with while loop
                     J. Adams        03/11/2015      n/a             Allow @sql > 11 to be handled
   

**********************************************************************************************************************/
 
 @DbExclusions          varchar(max)   = ''                     -- 
,@DbInclusions          varchar(max)   = ''                     -- 
,@device_name           varchar(255)   = ''                     -- name of backup device '\\.\Tape0'
,@path                  varchar(255)   = ''                     -- path to backup files
,@file_ext              varchar(3)     = ''                     -- 
,@Files                 varchar(max)   = ''                     -- 
,@FileGroups            varchar(max)   = ''                     -- 
,@bkp_type              varchar(1)     = 'L'                    -- L(itespeed), S(QL Native)
,@bkp_mode              varchar(1)     = 'F'                    -- F(ull), T(ransaction Log), D(iff)
,@print_restore         bit            = 1                      -- 1 Print, 0 Execute
,@encryption            bit            = 0                      -- 1 encrypt litespeed file, 0 do not encrypt
,@file_count            int            = 1                      -- number of files to split the backup into (1-50)
,@verify                bit            = 1                      -- 1 verify the backup, 0 do not verify
,@retention             int            = 0                      -- number of files to keep (0-??)
,@client_abbrv          varchar(4)     = ''                     -- client abbrv for encryption key
,@compressionlevel      int            = 2                      -- litespeed compression level (0-8)
,@threads               int            = 0                      -- litespeed threads - defaults to number of processors-1
,@priority              int            = 0                      -- litespeed priority - 0-Normal, 1-Above Normal, 2-High
,@init                  bit            = 0                      -- 
,@logging               tinyint        = 0                      -- 0 | 1 | 2
,@throttle              tinyint        = 100                    -- default 100% of enabled processors values (1-100)
,@cryptlevel            tinyint        = 8                      -- 
,@stats                 tinyint        = 0                      -- 0-100
,@retries               tinyint        = 0                      -- 0-10 number of times to retry a backup if it errors out
,@resume                bit            = 1                      -- 0 backup all databases, 1 start where backup failed
,@BufferCount			int				= 0
--with encryption

as
begin -- proc start

set nocount on

declare @cmd            varchar(max)                            -- 
       ,@sql            varchar(20)                             -- sql server version: 8(2000), 9(2005), 10(2008)
       ,@sls            varchar(20)                             -- lightspeed version: 4(.8.3.00025), 6(.0.1.1007)
       ,@client_abb_chk varchar
(4)                              -- 
       ,@client_abb_avl varchar(max)                            -- 
       ,@DbExIn         varchar(max)                            -- 
       ,@inorex         bit                                     -- 1 - include, 0 = exclude
       ,@DbExclusion    sysname                                 -- 
       ,@DbInclusion    sysname                                 -- 
       ,@string         varchar(max)                            --
       ,@id             int                                     -- database id
       ,@DBName         sysname                                 -- database name
       ,@exists         bit                                     -- was a backup file created?
       ,@datetime       datetime                                --
       ,@model          tinyint                                 -- 1 = FULL, 2 = BULK_LOGGED, 3 = SIMPLE
       ,@model_desc     nvarchar(60)                            -- FULL, BULK_LOGGED, SIMPLE
       ,@readonly       bit                                     -- 0 = Database is READ_WRITE, 1 = Database is READ_ONLY
       ,@standby        bit                                     -- 1 = Database is read-only for restore log. 
       ,@FileNames      varchar(max)                            -- 
       ,@FileName       varchar(max)                            -- 
       ,@dt             varchar(13)                             -- 
       ,@backup_dt      varchar(23)                             -- 
       ,@cycle_t        varchar(8)                              -- 
       ,@ForT           varchar(255)                            -- 
       ,@retry_attempts tinyint                                 -- 
       ,@count_u        int                                     -- 
       ,@count_d        int                                     -- 
       ,@encryptionkey  varchar(255)                            -- 
       ,@description    varchar(255)                            -- 
       ,@retention_p    int                                     -- 
       ,@ErrorMessage   nvarchar(4000)                          -- 
       ,@ErrorSeverity  int                                     -- 
       ,@ErrorState     int                                     -- 

-- L(itespeed), S(QL Native)
set @bkp_type = UPPER(@bkp_type)
if @bkp_type != 'L' and @bkp_type != 'S'
 begin
     print @bkp_type + ' is not a valid backup type!'
     return
 end
 
-- F(ull), T(ransaction Log), D(iff)
set @bkp_mode = UPPER(@bkp_mode)
if @bkp_mode != 'F' and @bkp_mode != 'T' and @bkp_mode != 'D'
 begin
     print @bkp_mode + ' is not a valid backup mode!'
     return
 end

-- define backup extenstion
if @file_ext = ''
 begin
  if @bkp_type = 'L'
   begin
     set @file_ext = 'bkp'
   end
  if @bkp_type = 'S'
   begin
     set @file_ext = 'bak'
   end
 end
 
if @DbExclusions <> '' and @DbInclusions <> ''
 begin
     print 'Only @DbExclusions or @DbInclusions can be used at a time, not both!'
     return
 end
 
 if @device_name <> '' and @path <> ''
 begin
     print 'Only @device_name or @path can be used at a time, not both!'
     return
 end
 
 if @path <> ''
 begin
    if left(reverse(@path), 1) != '\'
     begin
	    set @path = @path + '\'
     end
 end

if @bkp_type = 'L' and @path = '' and @device_name not like '\\.\t%' -- tape
 begin
     print '@device_name must be like \\.\tape0 when using litespeed'
     return
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

if @encryption = 1 and @bkp_type = 'L'
 begin -- client_type check

  set @client_abb_chk = ''
  set @client_abb_avl = ''
  
  select @client_abb_chk = isnull([client_abbrv],'') from msdb..encrptkey where [client_abbrv] = @client_abbrv
  
       if @client_abb_chk = ''
      begin
          print '@client_abbrv of ''' + @client_abbrv + ''' is not a valid backup mode! ' + char(13) + char(13) + 'Please use one of the following: '
           select @client_abb_avl = @client_abb_avl + char(39) + [client_abbrv] + char(39) + char(13) from msdb.dbo.encrptkey
          print  @client_abb_avl
          return
      end
 end -- client_type check

if @DbInclusions <> ''
 begin
     set @DbExIn = @DbInclusions
     set @string = @DbInclusions
     set @inorex = 1 -- include
 end
else
 begin
     set @DbExIn = @DbExclusions
     set @string = @DbExclusions
     set @inorex = 0 -- exclude
 end
 
-- fix path if needed start
if left(reverse(@path), 1) <> '\'
 begin
     set @path = @path + '\'
 end
 
-- set limits on amount of files allowed for each backup
if @file_count < 1
 begin
     set @file_count = 1
 end
if @file_count > 255
 begin
  if @bkp_type = 'L'
  begin
   set @file_count = 255 -- litespeed limit
  end
  else
  begin
   set @file_count = 64 -- sql limit
  end
 end
 
-- set stats limit 
if @stats < 0
 begin
     set @stats = 0
 end
if @stats > 100
 begin
     set @stats = 100
 end
 
-- turn off retention if init is on
if @init = 1
 begin
     set @retention = 0
 end

-- set retries limit 
if @retries < 0
 begin
     set @retries = 0
 end
if @retries > 10
 begin
     set @retries = 10
 end
 
-- set limit on compression level for litespeed backups 0-8 valid options, sql backups 0-1 valid options
 if @compressionlevel < 0
 begin
     set @compressionlevel = 0
 end
if @compressionlevel > 8
 begin
     set @compressionlevel = 8
 end
 
-- set litespeed threads to number of processors-1
if @threads = 0
 begin
     select @threads = (cpu_count-1) from sys.dm_os_sys_info
 end
if @threads < 2 -- minimum is 2
 begin
     set @threads = 2
 end
 
declare @databases table ([id] int null, [name] sysname null)

if @DbInclusions <> ''
 begin
     insert @databases
     select [database_id], [name]
     from   sys.databases
     where  isnull(databaseproperty([name],'isOffline'),0) = 0
     and    isnull(databaseproperty([name],'IsSuspect'),0) = 0
     and    isnull(databaseproperty([name],'IsShutDown'),0) = 0
     and    isnull(databaseproperty([name],'IsNotRecovered'),0) = 0
     and    isnull(databaseproperty([name],'IsInStandBy'),0) = 0
     and    isnull(databaseproperty([name],'IsInRecovery'),0) = 0
     and    isnull(databaseproperty([name],'IsInLoad'),0) = 0
     and    isnull(databaseproperty([name],'IsEmergencyMode'),0) = 0
     and    isnull(databaseproperty([name],'IsDetached'),0) = 0
     and    [name] != 'tempdb'
     and    [source_database_id] is null
     and    exists (select ltrim(rtrim([item])) from fn_ParseString (@DbExIn,',') where ltrim(rtrim([item])) = [name])
 end
else
 begin
     insert @databases
     select [database_id], [name]
     from   sys.databases
     where  isnull(databaseproperty([name],'isOffline'),0) = 0
     and    isnull(databaseproperty([name],'IsSuspect'),0) = 0
     and    isnull(databaseproperty([name],'IsShutDown'),0) = 0
     and    isnull(databaseproperty([name],'IsNotRecovered'),0) = 0
     and    isnull(databaseproperty([name],'IsInStandBy'),0) = 0
     and    isnull(databaseproperty([name],'IsInRecovery'),0) = 0
     and    isnull(databaseproperty([name],'IsInLoad'),0) = 0
     and    isnull(databaseproperty([name],'IsEmergencyMode'),0) = 0
     and    isnull(databaseproperty([name],'IsDetached'),0) = 0
     and    [name] != 'tempdb'
     and    [source_database_id] is null
 
    and    not exists (select ltrim(rtrim([item])) from fn_ParseString (@DbExIn,',') where ltrim(rtrim([item])) = [name])
 end

--clean up
delete from [DatabaseBackupUtility_Resume] where [lst_updt_tmestmp] < getdate() - 90

--
if @resume = 0
 begin
    delete from DatabaseBackupUtility_Resume where inorex = @inorex and string = @string and mode = @bkp_mode
 end

-- resume if failed in middle of backup
if not exists (select * from DatabaseBackupUtility_Resume where inorex = @inorex and string = @string and mode = @bkp_mode)
 begin
    select @id = min([id]) from @databases where [id] > 0 -- get id of first database to backup
    insert into DatabaseBackupUtility_Resume (inorex, string, mode, id, name) values (@inorex, @string, @bkp_mode, '', '')
 end
else
 begin
    select @id = id from DatabaseBackupUtility_Resume where inorex = @inorex and string = @string and mode = @bkp_mode
 end

 
while @id is not null
begin -- while loop start

-- get name of database to backup
select @DBName = name from @databases where [id] = @id 

-- updates the resume table for current database name
update DatabaseBackupUtility_Resume set [id] = @id, [name] = @DBName where inorex = @inorex and string = @string and mode = @bkp_mode
 
--select * from DatabaseBackupUtility_Resume 

--if @id = 6
--begin
--return
--end

set @exists = 0
set @datetime = getdate()

select @model = recovery_model
      ,@model_desc = recovery_model_desc
      ,@readonly = is_read_only
      ,@standby = is_in_standby
from sys.databases
where name = @DBName

-- set backup options 
if @bkp_mode = 'F'
 begin
     set @cycle_t = 'full'
     set @ForT    = 'database'
   if @FileGroups <> ''
    begin
     set @cycle_t = 'flfg'
    end
 end
if @bkp_mode = 'T'
 begin
     set @cycle_t = 'tran'
     set @ForT    = 'log'
   if @FileGroups <> ''
    begin
     set @cycle_t = 'tnfg'
    end
 end
if @bkp_mode = 'D'
 begin
    set @cycle_t = 'diff'
    set @ForT    = 'database'
   if @FileGroups <> ''
    begin
     set @cycle_t = 'dffg'
    end
 end
 


-- create datetime stamp for backups _yyyymmddhhmm
    set @dt = ''
if @retention > 0
 begin
    set @dt = '_' + cast(left(replace(replace(replace(convert(char(19), CONVERT(varchar(19), @datetime, 120)), ' ', ''), ':', ''), '-', ''), 12) as varchar(8000))
 end

-- create FileName(s)
    set @FileNames = ''
    set @count_d = @file_count
    set @count_u = 1
while @count_d > 0
begin -- create FileName(s) loop start

IF @bkp_type = 'L' -- create FileName(s) for litespeed backups
 begin
         set @FileNames = @FileNames + ',@filename = '
 end
      
IF @bkp_type = 'S' -- create FileName(s) for sql backups
 begin
     if @count_d = @file_count
      begin
         set @FileNames = @FileNames + '   to '
      end
     else
      begin
         set @FileNames = @FileNames + ',     '
      end
         set @FileNames = @FileNames + 'disk = N'
 end
 
         set @FileNames = @FileNames + '' + char(39) + @path + @DBName + @dt + '_' + @cycle_t + '_' + left(cast(replicate(cast(0 as varchar(max)), 9) as varchar(9)), 3 - len(@count_u)) + cast(@count_u as varchar(10)) + '_dmp.' + @file_ext + char(39) + char(13)
 
	set @count_d = @count_d - 1
	set @count_u = @count_u + 1
 
end -- create FileName(s) loop end
             
--get encryption key for litespeed
	set @encryptionkey = ''
	set @description = ''
	set @backup_dt = @datetime
if @bkp_type = 'L' and @encryption = 1
 begin
     select @encryptionkey = encrpt_key
           ,@description = @bkp_type + convert(char(23),eff_dt, 121) + '-' + UPPER(@client_abb_chk)
     from msdb.dbo.fn_encrpt_key(@client_abb_chk, @bkp_type, @backup_dt)

     if @encryptionkey is null or @encryptionkey = '' 
       begin
          raiserror ('LiteSpeed Backup Missing Encryption Key', 16, -1)
          return
       end

 end
else
 begin
     set @description = @bkp_type + convert(char(23), @datetime, 121)
 if @client_abbrv <> ''
  begin
     set @description = @description + '-' 
  end
     set @description = @description + UPPER(@client_abbrv)
 end

-- create backup statment
if (@DBName != 'master' and @bkp_type = 'L') or (@DBName = 'master' and @bkp_type = 'L' and @bkp_mode = 'F') -- Litespeed
 begin
     if (@model = 3 or @readonly = 1) and (@bkp_mode = 'T')
      begin
          if @model = 3
           begin
               set @cmd =  '--You cannot backup the transaction log for ' + @DBName + ' in simple recovery mode' + char(13)
           end
          if @readonly = 1
           begin
               set @cmd =  '--You cannot backup the transaction log for ' + @DBName + ' in Read-Only mode' + char(13)
           end
      end
     else
      begin
          set @exists = 1 -- backup file being created to verify
               set @cmd =        'exec master.dbo.xp_backup_' + @ForT + char(13)
               set @cmd = @cmd + ' @database = ' + char(39) + @DBName + char(39) + char(13)
          if @device_name = ''
           begin
               set @cmd = @cmd + @FileNames
           end
          else
           begin
               set @cmd = @cmd + ',@filename = ' + char(39) + @device_name + char(39) + char(13)
           end
        -- backup filegroups
          if @FileGroups <> ''
           begin
            select @cmd = @cmd + ',@filegroup = ' + char(39) + ltrim(rtrim([item])) + char(39) + char(13) + char(10) from fn_ParseString (@FileGroups,',')
               set @cmd = left(@cmd,len(@cmd)-2) + char(13) + char(10) 
           end
           
               set @cmd = @cmd + ',@desc = ' + char(39) + @description + char(39) + char(13)
               set @cmd = @cmd + ',@threads = ' + CAST(@threads as varchar(2)) + char(13)
          if @device_name = '' and @init = 1
           begin
               set @cmd = @cmd + ',@init = 1' + char(13)
           end
          if @device_name <> ''
           begin
               set @cmd = @cmd + ',@format = ' + CAST(@init as varchar(1)) + char(13)
               set @cmd = @cmd + ',@rewind = 0' + char(13)
               set @cmd = @cmd + ',@unload = 0' + char(13)
           end
               set @cmd = @cmd + ',@logging = ' + CAST(@logging as varchar(1)) + char(13)
               set @cmd = @cmd + ',@cryptlevel = ' + CAST(@cryptlevel as varchar(1)) + char(13)
               set @cmd = @cmd + ',@compressionlevel = ' + CAST(@compressionlevel as varchar(1)) + char(13)
               set @cmd = @cmd + ',@priority = ' + CAST(@priority as varchar(1)) + char(13)
               set @cmd = @cmd + ',@throttle = ' + CAST(@throttle as varchar(3)) + char(13)
          --if @verify = 1 and @sls >= '6'
          -- begin
          --     set @cmd = @cmd + ',@verify = 1' + char(13)       
          -- end
          if @bkp_mode = 'D'
           begin
               set @cmd = @cmd + ',@with = ' + char(39) + 'differential' + char(39) + char(13)
           end
          if @encryption = 1
           begin
               set @cmd = @cmd + ',@encryptionkey = ' + char(39) + @encryptionkey + char(39) + char(13)
           end     
      end
 end
 
if (@DBName != 'master' and @bkp_type = 'S') or (@DBName = 'master' and @bkp_type = 'S' and @bkp_mode = 'F') -- SQL
 begin
     if (@model = 3 or @readonly = 1) and (@bkp_mode = 'T')
      begin
          if @model = 3
           begin
               set @cmd =  '--You cannot backup the transaction log for ' + @DBName + ' in simple recovery mode' + char(13)
           end
          if @readonly = 1
           begin
               set @cmd =  '--You cannot backup the transaction log for ' + @DBName + ' in Read-Only mode' + char(13)
           end
      end
     else
      begin
          set @exists = 1 -- backup file being created to verify
               set @cmd =        'backup ' + @ForT + ' ['+@DBName+'] ' + char(13)
        -- backup
 logiical files
          if @Files <> ''
           begin
            select @cmd = @cmd + '      file = ' + ltrim(rtrim([item])) + ',' + char(13) + char(10) from fn_ParseString (@Files,',')
            if @FileGroups = ''
             begin
               set @cmd = left(@cmd,len(@cmd)-3) + char(13) + char(10) 
             end
           end
        -- backup filegroups
          if @FileGroups <> ''
           begin
            select @cmd = @cmd + ' filegroup = ' + char(39) + ltrim(rtrim([item])) + char(39) + ',' + char(13) + char(10) from fn_ParseString (@FileGroups,',')
               set @cmd = left(@cmd,len(@cmd)-3) + char(13) + char(10) 
           end


          if @device_name = ''
           begin
               set @cmd = @cmd + @FileNames
           end
          else
          begin
          if @device_name like '\\.\t%' -- tape
            begin
               set @cmd = @cmd + ' to tape = N' + char(39) + @device_name + char(39) + char(13)
            end
           else
            begin
               set @cmd = @cmd + ' to ' + @device_name + char(13)
            end
           end
               set @cmd = @cmd + ' with description = N' + char(39) + @description + char(39) + char(13)
          if @bkp_mode = 'D'
           begin
               set @cmd = @cmd + ',differential ' + char(13)
           end     
               set @cmd = @cmd + ',skip ' + char(13)
          if @init = 1
           begin
               set @cmd = @cmd + ',init ' + char(13)
               set @cmd = @cmd + ',format ' + char(13)
           end
          else
           begin
               set @cmd = @cmd + ',noformat ' + char(13)
           end
          if @device_name like '%\\.\t%' -- tape
            begin
               set @cmd = @cmd + ',norewind ' + char(13)
               set @cmd = @cmd + ',nounload ' + char(13)
            end
          if @sql >= '10' -- sql 2008   ja handle support > version 10/11 with >=
          begin
           if @compressionlevel = 0
            begin
               set @cmd = @cmd + ',no_compression ' + char(13)
            end
           else
            begin
               set @cmd = @cmd + ',compression ' + char(13)
            end
            IF @BufferCount > 0
				begin
					set @cmd = @cmd + ',buffercount=' + cast(@BufferCount as varchar(4)) + char(13)
				end
           end
          if @stats > 0
           begin
               set @cmd = @cmd + ',stats = ' + cast(@stats as varchar(3)) + char(13)
           end

      end
 end

-- print or exec backups start
if @print_restore = 1
 begin -- print
  if @cmd <> ''
   begin -- @cmd
    while datalength(@cmd) > 8000
     begin -- loop
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
     end -- loop
       print @cmd
       print 'go' + char(13)
       set @cmd = ''
   end -- @cmd
 end -- print
else
 begin -- exec
  if @cmd <> ''
   begin -- @cmd
  set @retry_attempts = 0

  backup_start:

  print 'Backup starting for ' + @DBName
     
  begin try
     exec (@cmd)
  end try
  begin catch
     select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
     print cast(@ErrorMessage as nvarchar(4000)) + ', ' + cast(@ErrorSeverity as varchar(8000)) + ', ' + cast(@ErrorState as varchar(8000))
     set @retry_attempts = @retry_attempts + 1

     if @retry_attempts < @retries
      begin
          print 'Backup failed for ' + @DBName + '...Restarting' + char(13)
          goto backup_start
      end
     else
      begin
          print 'Backup failed for ' + @DBName + '...Stopping' + char(13)
          raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState) with nowait
          return
      end

  end catch
  
     print 'Backup completed for ' + @DBName + char(13)
     set @cmd = ''

  end -- @cmd
 end -- exec
-- print or exec backups end
 
if @verify = 1 and @exists = 1
begin -- verify files start

          set @cmd = @cmd + 'declare @position int' + char(13)
          set @cmd = @cmd + 'select @position = position from msdb..backupset where database_name=N' + char(39) + @DBName + char(39) + ' and type = ' + char(39) + case when @bkp_mode = 'F' then 'D' when @bkp_mode = 'T' then 'L' else 'I' end + char(39) + ' and backup_set_id = (select max(backup_set_id) from msdb..backupset where database_name = N' + char(39) + @DBName + char(39) + ' and type = ' + char(39) + case when @bkp_mode = 'F' then 'D' when @bkp_mode = 'T' then 'L' else 'I' end + char(39) + ')' + char(13)

if @bkp_type = 'L'
 begin
          set @cmd = @cmd + 'exec master.dbo.xp_restore_verifyonly' + char(13)
          set @cmd = @cmd + ' ' + replace(replace(right(@FileNames,len(@FileNames)-1),char(13), ''),''',@',''''+char(13)+',@') + char(13)
          set @cmd = @cmd + ',@filenumber = @position' + char(13)
     if @device_name like '\\.\t%' -- tape
       begin
          set @cmd = @cmd + ',norewind ' + char(13)
          set @cmd = @cmd + ',nounload ' + char(13)
       end
          set @cmd = @cmd + ',@encryptionkey = ' + char(39) + @encryptionkey + char(39) + char(13)
 end
      
if @bkp_type = 'S'
 begin
          set @cmd = @cmd + 'restore verifyonly' + char(13)
     if @device_name = ''
      begin
          set @cmd = @cmd + replace(@FileNames, '   to disk = N', ' from disk = N')
      end
     else
     begin
     if @device_name like '\\.\t%' -- tape
       begin
          set @cmd = @cmd + ' from tape = N' + char(39) + @device_name + char(39) + char(13)
       end
      else
       begin
          set @cmd = @cmd + ' from ' + @device_name + char(13)
       end
      end
          set @cmd = @cmd + ' with file = @position' + char(13)
          set @cmd = @cmd + ',nounload' + char(13)
 end
 
-- print or exec verify start
if @print_restore = 1
 begin -- print
  if @cmd <> ''
   begin -- @cmd
    while datalength(@cmd) > 8000
     begin -- loop
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
     end -- loop
       print @cmd
      print 'go' + char(13)
      set @cmd = ''
   end -- @cmd
 end -- print
else
 begin -- exec
  if @cmd <> ''
   begin -- @cmd
  set @retry_attempts = 0
 
  verify_start:

  print 'Verify starting for ' + @DBName

  begin try
    
     exec (@cmd)
  end try
  begin catch
            SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
            print cast(@ErrorMessage as nvarchar(4000)) + ', ' + cast(@ErrorSeverity as varchar(8000)) + ', ' + cast(@ErrorState as varchar(8000))
  
     set @retry_attempts = @retry_attempts + 1

     if @retry_attempts < @retries
      begin
          print 'Verify failed for ' + @DBName + '...Restarting' + char(13)
          goto verify_start
      end
     else
      begin
          print 'Verify failed for ' + @DBName + '...' + char(13)
          raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState) with nowait
          return
      end

  end catch

     print 'Verify completed for ' + @DBName + char(13)
     set @cmd = ''

  end -- @cmd
 end -- exec
-- print or exec verify end
 
end -- verify files end


if @retention > 0
 begi
n -- delete older files if needed
 
-- get file list insert into #FileNames
create table #FileNames (FileOrder int identity(1,1), FileName varchar(max) null)
set @cmd = 'master..xp_cmdshell ''dir /b /l /odn /a-d "'+@path+@DBName+'_????????????_'+@cycle_t+'*dmp.'+@file_ext+'"'''
insert #FileNames 
exec (@cmd)
set @cmd = ''

delete #FileNames
where FileName = 'File Not Found' 
   or FileName = 'Access is denied.' 
   or FileName = 'The system cannot find the path specified.' 
   or FileName is null

set @retention_p = 0

if @print_restore = 1
 begin
     set @retention_p = @retention-1 -- accounts for non existant file that will be created if the @print_restore is selected
 end
else
 begin
     set @retention_p = @retention -- keep only the requested number of files
 end
 
set @cmd = 'delete #FileNames where left(FileName, ' + cast(len(@DBName) as varchar(8000)) + ' + 13) in (select distinct top (' + cast(@retention_p as varchar(8000)) + ') left(FileName, ' + cast(len(@DBName) as varchar(8000)) + ' + 13) from #FileNames where FileName is not null order by left(FileName, ' + cast(len(@DBName) as varchar(8000)) + ' + 13) desc)'
exec (@cmd)
set @cmd = ''

select @cmd = @cmd + 'exec master..xp_cmdshell ' + char(39) + 'del "' + @path + FileName + '"' + char(39) + ', no_output;' + char(13) from #FileNames

-- print or exec delete
if @print_restore = 1
 begin -- print
  if @cmd <> ''
   begin -- @cmd
    while datalength(@cmd) > 8000
     begin -- loop
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
     end -- loop
       print @cmd
       print 'go' + char(13)
       set @cmd = ''
   end -- @cmd
 end -- print
else
 begin -- exec
  if @cmd <> ''
   begin
     print 'Deletes starting for ' + @DBName
     print replace(replace(left(@cmd,len(@cmd)-1),'exec master..xp_cmdshell ''del "',''),''', no_output;','')
     exec (@cmd)
     print 'Deletes completed for ' + @DBName + char(13)
     set @cmd = ''
   end 
 end -- exec
-- print or exec delete end

     drop table #FileNames
     
 end -- delete older files if needed

select @id = min([id]) from @databases where [id] > 0 and [id] > @id -- get id of next database to backup
end -- while loop end

-- backup succedded remove entry in DatabaseBackupUtility_Resume database
delete from DatabaseBackupUtility_Resume where inorex = @inorex and string = @string and mode = @bkp_mode
 
end -- proc end




GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
