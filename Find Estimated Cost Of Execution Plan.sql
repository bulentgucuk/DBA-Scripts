-- Place to start Cost Threshold For Parallellism
;WITH XMLNAMESPACES (
                      DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
                   )
, TextPlans
AS (SELECT CAST(detqp.query_plan AS XML) AS QueryPlan,
           detqp.dbid
    FROM sys.dm_exec_query_stats AS deqs
    CROSS APPLY sys.dm_exec_text_query_plan(
                                              deqs.plan_handle,
                                              deqs.statement_start_offset,
                                              deqs.statement_end_offset
                                           ) AS detqp
   ),
  QueryPlans
AS (SELECT RelOp.pln.value(N'@EstimatedTotalSubtreeCost', N'float') AS EstimatedCost,
           RelOp.pln.value(N'@NodeId', N'integer') AS NodeId,
           tp.dbid,
           tp.QueryPlan
    FROM TextPlans AS tp
    CROSS APPLY tp.queryplan.nodes(N'//RelOp')RelOp(pln)
   )
SELECT qp.EstimatedCost, db_name(qp.dbid) as 'DBName', qp.QueryPlan
FROM QueryPlans AS qp
WHERE qp.NodeId = 0;
