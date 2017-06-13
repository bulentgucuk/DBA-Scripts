-- Find Connection Level Information for Each Session
-- Authentication, Login, HostName, Read\Write etc.
SELECT	ec.Auth_Scheme,
		es.Session_ID,
		es.Login_Name,
		es.STATUS,
		es.cpu_time,
		es.Memory_Usage,
		es.Reads,
		ec.Num_Reads,
		es.Writes,
		ec.Num_Writes,
		es.Logical_Reads,
		ec.Last_Read AS LastReadDateTime,
		ec.Last_Write AS LastWriteDateTime,
		es.Row_Count,
		es.Transaction_Isolation_Level,
		es.HOST_NAME,
		es.Program_name,
		es.Login_Time,
		ec.Client_Net_Address AS ClientIPAddress,
		ec.most_recent_sql_handle
FROM	sys.dm_exec_connections AS EC
	INNER JOIN sys.dm_exec_sessions AS ES
		ON ec.session_id = es.session_id		
--ORDER BY es.Logical_Reads DESC
OPTION(RECOMPILE)
