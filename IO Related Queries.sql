-- Isolate top waits for server instance since last restart or statistics clear
WITH Waits AS
(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s,
100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE'
,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_MANUAL_EVENT'
,'CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT'
,'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN'))
SELECT W1.wait_type, 
CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 95; -- percentage threshold

-- Common Significant I/O Wait types with BOL explanations

-- *** I/O Related Waits ***
-- ASYNC_IO_COMPLETION  Occurs when a task is waiting for I/Os to finish
-- IO_COMPLETION        Occurs while waiting for I/O operations to complete. 
--                      This wait type generally represents non-data page I/Os. Data page I/O completion waits appear 
--                      as PAGEIOLATCH_* waits
-- PAGEIOLATCH_SH        Occurs when a task is waiting on a latch for a buffer that is in an I/O request. 
--                      The latch request is in Shared mode. Long waits may indicate problems with the disk subsystem.
-- PAGEIOLATCH_EX        Occurs when a task is waiting on a latch for a buffer that is in an I/O request. 
--                      The latch request is in Exclusive mode. Long waits may indicate problems with the disk subsystem.
-- WRITELOG             Occurs while waiting for a log flush to complete. 
--                      Common operations that cause log flushes are checkpoints and transaction commits.
-- PAGELATCH_EX            Occurs when a task is waiting on a latch for a buffer that is not in an I/O request. 
--                      The latch request is in Exclusive mode.
-- BACKUPIO                Occurs when a backup task is waiting for data, or is waiting for a buffer in which to store data  -- Some I/O Specific DMV Queries
-- Glenn Berry
-- December 2009
-- http://glennberrysqlperformance.spaces.live.com/
-- Twitter: GlennAlanBerry

-- Always look at Avg Disk Sec/Read and Avg Disk Sec/Write in PerfMon for each Physical Disk 

-- Check for IO Bottlenecks (run multiple times, look for values above zero)
SELECT cpu_id, pending_disk_io_count 
FROM sys.dm_os_schedulers
WHERE [status] = 'VISIBLE ONLINE';

-- Look at average for all schedulers (run multiple times, look for values above zero)
SELECT AVG(pending_disk_io_count) AS [AvgPendingDiskIOCount]
FROM sys.dm_os_schedulers 
WHERE [status] = 'VISIBLE ONLINE';


-- High Latch waits (SH and EX) indicates the I/O subsystem is too busy 
-- the wait time indicates time waiting for disk
SELECT wait_type, waiting_tasks_count, wait_time_ms, signal_wait_time_ms,
       wait_time_ms - signal_wait_time_ms AS [io_wait_time_ms]
FROM sys.dm_os_wait_stats
WHERE wait_type IN('PAGEIOLATCH_EX', 'PAGEIOLATCH_SH', 'PAGEIOLATCH_UP')
ORDER BY wait_type;

-- Analyze Database I/O, ranked by IO Stall%
WITH DBIO AS
(SELECT DB_NAME(IVFS.database_id) AS db,
 CASE WHEN MF.type = 1 THEN 'log' ELSE 'data' END AS file_type,
 SUM(IVFS.num_of_bytes_read + IVFS.num_of_bytes_written) AS io,
 SUM(IVFS.io_stall) AS io_stall
 FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS IVFS
 INNER JOIN sys.master_files AS MF
 ON IVFS.database_id = MF.database_id
 AND IVFS.file_id = MF.file_id
 GROUP BY DB_NAME(IVFS.database_id), MF.[type])
SELECT db, file_type, 
  CAST(1. * io / (1024 * 1024) AS DECIMAL(12, 2)) AS io_mb,
  CAST(io_stall / 1000. AS DECIMAL(12, 2)) AS io_stall_s,
  CAST(100. * io_stall / SUM(io_stall) OVER()
       AS DECIMAL(10, 2)) AS io_stall_pct,
  ROW_NUMBER() OVER(ORDER BY io_stall DESC) AS rn
FROM DBIO
ORDER BY io_stall DESC;


