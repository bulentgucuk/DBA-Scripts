
-- Find the available space in each file
SELECT	File_id AS FileId,
		Name,
		Type_Desc AS FileType,
		STR((Size/128.0),10,2) AS TotalSpace,
		--CAST(FILEPROPERTY(name, 'SpaceUsed')/128.0  AS INT) AS SpaceUsed,
		CAST(FILEPROPERTY(name, 'SpaceUsed')/128.0  AS DECIMAL(9,2)) AS SpaceUsed,
		STR((Size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0),9,2) AS FreeSpaceInMB
FROM sys.database_files
ORDER BY NAME