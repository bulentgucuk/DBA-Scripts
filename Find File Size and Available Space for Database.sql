-- Find the available space in each database file and file group data
SELECT	dbf.File_id AS FileId,
		dbf.Name AS DBFileName,
		dbf.physical_name AS PhysicalDBFileName,
		dbf.Type_Desc AS FileType,
		STR((dbf.Size/128.0),10,2) AS TotalSpace,
		--CAST(FILEPROPERTY(name, 'SpaceUsed')/128.0  AS INT) AS SpaceUsed,
		CAST(FILEPROPERTY(dbf.name, 'SpaceUsed')/128.0  AS DECIMAL(9,2)) AS SpaceUsed,
		STR((Size/128.0 - CAST(FILEPROPERTY(dbf.name, 'SpaceUsed') AS int)/128.0),9,2) AS FreeSpaceInMB,
		dbfg.Name AS DBFileGroupName,
		dbfg.type_desc AS DataFGDesc,
		dbfg.is_default AS ISDefaultFileGroup
FROM	sys.database_files AS dbf
	LEFT OUTER JOIN sys.data_spaces AS dbfg
		ON dbf.data_space_id = dbfg.data_space_id
ORDER BY dbf.type_desc DESC, dbf.file_id