-- Find the number or Replication Commands in Distribution DB
SELECT	T.publisher_database_id
		,DATEPART(mm, entry_time) 'Month'
		,DATEPART(dd, entry_time) 'Day'
		,DATEPART(hh, entry_time) 'hour'
		,COUNT(C.xact_seqno) 'NumberOfCommands'
FROM	distribution.dbo.MSrepl_transactions (NOLOCK) AS T
	INNER JOIN dbo.MSrepl_commands (NOLOCK) AS C
		ON T.xact_seqno = C.xact_seqno
GROUP BY T.publisher_database_id
		,DATEPART(mm, entry_time)
		,DATEPART(dd, entry_time)
		,DATEPART(hh, entry_time)
ORDER BY 1,2,3,4 

