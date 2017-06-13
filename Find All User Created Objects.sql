

-- find all the user created objects
SELECT QUOTENAME(DB_NAME(database_id)) 
    + N'.' 
    + QUOTENAME(OBJECT_SCHEMA_NAME(object_id, database_id)) 
    + N'.' 
    + QUOTENAME(OBJECT_NAME(object_id, database_id))
    , * 
FROM sys.dm_db_index_operational_stats(5, null, null, null) -- CHENGE THE DB_ID
WHERE	OBJECT_ID > 100
ORDER BY	PAGE_LATCH_WAIT_COUNT DESC,
			PAGE_LATCH_WAIT_IN_MS DESC



