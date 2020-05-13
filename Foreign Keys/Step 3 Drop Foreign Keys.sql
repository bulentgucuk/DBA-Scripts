USE MYDATABASE -- CHANGE THE NAME OF THE DB
SET NOCOUNT ON;
--SELECT *
--FROM dbo.FKDrop

-- DROP FK CONSTRAINTS
DECLARE @MaxFKid INT,
		@Str NVARCHAR(1024);

SELECT	@MaxFKid = MAX(FKid)
FROM	dbo.FKDrop;

WHILE	@MaxFKid > 0
	BEGIN
		SELECT	@Str = '';
		SELECT	@Str = [Str]
		FROM	dbo.FKDrop
		WHERE	FKid = @MaxFKid;

		PRINT	@Str;
		
		EXEC sp_executesql @stmt = @Str;
		
		SELECT	@MaxFKid = @MaxFKid - 1;
	END
