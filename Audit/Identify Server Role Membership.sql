
SELECT SP_L.name AS Login_Name, SP_R.name AS Server_Role
FROM master.sys.server_principals SP_L
	INNER JOIN master.sys.server_role_members SRM
		ON SP_L.principal_id = SRM.member_principal_id
	INNER JOIN master.sys.server_principals SP_R
		ON SRM.role_principal_id = SP_R.principal_id
WHERE SP_R.type_desc = 'SERVER_ROLE'
ORDER BY SP_R.name, SP_L.name;

