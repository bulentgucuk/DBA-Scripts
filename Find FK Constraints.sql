
SELECT	OBJECT_NAME(parent_object_id) AS ParentTableName,
		OBJECT_NAME(referenced_object_id) AS ChildTableName,
		Name AS FKName,
		Type_Desc,
		Create_Date
FROM	sys.foreign_keys
ORDER BY ParentTableName