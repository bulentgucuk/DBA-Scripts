SELECT ROUND(100.0 * ( SELECT CAST([cntr_value] AS FLOAT)

FROM sys.dm_os_performance_counters

WHERE [object_name] LIKE '%Memory Manager%'

AND [counter_name] = 'Total Server Memory (KB)' ) / ( SELECT CAST([cntr_value] AS FLOAT)

FROM sys.dm_os_performance_counters

WHERE [object_name] LIKE '%Memory Manager%'

AND [counter_name] = 'Target Server Memory (KB)') , 2)AS [IDEAL MEMORY USAGE] 