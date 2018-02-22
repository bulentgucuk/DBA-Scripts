SELECT pr.*
FROM sys.database_principals AS pr
where	pr.type <> 'R'
and		pr.name like 'Rmahendrakumar%'


--List Database Roles and it's members
SELECT r.name AS role_principal_name
	 , m.name AS member_principal_name
FROM sys.database_role_members rm
JOIN sys.database_principals r
  ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals m
  ON rm.member_principal_id = m.principal_id
WHERE 1=1
--AND r.name IN ('loginmanager', 'dbmanager')
AND m.name LIKE 'jkoette%'
; 

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
