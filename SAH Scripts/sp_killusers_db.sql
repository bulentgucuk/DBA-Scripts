USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_killusers_db]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[sp_killusers_db]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



Create procedure [dbo].[sp_killusers_db]
@dbname char(30), 
@max_time int = '300'
as
set nocount on

--Updated for SQL 2000

declare @begin datetime
declare @duration int
declare @cnt int
declare @cmd varchar(12)

select @cnt = count(*)
  from master..sysdatabases a
  join master..sysprocesses b
    on a.dbid = b.dbid 
 where a.name = @dbname

set @begin = getdate()
while datediff(ss, @begin, getdate()) < @max_time and @cnt > 0
  begin
    select top 1 @cmd = 'kill ' + convert(varchar(3),b.spid)
      from master..sysdatabases a
      join master..sysprocesses b
        on a.dbid = b.dbid 
     where a.name = @dbname
       and b.cmd <> 'KILLED/ROLLBACK'  --Don't try and kill again.
       and b.SPID > 50                 --Don't try and kill system processes.
     order by b.spid desc

    exec (@cmd)

    waitfor delay '00:00:01'

    --This will find System (ghost cleanup) and
    --Killed spids that are rolling back waiting
    --until completed or @max_time is reached.
    select @cnt = count(*)
      from master..sysdatabases a
      join master..sysprocesses b
        on a.dbid = b.dbid 
     where a.name = @dbname

  end

print 'Kill Processes Complete'




GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
