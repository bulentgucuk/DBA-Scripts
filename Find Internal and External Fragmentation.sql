USE Cowboys_Reporting
GO
SELECT DB_NAME(database_id) AS 'Database Name'
,[object_id]
,Object_Name([object_id])
,index_id
,avg_fragmentation_in_percent AS 'External Fragmentation'
,avg_page_space_used_in_percent AS 'Internal Fragmentation' 
,*
FROM sys.dm_db_index_physical_stats(db_id(),OBJECT_ID('prodcopystg.Account'),NULL,NULL,'DETAILED')
--WHERE (avg_fragmentation_in_percent > 10 
--OR 
--avg_page_space_used_in_percent < 75)
--AND avg_page_space_used_in_percent <> 0
--AND page_count > 8;