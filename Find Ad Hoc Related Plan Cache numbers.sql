/***
DBCC FREEproccache

EXEC sp_configure 'optimize for ad hoc workloads', 0
RECONFIGURE
GO

**/

--Gives you the total number of one-time use ad hoc queries currently in the
--plan cache.
USE master
GO
SELECT  SUM(CASE WHEN usecounts = 1 THEN 1
                 ELSE 0
            END) AS [Adhoc Plans Use Count of 1]
FROM    sys.dm_exec_cached_plans
WHERE   objtype = 'Adhoc'
GROUP BY objtype;
GO

--List all the one-time ad hoc queries, row by row, currently in the plan 
--cache.
USE master
GO
SELECT  usecounts ,
        size_in_bytes ,
        cacheobjtype ,
        objtype
FROM    sys.dm_exec_cached_plans
WHERE   objtype = 'Adhoc'
        AND usecounts = 1
ORDER BY size_in_bytes desc      
GO

--Tells you how much memory is being used by the one-time use ad hoc queries
USE master
GO
SELECT  SUM(CAST(( CASE WHEN usecounts = 1 THEN size_in_bytes
                        ELSE 0
                   END ) AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs Used by Adhoc Plans With Use Count of 1]
FROM    sys.dm_exec_cached_plans
WHERE   objtype = 'Adhoc'
GROUP BY objtype;
GO