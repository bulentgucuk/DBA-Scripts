SELECT 
        t1.resource_type,
        t1.resource_database_id,
        t1.resource_associated_entity_id,
        t1.request_mode,
        t1.request_session_id,
        t2.blocking_session_id
    FROM sys.dm_tran_locks as t1
    INNER JOIN sys.dm_os_waiting_tasks as t2
        ON t1.lock_owner_address = t2.resource_address;


SELECT resource_type, resource_associated_entity_id,
    request_status, request_mode,request_session_id,
    resource_description 
    FROM sys.dm_tran_locks
    WHERE resource_database_id = 5



SELECT object_name(object_id), *
    FROM sys.partitions
    WHERE hobt_id=72057603711565824


exec dbo.beta_lockinfo

select status,* From sys.sysprocesses where blocked <> 0

dbcc opentran

--dbcc shrinkfile (2,7500)

SELECT * FROM sys.dm_exec_sessions

WHERE session_id = 81

SELECT 
r.session_id, 
r.blocking_session_id, 
s.program_name, 
s.host_name, 
t.text

FROM
sys.dm_exec_requests r
INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t

WHERE
s.is_user_process = 1 AND
r.session_id = 81

