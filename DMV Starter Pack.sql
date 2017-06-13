
-- Script 1
-- Get a count of SQL connections by IP address
SELECT  ec.client_net_address ,
        es.[program_name] ,
        es.[host_name] ,
        es.login_name ,
        COUNT(ec.session_id) AS [connection count]
FROM    sys.dm_exec_sessions AS es
        INNER JOIN sys.dm_exec_connections AS ec
                                   ON es.session_id = ec.session_id
GROUP BY ec.client_net_address ,
        es.[program_name] ,
        es.[host_name] ,
        es.login_name
ORDER BY ec.client_net_address ,
        es.[program_name] ;


-- Script 2
--  Get SQL users that are connected and how many sessions they have 
SELECT  login_name ,
        COUNT(session_id) AS [session_count]
FROM    sys.dm_exec_sessions
GROUP BY login_name
ORDER BY COUNT(session_id) DESC ;



-- Script 3
-- Look at current expensive or blocked requests
SELECT  r.session_id ,
        r.[status] ,
        r.wait_type ,
        r.scheduler_id ,
        SUBSTRING(qt.[text], r.statement_start_offset / 2,
            ( CASE WHEN r.statement_end_offset = -1
                   THEN LEN(CONVERT(NVARCHAR(MAX), qt.[text])) * 2
                   ELSE r.statement_end_offset
              END - r.statement_start_offset ) / 2) AS [statement_executing] ,
        DB_NAME(qt.[dbid]) AS [DatabaseName] ,
        OBJECT_NAME(qt.objectid) AS [ObjectName] ,
        r.cpu_time ,
        r.total_elapsed_time ,
        r.reads ,
        r.writes ,
        r.logical_reads ,
        r.plan_handle
FROM    sys.dm_exec_requests AS r
        CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS qt
WHERE   r.session_id > 50
ORDER BY r.scheduler_id ,
        r.[status] ,
        r.session_id ;

-- Script 4        
-- Top 3 CPU-sapping queries for which plans exist in the cache        
SELECT TOP 3
        total_worker_time ,
        execution_count ,
        total_worker_time / execution_count AS [Avg CPU Time] ,
        CASE WHEN deqs.statement_start_offset = 0
                  AND deqs.statement_end_offset = -1
             THEN '-- see objectText column--'
             ELSE '-- query --' + CHAR(13) + CHAR(10)
                  + SUBSTRING(execText.text, deqs.statement_start_offset / 2,
                              ( ( CASE WHEN deqs.statement_end_offset = -1
                                       THEN DATALENGTH(execText.text)
                                       ELSE deqs.statement_end_offset
                                  END ) - deqs.statement_start_offset ) / 2)
        END AS queryText
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
ORDER BY deqs.total_worker_time DESC ;


-- Script 5
-- Use Counts and # of plans for compiled plans
SELECT  objtype ,
        usecounts ,
        COUNT(*) AS [no_of_plans]
FROM    sys.dm_exec_cached_plans
WHERE   cacheobjtype = 'Compiled Plan'
GROUP BY objtype ,
        usecounts
ORDER BY objtype ,
        usecounts ;
        
        
-- Script 6

-- Script 7
-- Top Cached SPs By Total Logical Reads (SQL 2008 only).
-- Logical reads relate to memory pressure
SELECT TOP ( 25 )
        p.name AS [SP Name] ,
        qs.total_logical_reads AS [TotalLogicalReads] ,
        qs.total_logical_reads / qs.execution_count AS [AvgLogicalReads] ,
        qs.execution_count ,
        ISNULL(qs.execution_count / 
                 DATEDIFF(Second, qs.cached_time, GETDATE()),
               0) AS [Calls/Second] ,
        qs.total_elapsed_time ,
        qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time] ,
        qs.cached_time
FROM    sys.procedures AS p
        INNER JOIN sys.dm_exec_procedure_stats AS qs
                              ON p.[object_id] = qs.[object_id]
WHERE   qs.database_id = DB_ID()
ORDER BY qs.total_logical_reads DESC ;

-- Script 8
-- Top Cached SPs By Total Physical Reads (SQL 2008 only) 
-- Physical reads relate to disk I/O pressure
SELECT TOP ( 25 )
        p.name AS [SP Name] ,
        qs.total_physical_reads AS [TotalPhysicalReads] ,
        qs.total_physical_reads / qs.execution_count AS [AvgPhysicalReads] ,
        qs.execution_count ,
        ISNULL(qs.execution_count / 
                 DATEDIFF(Second, qs.cached_time, GETDATE()),
               0) AS [Calls/Second] ,
        qs.total_elapsed_time ,
        qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time] ,
        qs.cached_time
