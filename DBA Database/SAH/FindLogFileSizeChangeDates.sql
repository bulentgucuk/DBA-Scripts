USE DBA;
GO
SELECT	TM.DatabaseName, TM.LogSizeMB, MIN(TM.LogDate) AS SizeMinDate, MAX(TM.LogDate) AS SizeMaxDate
FROM	DBO.TransLogMonitor AS TM
	INNER JOIN (
		SELECT	DISTINCT DatabaseName, LogSizeMB
		FROM	DBO.TransLogMonitor WITH (NOLOCK)
		WHERE	DatabaseName = 'EbgProd' ) AS TM2 ON TM.DatabaseName = TM2.DatabaseName AND TM.LogSizeMB = TM2.LogSizeMB
GROUP BY TM.DatabaseName, TM.LogSizeMB