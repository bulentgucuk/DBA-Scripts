SELECT	c.session_id
	, s.host_name
	, s.login_time
	, s.login_name
	, s.status
	, c.client_net_address
	, c.client_tcp_port
	, s.cpu_time
	, s.memory_usage
	, c.num_reads
	, s.reads
	, c.num_writes
	, s.writes
	, s.logical_reads
	, c.last_read
	, c.last_write
	, s.client_interface_name
	, s.program_name
	, s.transaction_isolation_level
	, d.name AS database_name
	, c.connect_time
	, s.last_request_start_time
	, s.last_request_end_time
FROM	sys.dm_exec_connections AS c
	inner join sys.dm_exec_sessions AS s on c.session_id = s.session_id
	inner join sys.databases AS d on d.database_id = s.database_id
ORDER BY c.session_id
OPTION (RECOMPILE);



