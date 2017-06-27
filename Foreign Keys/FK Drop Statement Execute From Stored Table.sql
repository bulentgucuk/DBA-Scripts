------------------------------------------------------------------------
--
--  This job step drop foreign key constraints to make data purging easier..
--
------------------------------------------------------------------------
USE NetQuoteDevCut
SET NOCOUNT ON
-- DROP FK CONSTRAINTS
DECLARE @MaxFKid INT,
		@Str VARCHAR(1024)

SELECT	@MaxFKid = MAX(FKid)
FROM	dbo.FKDrop

WHILE	@MaxFKid > 0
	BEGIN
		SELECT	@Str = ''
		SELECT	@Str = [Str]
		FROM	dbo.FKDrop
		WHERE	FKid = @MaxFKid
		PRINT	@Str
		EXEC	(@Str)
		SELECT	@MaxFKid = @MaxFKid - 1
	END