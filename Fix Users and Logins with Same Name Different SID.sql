SELECT dp.type_desc, dp.SID, dp.name AS user_name
FROM sys.database_principals AS dp
LEFT JOIN sys.server_principals AS sp
    ON dp.SID = sp.SID
WHERE sp.SID IS NULL
    AND authentication_type_desc = 'INSTANCE';

GO

EXEC sp_change_users_login 'REPORT' 

GO

EXEC sp_change_users_login 'UPDATE_ONE','svcLogi','svcLogi'
EXEC sp_change_users_login 'UPDATE_ONE','svcssbrp','svcssbrp'
EXEC sp_change_users_login 'UPDATE_ONE','svcSegmentation','svcSegmentation'
GO

SELECT dp.type_desc, dp.SID, dp.name AS user_name
FROM sys.database_principals AS dp
LEFT JOIN sys.server_principals AS sp
    ON dp.SID = sp.SID
WHERE sp.SID IS NULL
    AND authentication_type_desc = 'INSTANCE';

GO

EXEC sp_change_users_login 'REPORT' 
