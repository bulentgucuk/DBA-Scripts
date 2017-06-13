create procedure usp_helpindexusagestats 
  @tablename varchar(1000)
as

set nocount on

if object_id('tempdb..#helpindex') > 0 drop table #helpindex

create table #helpindex (
   index_name varchar (1000) not null primary key
 , index_description varchar (1000) null
 , index_keys varchar (1000) null
)

insert #helpindex
exec sp_helpindex @tablename

alter table #helpindex add inccols varchar(1000) null

declare cr cursor for
select si.name, sc.name
from sysobjects so
join sysindexes si on so.id = si.id
join sys.index_columns ic on si.id = ic.object_id and si.indid = ic.index_id
join sys.columns sc on ic.object_id = sc.object_id and ic.column_id = sc.column_id
where so.xtype = 'U'
  and so.name = @tablename
  and ic.is_included_column = 1
order by si.name, ic.index_column_id

declare @siname varchar(1000), @scname varchar(1000)

open cr

fetch next from cr into @siname, @scname

while @@fetch_status = 0
 begin

  update #helpindex set inccols = isnull(inccols , '') + @scname + ', ' where index_name = @siname

  fetch next from cr into @siname, @scname
 end

update #helpindex set inccols = left(inccols, datalength(inccols) - 2)
where right(inccols, 2) = ', '

close cr
deallocate cr

select hi.index_name
     , hi.index_description
     , hi.index_keys
     , hi.inccols as included_columns
     , ius.index_id
     , user_seeks
     , user_scans
     , user_lookups
     , user_updates
     , last_user_seek
     , last_user_scan
     , last_user_lookup
from  #helpindex hi
join  sysindexes si on si.name = hi.index_name collate database_default
join sysobjects so on si.id = so.id
left join sys.dm_db_index_usage_stats ius on ius.object_id = si.id and ius.index_id = si.indid and ius.database_id = db_id()
where so.name = @tablename

drop table #helpindex
go
