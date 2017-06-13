-- SQL Server 2008 Diagnostic Information Queries
-- Glenn Berry 
-- May 2009
-- http://glennberrysqlperformance.spaces.live.com/


-- SQL and OS Version information for current instance
SELECT @@VERSION AS [SQL Version Info];

--   2008 RTM Builds                    2008 SP1 Builds
-- Build       Description        Build        Description
-- 1600        Gold RTM
-- 1763        RTM CU1
-- 1779        RTM CU2
-- 1787        RTM CU3    -->      2531        SP1 RTM
-- 1798        RTM CU4    -->      2710        SP1 CU1
-- 1806        RTM CU5    -->      2714        SP1 CU2 

-- Hardware information from SQL Server 2008 
-- (Cannot distinguish between HT and multi-core)
SELECT cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],
cpu_count/hyperthread_ratio AS [Physical CPU Count], 
physical_memory_in_bytes/1048576 AS [Physical Memory (MB)], sqlserver_start_time
FROM sys.dm_os_sys_info;


-- Get sp_configure values for instance
EXEC sp_configure 'Show Advanced Options', 1;
GO
RECONFIGURE;
GO
EXEC sp_configure;

-- Focus on
-- backup compression default
-- clr enabled
-- lightweight pooling (should be zero)
-- max degree of parallelism
-- max server memory (MB)
-- optimize for ad hoc workloads
-- priority boost (should be zero)


-- File Names and Paths for all databases in instance 
SELECT [dbid], fileid, [filename] 
FROM sys.sysaltfiles;

-- Things to look at
-- Are data files and log files on different drives?
-- Is everything on C: drive?
-- Is TempDB on dedicated drives?
-- Are there multiple data files?

-- Recovery model, log reuse wait description, and compatibility level for all databases on instance
SELECT [name], recovery_model_desc, log_reuse_wait_desc, [compatibility_level] 
FROM sys.databases;

-- Things to look at
-- How many databases are on the instance?
-- What recovery models are they using?
-- What is the log reuse wait description?
-- What compatibility level are they on?

-- Clear Wait Stats
-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);

-- Isolate top waits for server instance since last restart or statistics clear
WITH Waits AS
(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s,
    100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
    ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
 FROM sys.dm_os_wait_stats
 WHERE wait_type NOT IN( 'SLEEP_TASK', 'BROKER_TASK_STOP', 
  'SQLTRACE_BUFFER_FLUSH', 'CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT',
  'LAZYWRITER_SLEEP')) -- filter out additional irrelevant waits
SELECT W1.wait_type, 
  CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
  CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
  CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 95; -- percentage threshold

-- Common Significant Wait types with BOL explanations

-- *** Network Related Waits ***
-- ASYNC_NETWORK_IO        Occurs on network writes when the task is blocked behind the network

-- *** Locking Waits ***
-- LCK_M_IX                Occurs when a task is waiting to acquire an Intent Exclusive (IX) lock
-- LCK_M_IU                Occurs when a task is waiting to acquire an Intent Update (IU) lock
-- LCK_M_S                Occurs when a task is waiting to acquire a Shared lock

-- *** I/O Related Waits ***
-- ASYNC_IO_COMPLETION  Occurs when a task is waiting for I/Os to finish
-- IO_COMPLETION        Occurs while waiting for I/O operations to complete. 
--                      This wait type generally represents non-data page I/Os. Data page I/O completion waits 
--                      appear as PAGEIOLATCH_* waits
-- PAGEIOLATCH_SH        Occurs when a task is waiting on a latch for a buffer that is in an I/O request. 
--                      The latch request is in Shared mode. Long waits may indicate problems with the disk subsystem.
-- PAGEIOLATCH_EX        Occurs when a task is waiting on a latch for a buffer that is in an I/O request. 
--                      The latch request is in Exclusive mode. Long waits may indicate problems with the disk subsystem.
-- WRITELOG             Occurs while waiting for a log flush to complete. 
--                      Common operations that cause log flushes are checkpoints and transaction commits.
-- PAGELATCH_EX            Occurs when a task is waiting on a latch for a buffer that is not in an I/O request. 
--                      The latch request is in Exclusive mode.
-- BACKUPIO                Occurs when a backup task is waiting for data, or is waiting for a buffer in which to store data

-- *** CPU Related Waits ***
-- SOS_SCHEDULER_YIELD  Occurs when a task voluntarily yields the scheduler for other tasks to execute. 
--                      During this wait the task is waiting for its quantum to be renewed.

