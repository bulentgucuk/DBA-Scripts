SELECT avg(total_elapsed_time / execution_count)/1000 As avg_query_response_time /*total_avg_elapsed_time (div by 1000 for ms, div by 1000000 for sec) */
FROM sys.dm_exec_query_stats 