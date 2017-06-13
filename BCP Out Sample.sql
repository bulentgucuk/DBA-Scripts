SET NOCOUNT ON;
GO
SET ANSI_PADDING ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

DECLARE	@DatabaseName VARCHAR(32) = 'CU'
	, @ServerName VARCHAR(32) = 'SSBCIDW04'
	, @BcpFileLocation VARCHAR(128) = 'D:\';

IF OBJECT_ID('tempdb..#BcpOut') IS NOT NULL
	DROP TABLE #BcpOut;

CREATE TABLE #BcpOut (
	  RowId INT IDENTITY (1,1) NOT NULL
	, DatabaseName VARCHAR(32) NOT NULL
	, TableName VARCHAR(128) NOT NULL
	, BcpFileLocation VARCHAR(128) NOT NULL
	, ServerName VARCHAR(32) NOT NULL
	, OpStartDateTime DATETIME NULL
	, OpEndDateTime DATETIME NULL
	)

INSERT INTO #BcpOut
        ( 
          DatabaseName ,
          TableName ,
          BcpFileLocation ,
          ServerName 
        )
VALUES 
	(@DatabaseName, 'dbo.TK_TRANS_ITEM_EVENT', @BcpFileLocation, @ServerName);

DECLARE @cmd VARCHAR(MAX)
	, @MaxRowId INT

SELECT @MaxRowId = MAX(RowId)
FROM	#BcpOut

WHILE @MaxRowId > 0
BEGIN
	
	SELECT	@cmd = 'EXEC XP_CMDSHELL ''BCP ' + DatabaseName + '.' + TableName + ' OUT ' + BcpFileLocation + TableName + '.dat -n -b 5000 -E -T -S ' + ServerName + ''''
	FROM	#BcpOut
	WHERE	RowId = @MaxRowId;

	UPDATE	#BcpOut
	SET		OpStartDateTime = GETDATE()
	WHERE	RowId = @MaxRowId;

	PRINT @cmd
	--EXEC (@cmd)

	UPDATE	#BcpOut
	SET		OpEndDateTime = GETDATE()
	WHERE	RowId = @MaxRowId;

	SELECT @MaxRowId = @MaxRowId - 1;
END
