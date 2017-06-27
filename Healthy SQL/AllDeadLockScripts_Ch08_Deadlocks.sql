-- 1) Create Tables for Deadlock Simulation 
USE TEMPDB 
CREATE TABLE dbo.tab1 (col1 INT) 
INSERT dbo.tab1 SELECT 1 
CREATE TABLE dbo.tab2 (col1 INT) 
INSERT dbo.tab2 SELECT 1 
-- 2) Run in first connection 
BEGIN TRAN 
UPDATE tempdb.dbo.tab1 SET col1 = 1 
-- 3) Run in second connection 
BEGIN TRAN 
UPDATE tempdb.dbo.tab2 SET col1 = 1 
UPDATE tempdb.dbo.tab1 SET col1 = 1 
-- 4) Run in first connection 
UPDATE tempdb.dbo.tab2 SET col1 =1 
 /*The second connection will be chosen as  the   deadlock victim, and you should receive a deadlock error 
message. */ 
 --The following is a query to find the deadlock  XML   details using Extended Events: 
SELECT XEvent.query('(event/data/value/deadlock)[1]') AS DeadlockGraph 
FROM ( SELECT XEvent.query('.') AS XEvent 
FROM ( SELECT CAST(target_data AS XML) AS TargetData 
FROM sys.dm_xe_session_targets st 
JOIN sys.dm_xe_sessions s 
ON s.address = st.event_session_address 
WHERE s.name = 'system_health' 
AND st.target_name = 'ring_buffer' 
) AS Data 
CROSS APPLY 
TargetData.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') 
AS XEventData ( XEvent ) 
) AS src; 
 
/* Using the following T-SQL, you can examine the  Deadlock Graph  , and you can also return details of the 
statements involved in the deadlock. */
;WITH SystemHealth 
AS ( 
SELECT CAST(target_data AS xml) AS SessionXML 
FROM sys.dm_xe_session_targets st 
INNER JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address 
WHERE name = 'system_health' 
) 
SELECT Deadlock.value('@timestamp', 'datetime') AS DeadlockDateTime 
,CAST(Deadlock.value('(data/value)[1]', 'varchar(max)') as xml) as DeadlockGraph 
FROM SystemHealth s 
CROSS APPLY SessionXML.nodes ('//RingBufferTarget/event') AS t (Deadlock) 
WHERE Deadlock.value('@name', 'nvarchar(128)') = 'xml_deadlock_report'; 
       
/*based on SQL Server MCM, Wayne Sheffield’s XML Shred Deadlock script, which 
can be accessed in its original form at http://bit.ly/ShredDL
    This script here gets the data more reliably from the current event file target. */
