Select

ResourceWaitTimeMs=sum(wait_time_ms - signal_wait_time_ms)

,'%resource waits'= cast(100.0 * sum(wait_time_ms - signal_wait_time_ms) / sum (wait_time_ms) as numeric(20,2))

,SignalWaitTimeMs=sum(signal_wait_time_ms)

,'%signal waits' = cast(100.0 * sum(signal_wait_time_ms) / sum (wait_time_ms) as numeric(20,2))

from sys.dm_os_wait_stats 