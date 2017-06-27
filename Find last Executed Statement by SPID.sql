-- Find Last executed statement by SPID
SELECT	DEST.TEXT 
FROM	sys.[dm_exec_connections] SDEC
	CROSS APPLY sys.[dm_exec_sql_text](SDEC.[most_recent_sql_handle]) AS DEST
WHERE	SDEC.[most_recent_session_id] = @@spid