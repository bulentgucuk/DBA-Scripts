-- Change the database context to the user database
SELECT	[name] AS ObjectName,
		user_name(grantee_principal_id) as Grantee,
		user_name(grantor_principal_id) as Grantor,
		Permission_name,
		State_desc,
		o.Type_desc
FROM	sys.database_permissions AS dp
	JOIN sys.objects AS o on dp.major_id = o.object_id
WHERE	class = 1 
AND		o.type in ('U','P') -- U -USER_TABLE, P-SQL_STORED_PROCEDURE , V-- View, Fn-- Functions
AND		dp.type in ('SL','IN','UP','EX') -- SL- Select, IN - Insert, Up - Update ,'Ex - Execute
ORDER BY name

