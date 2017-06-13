-- Find the plan handle for the query 
-- OPTION (RECOMPILE) keeps this query from going into the plan cache
SELECT cp.plan_handle, cp.objtype, cp.usecounts, DB_NAME(st.dbid) AS [DatabaseName], st.objectid, OBJECT_NAME(st.objectid)
FROM	sys.dm_exec_cached_plans AS cp
	CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE OBJECT_NAME (st.objectid) LIKE N'%fn_Merchant_CommissionsDefaultAndVariable_Select_By_MerchantIDListReferSourceAndPlatformType%'
OPTION (RECOMPILE); 

--DBCC FREEPROCCACHE (0x05000F0024559633E0CCE3134601000001000000000000000000000000000000000000000000000000000000)
