SELECT (a.cntr_value * 1.0 / b.cntr_value) * 100 [BufferCacheHitRatio]

FROM (SELECT * FROM sys.dm_os_performance_counters

WHERE counter_name = 'Buffer cache hit ratio'

AND object_name = CASE WHEN @@SERVICENAME = 'MSSQLSERVER'

THEN 'SQLServer:Buffer Manager'

ELSE 'MSSQL$' + rtrim(@@SERVICENAME) +

':Buffer Manager' END ) a

CROSS JOIN

(SELECT * from sys.dm_os_performance_counters

WHERE counter_name = 'Buffer cache hit ratio base'

and object_name = CASE WHEN @@SERVICENAME = 'MSSQLSERVER'

THEN 'SQLServer:Buffer Manager'

ELSE 'MSSQL$' + rtrim(@@SERVICENAME) +

':Buffer Manager' END ) b; 