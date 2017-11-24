USE [DBAMaint]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[P_SMART_REINDEX]') AND type IN (N'U'))
DROP PROCEDURE [dbo].[P_SMART_REINDEX]

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[P_SMART_REINDEX]
	-- Add the parameters for the stored procedure here

AS

BEGIN

SET NOCOUNT ON

DECLARE @DB_TABLE TABLE (DB NVARCHAR(100)) 
DECLARE @DB AS NVARCHAR(100)
DECLARE @COUNTER INT 
DECLARE @COMMAND AS NVARCHAR(500)

INSERT INTO @DB_TABLE (DB)
SELECT [NAME] FROM SYS.DATABASES WHERE name NOT IN ('master','model','msdb','tempdb')
--SELECT * FROM @DB_TABLE AS [@DB_TABLE]

SET @COUNTER = (SELECT COUNT(*) FROM @DB_TABLE)
--SELECT @COUNTER AS [@COUNTER]

SET @DB = (SELECT TOP 1 DB FROM @DB_TABLE)
--SELECT @DB

WHILE @COUNTER > 0
BEGIN
	--SET @COMMAND = 'USE ['+RTRIM(@DB)+'] EXEC sp_updatestats'
	SET @COMMAND = 
	'EXEC [DBAMaint].[dbo].[rebuild_indexes_by_db] 
@DBName ='  +  ''''+@DB +'''' +

', @ReorgLimit = 15
, @RebuildLimit = 30
, @PageLimit  = 1000
, @SortInTempdb  = 1
, @OnLine  = 1  
, @ByPartition  = 1
, @LOBCompaction  = 1
, @DoCIOnly  = 0  
, @UpdateStats  = 1
, @MaxDOP = 0
, @ExcludedTables ='''''

	--PRINT @COMMAND
	EXEC (@COMMAND)
DELETE FROM @DB_TABLE WHERE DB = @DB
SET @DB = (SELECT TOP 1 DB FROM @DB_TABLE)

	SET @COUNTER = @COUNTER - 1
END



END







GO

SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO
