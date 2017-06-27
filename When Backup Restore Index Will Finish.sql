SELECT	r.[session_id],
		c.[client_net_address],
		s.[host_name],
		c.[connect_time],
		[request_start_time] = s.[last_request_start_time],
		[current_time] = CURRENT_TIMESTAMP,
		r.[percent_complete],
		[estimated_finish_time] = DATEADD (MILLISECOND,r.[estimated_completion_time],CURRENT_TIMESTAMP),
		current_command = SUBSTRING(t.[text],r.[statement_start_offset]/2,COALESCE(NULLIF(r.[statement_end_offset], -1)/2, 2147483647)       ),
		module = COALESCE(QUOTENAME(OBJECT_SCHEMA_NAME(t.[objectid], t.[dbid]))        + '.' + QUOTENAME(OBJECT_NAME(t.[objectid], t.[dbid])), '<ad hoc>')
FROM	sys.dm_exec_requests AS r 
	INNER JOIN   sys.dm_exec_connections AS c
		ON r.[session_id] = c.[session_id]
	INNER JOIN   sys.dm_exec_sessions AS s
		ON r.[session_id] = s.[session_id]
	CROSS APPLY   sys.dm_exec_sql_text(r.[sql_handle]) AS t
WHERE   r.[percent_complete] <> 0;