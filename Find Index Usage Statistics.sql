select db_name(database_id),
		object_name(object_id),
	* 
from 
	sys.dm_db_index_usage_stats 
where	user_seeks = 0
and		user_scans = 0
and		db_name(database_id) = 'netquoteqa'
order by 
	user_updates desc
