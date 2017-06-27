SELECT AVG(current_tasks_count) AS [Avg Current Task],

AVG(runnable_tasks_count) AS [Avg Wait Task]

FROM sys.dm_os_schedulers

WHERE scheduler_id < 255

AND status = 'VISIBLE ONLINE' 