-- Find Active Sessions
SELECT
	  r.session_id
	, r.blocking_session_id
	, s.program_name
	, s.host_name
	, s.login_name
	, s.login_time
	, t.text

FROM	sys.dm_exec_requests AS r
	INNER JOIN sys.dm_exec_sessions AS s on r.session_id = s.session_id
	CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t

WHERE	s.is_user_process = 1
AND		r.session_id <> @@SPID -- NOT MY SPID RUNNING THIS QUERY
--AND		s.login_name = 'NQCORP\ChappellO'