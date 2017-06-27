Begin Transaction 
Begin Try 
Declare @collection_set_id_1 int 
Declare @collection_set_uid_2 uniqueidentifier 
EXEC [msdb].[dbo].[sp_syscollector_create_collection_set] @name=N'Index Usage', 
@collection_mode=1, 
@description=N'Collects data about index usage for all databases.', 
@logging_level=0, 
@days_until_expiration=730, 
@schedule_name=N'RunAsSQLAgentServiceStartSchedule', 
@collection_set_id=@collection_set_id_1 OUTPUT, 
@collection_set_uid=@collection_set_uid_2 OUTPUT 
Select @collection_set_id_1, @collection_set_uid_2 
Declare @collector_type_uid_3 uniqueidentifier 
Select @collector_type_uid_3 = collector_type_uid From [msdb].[dbo].[syscollector_collector_types] Where name = N'Generic T-SQL Query Collector Type'; 
Declare @collection_item_id_4 int 
EXEC [msdb].[dbo].[sp_syscollector_create_collection_item] @name=N'Index Usage Statistics', 
@parameters=N'<ns:TSQLQueryCollector xmlns:ns="DataCollectorType"><Query><Value> 
SELECT o.name Object_Name,
SCHEMA_NAME(o.schema_id) Schema_name,
i.name Index_name,
i.Type_Desc,
s.user_seeks,
s.user_scans,
s.user_lookups,
s.user_updates,
s.system_seeks,
s.system_scans,
s.system_lookups,
getdate() Capture_Date
FROM sys.objects AS o
JOIN sys.indexes AS i
ON o.object_id = i.object_id
JOIN
sys.dm_db_index_usage_stats AS s
ON i.object_id = s.object_id
AND i.index_id = s.index_id
AND DB_ID() = s.database_id
WHERE  o.type = ''u''
AND i.type IN (1, 2)
AND(s.user_seeks > 0 OR s.user_scans > 0 OR s.user_lookups > 0
OR s.system_seeks > 0 OR s.system_scans > 0
OR s.system_lookups > 0)
</Value><OutputTable>index_usage</OutputTable></Query><Databases UseSystemDatabases="true" 
UseUserDatabases="true" /></ns:TSQLQueryCollector>', 
@collection_item_id=@collection_item_id_4 OUTPUT, 
@collection_set_id=@collection_set_id_1, 
@collector_type_uid=@collector_type_uid_3 
Commit Transaction; 
End Try 
Begin Catch 
Rollback Transaction; 
DECLARE @ErrorMessage NVARCHAR(4000); 
DECLARE @ErrorSeverity INT; 
DECLARE @ErrorState INT; 
DECLARE @ErrorNumber INT; 
DECLARE @ErrorLine INT; 
DECLARE @ErrorProcedure NVARCHAR(200); 
SELECT @ErrorLine = ERROR_LINE(), 
@ErrorSeverity = ERROR_SEVERITY(), 
@ErrorState = ERROR_STATE(), 
@ErrorNumber = ERROR_NUMBER(), 
@ErrorMessage = ERROR_MESSAGE(), 
@ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-'); 
RAISERROR (14684, @ErrorSeverity, 1 , @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine, @ErrorMessage); 
End Catch; 
GO 

/*Once the above code is run, you then need to start the collection agent, using SSMS or the following code: */

EXEC msdb.dbo.sp_syscollector_start_collection_set @name = 'Index Usage'