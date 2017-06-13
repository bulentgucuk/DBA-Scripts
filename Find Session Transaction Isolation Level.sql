SELECT transaction_isolation_level,
CASE WHEN transaction_isolation_level = 0 THEN 'Unspecified'
	WHEN transaction_isolation_level = 1 THEN 'ReadUncomitted'
	WHEN transaction_isolation_level = 2 THEN 'ReadCommitted'
	WHEN transaction_isolation_level = 3 THEN 'Repeatable'
	WHEN transaction_isolation_level = 4 THEN 'Serializable'
	WHEN transaction_isolation_level = 5 THEN 'Snapshot'
END AS ISOLATIONLEVEL,
* FROM sys.dm_exec_sessions
WHERE session_id > 50