FROM    sys.procedures AS p
        INNER JOIN sys.dm_exec_procedure_stats AS qs
                              ON p.[object_id] = qs.[object_id]
WHERE   qs.database_id = DB_ID()
ORDER BY qs.total_physical_reads DESC ;


-- Script 9
-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2008 version
SELECT  DB_NAME(st.dbid) AS [DatabaseName] ,
        mg.requested_memory_kb ,
        mg.ideal_memory_kb ,
        mg.request_time ,
        mg.grant_time ,
        mg.query_cost ,
        mg.dop ,
        st.[text]
FROM    sys.dm_exec_query_memory_grants AS mg
        CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE   mg.request_time < COALESCE(grant_time, '99991231')
ORDER BY mg.requested_memory_kb DESC ;

-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2005 version
SELECT  DB_NAME(st.dbid) AS [DatabaseName] ,
        mg.requested_memory_kb ,
        mg.request_time ,
        mg.grant_time ,
        mg.query_cost ,
        mg.dop ,
        st.[text]
FROM    sys.dm_exec_query_memory_grants AS mg
        CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE   mg.request_time < COALESCE(grant_time, '99991231')
ORDER BY mg.requested_memory_kb DESC ;


-- Script 10
-- Monitoring transaction activity
SELECT  st.session_id ,
        DB_NAME(dt.database_id) AS database_name ,
        CASE WHEN dt.database_transaction_begin_time IS NULL THEN 'read-only'
             ELSE 'read-write'
        END AS transaction_state ,
        dt.database_transaction_begin_time AS read_write_start_time ,
        dt.database_transaction_log_record_count ,
        dt.database_transaction_log_bytes_used
FROM    sys.dm_tran_session_transactions AS st
        INNER JOIN sys.dm_tran_database_transactions AS dt
            ON st.transaction_id = dt.transaction_id
ORDER BY st.session_id ,
        database_name

-- Script 11
-- Look at active Lock Manager resources for current database
SELECT  request_session_id ,
        DB_NAME(resource_database_id) AS [Database] ,
        resource_type ,
        resource_subtype ,
        request_type ,
        request_mode ,
        resource_description ,
        request_mode ,
        request_owner_type
FROM    sys.dm_tran_locks
WHERE   request_session_id > 50
        AND resource_database_id = DB_ID()
        AND request_session_id <> @@SPID
ORDER BY request_session_id ;

-- Look for blocking
SELECT  tl.resource_type ,
        tl.resource_database_id ,
        tl.resource_associated_entity_id ,
        tl.request_mode ,
        tl.request_session_id ,
        wt.blocking_session_id ,
        wt.wait_type ,
        wt.wait_duration_ms
FROM    sys.dm_tran_locks AS tl
        INNER JOIN sys.dm_os_waiting_tasks AS wt
           ON tl.lock_owner_address = wt.resource_address
ORDER BY wait_duration_ms DESC ;


-- Script 12
-- Missing Indexes in current database by Index Advantage
SELECT  user_seeks * avg_total_user_cost * ( avg_user_impact * 0.01 )
                                                       AS [index_advantage] ,
        migs.last_user_seek ,
        mid.[statement] AS [Database.Schema.Table] ,
        mid.equality_columns ,
        mid.inequality_columns ,
        mid.included_columns ,
        migs.unique_compiles ,
        migs.user_seeks ,
        migs.avg_total_user_cost ,
        migs.avg_user_impact
FROM    sys.dm_db_missing_index_group_stats AS migs WITH ( NOLOCK )
        INNER JOIN sys.dm_db_missing_index_groups AS mig WITH ( NOLOCK )
           ON migs.group_handle = mig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details AS mid WITH ( NOLOCK )
           ON mig.index_handle = mid.index_handle
WHERE   mid.database_id = DB_ID()
ORDER BY index_advantage DESC ;


-- Script 13
--- Index Read/Write stats (all tables in current DB)
SELECT  OBJECT_NAME(s.[object_id]) AS [ObjectName] ,
        i.name AS [IndexName] ,
        i.index_id ,
        user_seeks + user_scans + user_lookups AS [Reads] ,
        user_updates AS [Writes] ,
        i.type_desc AS [IndexType] ,
        i.fill_factor AS [FillFactor]
FROM    sys.dm_db_index_usage_stats AS s
        INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
        AND i.index_id = s.index_id
        AND s.database_id = DB_ID()
ORDER BY OBJECT_NAME(s.[object_id]) ,
        writes DESC ,
        reads DESC ;

-- Script 14
-- List unused indexes
SELECT  OBJECT_NAME(i.[object_id]) AS [Table Name] ,
        i.name
