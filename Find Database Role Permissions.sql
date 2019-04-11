-- Change the database context
-- Prints the script to create the existing role, permissions and members
DECLARE @roleName VARCHAR(255)
SET @roleName = 'db_SSBDeveloper'

-- Script out the Role
DECLARE @roleDesc VARCHAR(MAX), @crlf VARCHAR(2)
SET @crlf = CHAR(13) + CHAR(10)
--SET @roleDesc = 'CREATE ROLE [' + @roleName + '];' + @crlf + 'GO' + @crlf + @crlf
SET @roleDesc = 'IF DATABASE_PRINCIPAL_ID('+'''' + @roleName + ''''+') IS NULL' + @crlf + 'CREATE ROLE ' + QUOTENAME(@roleName) + ' AUTHORIZATION dbo;' + @crlf + 'GO' + @crlf + @crlf

SELECT    @roleDesc = @roleDesc +
        CASE dp.state
            WHEN 'D' THEN 'DENY '
            WHEN 'G' THEN 'GRANT '
            WHEN 'R' THEN 'REVOKE '
            WHEN 'W' THEN 'GRANT '
        END + 
        dp.permission_name + ' ' +
        CASE dp.class
            WHEN 0 THEN ''
            WHEN 1 THEN --table or column subset on the table
                CASE WHEN dp.major_id < 0 THEN
                    + 'ON [sys].[' + OBJECT_NAME(dp.major_id) + '] '
                ELSE
                    + 'ON [' +
                    (SELECT SCHEMA_NAME(schema_id) + '].[' + name FROM sys.objects WHERE object_id = dp.major_id)
                        + -- optionally concatenate column names
                    CASE WHEN MAX(dp.minor_id) > 0 
                         THEN '] ([' + REPLACE(
                                        (SELECT name + '], [' 
                                         FROM sys.columns 
                                         WHERE object_id = dp.major_id 
                                            AND column_id IN (SELECT minor_id 
                                                              FROM sys.database_permissions 
                                                              WHERE major_id = dp.major_id
                                                                AND USER_NAME(grantee_principal_id) IN (@roleName)
                                                             )
                                         FOR XML PATH('')
                                        ) --replace final square bracket pair
                                    + '])', ', []', '')
                         ELSE ']'
                    END + ' '
                END
            WHEN 3 THEN 'ON SCHEMA::[' + SCHEMA_NAME(dp.major_id) + '] '
            WHEN 4 THEN 'ON ' + (SELECT RIGHT(type_desc, 4) + '::[' + name FROM sys.database_principals WHERE principal_id = dp.major_id) + '] '
            WHEN 5 THEN 'ON ASSEMBLY::[' + (SELECT name FROM sys.assemblies WHERE assembly_id = dp.major_id) + '] '
            WHEN 6 THEN 'ON TYPE::[' + (SELECT name FROM sys.types WHERE user_type_id = dp.major_id) + '] '
            WHEN 10 THEN 'ON XML SCHEMA COLLECTION::[' + (SELECT SCHEMA_NAME(schema_id) + '.' + name FROM sys.xml_schema_collections WHERE xml_collection_id = dp.major_id) + '] '
            WHEN 15 THEN 'ON MESSAGE TYPE::[' + (SELECT name FROM sys.service_message_types WHERE message_type_id = dp.major_id) + '] '
            WHEN 16 THEN 'ON CONTRACT::[' + (SELECT name FROM sys.service_contracts WHERE service_contract_id = dp.major_id) + '] '
            WHEN 17 THEN 'ON SERVICE::[' + (SELECT name FROM sys.services WHERE service_id = dp.major_id) + '] '
            WHEN 18 THEN 'ON REMOTE SERVICE BINDING::[' + (SELECT name FROM sys.remote_service_bindings WHERE remote_service_binding_id = dp.major_id) + '] '
            WHEN 19 THEN 'ON ROUTE::[' + (SELECT name FROM sys.routes WHERE route_id = dp.major_id) + '] '
            WHEN 23 THEN 'ON FULLTEXT CATALOG::[' + (SELECT name FROM sys.fulltext_catalogs WHERE fulltext_catalog_id = dp.major_id) + '] '
            WHEN 24 THEN 'ON SYMMETRIC KEY::[' + (SELECT name FROM sys.symmetric_keys WHERE symmetric_key_id = dp.major_id) + '] '
            WHEN 25 THEN 'ON CERTIFICATE::[' + (SELECT name FROM sys.certificates WHERE certificate_id = dp.major_id) + '] '
            WHEN 26 THEN 'ON ASYMMETRIC KEY::[' + (SELECT name FROM sys.asymmetric_keys WHERE asymmetric_key_id = dp.major_id) + '] '
         END COLLATE SQL_Latin1_General_CP1_CI_AS
         + 'TO [' + @roleName + '];' + 
         CASE dp.state WHEN 'W' THEN ' WITH GRANT OPTION;' ELSE '' END + @crlf
FROM    sys.database_permissions dp
WHERE    USER_NAME(dp.grantee_principal_id) IN (@roleName)
GROUP BY dp.state, dp.major_id, dp.permission_name, dp.class

SELECT @roleDesc = @roleDesc + 'GO' + @crlf + @crlf

-- Display users within Role.  Code stubbed by Joe Spivey
--SELECT  @roleDesc = @roleDesc + 'EXECUTE sp_AddRoleMember ''' + roles.name + ''', ''' + users.name + '''' + @crlf
SELECT  @roleDesc = @roleDesc + 'ALTER ROLE ' + QUOTENAME(roles.name) + ' ADD MEMBER ' + QUOTENAME(users.name) + ';' + @crlf
FROM    sys.database_principals users
        INNER JOIN sys.database_role_members link 
            ON link.member_principal_id = users.principal_id
        INNER JOIN sys.database_principals roles 
            ON roles.principal_id = link.role_principal_id
WHERE   roles.name = @roleName

-- PRINT out in blocks of up to 8000 based on last \r\n
DECLARE @printCur INT
SET @printCur = 8000

WHILE LEN(@roleDesc) > 8000
BEGIN
    -- Reverse first 8000 characters and look for first lf cr (reversed crlf) as delimiter
    SET @printCur = 8000 - CHARINDEX(CHAR(10) + CHAR(13), REVERSE(SUBSTRING(@roleDesc, 0, 8000)))

    PRINT LEFT(@roleDesc, @printCur)
    SELECT @roleDesc = RIGHT(@roleDesc, LEN(@roleDesc) - @printCur)
END

PRINT @RoleDesc + 'GO'