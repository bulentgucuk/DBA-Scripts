/*
/*******************************************************************************************************************************************************************************************/
Written By: Tara Shankar Jana (SQL PFE- Microsoft)
Email id: tarasha@microsoft.com
Date:		1/07/2013
Purpose:	Provide a method to find the MaxServerMemory utilisation on a 64-bit environment
Applies to: SQL 2005, SQL 2008/R2, SQL 2012, SQL 2014

Change: John Balke
Date: 1/07/2013
Purpose: One script for all versions of SQL
Added: version logic flow

"Special Thanks to Matt lavery for recognizing the differences in the previous script and asking for creating a more appropriate script as per best practices"

Changes:
Who		    When		What
TaraSha     10/11/2011  Created the Script to determine the Buffer Pool distribution and optimal MaxServermemory setting
MLavery		10/12/2012	Changed to retrieve memory settings from sys.configurations view
TaraSha     1/07/2013   Updated the Script further as per best practices
                        Currently, i could only take care of option 1 as that gives me initial SQL Max memory configuration to get going

						There are 2 options which we have used in the past
                        1. "reserve 1 GB of RAM for the OS, 1 GB for each 4 GB of RAM installed from 4–16 GB, 
						    and then 1 GB for every 8 GB RAM installed above 16 GB RAM. 
							This has typically worked out well for servers that are dedicated to SQL Server. "

                        2. "((Total system memory) – (memory for thread stack) – (OS memory requirements ~ 2-4GB) – (memory for other applications) - (memory for multipage allocations; SQLCLR, linked servers, etc)), 
						   where the memory for thread stack = ((max worker threads) *(stack size)) and the stack size is 512KB for x86 systems, 2MB for x64 systems and 4MB for IA64 systems. 
						   The value for 'max worker threads' can be found in the max_worker_count column of sys.dm_os_sys_info "

Disclaimer:
This Sample Code is provided for the purpose of illustration only and is not intended to be 
used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED 
"AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant 
You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and 
distribute the object code form of the Sample Code, provided that You agree: (i) to not use 
Our name, logo, or trademarks to market Your software product in which the Sample Code is 
embedded; (ii) to include a valid copyright notice on Your software product in which the 
Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our 
suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise 
or result from the use or distribution of the Sample Code.
/*******************************************************************************************************************************************************************************************/
*/

SET NOCOUNT ON;

DECLARE 
--@pg_size INT, 
@Instancename varchar(50),
--@RecMem int,
@MaxMem int,
@MaxRamServer int,
@sql varchar(max),
@SQLVersion tinyint


SELECT @SQLVersion = @@MicrosoftVersion / 0x01000000  -- Get major version

-- SELECT physical_memory_kb as ServerRAM_KB from sys.dm_os_sys_info
-- SELECT @pg_size = low from master..spt_values where number = 1 and type = 'E'
-- SELECT @Instancename = LEFT([object_name], (CHARINDEX(':',[object_name]))) FROM sys.dm_os_performance_counters WHERE counter_name = 'Buffer cache hit ratio'
PRINT '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
PRINT 'Optimal MaxServermemory Setting for SQL Server instance ' + @@SERVERNAME  + ' (' + CAST(SERVERPROPERTY('productversion') AS VARCHAR) + ' - ' +  SUBSTRING(@@VERSION, CHARINDEX('X',@@VERSION),4)  + ' - ' + CAST(SERVERPROPERTY('edition') AS VARCHAR) + ')'
PRINT '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'

IF @SQLVersion in (12,11)
BEGIN
	PRINT '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
	PRINT 'Total Memory on the Server (MB)' 
	EXEC sp_executesql N'set @_MaxRamServer= (select physical_memory_kb/1024 from sys.dm_os_sys_info)', N'@_MaxRamServer int OUTPUT', @_MaxRamServer = @MaxRamServer OUTPUT
	Print @MaxRamServer
	PRINT '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
END
ELSE
IF @SQLVersion in (10,9)
BEGIN
	PRINT '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
	PRINT 'Total Memory on the Server (MB)' 
	EXEC sp_executesql N'set @_MaxRamServer= (select physical_memory_in_bytes/1024/1024 from sys.dm_os_sys_info)', N'@_MaxRamServer int OUTPUT', @_MaxRamServer = @MaxRamServer OUTPUT
	Print @MaxRamServer
	PRINT '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
END
ELSE 
BEGIN
	PRINT 'Script only supports SQL Server 2005 or later.'
	RETURN
END

--SELECT @RecMem=physical_memory_kb/1024 from sys.dm_os_sys_info

SET @MaxMem = CASE 
    WHEN @MaxRamServer < = 1024*2 THEN @MaxRamServer - 512  /*When the RAM is Less than or equal to 2GB*/
    WHEN @MaxRamServer < = 1024*4 THEN @MaxRamServer - 1024 /*When the RAM is Less than or equal to 4GB*/
    WHEN @MaxRamServer < = 1024*16 THEN @MaxRamServer - 1024 - Ceiling((@MaxRamServer-4096) / (4.0*1024))*1024 /*When the RAM is Less than or equal to 16GB*/

	-- My machines memory calculation
	-- RAM= 16GB
	-- Case 3 as above:- 16384 RAM-> MaxMem= 16384-1024-[(16384-4096)/4096] *1024
	-- MaxMem= 12106

    WHEN @MaxRamServer > 1024*16 THEN @MaxRamServer - 4096 - Ceiling((@MaxRamServer-1024*16) / (8.0*1024))*1024 /*When the RAM is Greater than or equal to 16GB*/
     END
 SET @sql='
EXEC sp_configure ''Show Advanced Options'',1;
RECONFIGURE WITH OVERRIDE;
EXEC sp_configure ''max server memory'','+CONVERT(VARCHAR(6), @MaxMem)+';
RECONFIGURE WITH OVERRIDE;'

PRINT '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
PRINT 'Optimal MaxServerMemory Setting for this instance of SQL' 
Print (@sql) 

 /* Do not execute the statement, print it and then execute it once verified with the second condition as mentioned in the comments section)*/
   --EXEC (@sql);
PRINT '------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
