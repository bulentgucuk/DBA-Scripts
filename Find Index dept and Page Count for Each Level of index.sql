
--Find Index depth and page count for each index
SELECT OBJECT_NAME(P.OBJECT_ID) AS 'Table'
     , I.name AS 'Index'
     , P.index_id AS 'IndexID'
     , P.index_type_desc 
     , P.index_depth 
     , P.page_count 
  FROM sys.dm_db_index_physical_stats (DB_ID(), 
                                       OBJECT_ID('Sales.SalesOrderDetail'), 
                                       NULL, NULL, NULL) P
  JOIN sys.indexes I ON I.OBJECT_ID = P.OBJECT_ID 
                    AND I.index_id = P.index_id;


-- Find Page Count for Each node in the index (leaf, intermidate, root)
SELECT OBJECT_NAME(P.OBJECT_ID) AS 'Table'
     , I.name AS 'Index'
     , P.index_id AS 'IndexID'
     , P.index_type_desc 
     , P.index_level  
     , P.page_count 
  FROM sys.dm_db_index_physical_stats (DB_ID(), OBJECT_ID('Sales.SalesOrderDetail'), 2, NULL, 'DETAILED') P
  JOIN sys.indexes I ON I.OBJECT_ID = P.OBJECT_ID 
                    AND I.index_id = P.index_id; 
                    