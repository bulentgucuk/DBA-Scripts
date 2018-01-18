--Find members of the database role
SELECT
	  @@SERVERNAME as ServerName
	, db_name() AS DatabaseName
	, DP1.name AS DatabaseRoleName
	, ISNULL (DP2.name, 'No members') AS DatabaseUserName
	, dp2.create_date AS DatabasePrincipalCreateDate
FROM	sys.database_role_members AS DRM
	RIGHT OUTER JOIN sys.database_principals AS DP1 ON DRM.role_principal_id = DP1.principal_id
	LEFT OUTER JOIN sys.database_principals AS DP2 ON DRM.member_principal_id = DP2.principal_id
--WHERE	dp1.name = 'db_datareader'  --This finds the member of the database roles
WHERE	dp2.name = 'svcETL' --This finds the database roles the login is a member of
ORDER BY DP1.name;
