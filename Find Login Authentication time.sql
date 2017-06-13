
-- Find Login Authentication type and Time
SELECT	s.session_id
		,c.connect_time
		,s.login_time
		,c.protocol_type
		,c.auth_scheme
		,s.host_name
		,s.program_name
		,s.status
		,c.client_net_address
FROM	sys.dm_exec_sessions s
	JOIN sys.dm_exec_connections c
		ON s.session_id = c.session_id
--WHERE	c.connect_time > '20111020 11:59'		