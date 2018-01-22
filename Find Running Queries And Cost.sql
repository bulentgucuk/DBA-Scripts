SELECT
	  r.[session_id]
	, r.blocking_session_id
	, c.[client_net_address]
	, s.[host_name]
	, s.login_name
	, DB_NAME(r.database_id) AS 'DatabaseName'
	, c.[connect_time]
	, s.[last_request_start_time] AS 'request_start_time'
	, CURRENT_TIMESTAMP AS 'current_time'
	, r.[percent_complete]
	, DATEADD (MILLISECOND,r.[estimated_completion_time],CURRENT_TIMESTAMP) AS 'estimated_finish_time'
	, SUBSTRING(t.[text],r.[statement_start_offset]/2,COALESCE(NULLIF(r.[statement_end_offset], -1)/2, 2147483647)       ) AS 'current_command'
	, COALESCE(QUOTENAME(OBJECT_SCHEMA_NAME(t.[objectid], t.[dbid]))        + '.' + QUOTENAME(OBJECT_NAME(t.[objectid], t.[dbid])), '<ad hoc>') AS 'module'
	, r.status
	, r.cpu_time
	, r.total_elapsed_time
	, r.logical_reads
	, r.writes
	, r.wait_resource
	, r.wait_type
	, r.last_wait_type
	, t.TEXT
FROM	sys.dm_exec_requests AS r 
	INNER JOIN   sys.dm_exec_connections AS c
		ON r.[session_id] = c.[session_id]
	INNER JOIN   sys.dm_exec_sessions AS s
		ON r.[session_id] = s.[session_id]
	CROSS APPLY   sys.dm_exec_sql_text(r.[sql_handle]) AS t
WHERE   r.[session_id] <> @@SPID
ORDER BY S.session_id

