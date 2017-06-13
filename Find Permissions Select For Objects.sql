select USER_NAME(p.grantee_principal_id) AS principal_name,
dp.type_desc AS principal_type_desc,
p.class_desc,
OBJECT_NAME(p.major_id) AS object_name,
p.permission_name,
p.state_desc AS permission_state_desc
from sys.database_permissions p
inner JOIN sys.database_principals dp
on p.grantee_principal_id = dp.principal_id
where p.major_id in 
	(select object_id
	FROM SYS.OBJECTS 
	WHERE schema_id = 6
	--and		NAME IN 
	--(
	--'vw__TI_TK_ODET',
	--'vw__VIP_Bio',
	--'vw__VIP_Contact',
	--'vw__VIP_Endowments',
	--'vw__VIP_Gift',
	--'vw__VIP_Pledge_Payments',
	--'vw__VIP_PPL_DSG',
	--'vw__VIP_Proposal',
	--'vw__VIP_Submitter',
	--'vw_DimCustomer_Base',
	--'vw__SFDC_Account'
	--)
	)
