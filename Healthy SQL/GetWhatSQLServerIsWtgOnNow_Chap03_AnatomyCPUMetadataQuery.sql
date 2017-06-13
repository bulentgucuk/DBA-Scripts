SELECT dm_ws.session_ID,

dm_ws.wait_type,

UPPER(dm_es.status) As status,

dm_ws.wait_duration_ms,

dm_t.TEXT,

dm_es.cpu_time,

dm_es.memory_usage,

dm_es.logical_reads,

dm_es.total_elapsed_time,

dm_ws.blocking_session_id,

dm_es.program_name,

DB_NAME(dm_r.database_id) DatabaseName

FROM sys.dm_os_waiting_tasks dm_ws

INNER JOIN sys.dm_exec_requests dm_r ON dm_ws.session_id = dm_r.session_id

INNER JOIN sys.dm_exec_sessions dm_es ON dm_es.session_id = dm_r.session_id

CROSS APPLY sys.dm_exec_sql_text (dm_r.sql_handle) dm_t

WHERE dm_es.is_user_process = 1 