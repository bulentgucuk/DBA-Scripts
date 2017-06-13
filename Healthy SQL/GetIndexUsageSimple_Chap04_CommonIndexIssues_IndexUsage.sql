SELECT

DB_NAME(database_id) As DBName,

Object_Name(object_id,database_id) As ObjectName,

database_id,

object_id,

Index_id,

user_seeks,

user_scans,

user_lookups,

user_updates,

last_user_seek,

last_user_scan,

last_user_lookup,

last_user_update

FROM sys.dm_db_index_usage_stats

order by DB_NAME(database_id) 

GO