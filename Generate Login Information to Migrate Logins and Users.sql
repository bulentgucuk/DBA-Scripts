-- Generate the login information to migrate 
-- Make sure to deploy sp_help_revlogin to master db
PRINT ' ';
PRINT 'Logins to migrate:';
PRINT ' ';

DECLARE cursLogins CURSOR FAST_FORWARD
FOR
SELECT L.[name]
FROM sys.database_principals AS U
  JOIN sys.server_principals  AS L
    ON U.sid = L.sid
WHERE U.type IN ('S', 'U', 'G')
  AND NOT U.name = 'dbo'
ORDER BY L.name;
GO 

DECLARE @login sysname;
DECLARE @SQL NVARCHAR(MAX);
OPEN cursLogins;

FETCH NEXT FROM cursLogins INTO @login;

WHILE (@@FETCH_STATUS = 0)
BEGIN
  SET @SQL = 'EXEC master..sp_help_revlogin ''' + @login + ''';';
  EXEC (@SQL);

  FETCH NEXT FROM cursLogins INTO @login;
END;

CLOSE cursLogins;
DEALLOCATE cursLogins;