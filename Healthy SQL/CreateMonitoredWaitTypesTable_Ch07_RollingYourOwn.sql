-- Create Schema 
IF SCHEMA_ID('Monitor') IS NULL EXECUTE ('CREATE SCHEMA Monitor'); 
-- Create WaitType repository for wait types 
IF OBJECT_ID('Monitor.WaitTypes','U') IS NULL 
CREATE TABLE Monitor.WaitTypes (wait_type varchar(50),track bit default (1)); 
GO 
-- Build the repository of available waits from the sys.dm_os_wait_stats DMW 
Insert Into Monitor.WaitTypes (wait_type) 
Select distinct s.wait_type 
From sys.dm_os_wait_stats s; 
-- Create clustered and filtered indices 
Create Clustered Index CX_waittype on Monitor.WaitTypes(wait_type); 
Create Index IX_waittype on Monitor.WaitTypes(wait_type) 
Where track = 1;