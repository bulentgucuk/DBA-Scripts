Written by Paul S. Randal, SQLskills.com
 
  (c) 2014, SQLskills.com. All rights reserved.
 
  For more scripts and sample code, check out
 
  For more scripts and sample code, check out http://www.SQLskills.com
 
  You may alter this code for your own *non-commercial* purposes (e.g. in a
  for-sale commercial tool). Use in your own environment is encouraged.
  You may republish altered code as long as you include this copyright and
  give due credit, but you must obtain prior permission before blogging
  this code.
 
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.

SELECT

--virtual file latency

[ReadLatency] =

CASE WHEN [num_of_reads] = 0

THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END,

[WriteLatency] =

CASE WHEN [num_of_writes] = 0

THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END,

[Latency] =

CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)

THEN 0 ELSE ([io_stall] / ([num_of_reads] + [num_of_writes])) END,

--avg bytes per IOP

[AvgBPerRead] =

CASE WHEN [num_of_reads] = 0

THEN 0 ELSE ([num_of_bytes_read] / [num_of_reads]) END,

[AvgBPerWrite] =

CASE WHEN [num_of_writes] = 0

THEN 0 ELSE ([num_of_bytes_written] / [num_of_writes]) END,

[AvgBPerTransfer] =

CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)

THEN 0 ELSE

(([num_of_bytes_read] + [num_of_bytes_written]) /

([num_of_reads] + [num_of_writes])) END,

LEFT ([mf].[physical_name], 2) AS [Drive],

DB_NAME ([vfs].[database_id]) AS [DB],

--[vfs].*,

[mf].[physical_name]

FROM

sys.dm_io_virtual_file_stats (NULL,NULL) AS [vfs]

JOIN sys.master_files AS [mf]

ON [vfs].[database_id] = [mf].[database_id]

AND [vfs].[file_id] = [mf].[file_id]

-- WHERE [vfs].[file_id] = 2 -- log files

-- ORDER BY [Latency] DESC

-- ORDER BY [ReadLatency] DESC

ORDER BY [WriteLatency] DESC;

GO 