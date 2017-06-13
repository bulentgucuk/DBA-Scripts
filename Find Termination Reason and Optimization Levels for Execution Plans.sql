-- FIND TERMINATION REASON AND OPTIMIZATION LEVELS FOR EXECUTION PLANS
-- RUNS LONG AND MAY TAKE CPU RESOURCES
WITH XMLNAMESPACES(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'), QueryPlans
AS  ( 
SELECT  RelOp.pln.value(N'@StatementOptmEarlyAbortReason', N'varchar(50)') AS TerminationReason,
        RelOp.pln.value(N'@StatementOptmLevel', N'varchar(50)') AS OptimizationLevel,
        --dest.text,
        SUBSTRING(dest.text, (deqs.statement_start_offset / 2) + 1,
                  (deqs.statement_end_offset - deqs.statement_start_offset)
                  / 2 + 1) AS StatementText,
        deqp.query_plan,
        deqp.dbid,
        deqs.execution_count,
        deqs.total_elapsed_time,
        deqs.total_logical_reads,
        deqs.total_logical_writes
FROM    sys.dm_exec_query_stats AS deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest
        CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) AS deqp
        CROSS APPLY deqp.query_plan.nodes(N'//StmtSimple') RelOp (pln)
WHERE   deqs.statement_end_offset > -1        
)   
SELECT  DB_NAME(qp.dbid),
        *
FROM    QueryPlans AS qp
WHERE   (qp.dbid = 13 OR qp.dbid IS NULL)
        AND qp.optimizationlevel = 'Full'
ORDER BY qp.execution_count DESC ;


