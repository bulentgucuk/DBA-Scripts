-- Find Column Names and Data Types for all columns in all tables
SELECT	Object_Name(C.Object_Id) AS TableName,
		C.Column_Id,
		C.Name,
		T.Name,
		C.Max_Length,
		C.Precision,
		C.Scale,
		C.Is_Nullable
FROM	sys.Columns AS C (NOLOCK)
	INNER JOIN	sys.Types AS T (NOLOCK)
		ON C.System_Type_Id = T.System_Type_Id
WHERE	C.Object_id > 100
ORDER BY Object_Name(C.Object_Id)