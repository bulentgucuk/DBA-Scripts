-- SQL Server 2005 Diagnostic Information Queries
-- Glenn Berry April 2009
-- http://glennberrysqlperformance.spaces.live.com/


-- SQL Version information for current instance
SELECT @@VERSION AS 'Version Info';
 
-- Hardware Information
SELECT cpu_count AS 'Logical CPU Count', hyperthread_ratio AS 'Hyperthread Ratio',
cpu_count/hyperthread_ratio As 'Physical CPU Count', 
physical_memory_in_bytes/1048576 AS 'Physical Memory (MB)'
FROM sys.dm_os_sys_info;

-- get sp_configure values for instance
EXEC sp_configure 'Show Advanced Options', 1
GO
RECONFIGURE
GO
EXEC sp_configure


-- File Names and Paths for all databases in instance 
SELECT dbid, fileid, filename 
FROM sys.sysaltfiles;

-- Recovery model for all databases on instance
SELECT [name], recovery_model_desc, log_reuse_wait_desc, [compatibility_level] 
FROM sys.databases;

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


-- Signal Waits for instance
SELECT '%signal (cpu) waits' = CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)),
       '%resource waits'= CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2))
FROM sys.dm_os_wait_stats;


-- Page Life Expectancy value
SELECT cntr_value AS 'Page Life Expectancy'
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager'
AND counter_name = 'Page life expectancy';


-- Buffer Pool Usage 
SELECT TOP (10) [type], sum(single_pages_kb) AS [SPA Mem, Kb] 
FROM sys.dm_os_memory_clerks 
GROUP BY type  
ORDER BY SUM(single_pages_kb) DESC;

-- Switch to user database
--USE YourDatabaseName;
--GO

-- Individual File Sizes and space available for current database
SELECT name AS 'File Name' , physical_name AS 'Physical Name', size/128 AS 'Total Size in MB',
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS 'Available Space In MB' FROM sys.database_files;


-- Cached SP's By Execution Count
SELECT TOP (25) qt.text AS 'SP Name', qs.execution_count AS 'Execution Count',  
qs.execution_count/DATEDIFF(Second, qs.creation_time, GetDate()) AS 'Calls/Second',
qs.total_worker_time/qs.execution_count AS 'AvgWorkerTime',
qs.total_worker_time AS 'TotalWorkerTime',
qs.total_elapsed_time/qs.execution_count AS 'AvgElapsedTime',
qs.max_logical_reads, qs.max_logical_writes, qs.total_physical_reads, 
DATEDIFF(Minute, qs.creation_time, GetDate()) AS 'Age in Cache'
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.dbid = db_id() -- Filter by current database
ORDER BY qs.execution_count DESC;


-- Cached SP's By Worker Time
SELECT TOP (25) qt.text AS 'SP Name', qs.total_worker_time AS 'TotalWorkerTime', 
qs.total_worker_time/qs.execution_count AS 'AvgWorkerTime',
qs.execution_count AS 'Execution Count', 
ISNULL(qs.execution_count/DATEDIFF(Second, qs.creation_time, GetDate()), 0) AS 'Calls/Second',
ISNULL(qs.total_elapsed_time/qs.execution_count, 0) AS 'AvgElapsedTime', 
qs.max_logical_reads, qs.max_logical_writes, 
DATEDIFF(Minute, qs.creation_time, GetDate()) AS 'Age in Cache'
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.dbid = db_id() -- Filter by current database
ORDER BY qs.total_worker_time DESC;


-- Cached SP's By Logical Reads
SELECT TOP (25) qt.text AS 'SP Name', total_logical_reads, 
qs.execution_count AS 'Execution Count', total_logical_reads/qs.execution_count AS 'AvgLogicalReads',
qs.execution_count/DATEDIFF(Second, qs.creation_time, GetDate()) AS 'Calls/Second', 
qs.total_worker_time/qs.execution_count AS 'AvgWorkerTime',
qs.total_worker_time AS 'TotalWorkerTime',
qs.total_elapsed_time/qs.execution_count AS 'AvgElapsedTime',
qs.total_logical_writes,
qs.max_logical_reads, qs.max_logical_writes, qs.total_physical_reads, 
DATEDIFF(Minute, qs.creation_time, GetDate()) AS 'Age in Cache'
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.dbid = db_id() -- Filter by current database
ORDER BY total_logical_reads DESC;


-- Possible bad Indexes (writes > reads)
SELECT object_name(s.object_id) AS 'Table Name', i.name AS 'Index Name', i.index_id,
        user_updates AS 'Total Writes', user_seeks + user_scans + user_lookups AS 'Total Reads',
        user_updates - (user_seeks + user_scans + user_lookups) AS 'Difference'
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON s.object_id = i.object_id
AND i.index_id = s.index_id
WHERE objectproperty(s.object_id,'IsUserTable') = 1
AND s.database_id = db_id()
AND user_updates > (user_seeks + user_scans + user_lookups)
AND i.index_id > 1
ORDER BY 'Difference' DESC, 'Total Writes' DESC, 'Total Reads' ASC;


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


-- Breaks down buffers used by current database by object (table, index) in the buffer cache
SELECT OBJECT_NAME(p.object_id) AS 'ObjectName', p.object_id, 
p.index_id, COUNT(*)/128 AS 'buffer size(MB)',  COUNT(*) AS 'buffer_count' 
FROM sys.allocation_units AS a
INNER JOIN sys.dm_os_buffer_descriptors AS b
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p
ON a.container_id = p.hobt_id
WHERE b.database_id = db_id()
GROUP BY p.object_id, p.index_id
ORDER BY buffer_count DESC;


-- Detect blocking 
SELECT t1.resource_type AS 'lock type',db_name(resource_database_id) AS 'database',
t1.resource_associated_entity_id AS 'blk object',t1.request_mode AS 'lock req',                                                                          --- lock requested
t1.request_session_id AS 'waiter sid', t2.wait_duration_ms AS 'wait time',             -- spid of waiter  
(SELECT [text] FROM sys.dm_exec_requests AS r                                           -- get sql for waiter
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
