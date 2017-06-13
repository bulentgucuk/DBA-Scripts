
DECLARE @listStr VARCHAR(255)
SELECT	@listStr = COALESCE(@listStr+', ' ,'') + CAST(NAME AS VARCHAR(32))
FROM	SYS.databases
WHERE database_id > 4
ORDER BY name
SELECT	@listStr

DECLARE	@Str NVARCHAR (512)
SELECT	@Str = 'SELECT	* FROM dbo.Products WHERE	ProductId in (' + @listStr + ')'

SELECT	@Str

EXECUTE sp_executesql 
		@Stmt = @Str
