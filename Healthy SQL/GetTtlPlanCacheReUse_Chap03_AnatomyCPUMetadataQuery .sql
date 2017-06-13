select t1.cntr_value As [Batch Requests/sec],

t2.cntr_value As [SQL Compilations/sec],

plan_reuse_percentage =

convert(decimal(15,2),

(t1.cntr_value*1.0-t2.cntr_value*1.0)/t1.cntr_value*100)

from

master.sys.dm_os_performance_counters t1,

master.sys.dm_os_performance_counters t2

where

t1.counter_name='Batch Requests/sec' and

t2.counter_name='SQL Compilations/sec' 