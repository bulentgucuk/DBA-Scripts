

SELECT	qplan.Query_Plan,
		Stext.text,
		qstats.*,
		plns.*
FROM	SYS.DM_EXEC_CACHED_PLANS AS plns
	INNER JOIN SYS.DM_EXEC_QUERY_STATS AS qstats
		ON plns.Plan_Handle = qstats.plan_handle
	CROSS APPLY SYS.DM_EXEC_QUERY_PLAN(qstats.Plan_Handle) AS qplan
	CROSS APPLY SYS.DM_EXEC_SQL_TEXT(QSTATS.Plan_Handle) AS stext
WHERE	Qplan.Query_Plan IS NOT NULL


