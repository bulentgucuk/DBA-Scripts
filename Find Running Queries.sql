SELECT
	req.session_id,
	req.start_time,
	req.command,
	DB_NAME(req.database_id) AS DatabaseName,
	req.status,
	req.cpu_time,
	req.total_elapsed_time,
	req.logical_reads,
	req.writes,
	req.blocking_session_id,
	req.wait_resource,
	req.wait_type,
	req.last_wait_type,
	sqltext.TEXT
FROM	sys.dm_exec_requests req
	CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext 
where req.session_id <> @@SPID
--AND	req.database_id = DB_ID()
order by total_elapsed_time desc;

SELECT	r.[session_id],
		c.[client_net_address],s.login_name,
		s.[host_name],
		DB_NAME(r.database_id) AS 'DatabaseName',
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
WHERE   r.[session_id] <> @@SPID
--AND		R.database_id = DB_ID()