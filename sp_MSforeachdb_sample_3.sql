USE master;
GO
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
DECLARE @SQL_command_01 VARCHAR(2000);
SET @SQL_command_01 = 
'USE [?]
IF EXISTS (SELECT 1 FROM sys.databases WHERE name LIKE ''%_Integration%'' and name = ''?'' and is_read_only = 0) --Chiefs_Integration2
BEGIN
	declare @message nvarchar(4000)
	set @message = ''?''
	raiserror (@message,0,1) with nowait
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
ORDER BY dbf.type_desc DESC, dbf.file_id;

END'
INSERT INTO #DbSize
EXEC SP_MSFOREACHDB @command1 = @SQL_command_01;
