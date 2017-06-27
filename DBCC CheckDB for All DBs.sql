--runs DBCC checkdb against ALL databases on a server 
--Needs to be run against master database i.e. that is where sp_MSForEachdb is found 
--To exclude a database add the database name to the NOT IN list in @cmd1 
DECLARE @cmd1 VARCHAR(500) 

 
SET @cmd1 = 'if ''?'' NOT IN (''tempdb'')  DBCC CHECKDB([?[) WITH NO_INFOMSGS'
EXEC sp_MSforeachdb @command1 = @cmd1