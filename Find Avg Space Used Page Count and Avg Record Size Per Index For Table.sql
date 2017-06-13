-- Find Avg Fragmentation, Page Count and Avg record size Per Index

-- alter index PK_PAYLOAD_STAGING on INSTRUMENTATION.PayloadStaging rebuild --with (online = on)

-- took 27 seconds to rebuild offline (xml datatype) on sqlclr01-d
-- took 22 seconds to rebuild offline (xml datatype) on sqlclr03-p

DECLARE @db_id SMALLINT;
DECLARE @object_id INT;

SET @db_id = DB_ID(N'SOCPLATFORM_QA');
SET @object_id = OBJECT_ID(N'INSTRUMENTATION.PayloadStaging');


SELECT 
	db_name(database_id) AS DatabaseName,
	object_name(object_id) AS ObjectName,
	Index_Id,
	Partition_Number,
	Index_Type_Desc,
	Alloc_Unit_type_desc,
	Index_Depth,
	Index_Level,
	
	avg_page_space_used_in_percent
,avg_fragmentation_in_percent
,avg_fragment_size_in_pages
,record_count
,page_count
,fragment_count
,avg_record_size_in_bytes
,min_record_size_in_bytes
,max_record_size_in_bytes
FROM sys.dm_db_index_physical_stats(@db_id,@object_id,null,NULL,'DETAILED')
GO

