select 
    o.Name AS 'TableName',
    i.Name AS 'IndexName',
    i.index_id,
    max(s.row_count) AS 'RowCount',
    sum(s.reserved_page_count) * 8.0 / (1024) as 'MB',
    (8 * 1024* sum(s.reserved_page_count)) / max(s.row_count) as 'Bytes/Row'
from 
    sys.dm_db_partition_stats s, 
    sys.indexes i, 
    sys.objects o
where 
    s.object_id = i.object_id
    and s.index_id = i.index_id
    and s.index_id >0
    and i.object_id = o.object_id
    and o.is_ms_shipped = 0
group by i.Name, o.Name, i.index_id
having SUM(s.row_count) > 0
order by TableName, index_id, MB desc;