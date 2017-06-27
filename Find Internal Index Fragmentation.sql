-- Find Internal Index Fragmentation
SELECT IX.name AS 'Name'
     , PS.index_level AS 'Level'
     , PS.page_count AS 'Pages'
     , PS.avg_page_space_used_in_percent AS 'Page Fullness (%)'
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('crm.MigrationSagaData'), DEFAULT, DEFAULT, 'DETAILED') AS PS
	INNER JOIN sys.indexes AS IX ON IX.OBJECT_ID = PS.OBJECT_ID AND IX.index_id = PS.index_id 
-- WHERE IX.name = 'PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID';
