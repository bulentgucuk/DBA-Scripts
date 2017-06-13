SELECT [counter_name], [cntr_value]

FROM sys.dm_os_performance_counters

WHERE [object_name]

LIKE '%Memory Manager%'

AND [counter_name] IN ('Total Server Memory (KB)', 'Target Server Memory (KB)') 
