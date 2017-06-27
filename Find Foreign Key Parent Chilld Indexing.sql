/**
Check the link below for explanation
http://www.sqlservercentral.com/articles/foreign+keys/136445/
**/
WITH FK_ColumnCount AS
(
	SELECT kc.constraint_object_id
		, ColumnCount = max(kc.constraint_column_id)
	FROM sys.foreign_key_columns kc
	GROUP BY kc.constraint_object_id
)
, ParentIndexGood AS
(
	SELECT kc.constraint_object_id 
		, FK_CC = cc.ColumnCount
		, ic.index_id
		, I_CC = COUNT(1)
	FROM sys.foreign_key_columns kc
		INNER JOIN FK_ColumnCount cc ON kc.constraint_object_id = cc.constraint_object_id
		INNER JOIN sys.index_columns ic ON ic.key_ordinal <= cc.ColumnCount
										AND ic.object_id = kc.parent_object_id 
										AND ic.column_id = kc.parent_column_id
	GROUP BY kc.constraint_object_id 
		, cc.ColumnCount
		, ic.index_id 
	HAVING cc.ColumnCount = COUNT(1)
)
, ReferencedIndexGood AS
(
	SELECT kc.constraint_object_id 
		, FK_CC = cc.ColumnCount
		, ic.index_id
		, I_CC = COUNT(1)
	FROM sys.foreign_key_columns kc
		INNER JOIN FK_ColumnCount cc ON kc.constraint_object_id = cc.constraint_object_id
		INNER JOIN sys.index_columns ic ON ic.key_ordinal <= cc.ColumnCount
										AND ic.object_id = kc.referenced_object_id 
										AND ic.column_id = kc.referenced_column_id
	GROUP BY kc.constraint_object_id 
		, cc.ColumnCount
		, ic.index_id 
	HAVING cc.ColumnCount = COUNT(1)
)
, ReferencedBoundIndexGood AS
(
	SELECT kc.constraint_object_id 
		, FK_CC = cc.ColumnCount
		, ic.index_id
		, I_CC = COUNT(1)
	FROM sys.foreign_keys k
		INNER JOIN sys.foreign_key_columns kc ON k.object_id = kc.constraint_object_id
		INNER JOIN FK_ColumnCount cc ON kc.constraint_object_id = cc.constraint_object_id
		INNER JOIN sys.index_columns ic ON ic.key_ordinal <= cc.ColumnCount
										AND ic.object_id = kc.referenced_object_id 
										AND ic.column_id = kc.referenced_column_id
										AND ic.index_id = k.key_index_id
	GROUP BY kc.constraint_object_id 
		, cc.ColumnCount
		, ic.index_id 
	HAVING cc.ColumnCount = COUNT(1)
)
SELECT FK_Name = k.name
	, k.is_disabled
	, k.is_not_trusted
	, k.delete_referential_action_desc
	, k.update_referential_action_desc
	, ParentTable = ps.name + '.' + pt.name 
	, ParentColumns = substring((SELECT (', ' + c.name)
							FROM sys.foreign_key_columns kc
								INNER JOIN sys.columns c ON kc.parent_object_id = c.object_id AND kc.parent_column_id = c.column_id
							WHERE kc.constraint_object_id = k.object_id 
							ORDER BY kc.constraint_column_id 
							FOR XML PATH ('')
							), 3, 4000)
	, ReferencedTable = rs.name + '.' + rt.name 
	, ReferencedColumns = substring((SELECT (', ' + c.name)
							FROM sys.foreign_key_columns kc
								INNER JOIN sys.columns c ON kc.referenced_object_id = c.object_id AND kc.referenced_column_id = c.column_id
							WHERE kc.constraint_object_id = k.object_id 
							ORDER BY kc.constraint_column_id 
							FOR XML PATH ('')
							), 3, 4000)
	, ReferenceBoundIndex = ri.name
	, IsParentIndexedForFK = CASE WHEN EXISTS (SELECT * FROM ParentIndexGood WHERE ParentIndexGood.constraint_object_id = k.object_id) THEN 'Yes' ELSE 'No' END
	, IsReferenceIndexedForFK = CASE WHEN EXISTS (SELECT * FROM ReferencedIndexGood WHERE ReferencedIndexGood.constraint_object_id = k.object_id) THEN 'Yes' ELSE 'No' END 
	, IsReferenceBoundToGoodIndex = CASE WHEN EXISTS (SELECT * FROM ReferencedBoundIndexGood WHERE ReferencedBoundIndexGood.constraint_object_id = k.object_id) THEN 'Yes' ELSE 'No' END 
FROM sys.foreign_keys k 
	INNER JOIN sys.tables pt ON k.parent_object_id = pt.object_id
	INNER JOIN sys.schemas ps ON pt.schema_id = ps.schema_id
	INNER JOIN sys.tables rt ON k.referenced_object_id = rt.object_id
	INNER JOIN sys.schemas rs ON rt.schema_id = rs.schema_id
	LEFT JOIN sys.indexes ri ON k.referenced_object_id = ri.object_id AND k.key_index_id = ri.index_id
ORDER BY 1