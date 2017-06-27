/*Healthy SQL - Chapter 8 Monitoring And Reporting - the following scripts are from the Blocking and Locking section of this Chapter. 
Run them all separately as needed according to the instruction in the book The Create blocking chain section presumes you are using 
AdventureWorks2012 database sample as directed in book.  All other code is usable to capture any blocking that occurs */

/*Enable and Set the "blocked process threshold configuration setting"*/

sp_configure 'show advanced options',1 ; 
GO 
RECONFIGURE; 
GO 
sp_configure 'blocked process threshold',5 ; 
GO 
RECONFIGURE; 
GO 

/*created and start session - the XE blocking script is  based on SQL MVP Jonathan Kehayias code. He is a trusted authority on 
Extended Events. */
CREATE EVENT SESSION MonitorBlocking 
ON SERVER 
ADD EVENT sqlserver.blocked_process_report 
ADD TARGET package0.ring_buffer(SET MAX_MEMORY=2048) 
WITH (MAX_DISPATCH_LATENCY = 5SECONDS) 
GO 
ALTER EVENT SESSION MonitorBlocking 
ON SERVER 
STATE=START 
  
 /* Test the Monitor_Blocking script by creating a blocking 
chain. Do this against the AdventureWorks2012 example database. 
 Open your SQL Server instance and open two query windows. In the first query window, run the 
following code */

USE AdventureWorks2012; 
GO 
BEGIN TRANSACTION 
SELECT * FROM Person.Person WITH (TABLOCKX, HOLDLOCK); 
WAITFOR DELAY '00:00:30' ---Wait 30 seconds! 
ROLLBACK TRANSACTION 
--Release the lock 

-- In the second query window, run the following code: 
USE AdventureWorks2012; 
GO 
SELECT * FROM Person.Person; 
 /* Once you create the blocking condition, in a new query window run the  
Monitoring_Blocking session script, shown here: */

SELECT 
n.value('(event/@name)[1]', 'varchar(50)') AS event_name, 
n.value('(event/@package)[1]', 'varchar(50)') AS package_name, 
DATEADD(hh, 
DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), 
n.value('(event/@timestamp)[1]', 'datetime2')) AS [timestamp], 
ISNULL(n.value('(event/data[@name="database_id"]/value)[1]', 'int'), 
n.value('(event/action[@name="database_id"]/value)[1]', 'int')) as 
[database_id], 
n.value('(event/data[@name="database_name"]/value)[1]', 'nvarchar(128)') as 
[database_name], 
n.value('(event/data[@name="object_id"]/value)[1]', 'int') as [object_id], 
n.value('(event/data[@name="index_id"]/value)[1]', 'int') as [index_id], 
CAST(n.value('(event/data[@name="duration"]/value)[1]', 'bigint')/1000000.0 AS 
decimal(6,2)) as [duration_seconds], 
n.value('(event/data[@name="lock_mode"]/text)[1]', 'nvarchar(10)') as [file_handle], 
n.value('(event/data[@name="transaction_id"]/value)[1]', 'bigint') as [transaction_id], 
n.value('(event/data[@name="resource_owner_type"]/text)[1]', 'nvarchar(10)') as 
[resource_owner_type], 
CAST(n.value('(event/data[@name="blocked_process"]/value)[1]', 'nvarchar(max)') as 
XML) as [blocked_process_report] 
FROM 
(    SELECT td.query('.') as n 
FROM 
( 
SELECT CAST(target_data AS XML) as target_data 
FROM sys.dm_xe_sessions AS s 
JOIN sys.dm_xe_session_targets AS t 
ON s.address = t.event_session_address 
WHERE s.name = 'MonitorBlocking' 
AND t.target_name = 'ring_buffer' 
) AS sub 
CROSS APPLY target_data.nodes('RingBufferTarget/event') AS q(td) 
) as tab 

 
SELECT * FROM Person.Person; 
BEGIN TRANSACTION 
SELECT * FROM Person.Person WITH (TABLOCKX, HOLDLOCK); 
WAITFOR DELAY '00:00:30' ---Wait a minute! 
ROLLBACK TRANSACTION 
--Release the lock 