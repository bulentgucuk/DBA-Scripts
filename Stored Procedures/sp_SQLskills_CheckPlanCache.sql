USE master
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_SQLskills_CheckPlanCache')
	EXEC ('CREATE PROC dbo.sp_SQLskills_CheckPlanCache AS SELECT ''stub version, to be replaced''')
GO

ALTER PROCEDURE dbo.sp_SQLskills_CheckPlanCache
	(@Percent	decimal(6,3) OUTPUT,
	 @WastedMB	decimal(19,3) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @ConfiguredMemory	decimal(19,3)
	, @PhysicalMemory		decimal(19,3)
	, @MemoryInUse			decimal(19,3)
	, @SingleUsePlanCount	bigint

CREATE TABLE #ConfigurationOptions
(
	[name]				nvarchar(35)
	, [minimum]			int
	, [maximum]			int
	, [config_value]	int				-- in bytes
	, [run_value]		int				-- in bytes
);
INSERT #ConfigurationOptions EXEC ('sp_configure ''max server memory''');

SELECT @ConfiguredMemory = run_value/1024/1024 
FROM #ConfigurationOptions 
WHERE name = 'max server memory (MB)'

SELECT @PhysicalMemory = total_physical_memory_kb/1024 
FROM sys.dm_os_sys_memory

SELECT @MemoryInUse = physical_memory_in_use_kb/1024 
FROM sys.dm_os_process_memory

SELECT @WastedMB = sum(cast((CASE WHEN usecounts = 1 AND objtype IN ('Adhoc', 'Prepared') 
								THEN size_in_bytes ELSE 0 END) AS DECIMAL(12,2)))/1024/1024 
	, @SingleUsePlanCount = sum(CASE WHEN usecounts = 1 AND objtype IN ('Adhoc', 'Prepared') 
								THEN 1 ELSE 0 END)
	, @Percent = @WastedMB/@MemoryInUse * 100
FROM sys.dm_exec_cached_plans

SELECT	[TotalPhysicalMemory (MB)] = @PhysicalMemory
	, [TotalConfiguredMemory (MB)] = @ConfiguredMemory
	, [MaxMemoryAvailableToSQLServer (%)] = @ConfiguredMemory/@PhysicalMemory * 100
	, [MemoryInUseBySQLServer (MB)] = @MemoryInUse
	, [TotalSingleUsePlanCache (MB)] = @WastedMB
	, TotalNumberOfSingleUsePlans = @SingleUsePlanCount
	, [PercentOfConfiguredCacheWastedForSingleUsePlans (%)] = @Percent

