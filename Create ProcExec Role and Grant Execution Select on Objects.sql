-- CREATE ROLE AND ADD ROLE MEMBERS THEN GRANT EXECUTE PERMISSIONS
IF NOT EXISTS (
                  SELECT      1
                  FROM        sys.database_principals
                  WHERE       Type = 'R'
                  AND         name = 'ProcExec'
                  )
      BEGIN
            CREATE ROLE ProcExec AUTHORIZATION dbo;
      END

GO
EXEC sp_addrolemember N'ProcExec', N'Peak8DDC\RPhelps'
GO
EXEC sp_addrolemember N'ProcExec', N'Peak8DDC\SQLReportViewer'
GO


-- GRANT EXECUTE ON STORED PROCEDURES
SELECT      'GRANT EXECUTE ON ' + QUOTENAME(s1.name) + '.' + QUOTENAME(s.name) + ' TO [ProcExec]' AS GrantExecuteForSPs
FROM  sys.procedures AS s
      INNER JOIN sys.schemas AS s1
            ON s.schema_id = s1.schema_id
AND		is_ms_shipped = 0

UNION ALL

-- GRANT SELECT FOR TABLE VALUED FUNCTIONS
SELECT	'GRANT SELECT ON ' + QUOTENAME(s.name) + '.' + QUOTENAME(o.name) + ' TO [ProcExec]' AS GrantSelectForTVFs
FROM	sys.objects AS O
	INNER JOIN sys.schemas AS s
		ON o.schema_id = s.schema_id
WHERE	type = 'tf'
AND		is_ms_shipped = 0

UNION ALL

-- GRANT EXECUTE ON SCALAR FUNCTIONS
SELECT	'GRANT EXECUTE ON ' + QUOTENAME(s.name) + '.' + QUOTENAME(o.name) + ' TO [ProcExec]' AS GrantExecuteForScalarFunctions
FROM	sys.objects AS O
	INNER JOIN sys.schemas AS s
		ON o.schema_id = s.schema_id
WHERE	type = 'FN'
AND		is_ms_shipped = 0



