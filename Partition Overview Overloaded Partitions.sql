;WITH cteUsedPartitions AS
(
SELECT object_id,
       SUM(rows) TotalNbrRows,
       COUNT(*) TotalUsedPartitions
from sys.partitions
where   index_id = 1 AND rows > 0 
 GROUP BY OBJECT_ID
 HAVING COUNT(*) > 1
)

SELECT DISTINCT
  OBJECT_NAME(sp.object_id) TableName,
  pf.name PartitionFunction,
  ps.name PartitionScheme,
  sp.partition_number,
  rows,
  TotalNbrRows,
  (SELECT COUNT(*) 
   FROM sys.partitions 
   WHERE object_id = sp.object_id  AND 
         index_id = 1) TotalPartitions,
  TotalUsedPartitions,
   CAST((rows / (TotalNbrRows * 1.0)) * 
         100 AS DECIMAL(10,2)) AS PrcentOfTotal,
   CAST(((TotalNbrRows * 1.0/TotalUsedPartitions) / 
        (TotalNbrRows * 1.0)) * 
        100 AS DECIMAL(10,2)) AS IdealPrcentOfTotal
FROM   sys.data_spaces d
        JOIN sys.indexes i ON 
             d.data_space_id = i.data_space_id
        JOIN cteUsedPartitions p ON 
             i.object_id = p.object_id 
        JOIN sys.partitions sp ON 
              p.object_id = sp.object_id 
          AND sp.index_id = i.index_id
        JOIN sys.partition_schemes ps ON 
              d.data_space_id = ps.data_space_id
        JOIN sys.partition_functions pf ON 
              ps.function_id = pf.function_id
        JOIN sys.index_columns ic ON 
              i.index_id = ic.index_id
          AND i.object_id = ic.object_id
        JOIN sys.columns c ON 
              c.object_id = ic.object_id
          AND c.column_id = ic.column_id
 WHERE  i.index_id = 1 AND
        CAST((rows / (TotalNbrRows * 1.0)) * 
            100 AS DECIMAL(10,2)) > --PercentOf Total
        (CAST(((TotalNbrRows/TotalUsedPartitions) / 
        (TotalNbrRows * 1.0)) * 
          100 AS DECIMAL(10,2)) * 2)--Ideal Percent * 2