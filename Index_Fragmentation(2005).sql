/*****************************************************

Global Script

*****************************************************/
/***********************************************************
View fragmentation levels of all indexes/tables on all tables in all databases
***********************************************************/
PRINT '==== Fragmentation Levels of all indexes in all databases==== '
SET NOCOUNT ON;

--Change database connection
USE master;
--View fragmented indexes on all tables in all databases
SELECT DB_NAME(database_id) AS 'Database Name'
,[object_id] AS 'Object ID'
--,Object_Name([object_id], DB_ID('NetQuoteSource')) As [Object]
,index_id AS 'Index ID'
,avg_fragmentation_in_percent AS 'External Fragmentation'
,avg_page_space_used_in_percent AS 'Internal Fragmentation' 
FROM sys.dm_db_index_physical_stats(null,NULL,NULL,NULL,'DETAILED')
WHERE (avg_fragmentation_in_percent > 10 
OR 
avg_page_space_used_in_percent < 75)
AND avg_page_space_used_in_percent <> 0
AND page_count > 8;


