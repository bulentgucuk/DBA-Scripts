select	DISTINCT OBJECT_SCHEMA_NAME(o.object_id) + '.' +  o.name AS 'ObjectName',
		--I.Index_Id,
		I.Name AS IndexName,
		I.Type_Desc,
		IUS.User_Seeks,
		IUS.Last_User_Seek,
		IUS.User_Scans,
		IUS.Last_User_Scan,
		IUS.User_Lookups,
		IUS.Last_User_Lookup,
		IUS.User_Updates,
		IUS.Last_User_Update
FROM	sys.Indexes AS I
	INNER JOIN sys.dm_db_index_usage_stats AS IUS ON I.Object_id = IUS.Object_id AND I.Index_id = IUS.Index_id
	INNER JOIN sys.objects as o on o.object_id = i.object_id
