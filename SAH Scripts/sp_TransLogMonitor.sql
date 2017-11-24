USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_TransLogMonitor]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[sp_TransLogMonitor]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[sp_TransLogMonitor]
AS
BEGIN

	IF OBJECT_ID('tempdb..#TransLogMonitor') IS NOT NULL DROP TABLE #TransLogMonitor;
	CREATE TABLE #TransLogMonitor
	(
		DatabaseName VARCHAR(100) NOT NULL,
		LogSizeMB DECIMAL(18, 2) NOT NULL,
		LogSpaceUsed DECIMAL(18, 2) NOT NULL,
		[Status] INT NOT NULL,
		VLF_count INT
	)

	IF OBJECT_ID('tempdb..#LogInfo2012') IS NOT NULL DROP TABLE #LogInfo2012;
	CREATE TABLE #LogInfo2012
	(
		recoveryunitid INT ,
		FileID SMALLINT ,
		FileSize BIGINT ,
		StartOffset BIGINT ,
		FSeqNo BIGINT ,
		[Status] TINYINT ,
		Parity TINYINT ,
		CreateLSN NUMERIC(38)
	)

	IF OBJECT_ID('tempdb..#LogInfo') IS NOT NULL DROP TABLE #LogInfo;
	CREATE TABLE #LogInfo
	(
		FileID SMALLINT ,
		FileSize BIGINT ,
		StartOffset BIGINT ,
		FSeqNo BIGINT ,
		[Status] TINYINT ,
		Parity TINYINT ,
		CreateLSN NUMERIC(38)
	)

	IF OBJECT_ID('tempdb..#results') IS NOT NULL DROP TABLE #results;
	CREATE TABLE #results
	(
		Database_Name   SYSNAME
	  , VLF_count       INT 
	)

	INSERT INTO #TransLogMonitor(DatabaseName, LogSizeMB, LogSpaceUsed, [Status])
	EXEC ('DBCC SQLPERF(logspace)')

	IF @@VERSION LIKE 'Microsoft SQL Server 2012%' OR @@VERSION LIKE 'Microsoft SQL Server 2014%'
	BEGIN
		EXEC sp_MSforeachdb N'USE [?];
			  INSERT INTO #LogInfo2012
			  EXEC sp_executesql N''DBCC LogInfo() WITH NO_INFOMSGS'';

			  Insert Into #results 
			  Select DB_Name(), Count(*)
			  From #LogInfo2012;
	          
			  Truncate Table #LogInfo2012;'

		DROP TABLE #LogInfo2012;
	END
	ELSE
	BEGIN
		EXEC sp_MSforeachdb N'USE [?];
			INSERT INTO #LogInfo
			EXEC sp_executesql N''DBCC LogInfo() WITH NO_INFOMSGS'';

			 Insert Into #results 
			 Select DB_Name(), Count(*)
			 From #LogInfo;
	          
			 Truncate Table #LogInfo;'
	                  
		DROP TABLE #LogInfo;
	END

	IF NOT EXISTS (SELECT 1 FROM TransLogMonitor WHERE CONVERT(DATE, LogDate) = CONVERT(DATE, GETDATE()))
	BEGIN
		INSERT INTO TransLogMonitor(DatabaseName, LogSizeMB, LogSpaceUsed, [Status], VLF_count)
		SELECT t.DatabaseName, t.LogSizeMB, t.LogSpaceUsed, t.[Status],r.VLF_count
		FROM #TransLogMonitor t
		INNER JOIN #results r
			ON t.DatabaseName = r.Database_Name
	END
	
	DROP TABLE #TransLogMonitor
	DROP TABLE #results
END


GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
