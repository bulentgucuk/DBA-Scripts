DECLARE @s datetime;  
DECLARE @e datetime;  
SET @s= DateAdd(d,-15,GetUTCDate());  
SET @e= GETUTCDATE();  
SELECT start_time
	, end_time
	, database_name
	, sku
	, storage_in_megabytes
	, avg_cpu_percent
	, avg_data_io_percent
	, avg_log_write_percent
	, max_worker_percent
	, dtu_limit  
FROM sys.resource_stats   
WHERE start_time BETWEEN @s AND @e  

SELECT * FROM
sys.dm_db_resource_stats