
-- Find SQL Server Data Access Driver and Queries Executed from Client
SELECT	session_id,
		protocol_type,
		driver_version = CASE SUBSTRING(CAST(protocol_version AS BINARY(4)), 1,1)
							WHEN 0x70 THEN 'SQL Server 7.0'
							WHEN 0x71 THEN 'SQL Server 2000'
							WHEN 0x72 THEN 'SQL Server 2005'
							WHEN 0x73 THEN 'SQL Server 2008'
							ELSE 'Unknown driver'
							END,
		client_net_address,
		client_tcp_port,
		local_tcp_port,
		T.text
FROM	sys.dm_exec_connections
	CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS T