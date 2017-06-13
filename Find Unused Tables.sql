-- Create CTE for the unused tables, which are the tables from the sys.all_objects and 
-- not in the sys.dm_db_index_usage_stats table

; with UnUsedTables (TableName , TotalRowCount, CreatedDate , LastModifiedDate ) 
AS ( 
  SELECT DBTable.name AS TableName
     ,PS.row_count AS TotalRowCount
     ,DBTable.create_date AS CreatedDate
     ,DBTable.modify_date AS LastModifiedDate
  FROM sys.all_objects  DBTable 
     JOIN sys.dm_db_partition_stats PS ON OBJECT_NAME(PS.object_id)=DBTable.name
  WHERE DBTable.type ='U' 
     AND NOT EXISTS (SELECT OBJECT_ID  
                     FROM sys.dm_db_index_usage_stats
                     WHERE OBJECT_ID = DBTable.object_id )
)
-- Select data from the CTE
SELECT TableName , TotalRowCount, CreatedDate , LastModifiedDate 
FROM UnUsedTables
ORDER BY TotalRowCount ASC