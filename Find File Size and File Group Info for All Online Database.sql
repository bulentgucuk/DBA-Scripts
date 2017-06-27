-- Find the available space in each file and file group data for all online databases
-- Clean up the temp table if exists
set nocount on;
if OBJECT_ID ('tempdb.dbo.#TempDbFiles') is not null
	drop table #TempDbFiles;

-- Create temp table
create table #TempDbFiles (
	DbName varchar(128),
	database_id smallint,
	FileId tinyint,
	DbFileName varchar(128),
	PhysicalDBFileName varchar(256),
	FileType varchar(10),
	TotalSpaceInMb decimal,
	SpaceUsedInMb decimal,
	FreeSpaceInMb decimal,
	DBFileGroupName varchar(128),
	DataFGDesc varchar(128),
	IsDefaultFileGroup bit
	);
declare @string varchar(1024);
declare	@dbname varchar(128);
declare	@Maxrowid int;
declare	@t table (
	RowId int identity(1,1),
	DbName varchar(128)
	);
insert	into @t
select	name
from	sys.databases
where	state = 0
order by name desc;


select	@Maxrowid = MAX(rowid) from @t;

while @Maxrowid > 0
	begin
		select	@dbname = DbName
		from	@t
		where	RowId = @Maxrowid;
		
		select	@string = 
		'use [' + @dbname + ']
		insert into #TempDbFiles 
		select	''' + @dbname + ''' as DbName,
				db_id(''' + @dbname + ''') as database_id,
				dbf.File_id AS FileId,
				dbf.Name AS DBFileName,
				dbf.physical_name AS PhysicalDBFileName,
				dbf.Type_Desc AS FileType,
				STR((dbf.Size/128.0),10,2) AS TotalSpaceInMb,
				--CAST(FILEPROPERTY(name, ''SpaceUsed'')/128.0  AS INT) AS SpaceUsed,
				CAST(FILEPROPERTY(dbf.name, ''SpaceUsed'')/128.0  AS DECIMAL(9,2)) AS SpaceUsedInMb,
				STR((Size/128.0 - CAST(FILEPROPERTY(dbf.name, ''SpaceUsed'') AS int)/128.0),9,2) AS FreeSpaceInMB,
				dbfg.Name AS DBFileGroupName,
				dbfg.type_desc AS DataFGDesc,
				dbfg.is_default AS ISDefaultFileGroup
		FROM	sys.database_files AS dbf
			LEFT OUTER JOIN sys.data_spaces AS dbfg
				ON dbf.data_space_id = dbfg.data_space_id
		ORDER BY dbf.type_desc DESC, dbf.file_id';

		--print @string;
		exec (@string);
		select	@Maxrowid = @Maxrowid - 1;
	end

select	*, getdate() as 'DataCollectionDate'
from	#TempDbFiles
--order by TotalSpaceInMb desc, SpaceUsedInMb asc
order by database_id,  FileId;

drop table #TempDbFiles;
