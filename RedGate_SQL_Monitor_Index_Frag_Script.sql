--vm-monitor-01
use RedgateSQLMonitor;
GO
SELECT	IV.CollectionDate_DateTime
	, IV.Cluster_Name
	, IV.Cluster_SqlServer_Database_Name
	, IV.Cluster_SqlServer_Database_Table_Schema
	, IV.Cluster_SqlServer_Database_Table_Name
	, IV.Cluster_SqlServer_Database_Table_Index_Name
	, IV.Cluster_SqlServer_Database_Table_Index_Fragmentation
	, IV.Cluster_SqlServer_Database_Table_Index_Pages
FROM	[data].Cluster_SqlServer_Database_Table_Index_UnstableSamples_View AS IV
WHERE	IV.Cluster_Name = 'vm-db-prod-02'
AND		IV.Cluster_SqlServer_Database_Table_Index_Fragmentation > 0.3
AND		IV.Cluster_SqlServer_Database_Table_Index_Pages > 1000
AND		IV.CollectionDate_DateTime > '20190304'


-- Execute in the server with fragmentation
/****
USE master
GO
EXECUTE [dbo].[IndexOptimize]
@Databases  = 'ASU',
@FragmentationLow  = NULL,
@FragmentationMedium  = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh  = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 10,
@FragmentationLevel2 = 30,
@MinNumberOfPages = 1000,
@SortInTempdb = 'Y',
@MaxDOP = 4,
--@FillFactor = 90,
@PadIndex  = NULL,
@LOBCompaction  = 'Y',
@PartitionLevel = 'Y',
@MSShippedObjects  = 'N',
@Indexes  = 'ASU.dbo.FD_SDA_ENTITY_OTHER_IDS',
@TimeLimit = NULL,
@Delay = NULL,
@WaitAtLowPriorityMaxDuration = NULL,
@WaitAtLowPriorityAbortAfterWait = NULL,
@LockTimeout = NULL,
@LogToTable = 'Y',
@Execute = 'Y'

******/
