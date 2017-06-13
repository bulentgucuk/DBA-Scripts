/*
    Create new linked server
*/

-- Make a link to the cloud
EXEC sp_addlinkedserver   
   @server=N'AzureNFLDB', 
   @srvproduct=N'Azure SQL Db',
   @provider=N'SQLNCLI', 
   @datasrc=N'xxxxxx.database.windows.net',  -- azure db address
   @catalog='xxxxxx'; -- azure db name
GO

--Set up login mapping
EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'AzureNFLDB', 
    @useself = 'FALSE', 
    @locallogin=NULL,
    @rmtuser = 'xxxxxx', -- remote login
    @rmtpassword = 'xxxxxxqqqqwwwwww'  -- password
GO

-- Test the connection
exec sp_testlinkedserver AzureNFLDB;
GO

-- Sample remote queries to linked server
/***
--https://msdn.microsoft.com/en-us/library/ms188427.aspx

SELECT * FROM OPENQUERY (AzureNFLDB , 'select objectname, indexname, commandtype, starttime, endtime from dbo.CommandLog
where starttime > ''20160405''');


SELECT * FROM OPENQUERY (AzureNFLDB , 'declare @d date = getdate() select objectname, indexname, commandtype, starttime, endtime from dbo.CommandLog
where starttime > @d');


DECLARE @Sname SYSNAME = 'AzureNFLDB';
IF EXISTS (SELECT *
			FROM	sys.servers
			WHERE	name = @Sname
			)
	BEGIN
		DELETE OPENQUERY (AzureNFLDB , 'SELECT ID  FROM dbo.CommandLog WHERE starttime < DATEADD(DAY,-30,GETDATE());');
	END


DELETE OPENQUERY (AzureNFLDB , 'DECLARE @d DATETIME = DATEADD(DAY, -30, GETDATE()) SELECT ID FROM dbo.CommandLog WHERE starttime < @d');

***/