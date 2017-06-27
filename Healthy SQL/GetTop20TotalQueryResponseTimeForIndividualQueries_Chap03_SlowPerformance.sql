Select top 20  AVG(total_elapsed_time/execution_count)/1000000 as "Total Query Response Time",

SUM(query_stats.total_worker_time) / SUM(query_stats.execution_count)/1000 AS "Avg CPU Time",

MIN(query_stats.statement_text) AS "Statement Text"

FROM

(SELECT QS.*,

SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,

((CASE statement_end_offset

WHEN -1 THEN DATALENGTH(ST.text)

ELSE QS.statement_end_offset END

- QS.statement_start_offset)/2) + 1) AS statement_text

FROM sys.dm_exec_query_stats AS QS

CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST) as query_stats

WHERE statement_text IS NOT NULL

GROUP BY query_stats.query_hash

ORDER BY 2 DESC; -- ORDER BY 1 DESC – uncomment to sort by TRT 