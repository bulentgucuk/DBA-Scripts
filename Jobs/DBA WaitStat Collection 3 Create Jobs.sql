SET NOCOUNT ON;
DECLARE @ID BIGINT
	, @KeepLast BIGINT = 10000
-- dbo.WaitingTasks cleanup
SELECT	@ID = MAX(WaitingTaskID) - @KeepLast
FROM	dbo.WaitingTasks WITH(NOLOCK);

DELETE FROM dbo.WaitingTasks
WHERE	WaitingTaskID < @ID;

-- dbo.Waits cleanup
SELECT	@ID = MAX(WaitID) - @KeepLast
FROM	dbo.Waits WITH(NOLOCK);

DELETE FROM dbo.Waits
WHERE	WaitID < @ID;

-- dbo.WhoIsActive cleanup
SELECT	@ID = MAX(RowId)- @KeepLast
FROM	dbo.WhoIsActive WITH(NOLOCK);

DELETE FROM dbo.WhoIsActive
WHERE	RowId < @ID;

-- dbo.DatabaseFileLatency cleanup
SELECT	@ID = MAX(RowId)- @KeepLast
FROM	dbo.DatabaseFileLatency WITH(NOLOCK);

DELETE FROM dbo.DatabaseFileLatency
WHERE	RowId < @ID;