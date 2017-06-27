SELECT CAST(target_data as xml) AS targetdata 
INTO #system_health_data 
FROM sys.dm_xe_session_targets xet 
JOIN sys.dm_xe_sessions xe 
ON xe.address = xet.event_session_address 
WHERE name = 'system_health' 
AND xet.target_name = 'ring_buffer'; 
SELECT 
DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), xevents.event_data.value
('(@timestamp)[1]', 'datetime2')) AS [err timestamp], 
xevents.event_data.value('(data[@name="severity"]/value)[1]', 'bigint') 
AS [err severity], 
xevents.event_data.value('(data[@name="error_number"]/value)[1]', 'bigint') 
AS [err number], 
xevents.event_data.value('(data[@name="message"]/value)[1]', 'nvarchar(512)') 
AS [err message], 
xevents.event_data.value('(action/value)[2]', 'varchar(10)') as [session id], 
xevents.event_data.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(max)') 
AS [query text], 
xevents.event_data.query('.') as [event details] 
FROM #system_health_data 
CROSS APPLY targetdata.nodes('//RingBufferTarget/event') AS xevents (event_data) 
WHERE xevents.event_data.value('(@name)[1]', 'nvarchar(256)')='error_reported'; 
DROP TABLE #system_health_data; 
GO 