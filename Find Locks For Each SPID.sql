
SELECT 
  tl.request_session_id as spid,tl.resource_type, 
  tl.resource_subtype,
  CASE 
     WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(tl.resource_associated_entity_id, tl.resource_database_id)
     ELSE '' 
  END AS object,
  tl.resource_description,
  request_mode, 
  request_type, 
  request_status,
  wt.blocking_session_id as blocking_spid
FROM sys.dm_tran_locks tl 
LEFT JOIN sys.dm_os_waiting_tasks AS wt ON tl.lock_owner_address = wt.resource_address
