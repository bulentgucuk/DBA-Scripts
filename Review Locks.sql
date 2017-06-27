SELECT	 resource_type
		,(CASE
			WHEN resource_type = 'OBJECT' THEN object_name(resource_associated_entity_id)
			WHEN resource_type IN ('DATABASE', 'FILE', 'METADATA') THEN 'N/A'
			WHEN resource_type IN ('KEY', 'PAGE', 'RID') THEN (
													SELECT
													object_name(object_id)
													FROM
													sys.partitions
													WHERE
													hobt_id=resource_associated_entity_id)
		 ELSE	'Undefined'
		 END) AS resource_name
		,request_mode as lock_type
		,resource_description
		,request_status
		,request_session_id
		,request_owner_id AS transaction_id

FROM	sys.dm_tran_locks
WHERE	resource_type <> 'DATABASE';