-- THREADPOOL            Occurs when a task is waiting for a worker to run on. 
--                      This can indicate that the maximum worker setting is too low, or that batch executions are 
--                      taking unusually long, thus reducing the number of workers available to satisfy other batches.
-- CX_PACKET            Occurs when trying to synchronize the query processor exchange iterator 
--                 You may consider lowering the degree of parallelism if contention on this wait type becomes a problem


-- Signal Waits for instance
SELECT CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [%signal (cpu) waits],
       CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) AS [%resource waits]
FROM sys.dm_os_wait_stats;
-- Signal Waits above 10-15% is usually a sign of CPU pressure


-- Page Life Expectancy (PLE) value for default instance
SELECT cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager' -- Modify this if you have named instances
AND counter_name = 'Page life expectancy';

-- PLE is a good measurement of memory pressure
-- Higher PLE is better. Below 300 is generally bad.
-- Watch the trend, not the absolute value

-- Buffer Pool Usage for instance
SELECT TOP(20) [type], SUM(single_pages_kb) AS [SPA Mem, Kb] 
FROM sys.dm_os_memory_clerks 
GROUP BY type  
ORDER BY SUM(single_pages_kb) DESC;

-- CACHESTORE_SQLCP  SQL Plans - These are cached SQL statements or batches that aren't in stored procedures, 
--                               functions and triggers
-- CACHESTORE_OBJCP  Object Plans - These are compiled plans for stored procedures, functions and triggers
-- CACHESTORE_PHDR   Algebrizer Trees - An algebrizer tree is the parsed SQL text that resolves the table and column names


-- Switch to a user database
--USE YourDatabaseName;
--GO

-- Individual File Sizes and space available for current database
SELECT name AS [File Name] , physical_name AS [Physical Name], size/128 AS [Total Size in MB],
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS [Available Space In MB]
FROM sys.database_files;

-- Look at how large and how full the files are and where they are located
-- Make sure transaction log is not full!!

-- Top Cached SPs By Execution Count (SQL 2008)
SELECT TOP(50) p.name AS [SP Name], qs.execution_count,
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GetDate()), 0) AS [Calls/Second],
qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], qs.total_worker_time AS [TotalWorkerTime],  
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], qs.last_elapsed_time,
qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.object_id = qs.object_id
ORDER BY qs.execution_count DESC;


-- Top Cached SPs By Total Worker time (SQL 2008). Worker time relates to CPU cost
SELECT TOP(25) p.name AS [SP Name], 
qs.total_worker_time AS [TotalWorkerTime], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.execution_count, ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GetDate()), 0) AS [Calls/Second],
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], qs.last_elapsed_time,
qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.object_id = qs.object_id
ORDER BY qs.total_worker_time DESC;

-- Top Cached SPs By Total Logical Reads (SQL 2008). Logical reads relate to memory pressure
SELECT TOP(25) p.name AS [SP Name],
qs.total_logical_reads AS [TotalLogicalReads], qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GetDate()), 0) AS [Calls/Second],
qs.total_worker_time AS [TotalWorkerTime], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.execution_count, 
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], qs.last_elapsed_time,
qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.object_id = qs.object_id
ORDER BY qs.total_logical_reads DESC;

-- Top Cached SPs By Total Physical Reads (SQL 2008). Physical reads relate to disk I/O pressure
SELECT TOP(25) p.name AS [SP Name],
qs.total_physical_reads AS [TotalPhysicalReads], qs.total_physical_reads/qs.execution_count AS [AvgPhysicalReads],
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GetDate()), 0) AS [Calls/Second],
qs.total_logical_reads AS [TotalLogicalReads], qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
qs.total_worker_time AS [TotalWorkerTime], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.execution_count, 
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], qs.last_elapsed_time,
qs.cached_time 
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.object_id = qs.object_id
ORDER BY qs.total_physical_reads DESC;
    
    
-- Top Cached SPs By Total Logical Writes (SQL 2008). Logical writes relate to both memory and disk I/O pressure 
SELECT TOP(25) p.name AS [SP Name],
qs.total_logical_writes AS [TotalLogicalWrites], qs.total_logical_writes/qs.execution_count AS [AvgLogicalWrites],
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GetDate()), 0) AS [Calls/Second],
qs.total_logical_reads AS [TotalLogicalReads], qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
qs.total_worker_time AS [TotalWorkerTime], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime], 
qs.execution_count, 
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], qs.last_elapsed_time,
qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.object_id = qs.object_id
ORDER BY qs.total_logical_writes DESC;


