--List Active Extended Event (XE) Sessions on your SQL Server
select * from sys.dm_xe_sessions
GO

-- Information caputre for system_health_session

select event_name,name from sys.dm_xe_session_events e 
inner join sys.dm_xe_sessions s 
on e.event_session_address = s.address 
where name='system_health' 

GO

-- Event session name and target information
SELECT 
es.name AS session_name, 
tg.name AS target_name 
FROM sys.server_event_sessions AS es 
JOIN sys.server_event_session_targets AS tg 
ON es.event_session_id = tg.event_session_id
GO