FROM    sys.indexes AS i
        INNER JOIN sys.objects AS o ON i.[object_id] = o.[object_id]
WHERE   i.index_id NOT IN ( SELECT  s.index_id
                            FROM    sys.dm_db_index_usage_stats AS s
                            WHERE   s.[object_id] = i.[object_id]
                                    AND i.index_id = s.index_id
                                    AND database_id = DB_ID() )
        AND o.[type] = 'U'
ORDER BY OBJECT_NAME(i.[object_id]) ASC ;

-- Script 15
-- Possible Bad NC Indexes (writes > reads)
SELECT  OBJECT_NAME(s.[object_id]) AS [Table Name] ,
        i.name AS [Index Name] ,
        i.index_id ,
        user_updates AS [Total Writes] ,
        user_seeks + user_scans + user_lookups AS [Total Reads] ,
        user_updates - ( user_seeks + user_scans + user_lookups )
            AS [Difference]
FROM    sys.dm_db_index_usage_stats AS s WITH ( NOLOCK )
        INNER JOIN sys.indexes AS i WITH ( NOLOCK )
            ON s.[object_id] = i.[object_id]
            AND i.index_id = s.index_id
WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
        AND s.database_id = DB_ID()
        AND user_updates > ( user_seeks + user_scans + user_lookups )
        AND i.index_id > 1
ORDER BY [Difference] DESC ,
        [Total Writes] DESC ,
        [Total Reads] ASC ;

-- Script 16
-- Table and row count information   
SELECT  OBJECT_NAME(ps.[object_id]) AS [TableName] ,
        i.name AS [IndexName] ,
        SUM(ps.row_count) AS [RowCount]
FROM    sys.dm_db_partition_stats AS ps
        INNER JOIN sys.indexes AS i ON i.[object_id] = ps.[object_id]
                                       AND i.index_id = ps.index_id
WHERE   i.type_desc IN ( 'CLUSTERED', 'HEAP' )
        AND i.[object_id] > 100
        AND OBJECT_SCHEMA_NAME(ps.[object_id]) <> 'sys'
GROUP BY ps.[object_id] ,
        i.name
ORDER BY SUM(ps.row_count) DESC ;


-- Script 17
-- Get Free Space in TempDB
SELECT  SUM(unallocated_extent_page_count) AS [free pages] ,
        ( SUM(unallocated_extent_page_count) * 1.0 / 128 ) AS [free space in MB]
FROM    sys.dm_db_file_space_usage ;
      
-- Quick TempDB Summary
SELECT SUM(user_object_reserved_page_count) * 8.192 AS [UserObjectsKB] ,
      SUM(internal_object_reserved_page_count) * 8.192 AS [InternalObjectsKB] ,
      SUM(version_store_reserved_page_count) * 8.192 AS [VersonStoreKB] ,
      SUM(unallocated_extent_page_count) * 8.192 AS [FreeSpaceKB]
FROM    sys.dm_db_file_space_usage ;

-- Script 18
-- Calculates average stalls per read, per write, and per total input/output
-- for each database file. 
SELECT  DB_NAME(database_id) AS [Database Name] ,
        file_id ,
        io_stall_read_ms ,
        num_of_reads ,
        CAST(io_stall_read_ms / ( 1.0 + num_of_reads ) AS NUMERIC(10, 1))
            AS [avg_read_stall_ms] ,
        io_stall_write_ms ,
        num_of_writes ,
        CAST(io_stall_write_ms / ( 1.0 + num_of_writes ) AS NUMERIC(10, 1))
            AS [avg_write_stall_ms] ,
        io_stall_read_ms + io_stall_write_ms AS [io_stalls] ,
        num_of_reads + num_of_writes AS [total_io] ,
        CAST(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads
                                                          + num_of_writes)
           AS NUMERIC(10,1)) AS [avg_io_stall_ms]
FROM    sys.dm_io_virtual_file_stats(NULL, NULL)
ORDER BY avg_io_stall_ms DESC ;

-- Script 19
-- Look at pending I/O requests by file
SELECT  DB_NAME(mf.database_id) AS [Database] ,
        mf.physical_name ,
        r.io_pending ,
        r.io_pending_ms_ticks ,
        r.io_type ,
        fs.num_of_reads ,
        fs.num_of_writes
FROM    sys.dm_io_pending_io_requests AS r
        INNER JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
                                          ON r.io_handle = fs.file_handle
        INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
                                             AND fs.file_id = mf.file_id
ORDER BY r.io_pending ,
        r.io_pending_ms_ticks DESC ;
        
