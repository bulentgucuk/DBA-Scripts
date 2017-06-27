/*The following queries from Healthy SQL Chapter 5-Tools Of The Trade
  Default Trace >> Ensure Default Trace Is On section 
  Run these separately as needed */

-- Check if Default Trace is Enabled/On
SELECT name, CASE WHEN value_in_use=1 THEN 'ENABLED' 
WHEN value_in_use=0 THEN 'DISABLED' 
END AS [status] 
FROM sys.configurations 
WHERE name='default trace enabled'

GO

--List Events Captured By The Default Trace
declare @handle int = (select id from sys.traces where is_default = 1); 
-- or use where id=@traceid 
select distinct e.eventid, n.name from 
fn_trace_geteventinfo(@handle) e 
join sys.trace_events n 
on e.eventid = n.trace_event_id 
order by n.name asc 

GO

--Get Active Default Trace Path on you SQL Server
declare @trcpath varchar(255) 
select @trcpath=convert(varchar(255),value) from [fn_trace_getinfo](NULL) 
where [property] = 2 AND traceid=1 
select @trcpath As ActiveDefaultTracePath 
-- Use fn_trace_gettable to return system trace data 
SELECT name, EventClass, category_id, substring(TextData,1,50), Error, DatabaseName, 
ApplicationName,LoginName,SPID,StartTime,ObjectName 
FROM [fn_trace_gettable]('' + @trcpath + '', DEFAULT) t 
inner join sys.trace_events te 
on t.EventClass=te.trace_event_id 
ORDER BY StartTime;		