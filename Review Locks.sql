SELECT	 l.resource_type
		,(CASE
			WHEN l.resource_type = 'OBJECT' THEN object_name(l.resource_associated_entity_id)
			WHEN l.resource_type IN ('DATABASE', 'FILE', 'METADATA') THEN 'N/A'
			WHEN l.resource_type IN ('KEY', 'PAGE', 'RID') THEN (
													SELECT
													object_name(object_id)
													FROM
													sys.partitions
													WHERE
													hobt_id=resource_associated_entity_id)
		 ELSE	'Undefined'
		 END) AS resource_name
		,request_mode as lock_type
		,l.resource_description
		,request_status
		,request_session_id
		,request_owner_id AS transaction_id
		,s.name as database_name
FROM	sys.dm_tran_locks as l
	INNER JOIN sys.databases as s ON l.resource_database_id = s.database_id
WHERE	l.resource_type <> 'DATABASE'
OPTION(RECOMPILE);