-- Script 20        
-- Total waits are wait_time_ms (high signal waits indicates CPU pressure)
SELECT  CAST(100.0 * SUM(signal_wait_time_ms) / SUM(wait_time_ms)
                              AS NUMERIC(20,2)) AS [%signal (cpu) waits] ,
        CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms)
        / SUM(wait_time_ms) AS NUMERIC(20, 2)) AS [%resource waits]
FROM    sys.dm_os_wait_stats ;


-- Script 21
-- Isolate top waits for server instance since last restart 
-- or statistics clear
WITH    Waits
      AS ( SELECT   wait_type ,
                    wait_time_ms / 1000. AS wait_time_s ,
                    100. * wait_time_ms / SUM(wait_time_ms) OVER ( ) AS pct ,
                    ROW_NUMBER() OVER ( ORDER BY wait_time_ms DESC ) AS rn
           FROM     sys.dm_os_wait_stats
           WHERE    wait_type NOT IN ( 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP',
                                       'RESOURCE_QUEUE', 'SLEEP_TASK',
                                       'SLEEP_SYSTEMTASK',
                                       'SQLTRACE_BUFFER_FLUSH', 'WAITFOR',
                                       'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE',
                                       'REQUEST_FOR_DEADLOCK_SEARCH',
                                       'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
                                       'BROKER_TASK_STOP',
                                       'CLR_MANUAL_EVENT',
                                       'CLR_AUTO_EVENT',
                                       'DISPATCHER_QUEUE_SEMAPHORE',
                                       'FT_IFTS_SCHEDULER_IDLE_WAIT',
                                       'XE_DISPATCHER_WAIT',
                                       'XE_DISPATCHER_JOIN' )
         )
    SELECT  W1.wait_type ,
            CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s ,
            CAST(W1.pct AS DECIMAL(12, 2)) AS pct ,
            CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
    FROM    Waits AS W1
            INNER JOIN Waits AS W2 ON W2.rn <= W1.rn
    GROUP BY W1.rn ,
            W1.wait_type ,
            W1.wait_time_s ,
            W1.pct
    HAVING  SUM(W2.pct) - W1.pct < 95 ; -- percentage threshold


-- Script 22
-- Recovery model, log reuse wait description, log file size, 
-- log usage size and compatibility level for all databases on instance
SELECT  db.[name] AS [Database Name] ,
        db.recovery_model_desc AS [Recovery Model] ,
        db.log_reuse_wait_desc AS [Log Reuse Wait Description] ,
        ls.cntr_value AS [Log Size (KB)] ,
        lu.cntr_value AS [Log Used (KB)] ,
        CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)
                    AS DECIMAL(18,2)) * 100 AS [Log Used %] ,
        db.[compatibility_level] AS [DB Compatibility Level] ,
        db.page_verify_option_desc AS [Page Verify Option]
FROM    sys.databases AS db
        INNER JOIN sys.dm_os_performance_counters AS lu
                    ON db.name = lu.instance_name
        INNER JOIN sys.dm_os_performance_counters AS ls
                    ON db.name = ls.instance_name
WHERE   lu.counter_name LIKE 'Log File(s) Used Size (KB)%'
        AND ls.counter_name LIKE 'Log File(s) Size (KB)%' ;
        
        
-- Script 23
-- Hardware information from SQL Server 2008 
-- (Cannot distinguish between HT and multi-core)
SELECT  cpu_count AS [Logical CPU Count] ,
        hyperthread_ratio AS [Hyperthread Ratio] ,
        cpu_count / hyperthread_ratio AS [Physical CPU Count] ,
        physical_memory_in_bytes / 1048576 AS [Physical Memory (MB)] ,
        sqlserver_start_time
FROM    sys.dm_os_sys_info ;

-- Hardware information from SQL Server 2005 
-- (Cannot distinguish between HT and multi-core)
SELECT  cpu_count AS [Logical CPU Count] ,
        hyperthread_ratio AS [Hyperthread Ratio] ,
        cpu_count / hyperthread_ratio AS [Physical CPU Count] ,
        physical_memory_in_bytes / 1048576 AS [Physical Memory (MB)]
FROM    sys.dm_os_sys_info ;


-- Script 24
-- Get CPU Utilization History for last 30 minutes (in one minute intervals)
-- This version works with SQL Server 2008 and SQL Server 2008 R2 only
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 

SELECT TOP(30) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM ( 
	  SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
			AS [SystemIdle], 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
			'int') 
			AS [SQLProcessUtilization], [timestamp] 
	  FROM ( 
			SELECT [timestamp], CONVERT(xml, record) AS [record] 
			FROM sys.dm_os_ring_buffers 
			WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
			AND record LIKE N'%<SystemHealth>%') AS x 
	  ) AS y 