DECLARE @deadlock TABLE ( 
DeadlockID INT IDENTITY PRIMARY KEY CLUSTERED, 
DeadlockGraph XML 
); 
WITH cte1 AS 
( 
SELECT    target_data = convert(XML, target_data) 
FROM    sys.dm_xe_session_targets t 
JOIN sys.dm_xe_sessions s 
ON t.event_session_address = s.address 
WHERE    t.target_name = 'event_file' 
AND        s.name = 'system_health' 
), cte2 AS 
( 
SELECT    [FileName] = FileEvent.FileTarget.value('@name', 'varchar(1000)') 
FROM    cte1 
CROSS APPLY cte1.target_data.nodes('//EventFileTarget/File') FileEvent(FileTarget) 
), cte3 AS 
( 
SELECT    event_data = CONVERT(XML, t2.event_data) 
FROM    cte2 
CROSS APPLY sys.fn_xe_file_target_read_file(cte2.[FileName], NULL, NULL, NULL) t2 
WHERE    t2.object_name = 'xml_deadlock_report' 
) 
INSERT INTO @deadlock(DeadlockGraph) 
SELECT  Deadlock = Deadlock.Report.query('.') 
FROM    cte3 
CROSS APPLY cte3.event_data.nodes('//event/data/value/deadlock') Deadlock(Report); 
-- use below to load individual deadlocks. 
INSERT INTO @deadlock VALUES (''); 
-- Insert the deadlock XML in the above line! 
-- Duplicate as necessary for additional graphs. 
WITH CTE AS 
( 
SELECT  DeadlockID, 
DeadlockGraph 
FROM    @deadlock 
), Victims AS 
( 
SELECT    ID = Victims.List.value('@id', 'varchar(50)') 
FROM      CTE 
CROSS APPLY CTE.DeadlockGraph.nodes('//deadlock/victim-list/victimProcess') AS 
Victims (List) 
), Locks AS 
( 
-- Merge all of the lock information together. 
SELECT  CTE.DeadlockID, 
MainLock.Process.value('@id', 'varchar(100)') AS LockID, 
OwnerList.Owner.value('@id', 'varchar(200)') AS LockProcessId, 
REPLACE(MainLock.Process.value('local-name(.)', 'varchar(100)'), 'lock', '') AS 
LockEvent, 
MainLock.Process.value('@objectname', 'sysname') AS ObjectName, 
OwnerList.Owner.value('@mode', 'varchar(10)') AS LockMode, 
MainLock.Process.value('@dbid', 'INTEGER') AS Database_id, 
MainLock.Process.value('@associatedObjectId', 'BIGINT') AS AssociatedObjectId, 
MainLock.Process.value('@WaitType', 'varchar(100)') AS WaitType, 
WaiterList.Owner.value('@id', 'varchar(200)') AS WaitProcessId, 
WaiterList.Owner.value('@mode', 'varchar(10)') AS WaitMode 
FROM    CTE 
CROSS APPLY CTE.DeadlockGraph.nodes('//deadlock/resource-list') AS Lock (list) 
CROSS APPLY Lock.list.nodes('*') AS MainLock (Process) 
OUTER APPLY MainLock.Process.nodes('owner-list/owner') AS OwnerList (Owner) 
CROSS APPLY MainLock.Process.nodes('waiter-list/waiter') AS WaiterList (Owner) 
), Process AS 
( 
-- get the data from the process node 
SELECT  CTE.DeadlockID, 
[Victim] = CONVERT(BIT, CASE WHEN Deadlock.Process.value('@id', 'varchar(50)') = 
ISNULL(Deadlock.Process.value('../../@victim', 'varchar(50)'), v.ID) 
THEN 1 
ELSE 0 
END), 
[LockMode] = Deadlock.Process.value('@lockMode', 'varchar(10)'), 
[ProcessID] = Process.ID, --Deadlock.Process.value('@id', 'varchar(50)'), 
[KPID] = Deadlock.Process.value('@kpid', 'int'), -- kernel-process id / thread ID number 
[SPID] = Deadlock.Process.value('@spid', 'int'), -- system process id (connection to sql) 
[SBID] = Deadlock.Process.value('@sbid', 'int'), -- system batch id / request_id (a query that a SPID is running) 
[ECID] = Deadlock.Process.value('@ecid', 'int'), -- execution context ID (a worker thread running part of a query) 
[IsolationLevel] = Deadlock.Process.value('@isolationlevel', 'varchar(200)'), 
[WaitResource] = Deadlock.Process.value('@waitresource', 'varchar(200)'), 
[LogUsed] = Deadlock.Process.value('@logused', 'int'), 
[ClientApp] = Deadlock.Process.value('@clientapp', 'varchar(100)'), 
[HostName] = Deadlock.Process.value('@hostname', 'varchar(20)'), 
[LoginName] = Deadlock.Process.value('@loginname', 'varchar(20)'), 
[TransactionTime] = Deadlock.Process.value('@lasttranstarted', 'datetime'), 
[BatchStarted] = Deadlock.Process.value('@lastbatchstarted', 'datetime'), 
[BatchCompleted] = Deadlock.Process.value('@lastbatchcompleted', 'datetime'), 
[InputBuffer] = Input.Buffer.query('.'), 
CTE.[DeadlockGraph], 
es.ExecutionStack, 
[QueryStatement] = Execution.Frame.value('.', 'varchar(max)'), 
ProcessQty = SUM(1) OVER (PARTITION BY CTE.DeadlockID), 
TranCount = Deadlock.Process.value('@trancount', 'int') 
FROM    CTE 
CROSS APPLY CTE.DeadlockGraph.nodes('//deadlock/process-list/process') AS Deadlock 
(Process) 
CROSS APPLY (SELECT Deadlock.Process.value('@id', 'varchar(50)') ) AS Process (ID) 
LEFT JOIN Victims v ON Process.ID = v.ID 
CROSS APPLY Deadlock.Process.nodes('inputbuf') AS Input (Buffer) 
CROSS APPLY Deadlock.Process.nodes('executionStack') AS Execution (Frame) 
-- get the data from the executionStack node as XML 
CROSS APPLY (SELECT ExecutionStack = (SELECT   ProcNumber = ROW_NUMBER() 
OVER (PARTITION BY CTE.DeadlockID, 
Deadlock.Process.value('@id', 'varchar(50)'), 
Execution.Stack.value('@procname', 'sysname'), 
Execution.Stack.value('@code', 'varchar(MAX)') 
ORDER BY (SELECT 1)), 
ProcName = Execution.Stack.value('@procname', 'sysname'), 
Line = Execution.Stack.value('@line', 'int'), 
SQLHandle = Execution.Stack.value('@sqlhandle', 'varchar(64)'), 
Code = LTRIM(RTRIM(Execution.Stack.value('.', 'varchar(MAX)'))) 
FROM Execution.Frame.nodes('frame') AS Execution (Stack) 
ORDER BY ProcNumber 
FOR XML PATH('frame'), ROOT('executionStack'), TYPE ) 
) es 
) 
-- get the columns in the desired order 
SELECT  p.DeadlockID, 
p.Victim, 
p.ProcessQty, 
ProcessNbr = DENSE_RANK() 
OVER (PARTITION BY p.DeadlockId 
ORDER BY p.ProcessID), 
p.LockMode, 
LockedObject = NULLIF(l.ObjectName, ''), 
l.database_id, 
l.AssociatedObjectId, 
LockProcess = p.ProcessID, 
p.KPID, 
p.SPID, 
p.SBID, 
p.ECID, 
p.TranCount, 
l.LockEvent, 
LockedMode = l.LockMode, 
l.WaitProcessID, 
l.WaitMode, 
p.WaitResource, 
l.WaitType, 
p.IsolationLevel, 
p.LogUsed, 
p.ClientApp, 
p.HostName, 
p.LoginName, 
p.TransactionTime, 
p.BatchStarted, 
p.BatchCompleted, 
p.QueryStatement, 
p.InputBuffer, 
p.DeadlockGraph, 
p.ExecutionStack 
FROM    Process p 
LEFT JOIN Locks l 
ON p.DeadlockID = l.DeadlockID 
AND p.ProcessID = l.LockProcessID 
ORDER BY p.DeadlockId, 
p.Victim DESC, 
p.ProcessId; 