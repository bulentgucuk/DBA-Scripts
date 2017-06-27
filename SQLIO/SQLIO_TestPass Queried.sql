/*
DATASQL02
SQLCLR02-S
SQLCLR04-P
SQLCLR05-P
*/

SELECT	Threads,
		ReadOrWrite,
		DurationSeconds,
		IOPattern,
		IOsOutStanding,
		CAST(AVG(IOs_SEC) AS INT) AvgIOPS,
		CAST(AVG(MBs_Sec) AS INT) AvgThroughput,
		AVG(LatencyMS_Min) AS AvgLatencyMs_Min,
		AVG(LatencyMS_Avg) AS AvgLatencyMS_Avg,
		AVG(LatencyMS_Max) AS AvgLatencyMS_Max
FROM	dbo.SQLIO_TestPass
WHERE	ServerName = 'DATASQL02'
AND		ReadOrWrite = 'R'
--AND		IOpattern = 'random'
AND		IOpattern = 'sequential'
AND		TestDate = '2011-09-30 00:00:00.000'
GROUP BY Threads,
		ReadOrWrite,
		DurationSeconds,
		IOPattern,
		IOsOutStanding





SELECT	*
FROM	dbo.SQLIO_TestPass
WHERE	ServerName = 'SQLCLR04-P'
AND		ReadOrWrite = 'r'
--AND		IOpattern = 'random'
AND		IOpattern = 'sequential'


SELECT	DISTINCT(Servername), TestDate, COUNT(TestPassID) AS RowCnt
FROM	dbo.SQLIO_TestPass
GROUP BY ServerName, TestDate
ORDER BY ServerName



SELECT	Threads,
		ReadOrWrite,
		DurationSeconds,
		IOPattern,
		IOsOutStanding,
		CAST(AVG(IOs_SEC) AS INT) AvgIOPS,
		CAST(AVG(MBs_Sec) AS INT) AvgThroughput,
		AVG(LatencyMS_Min) AS AvgLatencyMs_Min,
		AVG(LatencyMS_Avg) AS AvgLatencyMS_Avg,
		AVG(LatencyMS_Max) AS AvgLatencyMS_Max
FROM	dbo.SQLIO_TestPass
WHERE	ServerName = 'SQLCLR04-P'
AND		TestDate = '2011-11-17 00:00:00.000'
AND		ReadOrWrite = 'r'
AND		IOpattern = 'random'
--AND		IOpattern = 'sequential'
AND		SANModel = 'SUN NAS N:'

GROUP BY Threads,
		ReadOrWrite,
		DurationSeconds,
		IOPattern,
		IOsOutStanding
