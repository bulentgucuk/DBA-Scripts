-- Check for security vulnerabilities (Kimberly Tripp)
SELECT OBJECT_NAME(object_id) AS [Procedure Name],
  CASE
      WHEN sm.definition LIKE '%EXEC (%' OR sm.definition LIKE '%EXEC(%' 
         THEN 'WARNING: code contains EXEC'
      WHEN sm.definition LIKE '%EXECUTE (%' OR sm.definition LIKE '%EXECUTE(%' 
         THEN 'WARNING: code contains EXECUTE'
  END AS [Dynamic Strings],
  CASE
      WHEN execute_as_principal_id IS NOT NULL 
         THEN N'WARNING: EXECUTE AS ' + user_name(execute_as_principal_id)
      ELSE 'Code to run as caller - check connection context'
  END AS [Execution Context Status]
FROM sys.sql_modules AS sm
ORDER BY [Procedure Name]; 

-- Look at modules that don't have SET NOCOUNT ON
SELECT OBJECT_NAME(object_id) AS [Procedure Name],
CASE
      WHEN sm.Definition NOT LIKE '%SET NOCOUNT ON%' 
          THEN 'WARNING: code does not have SET NO COUNT ON'
END AS [SET NOCOUNT ON Check]
FROM sys.sql_modules AS sm
ORDER BY [Procedure Name];

-- List modules that don't have SET NOCOUNT ON
SELECT OBJECT_NAME(object_id) AS [Procedure Name]
FROM sys.sql_modules AS sm
WHERE sm.Definition NOT LIKE '%SET NOCOUNT ON%'
ORDER BY [Procedure Name];

-- List modules that have NOLOCK hints
SELECT OBJECT_NAME(object_id) AS [Procedure Name]
FROM sys.sql_modules AS sm
WHERE sm.Definition LIKE '%NOLOCK%'
ORDER BY [Procedure Name];

-- List modules that have WITH RECOMPILE option set
SELECT OBJECT_NAME(object_id) AS [Procedure Name]
FROM sys.sql_modules AS sm
WHERE is_recompiled = 1;

-- List each module in the current database
SELECT OBJECT_NAME(sm.object_id) AS [Object Name], 
       o.[type], o.type_desc, sm.[definition]
FROM sys.sql_modules AS sm
INNER JOIN sys.objects AS o 
ON sm.object_id = o.object_id
ORDER BY o.[type], [Object Name];