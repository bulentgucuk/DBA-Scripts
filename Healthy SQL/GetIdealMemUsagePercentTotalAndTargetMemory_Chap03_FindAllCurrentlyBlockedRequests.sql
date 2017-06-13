/* Get all blocked processes
SELECT * FROM sys.sysprocesses WHERE blocked > 0 

DBCC INPUTBUFFER (SPID) -- Replace (SPID) with blocked spid from above query for text) */

SELECT sqltext.TEXT,

xr.session_id,

xr.status,

xr.blocking_session_id,

xr.command,

xr.cpu_time,

xr.total_elapsed_time,

xr.wait_resource

FROM sys.dm_exec_requests xr

CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext

WHERE status='suspended' 