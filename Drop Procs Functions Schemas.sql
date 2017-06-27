-- drop all the type of functions
declare @cnt int,
		@sql Varchar(1000),
		@rowcount int

create table #test (
		id int identity,
		line Varchar(1000)
		)
insert into #test(line)
select	'drop function ' +
		quotename(schema_name(schema_id)) + '.' +
		quotename(name)
from	sys.objects
where	type = 'tf' -- table valued funciont
or		type = 'if' -- inline function
or		type = 'af' -- aggregate function (clr)
or		type = 'fn' -- scalar function
order by name

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


-- drop all the stored procedures
declare @cnt int,
		@sql Varchar(1000),
		@rowcount int

create table #test (
		id int identity,
		line Varchar(1000)
		)
insert into #test(line)
select	'drop procedure ' +
		QUOTENAME(schema_name(schema_id)) + '.' +
		QUOTENAME(name)
from	sys.procedures
where	is_ms_shipped = 0
and		name != 'sp_whoisactive'
and		name != 'sp_who3'
order by name

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


-- drop all the synonyms
declare @cnt int,
		@sql Varchar(1000),
		@rowcount int

create table #test (
		id int identity,
		line Varchar(1000)
		)
insert into #test(line)
select	'drop synonym ' +
		QUOTENAME(schema_name(schema_id)) + '.' +
		QUOTENAME(name)
from	sys.synonyms
where	is_ms_shipped = 0
order by name

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

-- drop all the xml schema collections
declare @cnt int,
		@sql Varchar(1000),
		@rowcount int

create table #test (
		id int identity,
		line Varchar(1000)
		)
insert into #test(line)
select	'drop xml schema collection ' +
		QUOTENAME(schema_name(schema_id)) + '.' +
		QUOTENAME(name)
from	sys.xml_schema_collections
where	name != 'sys'

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

-- drop all the schemas
declare @cnt int,
		@sql Varchar(1000),
		@rowcount int

create table #test (
		id int identity,
		line Varchar(1000)
		)
insert into #test(line)
select	'drop schema ' +
		QUOTENAME(name)
from	sys.schemas
where	name in (
'SalesLT',
'HumanResources',
'Person',
'Production',
'Purchasing',
'Sales',
'MetadataSchema'
)

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

IF  EXISTS (SELECT * FROM sys.triggers WHERE parent_class_desc = 'DATABASE' AND name = N'ddlDatabaseTriggerLog')
DISABLE TRIGGER [ddlDatabaseTriggerLog] ON DATABASE

GO

/****** Object:  DdlTrigger [ddlDatabaseTriggerLog]    Script Date: 10/02/2012 13:33:32 ******/
IF  EXISTS (SELECT * FROM sys.triggers WHERE parent_class_desc = 'DATABASE' AND name = N'ddlDatabaseTriggerLog')DROP TRIGGER [ddlDatabaseTriggerLog] ON DATABASE
GO