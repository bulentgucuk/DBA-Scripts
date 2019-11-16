--List all users
SELECT	name, type_desc, create_date, authentication_type_desc
FROM	sys.database_principals
WHERE	principal_id > 4
AND		principal_id < 16384
AND		name LIKE 'SVC%'



--List Database Roles and it's members
SELECT	dp.name AS DatabaseRoleName, dp.type_desc, p.name AS DatabaseRoleMemberName, p.create_date
FROM	sys.database_principals AS dp
	INNER JOIN SYS.database_role_members AS drm ON dp.principal_id = drm.role_principal_id
	INNER JOIN sys.database_principals AS P ON p.principal_id = drm.member_principal_id
WHERE p.name LIKE 'svcETL%'  -- User is a member of all the roles in first row
ORDER BY dp.name, p.create_date;


--List permissions on schemas for database roles
SELECT state_desc, permission_name, 'ON', class_desc,
SCHEMA_NAME(major_id) AS SCHEMANAME,
'TO', USER_NAME(grantee_principal_id) AS UserGroup
FROM sys.database_permissions AS Perm
JOIN sys.database_principals AS Prin
ON Perm.major_id = Prin.principal_id AND class_desc = 'SCHEMA'
WHERE 1=1
--AND major_id = SCHEMA_ID('prodcopystg')
AND USER_NAME(grantee_principal_id) LIKE 'CI_ClientAccess%' 
;
