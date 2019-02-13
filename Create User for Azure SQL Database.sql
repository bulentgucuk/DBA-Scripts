/****** Object:  SQL User For Azure SQL Database Create Script Date: 2/9/2018 1:14:55 PM ******/
DECLARE	@UserName SYSNAME = 'ssb_azure_dba'
	, @Password NVARCHAR(128) = 'jC73dYDu82BmwYNyTq'
	, @RoleName VARCHAR(64) = 'db_owner'
	, @str NVARCHAR(1024);

IF USER_ID(@UserName) IS NULL
	BEGIN
		SELECT	@str = 'CREATE USER ' + QUOTENAME(@UserName) + ' WITH PASSWORD = N' + '''' + @Password + '''' +' , DEFAULT_SCHEMA=[dbo];';
		PRINT @str;
		EXEC sp_executesql @stmt = @str;
	END


SELECT	@str = 'ALTER ROLE ' + QUOTENAME(@RoleName) + ' ADD MEMBER ' + QUOTENAME(@UserName) + ';';
PRINT @str;
EXEC sp_executesql @stmt = @str;

GO

/****** Object:  SQL User For Azure SQL Database Create Script Date: 2/9/2018 1:14:55 PM ******/
DECLARE	@UserName SYSNAME = 'jmalone@ssbinfo.com'
	, @RoleName VARCHAR(64) = 'db_owner'
	, @str NVARCHAR(1024);

IF USER_ID(@UserName) IS NULL
	BEGIN
		SELECT	@str = 'CREATE USER ' + QUOTENAME(@UserName) + ' FROM EXTERNAL PROVIDER;';
		PRINT @str;
		EXEC sp_executesql @stmt = @str;
	END


SELECT	@str = 'ALTER ROLE ' + QUOTENAME(@RoleName) + ' ADD MEMBER ' + QUOTENAME(@UserName) + ';';
PRINT @str;
EXEC sp_executesql @stmt = @str;

