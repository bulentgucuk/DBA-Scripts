--Capture point in time (PIT) - Baseline 
Select wait_type, 
waiting_tasks_count, 
wait_time_ms/1000 as WaitTimeSec, 
(wait_time_ms - signal_wait_time_ms) / 1000 AS ResourceWaitTimeSec, 
signal_wait_time_ms / 1000 AS SignalWaitTimeSec, 
max_wait_time_ms, 
signal_wait_time_ms, 
100.0 * wait_time_ms / SUM (wait_time_ms) OVER() AS Percentage, 
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum 
into   #WaitStatSnapshotPIT1 
from sys.dm_os_wait_stats 
-- Wait for x amount of time 
WAITFOR DELAY '00:00:10'; 
--Collect again - Trend 
Select  wait_type, 
waiting_tasks_count, 
wait_time_ms/1000 as WaitTimeSec, 
(wait_time_ms - signal_wait_time_ms) / 1000.0 AS ResourceWaitTimeSec, 
signal_wait_time_ms / 1000.0 AS SignalWaitTimeSec, 
max_wait_time_ms, 
signal_wait_time_ms, 
100.0 * wait_time_ms / SUM (wait_time_ms) OVER() AS Percentage, 
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum 
into   #WaitStatSnapshotPIT2 
from sys.dm_os_wait_stats 
--select * from #WaitStatSnapshotPIT1 
-- Compare Results - Delta 
Select pit1.wait_type, 
(pit2.WaitTimeSec-pit1.WaitTimeSec) CumWaitTimeSecDelta, 
(pit2.ResourceWaitTimeSec -pit1.ResourceWaitTimeSec) ResourceWaitTimeDelta, 
(pit2.SignalWaitTimeSec -pit1.SignalWaitTimeSec) SignalWaitTimeDelta, 
CAST (pit1.Percentage AS DECIMAL(4, 2)) AS Percentage, 
GETDATE() as CaptureDateTime 
from #WaitStatSnapshotPIT1 pit1 
inner join #WaitStatSnapshotPIT2 pit2 on 
pit1.wait_type=pit2.wait_type 
where pit2.WaitTimeSec > pit1.WaitTimeSec 
GROUP BY pit2.RowNum, pit2.wait_type, pit2.WaitTimeSec, pit2.WaitTimeSec, pit2.
ResourceWaitTimeSec, 
pit2.SignalWaitTimeSec, pit2.waiting_tasks_count, pit2.Percentage, 
pit1.RowNum, pit1.wait_type, pit1.WaitTimeSec, pit1.WaitTimeSec, pit1.
ResourceWaitTimeSec, 
pit1.SignalWaitTimeSec, pit1.waiting_tasks_count, pit1.Percentage 
HAVING SUM (pit2.Percentage) - pit1.Percentage < 95; -- percentage threshold 
--order by pit2.WaitTimeSec DESC 
drop table #WaitStatSnapshotPIT1 
drop table #WaitStatSnapshotPIT2