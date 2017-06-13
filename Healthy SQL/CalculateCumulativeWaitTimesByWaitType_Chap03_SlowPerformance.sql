Select wait_type, waiting_tasks_count, wait_time_ms as total_wait_time_ms,

signal_wait_time_ms,

(wait_time_ms-signal_wait_time_ms) as resource_wait_time_ms

FROM sys.dm_os_wait_stats

ORDER BY total_wait_time_ms DESC 