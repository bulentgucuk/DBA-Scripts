-- Set WaitsToIgnore 
Update Monitor.WaitTypes 
Set track = 0 
Where wait_type in ( 
'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK','SP_SERVER_
DIAGNOSTICS_SLEEP', 
'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE', 
'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_
FLUSH', 
'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT', 'DISPATCHER_QUEUE_
SEMAPHORE', 
'FT_IFTS_SCHEDULER_IDLE_WAIT', 'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'BROKER_
EVENTHANDLER', 
'TRACEWRITE', 'FT_IFTSHC_MUTEX', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', 'DIRTY_PAGE_
POLL', 'BROKER_RECEIVE_WAITFOR', 'ONDEMAND_TASK_QUEUE', 'DBMIRROR_EVENTS_QUEUE', 
'DBMIRRORING_CMD', 'BROKER_TRANSMITTER', 'SQLTRACE_WAIT_ENTRIES', 
'SLEEP_BPOOL_FLUSH', 'SQLTRACE_LOCK', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION'); 
SET ANSI_NULLS ON 
GO