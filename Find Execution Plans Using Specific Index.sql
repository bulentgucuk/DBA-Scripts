
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

DECLARE @IndexName sysname = 'ncIndx1';
SET @IndexName = QUOTENAME(@IndexName,'[');

WITH XMLNAMESPACES(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
,IndexSearch
AS (
    SELECT qp.query_plan
        ,cp.usecounts
        ,ix.query('.') AS StmtSimple
    FROM sys.dm_exec_cached_plans cp
        OUTER APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
        CROSS APPLY qp.query_plan.nodes('//StmtSimple') AS p(ix)
    WHERE query_plan.exist('//Object[@Index = sql:variable("@IndexName")]') = 1
)
SELECT StmtSimple.value('StmtSimple[1]/@StatementText', 'VARCHAR(4000)') AS sql_text
    ,obj.value('@Database','sysname') AS database_name
    ,obj.value('@Schema','sysname') AS schema_name
    ,obj.value('@Table','sysname') AS table_name
    ,obj.value('@Index','sysname') AS index_name
    ,ixs.query_plan
FROM IndexSearch ixs
    CROSS APPLY StmtSimple.nodes('//Object') AS o(obj)
WHERE obj.exist('//Object[@Index = sql:variable("@IndexName")]') = 1 
