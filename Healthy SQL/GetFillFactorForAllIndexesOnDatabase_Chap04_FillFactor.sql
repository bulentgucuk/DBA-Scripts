SELECT

db_name() AS DbName

, B.name AS TableName

, C.name AS IndexName

, C.fill_factor AS IndexFillFactor

, D.rows AS RowsCount

, A.avg_fragmentation_in_percent

, A.page_count

, GetDate() as [TimeStamp]

FROM sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,NULL) A

INNER JOIN sys.objects B

ON A.object_id = B.object_id

INNER JOIN sys.indexes C

ON B.object_id = C.object_id AND A.index_id = C.index_id

INNER JOIN sys.partitions D

ON B.object_id = D.object_id AND A.index_id = D.index_id

WHERE C.index_id > 0

