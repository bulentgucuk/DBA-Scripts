SELECT
	  OBJECT_SCHEMA_NAME(object_id) AS 'Schema_Name'
	, OBJECT_NAME(object_id) AS 'Table_Name'
	, SUM (row_count) AS 'Row_Count'
FROM sys.dm_db_partition_stats
WHERE (object_id=OBJECT_ID('[ods].[CoreMetrics_PageViewEventsPivot]')
	OR object_id=OBJECT_ID('[ods].[CoreMetrics_CartEventsPivot]')
	OR object_id=OBJECT_ID('[ods].[CoreMetrics_OrderEventsPivot]')
	OR object_id=OBJECT_ID('[ods].[CoreMetrics_ProductViewEventsPivot]')
	OR object_id=OBJECT_ID('[ods].[CoreMetrics_RegistrationDataPivot]'))
AND (index_id=0 or index_id=1)
GROUP BY OBJECT_SCHEMA_NAME(object_id) ,OBJECT_NAME(object_id)
ORDER BY Row_Count desc;
