USE [master];
GO
IF OBJECT_ID('tempdb.dbo.TableSizes') IS NOT NULL
	DROP TABLE tempdb.dbo.TableSizes;

CREATE TABLE tempdb.dbo.TableSizes (ServerName VARCHAR(32), DatabaseName VARCHAR(128), SchemaName VARCHAR(32), TableName VARCHAR(128), RowCounts BIGINT, TotalSpaceKB BIGINT, UsedSpaceKB BIGINT, UnuseSpaceKB BIGINT)

EXEC sp_msforeachdb 'USE [?]; 
INSERT INTO tempdb.dbo.TableSizes
SELECT  
@@ServerName,
''?'' as db,  
s.Name AS SchemaName,   
t.NAME AS TableName,    
p.rows AS RowCounts,    
SUM(a.total_pages) * 8 AS TotalSpaceKB,     
SUM(a.used_pages) * 8 AS UsedSpaceKB, 
(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB 
FROM     sys.tables t 
INNER JOIN      sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id 
INNER JOIN     sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN     sys.schemas s ON t.schema_id = s.schema_id 
WHERE    p.rows > 0 AND t.is_ms_shipped = 0    AND i.OBJECT_ID > 255 
GROUP BY     t.Name, s.Name, p.Rows 
ORDER BY p.rows DESC' ;

SELECT	*
FROM tempdb.dbo.TableSizes
ORDER BY DatabaseName, SchemaName, TableName