ORDER BY record_id DESC;

-- Script 25
-- Get Avg task count and Avg runnable task count
SELECT  AVG(current_tasks_count) AS [Avg Task Count] ,
        AVG(runnable_tasks_count) AS [Avg Runnable Task Count]
FROM    sys.dm_os_schedulers
WHERE   scheduler_id < 255
        AND [status] = 'VISIBLE ONLINE' ;
        
        
-- Script 26
-- Is NUMA enabled
SELECT  CASE COUNT(DISTINCT parent_node_id)
          WHEN 1 THEN 'NUMA disabled'
          ELSE 'NUMA enabled'
        END
FROM    sys.dm_os_schedulers
WHERE   parent_node_id <> 32 ;


-- Script 27
-- Good basic information about memory amounts and state
-- SQL Server 2008 and 2008 R2 only
SELECT  total_physical_memory_kb ,
        available_physical_memory_kb ,
        total_page_file_kb ,
        available_page_file_kb ,
        system_memory_state_desc
FROM    sys.dm_os_sys_memory ;


-- Script 28
-- SQL Server Process Address space info (SQL 2008 and 2008 R2 only)
--(shows whether locked pages is enabled, among other things)
SELECT  physical_memory_in_use_kb ,
        locked_page_allocations_kb ,
        page_fault_count ,
        memory_utilization_percentage ,
        available_commit_limit_kb ,
        process_physical_memory_low ,
        process_virtual_memory_low
FROM    sys.dm_os_process_memory ;

-- Script 29
-- Look at the number of items in different parts of the cache
SELECT  name ,
        [type] ,
        entries_count ,
        single_pages_kb ,
        single_pages_in_use_kb ,
        multi_pages_kb ,
        multi_pages_in_use_kb
FROM    sys.dm_os_memory_cache_counters
WHERE   [type] = 'CACHESTORE_SQLCP'
        OR [type] = 'CACHESTORE_OBJCP'
ORDER BY multi_pages_kb DESC ;

-- Script 30
-- Get total buffer usage by database
SELECT  DB_NAME(database_id) AS [Database Name] ,
        COUNT(*) * 8 / 1024.0 AS [Cached Size (MB)]
FROM    sys.dm_os_buffer_descriptors
WHERE   database_id > 4 -- exclude system databases
        AND database_id <> 32767 -- exclude ResourceDB
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC ;

-- Breaks down buffers by object (table, index) in the buffer pool
SELECT  OBJECT_NAME(p.[object_id]) AS [ObjectName] ,
        p.index_id ,
        COUNT(*) / 128 AS [Buffer size(MB)] ,
        COUNT(*) AS [Buffer_count]
FROM    sys.allocation_units AS a
        INNER JOIN sys.dm_os_buffer_descriptors
                 AS b ON a.allocation_unit_id = b.allocation_unit_id
        INNER JOIN sys.partitions AS p ON a.container_id = p.hobt_id
WHERE   b.database_id = DB_ID()
        AND p.[object_id] > 100 
GROUP BY p.[object_id] ,
        p.index_id
ORDER BY buffer_count DESC ;


-- Script 31
-- Find long running SQL/CLR tasks
SELECT  os.task_address ,
        os.[state] ,
        os.last_wait_type ,
        clr.[state] ,
        clr.forced_yield_count
FROM    sys.dm_os_workers AS os
        INNER JOIN sys.dm_clr_tasks AS clr
                     ON ( os.task_address = clr.sos_task_address )
WHERE   clr.[type] = 'E_TYPE_USER' ;

-- Script 32
-- Get population status for all FT catalogs in the current database
SELECT  c.name ,
        c.[status] ,
        c.status_description ,
        OBJECT_NAME(p.table_id) AS [table_name] ,
        p.population_type_description ,
        p.is_clustered_index_scan ,
        p.status_description ,
        p.completion_type_description ,
        p.queued_population_type_description ,
        p.start_time ,
        p.range_count
FROM    sys.dm_fts_active_catalogs AS c
        INNER JOIN sys.dm_fts_index_population AS p
                       ON c.database_id = p.database_id
                        AND c.catalog_id = p.catalog_id
WHERE   c.database_id = DB_ID()
ORDER BY c.name ;

-- Script 33
-- Check auto page repair history (New in SQL 2008)
SELECT  DB_NAME(database_id) AS [database_name] ,
        database_id ,
        file_id ,
        page_id ,
        error_type ,
        page_status ,
        modification_time
FROM    sys.dm_db_mirroring_auto_page_repair ; 






