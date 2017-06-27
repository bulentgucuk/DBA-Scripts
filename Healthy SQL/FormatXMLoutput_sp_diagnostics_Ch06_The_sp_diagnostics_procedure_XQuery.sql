create table #diagdata 
( 
create_time datetime, 
component_type sysname, 
component_name sysname, 
[state] int, 
state_desc sysname, 
data varchar(max) 
) 
insert into #diagdata 
exec sp_server_diagnostics

select * from #diagdata

select cast(data as xml) as xml_data 
from #diagdata for xml auto,elements

declare @x varchar(max) 
declare @dochandle int 
select @x = data 
from #diagdata 
where component_name = 'resource' 
exec sp_xml_preparedocument @dochandle output, @x 
select * 
from openxml(@dochandle, '/resource/memoryReport/entry', 3) 
with (description varchar(255), value bigint) 

exec sp_xml_removedocument @dochandle

--Top 10 waits by count: 

select @x = data 
from #diagdata 
where component_name = 'query_processing' 
exec sp_xml_preparedocument @dochandle output, @x 

select * 
from openxml(@dochandle, '/queryProcessing/topWaits/nonPreemptive/byCount/wait', 3) 
with (waitType varchar(255), waits bigint, averageWaitTime bigint, maxWaitTime bigint) 
exec sp_xml_removedocument @dochandle

-- Top 10 waits by duration: 
select @x = data 
from #diagdata 
where component_name = 'query_processing' 
exec sp_xml_preparedocument @dochandle output, @x 

select * 
from openxml(@dochandle, '/queryProcessing/topWaits/nonPreemptive/byDuration/wait', 3) 
with (waitType varchar(255), waits bigint, averageWaitTime bigint, maxWaitTime bigint) 
exec sp_xml_removedocument @dochandle

--Drop the temp table when you've finished: 
drop table #diagdata