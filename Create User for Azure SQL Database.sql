/****** Object:  SQL User For Azure SQL Database Create Script Date: 1/3/2018 2:11:55 PM ******/
DECLARE	@UserName SYSNAME = 'twhite_kings.com'
	, @Password NVARCHAR(128) = 'XEb8^3SjSqEejyOr3K*c8O4L@zXt#o%Cw5NY5P9laJ45'

IF USER_ID(@UserName) IS NULL
	BEGIN
		DECLARE	@str NVARCHAR(1024);
		SELECT	@str = 'CREATE USER ' + QUOTENAME(@UserName) + ' WITH PASSWORD = N' + '''' + @Password + '''' +' , DEFAULT_SCHEMA=[dbo];';
		PRINT @str;
		EXEC sp_executesql @stmt = @str;
	END
GO

--ALTER ROLE CI_ClientAccess ADD MEMBER [twhite_kings.com];
