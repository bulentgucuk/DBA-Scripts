declare @dbid int
select @dbid = db_id()

Select dbid=database_id
	, objectname=object_name(s.object_id)
	, indexname=i.name, i.index_id	--, partition_number
	, row_lock_count, row_lock_wait_count
	, [block %]=cast (100.0 * row_lock_wait_count / (1 + row_lock_count) as numeric(15,2))
	, row_lock_wait_in_ms
	, [avg row lock waits in ms]=cast (1.0 * row_lock_wait_in_ms / (1 + row_lock_wait_count) as numeric(15,2))
from sys.dm_db_index_operational_stats (@dbid, NULL, NULL, NULL) s
	inner join sys.indexes i
		on i.index_id = s.index_id
		and i.object_id = s.object_id
		
where objectproperty(s.object_id,'IsUserTable') = 1
and i.object_id = s.object_id
and row_lock_wait_count > 0
order by row_lock_wait_count desc
