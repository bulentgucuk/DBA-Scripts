/* HealthySQL Chapter 4 - Much Ado About Indexes - The following queries are from Page Split Tracking section in Chapter 4 - Please run each query separately as needed (c) Robert Pearl */

-- Raw Page Splits/sec Perfomance Counter Value

Select * from sys.dm_os_performance_counters

where counter_name = 'page splits/sec' 

--Here is an example of how to calculate the per-second counter value for Page Splits/sec:

-- Collect first sample

DECLARE @old_cntr_value INT;

DECLARE @first_sample_date DATETIME;

SELECT @old_cntr_value = cntr_value,

@first_sample_date = getdate()

FROM sys.dm_os_performance_counters

where counter_name = 'page splits/sec'

-- Time frame to wait before collecting second sample

WAITFOR DELAY '00:00:10'

-- Collect second sample and calculate per-second counter

SELECT (cntr_value - @old_cntr_value) /

DATEDIFF(ss,@first_sample_date, GETDATE()) as PageSplitsPerSec

FROM sys.dm_os_performance_counters

WHERE counter_name = 'page splits/sec' 


/* The next query identifies the top ten objects involved with page splits 
(ordering by leaf_allocation_count and referencing both the 
leaf_allocation_count and nonleaf_allocation_count columns). */

SELECT TOP 10

OBJECT_NAME(object_id, database_id) object_nm,

index_id,

partition_number,

leaf_allocation_count,

nonleaf_allocation_count

FROM sys.dm_db_index_operational_stats

(db_id(), NULL, NULL, NULL)

ORDER BY leaf_allocation_count DESC 


/*You can first look at the cumulative wait stats for PAGELATCH% view by running a simple query below */

select * from

sys.dm_os_wait_stats

WHERE wait_type LIKE 'PAGELATCH%'

AND waiting_tasks_count >0  


/*for PAGELATCH, you can run the following query, which will identify the associated session and the resource_description column that tells you the actual database_id, file_id, and page_id:*/

SELECT session_id, wait_type, resource_description

FROM sys.dm_os_waiting_tasks

WHERE wait_type LIKE 'PAGELATCH%' 




/* You can identify the top ten objects associated with waits on page locks by running the following query */

SELECT TOP 10

OBJECT_NAME(o.object_id, o.database_id) object_nm,

o.index_id,

partition_number,

page_lock_wait_count,

page_lock_wait_in_ms,

case when mid.database_id is null then 'N' else 'Y' end as missing_index_identified

FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) o

LEFT OUTER JOIN (SELECT DISTINCT database_id, object_id

FROM sys.dm_db_missing_index_details) as mid

ON mid.database_id = o.database_id and mid.object_id = o.object_id

ORDER BY page_lock_wait_count DESC 


/*Specifically identify the top ten objects involved with page splits.*/

SELECT TOP 10

OBJECT_NAME(object_id, database_id) object_nm,

index_id,

partition_number,

leaf_allocation_count,

nonleaf_allocation_count

FROM sys.dm_db_index_operational_stats

(db_id(), NULL, NULL, NULL)

ORDER BY leaf_allocation_count DESC 