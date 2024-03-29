﻿-- <Migration ID="6e25b699-1df5-4499-8867-2f3e14d97cb4" />
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.sp_whoisactive_prune
AS
BEGIN

SET NOCOUNT ON;
DECLARE @ID BIGINT;
DECLARE @D DATETIME;

-- dbo.WhoIsActive clean up keep last 7 days of data
SET	@D = (SELECT CAST(DATEADD(DAY, -7, GETDATE()) AS DATE));
SELECT	@ID = MAX(RowId)
FROM	dbo.WhoIsActive WITH(NOLOCK)
WHERE	collection_time <= @D;

DELETE FROM dbo.WhoIsActive
WHERE	RowId < @ID;

END
GO