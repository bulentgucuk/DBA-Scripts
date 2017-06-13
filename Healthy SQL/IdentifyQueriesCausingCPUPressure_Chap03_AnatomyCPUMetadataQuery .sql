Select

t.task_state,

r.session_id,

s.context_switches_count,

s.pending_disk_io_count,

s.scheduler_id AS CPU_ID,

s.status AS Scheduler_Status,

db_name(r.database_id) AS Database_Name,

r.command,

px.text

from sys.dm_os_schedulers as s

INNER JOIN sys.dm_os_tasks t on s.active_worker_address = t.worker_address

INNER JOIN sys.dm_exec_requests r on t.task_address = r.task_address

CROSS APPLY sys.dm_exec_sql_text(r.plan_handle) as px

WHERE @@SPID<>r.session_id -- filters out this session

-- AND t.task_state='RUNNABLE' --To filter out sessions that are waiting on CPU uncomment. 