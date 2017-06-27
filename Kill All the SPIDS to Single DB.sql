-- Kill all spids to a single DB
DECLARE @SQL VARCHAR(8000) 

SELECT	@SQL=COALESCE(@SQL,'')+'Kill '+CAST(spid AS VARCHAR(10))+ '; '  
FROM	sys.sysprocesses
WHERE DBID = DB_ID('MyDatatbase') 

PRINT @SQL 
--EXEC(@SQL) Replace the print statement with exec to execute