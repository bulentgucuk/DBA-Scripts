--Find the Count of locks acquired for the given session id
SELECT
	  COUNT(*) AS 'LockCount'
	, resource_associated_entity_id
	, DB_NAME(resource_database_id) AS 'DbName'
	, request_mode
	, request_type
	, resource_type
FROM	sys.dm_tran_locks
WHERE	resource_database_id = DB_ID('ebgtest')
AND		request_session_id = 71
GROUP BY resource_associated_entity_id
	, resource_database_id
	, request_mode
	, request_type
	, resource_type
OPTION(RECOMPILE);
