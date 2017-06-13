
-- Find the available space
SELECT name ,size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS AvailableSpaceInMB
FROM sys.database_files;

Declare @SQL VarChar(8000)
Set @SQL = 'DBCC SHOWFILESTATS WITH TABLERESULTS'
If Object_ID('tempdb.dbo.#UsedSpace') > 0
	Drop Table #UsedSpace
Create Table #UsedSpace (FileID SmallInt, FileGroup SmallInt, TotalExtents Int, UsedExtents Int, 
Name NVarChar(256), FileName NVarChar(512))
Insert Into #UsedSpace
Exec(@SQL)
Select Name, (TotalExtents * 64) / 1024 As 'TotalSpace',
(UsedExtents * 64) / 1024 As 'UsedSpace', 
((TotalExtents * 64) / 1024) - ((UsedExtents * 64) / 1024) As 'FreeSpace'
From #UsedSpace
order by Name
Drop Table #UsedSpace


DBCC SQLPERF(LOGSPACE)


DBCC LOGINFO('ODSQA')

