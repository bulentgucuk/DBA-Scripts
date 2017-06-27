-- CONFIGURE REMOTE LINKED SERVE FOR RPC OUT TRUE
use tempdb
CREATE TABLE #tmpServices(ServiceName varchar(255))
INSERT INTO #tmpServices
exec master..xp_cmdshell 'net start'
SELECT * FROM #tmpServices WHERE ServiceName LIKE '%SQL SERVER%'


IF EXISTS(SELECT * FROM #tmpServices WHERE ServiceName LIKE '   SQL Server (SQL2008)')
	BEGIN
		PRINT '2008 SERVICE RUNNING'
		EXEC [FROST\SQL2005].TEMPDB.DBO.DBASetMaxMemory

	END

DROP TABLE #tmpServices




EXEC SP_CONFIGURE 'xp_cmdshell',1
GO
RECONFIGURE
GO
EXEC SP_CONFIGURE 'max server memory (MB)', 1024
GO
RECONFIGURE
GO


CREATE PROCEDURE dbo.DBASetMaxMemory
AS

EXEC SP_CONFIGURE 'max server memory (MB)', 512
RECONFIGURE
GO

-
