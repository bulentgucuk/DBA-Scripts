SELECT object_name,

counter_name,

case when instance_name =''

then @@SERVICENAME end as instance_name,

cntr_type,

cntr_value

FROM sys.dm_os_performance_counters 