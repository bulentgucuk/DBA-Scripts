SELECT
	  deqs.query_hash
	, deqs.query_plan_hash
	, deqs.creation_time
	, deqs.execution_count
	, deqs.last_execution_time
	, deqs.max_logical_reads
	, deqp.query_plan
	, dest.text
FROM    sys.dm_exec_query_stats AS deqs
CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) AS deqp
CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest
WHERE   deqp.objectid = OBJECT_ID('dbo.fn_Merchant_CommissionsDefaultAndVariable_Select_By_MerchantIDPlatformType')
OPTION (RECOMPILE);