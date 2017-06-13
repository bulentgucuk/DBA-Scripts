USE msdb 
DECLARE @collection_set_id int 
DECLARE @collection_set_uid uniqueidentifier 
EXEC sp_syscollector_create_collection_set 
@name=N'QueryExecStatsDMV', 
@collection_mode=0, 
@description=N'HealthySQL sample collection set', 
@logging_level=1, 
@days_until_expiration=14, 
@schedule_name=N'CollectorSchedule_Every_15min', 
@collection_set_id=@collection_set_id OUTPUT, 
@collection_set_uid=@collection_set_uid OUTPUT 
DECLARE @collector_type_uid uniqueidentifier 
SELECT @collector_type_uid = collector_type_uid FROM [msdb].[dbo].[syscollector_collector_types] 
WHERE name = N'Generic T-SQL Query Collector Type'; 
DECLARE @collection_item_id int 
EXEC sp_syscollector_create_collection_item 
@name=N'Query Stats - Test 1', 
@parameters=N' 
<ns:TSQLQueryCollector xmlns:ns="DataCollectorType"> 
<Query> 
<Value> 
SELECT * FROM sys.dm_exec_query_stats
</Value> 
<OutputTable>dm_exec_query_stats</OutputTable> 
</Query> 
</ns:TSQLQueryCollector>', 
@collection_item_id=@collection_item_id OUTPUT, 
@frequency=5, 
@collection_set_id=@collection_set_id, 
@collector_type_uid=@collector_type_uid 
SELECT @collection_set_id as Collection_Set_ID, @collection_set_uid as Collection_Set_UID, 
@collection_item_id as Collection_Item_I