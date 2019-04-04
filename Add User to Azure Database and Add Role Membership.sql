SELECT	compatibility_level, name, create_date
FROM	sys.databases
WHERE	name = db_name();

-- Database compatibility level must be 130 for string_split function to work otherwise adding the user to datbase role will fail
-- Change connection to user database and replace the user name then list the database role(s) in a comma seperated list
-- If creating a sql user with password set the @Password to a value, if it's a domain account set the @Password to null
SET NOCOUNT ON;
DECLARE	@UserName SYSNAME = 'kmm8wq_virginia.edu'
	, @Roles NVARCHAR(512) = 'CI_ClientAccess,CI_ClientWriter'
	, @Password NVARCHAR(128) = '<Last_Pass>'
	, @str NVARCHAR(512)
	, @RowId TINYINT = 1;
-- Create the user
IF NOT EXISTS (
	SELECT	*
	FROM	sys.database_principals
	WHERE	name = @UserName
	)
	BEGIN
		IF @Password IS NULL
			BEGIN
				SET @str = 'CREATE USER ' + QUOTENAME(@UserName) + ' FROM EXTERNAL PROVIDER';
				PRINT @STR;
				EXEC SP_EXECUTESQL @Stmt = @str;
			END
		IF @Password IS NOT NULL
			BEGIN
				SELECT	@str = 'CREATE USER ' + QUOTENAME(@UserName) + ' WITH PASSWORD = N' + '''' + @Password + '''' +' , DEFAULT_SCHEMA=[dbo];';
				PRINT @str;
				EXEC sp_executesql @stmt = @str;
			END
	END
-- Find the roles that the user is not a member
IF OBJECT_ID ('tempdb..#DbRoles') IS NOT NULL
	DROP TABLE #DbRoles;
SELECT
	  IDENTITY(TINYINT) AS RowId
	, LTRIM(RTRIM(value)) AS 'RoleName'
	, 'ALTER ROLE ' + QUOTENAME((LTRIM(RTRIM(value)))) + ' ADD MEMBER ' + QUOTENAME(@UserName) + ';' AS 'Str'
INTO	#DbRoles
FROM	string_split(@Roles, ',')
WHERE	not exists (
	SELECT	DP1.name
	FROM	sys.database_role_members AS DRM
		RIGHT OUTER JOIN sys.database_principals AS DP1 ON DRM.role_principal_id = DP1.principal_id
		LEFT OUTER JOIN sys.database_principals AS DP2 ON DRM.member_principal_id = DP2.principal_id
	WHERE	dp2.name = @UserName --This is user name
	)
-- Add the user as a member of the roles
WHILE EXISTS (SELECT RowId FROM #DbRoles WHERE RowId = @RowId)
	BEGIN
		SET @str = '';
		SELECT @str = Str
		FROM	#DbRoles
		WHERE	RowId = @RowId;
		PRINT @Str;
		EXEC SP_EXECUTESQL @Stmt = @str;
		SET @RowId = @RowId + 1;
	END
DROP TABLE #DbRoles;
