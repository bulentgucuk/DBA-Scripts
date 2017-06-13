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
WHERE  o.type = 'u' 
AND i.type IN (1, 2) 
AND(s.user_seeks > 0 OR s.user_scans > 0 OR s.user_lookups > 0 
OR s.system_seeks > 0 OR s.system_scans > 0 
OR s.system_lookups > 0)