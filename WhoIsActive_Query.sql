;WITH CTE_ROWS AS (
	SELECT	ROW_NUMBER () OVER(Partition by collection_time order by [dd hh:mm:ss.mss] desc) as RN,
		RowId, collection_time, [dd hh:mm:ss.mss], session_id, sql_text, login_name, wait_info, tran_log_writes, tempdb_current, blocking_session_id, writes, used_memory, status, tran_start_time, open_tran_count, percent_complete, host_name, program_name, start_time, login_time
	from	dbo.WhoIsActive (nolock)
	where	collection_time > '20161113 10:42'
	and		collection_time < '20161113 12:13'
	)
SELECT	*
FROM	CTE_ROWS
WHERE	RN <= 5
ORDER BY collection_time DESC, RN
