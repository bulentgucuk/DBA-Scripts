--CREATE PROCEDURE [MetaBOT].[usp_LogWatch] AS 
DECLARE @SQL VARCHAR(5000) 
--Clean up temp objects if not properly done so previously 
IF EXISTS (SELECT NAME FROM tempdb..sysobjects WHERE NAME = '#usp_LogWatch_Results') 
   BEGIN 
       DROP TABLE #usp_LogWatch_Results 
   END 
--Create temporary table to store results 
CREATE TABLE #usp_LogWatch_Results ([Database Name] sysname, [File Type] VARCHAR(4), [Total Size in Mb] INT) 
--Create SQL script to run against all databases on the instance 
SELECT @SQL = 
'USE [?] 
INSERT INTO #usp_LogWatch_Results([Database Name], [File Type], [Total Size in Mb]) 
SELECT DB_NAME(), [File Type] = 
CASE type 
WHEN 0 THEN ''Data''' 
+ 
           'WHEN 1 THEN ''Log''' 
+ 
       'END, 
[Total Size in Mb] = 
CASE ceiling([size]/128) 
WHEN 0 THEN 1 
ELSE ceiling([size]/128) 
END 
FROM sys.database_files 
'
--Run the command against each database 
EXEC sp_MSforeachdb @SQL 
SELECT D.[Database Name], D.[Total Data File Size In Mb], L.[Total Log File Size In Mb], 
        CAST(CAST(L.[Total Log File Size In Mb] AS decimal(8,1))/CAST(D.[Total Data File Size In Mb] 
             AS decimal(8,1)) AS decimal(4,2)) AS [Log::Data Ratio] 
FROM 
        ( 
        SELECT [Database Name], [File Type], SUM([Total Size in Mb]) AS [Total Data File Size In Mb] 
        FROM #usp_LogWatch_Results 
        WHERE [File Type] = 'Data' 
        GROUP BY [Database Name], [File Type] 
        ) AS D INNER JOIN 
        ( 
        SELECT [Database Name], [File Type], SUM([Total Size in Mb]) AS [Total Log File Size In Mb] 
        FROM #usp_LogWatch_Results 
        WHERE [File Type] = 'Log' 
        GROUP BY [Database Name], [File Type] 
        ) AS L ON D.[Database Name] = L.[Database Name] 
WHERE L.[Total Log File Size In Mb] > 500 AND 
        CAST(CAST(L.[Total Log File Size In Mb] AS decimal(8,1))/CAST(D.[Total Data File Size In Mb] 
             AS decimal(8,1)) AS decimal(4,2)) > 0.5 
ORDER BY CAST(CAST(L.[Total Log File Size In Mb] AS decimal(8,1))/CAST(D.[Total Data File Size In Mb] 
             AS decimal(8,1)) AS decimal(4,2)) DESC, 
        L.[Total Log File Size In Mb] DESC 
--Clean up your temporary objects 
DROP TABLE #usp_LogWatch_Results 