-- Average stalls per read, write and total
SELECT DB_NAME(database_id) AS [Database Name], file_id, io_stall_read_ms, num_of_reads,
CAST(io_stall_read_ms/(1.0+num_of_reads) AS numeric(10,1)) AS [avg_read_stall_ms],
io_stall_write_ms, num_of_writes,
CAST(io_stall_write_ms/(1.0+num_of_writes) AS numeric(10,1)) AS [avg_write_stall_ms],
io_stall_read_ms + io_stall_write_ms AS io_stalls,
num_of_reads + num_of_writes AS total_io,
CAST((io_stall_read_ms+io_stall_write_ms)/(1.0+num_of_reads + num_of_writes) 
AS numeric(10,1)) AS [avg_io_stall_ms]
FROM sys.dm_io_virtual_file_stats(null,null)
ORDER BY avg_io_stall_ms DESC;


-- Calculates average stalls per read, per write, and per total input/output for each database file. 
SELECT DB_NAME(database_id) AS [Database Name], file_id ,io_stall_read_ms, num_of_reads,
CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],io_stall_write_ms, 
num_of_writes,CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],
io_stall_read_ms + io_stall_write_ms AS [io_stalls], num_of_reads + num_of_writes AS [total_io],
CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) 
AS [avg_io_stall_ms]
FROM sys.dm_io_virtual_file_stats(null,null)
ORDER BY avg_io_stall_ms DESC;


-- Which queries are causing the most IO operations (can take a few seconds)
SELECT TOP (20) total_logical_reads/execution_count AS [avg_logical_reads],
    total_logical_writes/execution_count AS [avg_logical_writes],
    total_worker_time/execution_count AS [avg_cpu_cost], execution_count,
    total_worker_time, total_logical_reads, total_logical_writes, 
    (SELECT DB_NAME(dbid) + ISNULL('..' + OBJECT_NAME(objectid), '') 
     FROM sys.dm_exec_sql_text([sql_handle])) AS query_database,
    (SELECT SUBSTRING(est.[text], statement_start_offset/2 + 1,
        (CASE WHEN statement_end_offset = -1
            THEN LEN(CONVERT(nvarchar(max), est.[text])) * 2
            ELSE statement_end_offset
            END - statement_start_offset
        ) / 2)
        FROM sys.dm_exec_sql_text(sql_handle) AS est) AS query_text,
    last_logical_reads, min_logical_reads, max_logical_reads,
    last_logical_writes, min_logical_writes, max_logical_writes,
    total_physical_reads, last_physical_reads, min_physical_reads, max_physical_reads,
    (total_logical_reads + (total_logical_writes * 5))/execution_count AS io_weighting,
    plan_generation_num, qp.query_plan
FROM sys.dm_exec_query_stats
OUTER APPLY sys.dm_exec_query_plan([plan_handle]) AS qp
WHERE [dbid] >= 5 AND (total_worker_time/execution_count) > 100
ORDER BY io_weighting DESC;



-- Top Cached SPs By Total Physical Reads (SQL 2008). Physical reads relate to disk I/O pressure
SELECT TOP(25) p.name AS [SP Name],
qs.total_physical_reads AS [TotalPhysicalReads], qs.total_physical_reads/qs.execution_count AS [AvgPhysicalReads],
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
qs.total_logical_reads AS [TotalLogicalReads], qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
qs.total_worker_time AS [TotalWorkerTime], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.execution_count, 
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], qs.last_elapsed_time,
qs.cached_time 
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_physical_reads DESC;
    
    
-- Top Cached SPs By Total Logical Writes (SQL 2008). Logical writes relate to both memory and disk I/O pressure 
SELECT TOP(25) p.name AS [SP Name],
qs.total_logical_writes AS [TotalLogicalWrites], qs.total_logical_writes/qs.execution_count AS [AvgLogicalWrites],
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
qs.total_logical_reads AS [TotalLogicalReads], qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
qs.total_worker_time AS [TotalWorkerTime], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.execution_count, 
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], qs.last_elapsed_time,
qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_logical_writes DESC;