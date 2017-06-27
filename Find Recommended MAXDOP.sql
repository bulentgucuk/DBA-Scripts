/*************************************************************************
Author          :   Dennis Winter (Thought: Adapted from a script from "Kin Shah")
Purpose         :   Recommend MaxDop settings for the server instance
Tested RDBMS    :   SQL Server 2008R2
http://dba.stackexchange.com/questions/36522/what-is-a-good-repeatable-way-to-calculate-maxdop-on-sql-server
**************************************************************************/
declare @hyperthreadingRatio bit
declare @logicalCPUs int
declare @HTEnabled int
declare @physicalCPU int
declare @SOCKET int
declare @logicalCPUPerNuma int
declare @NoOfNUMA int
declare @MaxDOP int

select @logicalCPUs = cpu_count -- [Logical CPU Count]
    ,@hyperthreadingRatio = hyperthread_ratio --  [Hyperthread Ratio]
    ,@physicalCPU = cpu_count / hyperthread_ratio -- [Physical CPU Count]
    ,@HTEnabled = case 
        when cpu_count > hyperthread_ratio
            then 1
        else 0
        end -- HTEnabled
from sys.dm_os_sys_info
option (recompile);

select @logicalCPUPerNuma = COUNT(parent_node_id) -- [NumberOfLogicalProcessorsPerNuma]
from sys.dm_os_schedulers
where [status] = 'VISIBLE ONLINE'
    and parent_node_id < 64
group by parent_node_id
option (recompile);

select @NoOfNUMA = count(distinct parent_node_id)
from sys.dm_os_schedulers -- find NO OF NUMA Nodes 
where [status] = 'VISIBLE ONLINE'
    and parent_node_id < 64

IF @NoofNUMA > 1 AND @HTEnabled = 0
    SET @MaxDOP= @logicalCPUPerNuma 
ELSE IF  @NoofNUMA > 1 AND @HTEnabled = 1
    SET @MaxDOP=round( @NoofNUMA  / @physicalCPU *1.0,0)
ELSE IF @HTEnabled = 0
    SET @MaxDOP=@logicalCPUs
ELSE IF @HTEnabled = 1
    SET @MaxDOP=@physicalCPU

IF @MaxDOP > 10
    SET @MaxDOP=10
IF @MaxDOP = 0
    SET @MaxDOP=1

PRINT 'logicalCPUs : '         + CONVERT(VARCHAR, @logicalCPUs)
PRINT 'hyperthreadingRatio : ' + CONVERT(VARCHAR, @hyperthreadingRatio) 
PRINT 'physicalCPU : '         + CONVERT(VARCHAR, @physicalCPU) 
PRINT 'HTEnabled : '           + CONVERT(VARCHAR, @HTEnabled)
PRINT 'logicalCPUPerNuma : '   + CONVERT(VARCHAR, @logicalCPUPerNuma) 
PRINT 'NoOfNUMA : '            + CONVERT(VARCHAR, @NoOfNUMA)
PRINT '---------------------------'
Print 'MAXDOP setting should be : ' + CONVERT(VARCHAR, @MaxDOP)
EXEC sp_configure 'max degree of parallelism'