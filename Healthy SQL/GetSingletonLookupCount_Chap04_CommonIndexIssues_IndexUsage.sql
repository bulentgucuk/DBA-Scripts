SELECT OBJECT_SCHEMA_NAME(idxos.object_id) + '.' + OBJECT_NAME(idxos.object_id) as table_name

,idx.name as index_name

,idxos.range_scan_count

,idxos.singleton_lookup_count

FROM sys.dm_db_index_operational_stats(DB_ID(),NULL,NULL,NULL) idxos

INNER JOIN sys.indexes idx ON idx.object_id = idxos.object_id AND idx.index_id = idxos.index_id

WHERE OBJECTPROPERTY(idxos.object_id,'IsUserTable') = 1

ORDER BY idxos.range_scan_count DESC

GO 