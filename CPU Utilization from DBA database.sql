USE DBA
-- Daily CPU utilization last 30 days
SELECT
	  CAST(EventTime AS DATE) AS [Date]
	, MAX(SqlCpuUtilization) AS MaxSQLCPU
	, MAX(OtherProcessCpuUtilization) AS MaxOtherCPU
	, MAX(SystemIdleProcess) AS MaxIdle
	, MIN(SqlCpuUtilization) AS MinSQLCPU
	, MIN(OtherProcessCpuUtilization) AS MinOtherCPU
	, MIN(SystemIdleProcess) AS MinIdle
	, AVG(SqlCpuUtilization) AS AvgSQLCPU
	, AVG(OtherProcessCpuUtilization) AS AvgOtherCPU
	, AVG(SystemIdleProcess) AS AvgIdle
FROM	dbo.CpuUtilization
WHERE	EventTime > DATEADD(DAY, -30, GETDATE())
GROUP BY CAST(EventTime AS DATE)
--HAVING	MAX(SqlCpuUtilization) > 50
OPTION(RECOMPILE);


-- Hourly CPU utilization last 7 days
SELECT
	  CAST(EventTime AS DATE) AS [Date]
	, CAST(CAST(DATEPART(HOUR, EventTime) AS VARCHAR(2)) + ':00' AS TIME(0)) AS TimeStart
	, CAST(CAST(DATEPART(HOUR, EventTime) AS VARCHAR(2)) + ':59:59' AS TIME(0)) AS TimeEnd
	, MAX(SqlCpuUtilization) AS MaxSQLCPU
	, MAX(OtherProcessCpuUtilization) AS MaxOtherCPU
	, MAX(SystemIdleProcess) AS MaxIdle
	, MIN(SqlCpuUtilization) AS MinSQLCPU
	, MIN(OtherProcessCpuUtilization) as MinOtherCPU
	, MIN(SystemIdleProcess) AS MinIdle
	, AVG(SqlCpuUtilization) AS AvgSQLCPU
	, AVG(OtherProcessCpuUtilization) AS AvgOtherCPU
	, AVG(SystemIdleProcess) AS AvgIdle
FROM	dbo.CpuUtilization
WHERE	EventTime > DATEADD(DAY, -7, GETDATE())
GROUP BY  CAST(EventTime AS DATE), DATEPART(HOUR, EventTime)
ORDER BY [Date], TimeStart
OPTION(RECOMPILE);

