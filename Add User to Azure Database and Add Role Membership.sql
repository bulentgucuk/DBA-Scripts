SELECT	compatibility_level, name, create_date
FROM	sys.databases
WHERE	name = db_name();

-- Database compatibility level must be 130 for string_split function to work otherwise adding the user to datbase role will fail
-- Change connection to user database and replace the user name then list the database role(s) in a comma seperated list

SET NOCOUNT ON;
DECLARE	@SqlUser SYSNAME = 'rsimmons@ssbinfo.com'
	, @Roles NVARCHAR(512) = 'db_datareader'
	, @str NVARCHAR(512)
	, @RowId TINYINT = 1;
-- Create the user
IF NOT EXISTS (
	SELECT	*
	FROM	sys.database_principals
	WHERE	name = @SqlUser
	)
	BEGIN
		SET @str = 'CREATE USER ' + QUOTENAME(@SqlUser) + ' FROM EXTERNAL PROVIDER';
		PRINT @STR;
		EXEC SP_EXECUTESQL @Stmt = @str;
	END
-- Find the roles that the user is not a member
IF OBJECT_ID ('tempdb..#DbRoles') IS NOT NULL
	DROP TABLE #DbRoles;
SELECT
	  IDENTITY(TINYINT) AS RowId
	, LTRIM(RTRIM(value)) AS 'RoleName'
	, 'ALTER ROLE ' + LTRIM(RTRIM(value)) + ' ADD MEMBER ' + QUOTENAME(@SqlUser) + ';' AS 'Str'
INTO	#DbRoles
FROM	string_split(@Roles, ',')
WHERE	not exists (
	SELECT	DP1.name
	FROM	sys.database_role_members AS DRM
		RIGHT OUTER JOIN sys.database_principals AS DP1 ON DRM.role_principal_id = DP1.principal_id
		LEFT OUTER JOIN sys.database_principals AS DP2 ON DRM.member_principal_id = DP2.principal_id
	WHERE	dp2.name = @SqlUser --This is user name
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