-- Possible Bad Indexes (writes > reads)
SELECT object_name(s.object_id) AS [Table Name], i.name AS [Index Name], i.index_id,
        user_updates AS [Total Writes], user_seeks + user_scans + user_lookups AS [Total Reads],
        user_updates - (user_seeks + user_scans + user_lookups) AS [Difference]
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON s.object_id = i.object_id
AND i.index_id = s.index_id
WHERE objectproperty(s.object_id,'IsUserTable') = 1
AND s.database_id = db_id()
AND user_updates > (user_seeks + user_scans + user_lookups)
AND i.index_id > 1
ORDER BY [Difference] DESC, [Total Writes] DESC, [Total Reads] ASC;


-- Missing Indexes for entire instance by Index Advantage
SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS index_advantage, migs.last_user_seek, 
mid.statement AS [Database.Schema.Table],
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
ORDER BY index_advantage DESC;
-- Look at last user seek time, number of user seeks to help determine source and importance
-- SQL Server is overly eager to add included columns, so beware


-- Breaks down buffers used by current database by object (table, index) in the buffer cache
SELECT OBJECT_NAME(p.object_id) AS [ObjectName], p.object_id, 
p.index_id, COUNT(*)/128 AS [buffer size(MB)],  COUNT(*) AS [buffer_count] 
FROM sys.allocation_units AS a
INNER JOIN sys.dm_os_buffer_descriptors AS b
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p
ON a.container_id = p.hobt_id
WHERE b.database_id = db_id()
AND p.object_id > 100
GROUP BY p.object_id, p.index_id
ORDER BY buffer_count DESC;
-- Tells you what tables and indexes are using the most memory in the buffer cache


-- Detect blocking (run multiple times)
SELECT t1.resource_type AS 'lock type',db_name(resource_database_id) AS 'database',
t1.resource_associated_entity_id AS 'blk object',t1.request_mode AS 'lock req',                                                                          --- lock requested
t1.request_session_id AS 'waiter sid', t2.wait_duration_ms AS 'wait time', -- spid of waiter  
(SELECT [text] FROM sys.dm_exec_requests AS r                              -- get sql for waiter
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) 
WHERE r.session_id = t1.request_session_id) AS 'waiter_batch',
(SELECT substring(qt.text,r.statement_start_offset/2, 
    (CASE WHEN r.statement_end_offset = -1 
    THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2 
    ELSE r.statement_end_offset END - r.statement_start_offset)/2) 
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS qt
WHERE r.session_id = t1.request_session_id) AS 'waiter_stmt',    -- statement blocked
t2.blocking_session_id AS 'blocker sid',                         -- spid of blocker
(SELECT [text] FROM sys.sysprocesses AS p                        -- get sql for blocker
CROSS APPLY sys.dm_exec_sql_text(p.sql_handle) 
WHERE p.spid = t2.blocking_session_id) AS 'blocker_stmt'
FROM sys.dm_tran_locks AS t1 
INNER JOIN sys.dm_os_waiting_tasks AS t2
ON t1.lock_owner_address = t2.resource_address;

-- Determine if you are using certain Enterprise Only features in SQL Server 2008
    SELECT feature_name, feature_id 
    FROM sys.dm_db_persisted_sku_features-- Determine which tables and indexes are using data compression
    SELECT OBJECT_NAME([object_id]) AS [TableName], index_id, [rows], 
                       data_compression, data_compression_desc
    FROM sys.partitions
    WHERE data_compression > 0-- Look for deprecated features in SQL Server 2008 
    SELECT object_name, instance_name, cntr_value 
    FROM sys.dm_os_performance_counters 
    WHERE object_name = 'SQLServer:Deprecated Features' 
    -- (Default instance) Alter this for named instances -- Look at recent compressed full backups
    SELECT TOP (5) bs.server_name, bs.database_name AS 'Database Name', 
    CONVERT (BIGINT, bs.backup_size / 1048576 ) AS 'Uncompressed Backup Size (MB)',
    CONVERT (BIGINT, bs.compressed_backup_size / 1048576 ) AS 'Compressed Backup Size (MB)',
    CONVERT (NUMERIC (20,2), (CONVERT (FLOAT, bs.backup_size) /
    CONVERT (FLOAT, bs.compressed_backup_size))) AS 'Compression Ratio', 
    DATEDIFF (SECOND, bs.backup_start_date, bs.backup_finish_date) AS 'Backup Elapsed Time (sec)',
    bs.backup_finish_date AS 'Backup Finish Date'
    FROM msdb.dbo.backupset AS bs 
    WHERE DATEDIFF (SECOND, bs.backup_start_date, bs.backup_finish_date) > 0 
    AND bs.backup_size > 0
    AND bs.type = 'D' -- Change to L if you want Log backups
    ORDER BY bs.backup_finish_date DESC