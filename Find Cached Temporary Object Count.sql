SELECT
    DOMCC.[type],
    DOMCC.pages_kb,
    DOMCC.pages_in_use_kb,
    DOMCC.entries_count,
    DOMCC.entries_in_use_count
FROM sys.dm_os_memory_cache_counters AS DOMCC 
WHERE 
    DOMCC.[name] = N'Temporary Tables & Table Variables';