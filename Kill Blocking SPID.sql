
-- check for blocking
use master
select distinct(blocked) from sysprocesses where blocked <> 0

-- check if the blocking is blocked
select blocked from sysprocesses where spid =   

-- check the command
dbcc inputbuffer (106) -- change the spid to blocker

-- if the blocker executing a select statement the spid can be safely killed
kill 106  -- change the spid to blocker