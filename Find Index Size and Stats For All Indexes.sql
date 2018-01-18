-- Index size
select
    object_schema_name(o.object_id) AS 'SchemaName', 
    o.Name AS 'TableName',
    i.Name AS 'IndexName',
    max(s.row_count) AS 'RowCount',
    sum(s.reserved_page_count) * 8.0 / (1024) as 'MB',
    (8 * 1024* sum(s.reserved_page_count)) / max(s.row_count) as 'Bytes/Row',
	s.reserved_page_count,
	p.Data_compression_desc
	,  STATS_DATE(i.[object_id], i.index_id) AS StatisticsDate
from 
    sys.dm_db_partition_stats s, 
    sys.indexes i, 
    sys.objects o,
	sys.partitions as p
where 
    s.object_id = i.object_id
    and s.index_id = i.index_id
    --and s.index_id >0
    and i.object_id = o.object_id
    and p.object_id = o.object_id
    and p.index_id = i.Index_id
    and o.is_ms_shipped = 0  -- Non Microsoft Objects
    --and o.Name  = 'FactInventory'
group by i.Name, o.Name, p.Data_compression_desc,o.object_id, i.index_id, STATS_DATE(i.[object_id], i.index_id),s.reserved_page_count
having SUM(s.row_count) > 0
order by SchemaName, tablename, i.index_id-- MB desc
OPTION(RECOMPILE);
