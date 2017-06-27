--Run this command to display the fragmentation for the database
--DBCC Showcontig with tableresults, All_Indexes

--Run this query to perform the re-index.
/*
DECLARE @TableName varchar(100)
DECLARE @StartTime datetime
DECLARE @TotalTime int
DECLARE Cur_Tables CURSOR FOR 
SELECT [Name] from sysobjects
WHERE OBJECTPROPERTY(id, N'IsUserTable') = 1
AND NAME != 'dtproperties'
AND NAME != 'VisitorPageHits' --Uncomment these entries for exclusions
AND NAME != 'VisitorSessions'
Order By [Name] Asc
OPEN Cur_Tables
FETCH NEXT FROM Cur_Tables 
INTO @TableName
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @StartTime = GetDate()
	DBCC DBREINDEX (@TableName, '', 0) WITH NO_INFOMSGS
	SET  @TotalTime = DATEDIFF(ss, @StartTime, GetDate())
	Print 'Re-indexing of ' + @TableName + ' took ' + CAST(@TotalTime AS varchar(20)) + ' seconds.'
   	FETCH NEXT FROM Cur_Tables 
   	INTO @TableName
END
CLOSE Cur_Tables
DEALLOCATE Cur_Tables
GO
*/