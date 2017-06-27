/**********************************************************************
 * Name:        GetFileSpaceStats
 * Author:      Jonathan Kehayias
 * Date:        28 October 2008
 * Database:    DBA_Data
 *
 * Purpose:
 * Checks each database file on the Server for Percent Free Space and 
 * logs the values for all files to the FileSpaceStats table for 
 * historical analysis.  
 * 
 *
 * Changes
 **********************************************************************
 * No Changes
 *
 **********************************************************************/
CREATE PROCEDURE [dbo].[GetFileSpaceStats] (@RunLocal bit = 0)
AS
BEGIN 
 
/*
DECLARE @RunLocal bit
SET @RUnLocal = 1
*/
DECLARE @dbName sysname 
 
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE name = 'FileSpaceStats' AND type='U') 
BEGIN 
	CREATE TABLE [dbo].[FileSpaceStats] 
	( 
		Server_Name sysname NOT NULL, 
		dbName sysname NOT NULL, 
		Flag bit NULL, 
		Fileid tinyint NULL, 
		FileGroup sysname NULL, 
		Total_Space decimal(20, 1) NULL, 
		UsedSpace decimal(20, 1) NULL, 
		FreeSpace decimal(20, 1) NULL, 
		FreePct decimal(20, 3) NULL, 
		Name varchar(250) NULL, 
		FileName sysname NULL , 
		Report_Date datetime default getdate() 
	)
	--ON PRIMARY 
END 
 
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE name LIKE '#FileSpaceStats%') 
BEGIN
	DROP TABLE #FileSpaceStats 
END
 
CREATE TABLE #FileSpaceStats
(
	RowID int IDENTITY PRIMARY KEY, 
	Server_Name sysname NOT NULL, 
	dbName sysname NOT NULL, 
	Flag bit NULL, 
	Fileid tinyint NULL, 
	FileGroup sysname NULL, 
	Total_Space decimal(20, 1) NULL, 
	UsedSpace decimal(20, 1) NULL, 
	FreeSpace decimal(20, 1) NULL, 
	FreePct decimal(20, 3) NULL, 
	Name varchar(2500) NULL, 
	FileName sysname NULL , 
	Report_Date datetime default getdate()
)
 
 
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE name LIKE '#DataFileStats%') 
BEGIN
	DROP TABLE #DataFileStats 
END
 
CREATE TABLE #DataFileStats 
( 
	RowID int IDENTITY PRIMARY KEY,
	Flag bit default 0, 
	Fileid tinyint, 
	FileGroup tinyint, 
	TotalExtents dec (20, 1), 
	UsedExtents dec (20, 1), 
	Name varchar(250), 
	FileName sysname 
) 
 
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE name LIKE '#LogSpaceStats%') 
BEGIN
	DROP TABLE #LogSpaceStats 
END
CREATE TABLE #LogSpaceStats 
( 
	RowID int IDENTITY PRIMARY KEY,
	dbName sysname, 
	Flag bit default 1, 
	Totallogspace dec (20, 1), 
	UsedLogSpace dec (20, 1), 
	Status char(1) 
) 
 
DECLARE @string sysname 
DECLARE cur_dbName CURSOR FOR 
 
SELECT name 
FROM master..sysdatabases
 
OPEN cur_dbName 
 
FETCH NEXT FROM cur_dbName into @dbName 
WHILE @@FETCH_Status=0 
BEGIN 
 
	DELETE #DataFileStats
 
	SET @string = 'USE [' + @dbName + '] DBCC SHOWFILESTATS WITH NO_INFOMSGS' 
 
	INSERT INTO #DataFileStats (Fileid, FileGroup, TotalExtents, UsedExtents, Name, FileName) 
	EXEC (@string) 
 
	INSERT #FileSpaceStats (Server_Name, dbName, Flag, Fileid, FileGroup, Total_Space, 
										UsedSpace, FreeSpace, FreePct, Name, FileName)
 
	SELECT @@SERVERNAME, @dbName, Flag, Fileid, FileGroup_Name(FileGroup), (TotalExtents*64/1024), 
			(UsedExtents*64/1024), ((TotalExtents*64/1024)-(UsedExtents*64/1024)),
			(((TotalExtents*64/1024)-(UsedExtents*64/1024))*100/(TotalExtents*64/1024))/100,
			Name, FileName
	FROM #DataFileStats 
 
FETCH NEXT FROM cur_dbName into @dbName 
END 
CLOSE cur_dbName 
DEALLOCATE cur_dbName 
 
 
 
INSERT #LogSpaceStats (dbName, Totallogspace, UsedLogSpace, Status) 
EXEC ('DBCC sqlperf(logspace) WITH NO_INFOMSGS') 
 
INSERT #FileSpaceStats (Server_Name, dbName, Flag, Fileid, FileGroup, Total_Space, 
					UsedSpace, FreeSpace, FreePct, Name, FileName)
SELECT @@SERVERNAME, dbName, Flag, 0, 'LOG', Totallogspace, (TotalLogSpace*(UsedLogSpace/100)),
	 (TotalLogSpace-(TotalLogSpace*(UsedLogSpace/100))), (100-UsedLogSpace)/100, dbName+'_Log',
	  dbName+'_Log.ldf'
FROM #LogSpaceStats 
 
INSERT dbo.FileSpaceStats 
	(Server_Name, dbName, Flag, Fileid, FileGroup, Total_Space, UsedSpace, 
		FreeSpace, FreePct, Name, FileName)
SELECT Server_Name, dbName, Flag, Fileid, FileGroup, Total_Space, UsedSpace, 
		FreeSpace, FreePct, Name, FileName
FROM #FileSpaceStats
 
IF @RunLocal = 1
BEGIN
  SELECT * FROM #FileSpaceStats
END
ELSE
BEGIN	
		DECLARE @Loop int
		DECLARE @Subject varchar(100)
		DECLARE @strMsg varchar(4000)
 
		SELECT @Subject = 'SQL Monitor Alert: ' + @@servername
 
		SELECT @Loop = min(RowID)
		FROM #FileSpaceStats
		WHERE FreePct <= .10
 
		WHILE @Loop IS NOT NULL
		BEGIN
 
			SELECT 	@strMsg =  convert(char(15),'Database:') + isnull(dbName, 'Unknown') + char(10) +
					convert(char(15),'FileGroup:') + isnull(FileGroup, 'Unknown') + char(10) +
					convert(char(15),'FileName:') + isnull(Name, 'Unknown') + char(10) +
					convert(char(15),'') + convert(varchar, convert(decimal(18,1), FreePct*100)) + '% free space remaining.'+ char(10) +
					convert(char(15),'') + char(10) +
					convert(char(15),'EventTime:') + convert(varchar, getdate())
			FROM #FileSpaceStats
			WHERE RowID = @Loop
 
			EXEC dbo.SendEmailNotification @Subject, @strMsg
 
			SELECT @Loop = min(RowID)
			FROM #FileSpaceStats
			WHERE FreePct <= .10
			  AND RowID > @Loop
 
		END
 
END
 
DROP TABLE #FileSpaceStats
DROP TABLE #DataFileStats 
DROP TABLE #LogSpaceStats 
 
END 