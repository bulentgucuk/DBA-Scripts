SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#DbSize') IS NOT NULL
	DROP TABLE #DbSize
CREATE TABLE #DbSize (
	  DatabaseName SYSNAME
	, DatabaseId INT NOT NULL
	, DBFileName SYSNAME
	, FileId INT NOT NULL
	, PhysicalDBFileName VARCHAR(1024)
	, FileType VARCHAR(32)
	, TotalSpace DECIMAL(19,2)
	, SpaceUsed DECIMAL(19,2)
	, FreeSpaceInMB DECIMAL(19,2)
	, DBFileGroupName VARCHAR(128)
	, DataFGDesc VARCHAR(128)
	, ISDefaultFileGroup BIT
	)
INSERT INTO #DbSize
EXEC SP_MSFOREACHDB
'USE [?];
SELECT	DB_NAME() AS DatabaseName,
		DB_ID() AS DatabaseId,
		dbf.Name AS DBFileName,
		dbf.File_id AS FileId,
		dbf.physical_name AS PhysicalDBFileName,
		dbf.Type_Desc AS FileType,
		STR((dbf.Size/128.0),10,2) AS TotalSpace,
		CAST(FILEPROPERTY(dbf.name, ''SpaceUsed'')/128.0  AS DECIMAL(9,2)) AS SpaceUsed,
		STR((Size/128.0 - CAST(FILEPROPERTY(dbf.name, ''SpaceUsed'') AS int)/128.0),9,2) AS FreeSpaceInMB,
		dbfg.Name AS DBFileGroupName,
		dbfg.type_desc AS DataFGDesc,
		dbfg.is_default AS ISDefaultFileGroup
FROM	sys.database_files AS dbf
	LEFT OUTER JOIN sys.data_spaces AS dbfg ON dbf.data_space_id = dbfg.data_space_id
ORDER BY dbf.type_desc DESC, dbf.file_id;'

SELECT	*
FROM	#DbSize

SELECT	DatabaseName, sum(totalspace/1024) as DatabaseFileSizeInGB, sum(spaceused/1024) as SpaceUsedInGB, sum(freespaceinMB/1024) as FreeSpaceInGB
FROM	#DbSize
where	DatabaseId > 4
and		DatabaseName <> 'dba'
and		FileId <> 2
group by DatabaseName
order by DatabaseName

-- DROP TABLE #DbSize
