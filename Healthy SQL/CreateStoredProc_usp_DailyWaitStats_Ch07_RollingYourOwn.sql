/****** Object:  StoredProcedure [dbo].[usp_DailyWaitStats]******/ 
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
CREATE PROC [dbo].[usp_DailyWaitStats] AS 
INSERT  INTO dbo.WaitStats 
( 
[CaptureDate], 
[wait_type] , 
[WaitSec] , 
[ResourceSec] , 
[SignalSec] , 
[WaitCount] , 
[Percentage] , 
[AvgWait_Sec] , 
[AvgRes_Sec] , 
[AvgSig_Sec] 
) 
EXEC 
('
WITH [Waits] AS 
(SELECT 
s.[wait_type], 
[wait_time_ms] / 1000.0 AS [WaitSec], 
([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceSec], 
[signal_wait_time_ms] / 1000.0 AS [SignalSec], 
[waiting_tasks_count] AS [WaitCount], 
100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage], 
ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum] 
FROM sys.dm_os_wait_stats s 
INNER JOIN Monitor.waittypes w 
On s.wait_type = w.wait_type 
WHERE w.track = 1 
) 
SELECT 
GETDATE(), 
[W1].[wait_type] AS [Wait_Type], 
CAST ([W1].[WaitSec] AS DECIMAL(14, 2)) AS [Wait_Sec], 
CAST ([W1].[ResourceSec] AS DECIMAL(14, 2)) AS [Resource_Sec], 
CAST ([W1].[SignalSec] AS DECIMAL(14, 2)) AS [Signal_Sec], 
[W1].[WaitCount] AS [WaitCount], 
CAST ([W1].[Percentage] AS DECIMAL(4, 2)) AS [Percentage], 
CAST (([W1].[WaitSec] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgWait_Sec], 
CAST (([W1].[ResourceSec] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgRes_Sec], 
CAST (([W1].[SignalSec] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgSig_Sec] 
FROM [Waits] AS [W1] 
INNER JOIN [Waits] AS [W2] 
ON [W2].[RowNum] <= [W1].[RowNum] 
GROUP BY [W1].[RowNum], [W1].[wait_type], [W1].[WaitSec], 
[W1].[ResourceSec], [W1].[SignalSec], [W1].[WaitCount], [W1].[Percentage] 
HAVING SUM ([W2].[Percentage]) - [W1].[Percentage] < 95;' 
); 

/*Once the above stored procedure code is created, to run the procedure use: */

Exec usp_DailyWaitStats 
GO