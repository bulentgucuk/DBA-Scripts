-- drop all the views
declare @cnt int,
		@sql Varchar(1000),
		@rowcount int

create table #test (
		id int identity,
		line Varchar(1000)
		)
insert into #test(line)
select	'drop view ' +
		QUOTENAME(SCHEMA_NAME(schema_id)) + '.' +
		QUOTENAME(name)
from	sys.views
where	is_ms_shipped = 0


select @rowcount = @@rowcount 
select @cnt = 1 
while @rowcount > = @cnt
	begin
		select @sql = line from #test where id = @cnt
		print @sql
		exec (@sql)
		select @cnt= @cnt+ 1
	end
drop table #test

go

-- drop all the tables
declare @cnt int,
		@sql Varchar(1000),
		@rowcount int

create table #test (
		id int identity,
		line Varchar(1000)
		)
insert into #test(line)
select	'drop table ' +
		QUOTENAME(SCHEMA_NAME(schema_id)) + '.' +
		QUOTENAME(name)
from	sys.tables
where	is_ms_shipped = 0


select @rowcount = @@rowcount 
select @cnt = 1 
while @rowcount > = @cnt
	begin
		select @sql = line from #test where id = @cnt
		print @sql
		exec (@sql)
		select @cnt= @cnt+ 1
	end
drop table #test

