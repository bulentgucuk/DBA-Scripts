dbcc sqlperf (UMSStats, clear)
dbcc sqlperf (WaitStats, clear)
dbcc sqlperf (IOStats, clear)
dbcc sqlperf (Threads, clear)
dbcc freeproccache
dbcc sqlperf ('sys.dm_os_wait_stats', clear)