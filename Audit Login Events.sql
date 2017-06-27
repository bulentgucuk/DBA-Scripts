/****************************************************/
/* Created by: SQL Server Profiler 2005             */
/* Date: 05/23/2013  10:12:29 AM         */
/****************************************************/
-- Trace to audit login events to SQL Server grouped by database name

-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
declare @DateTime datetime

set @DateTime = '2013-05-31 09:00:00.000'
set @maxfilesize = 1024

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec @rc = sp_trace_create @TraceID output, 0, N'F:\AuditLoginTraceFile', @maxfilesize, @Datetime
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 14, 7, @on
exec sp_trace_setevent @TraceID, 14, 23, @on
exec sp_trace_setevent @TraceID, 14, 8, @on
exec sp_trace_setevent @TraceID, 14, 6, @on
exec sp_trace_setevent @TraceID, 14, 10, @on
exec sp_trace_setevent @TraceID, 14, 14, @on
exec sp_trace_setevent @TraceID, 14, 26, @on
exec sp_trace_setevent @TraceID, 14, 11, @on
exec sp_trace_setevent @TraceID, 14, 35, @on
exec sp_trace_setevent @TraceID, 14, 12, @on
exec sp_trace_setevent @TraceID, 20, 7, @on
exec sp_trace_setevent @TraceID, 20, 23, @on
exec sp_trace_setevent @TraceID, 20, 31, @on
exec sp_trace_setevent @TraceID, 20, 8, @on
exec sp_trace_setevent @TraceID, 20, 12, @on
exec sp_trace_setevent @TraceID, 20, 6, @on
exec sp_trace_setevent @TraceID, 20, 10, @on
exec sp_trace_setevent @TraceID, 20, 14, @on
exec sp_trace_setevent @TraceID, 20, 26, @on
exec sp_trace_setevent @TraceID, 20, 11, @on
exec sp_trace_setevent @TraceID, 20, 35, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go
-- BQDBXX0000 TRACEID = 3 E:\AuditLoginTraceFile
-- BQDBXX0012 TRACEID = 3 E:\AuditLoginTraceFile
-- BQDBXX0017 TRACEID = 2 F:\AuditLoginTraceFile