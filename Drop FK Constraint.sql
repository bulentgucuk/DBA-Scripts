-- drop all FK constraints
declare @cnt int,
		@sql Varchar(1000),
		@rowcount int

create table #test (
		id int identity,
		line Varchar(1000)
		)
insert into #test(line)
select	'alter table ' + 
		quotename(schema_name(fk.schema_id)) + '.' +
		quotename(OBJECT_NAME(fk.parent_object_id)) + ' drop constraint ' +
		quotename(fk.name)
		--,fk.*
from	sys.foreign_keys as fk
	inner join sys.objects as o
		on fk.referenced_object_id = o.object_id
where	o.is_ms_shipped = 0

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



