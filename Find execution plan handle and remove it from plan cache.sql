SELECT cp.plan_handle, st.[text]
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE [text] LIKE N'%fn_Merchant_CommissionsDefaultAndVariable_Select_By_MerchantIDsPlatformType%'
OPTION (RECOMPILE);

-- Remove the specific plan from the cache using the plan handle
/***

DBCC FREEPROCCACHE (0x05001500ADD91769505FF30EC000000001000000000000000000000000000000000000000000000000000000)

***/
