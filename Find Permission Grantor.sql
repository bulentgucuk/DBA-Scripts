select  princ.name
,       princ.type_desc
,       perm.permission_name
,       perm.state_desc
,       perm.class_desc
,		OBJECT_SCHEMA_NAME((perm.major_id)) AS 'SchemaName'
,       object_name(perm.major_id) AS 'ObjectName'
,		perm.grantor_principal_id
,		dp.name
,		perm.*
from    sys.database_principals princ
	LEFT JOIN sys.database_permissions perm on perm.grantee_principal_id = princ.principal_id
	LEFT JOIN sys.database_principals as dp on perm.grantor_principal_id = dp.principal_id
