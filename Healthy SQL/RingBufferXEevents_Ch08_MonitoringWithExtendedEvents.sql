SET NOCOUNT ON 
--Store the XML data in a temp table 
SELECT CAST(xet.target_data as xml) as XMLDATA 
INTO #SystemHealthSessionData 
FROM sys.dm_xe_session_targets xet 
JOIN sys.dm_xe_sessions xe 
ON (xe.address = xet.event_session_address) 
WHERE xe.name = 'system_health' 
-- Group the events by type 
;WITH CTE_HealthSession AS 
( 
SELECT C.query('.').value('(/event/@name)[1]', 'varchar(255)') as EventName, 
C.query('.').value('(/event/@timestamp)[1]', 'datetime') as EventTime 
FROM #SystemHealthSessionData a 
CROSS APPLY a.XMLDATA.nodes('/RingBufferTarget/event') as T(C)) 
SELECT EventName, 
COUNT(*) as Occurrences, 
MAX(EventTime) as LastReportedEventTime, 
MIN(EventTime) as OldestRecordedEventTime 
FROM CTE_HealthSession 
GROUP BY EventName 
ORDER BY 2 DESC 
--Drop the temporary table 
DROP TABLE #SystemHealthSessionData 