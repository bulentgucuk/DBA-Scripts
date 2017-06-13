SELECT MachineName, 
CONVERT(DATETIME, CONVERT(VARCHAR(16), CounterDateTime)) as [Date], 
AVG(CounterValue) as Average, 
MIN(CounterValue) as Minimum, 
MAX(CounterValue) as Maximum 
FROM CounterDetails 
JOIN CounterData ON CounterData.CounterID = CounterDetails.CounterID 
JOIN DisplayToID ON DisplayToID.GUID = CounterData.GUID/*WHERE CounterName = 'Context 
Switches/sec'—uncomment to filter for specific counter */ 
GROUP BY MachineName, 
CONVERT(DATETIME, CONVERT(VARCHAR(16), CounterDateTime))