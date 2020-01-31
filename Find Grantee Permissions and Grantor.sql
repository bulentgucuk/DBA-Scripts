SELECT DB_NAME() AS database_name
    , class
    , class_desc
    , major_id
    , minor_id
    , grantee_principal_id
    , grantor_principal_id
    , databasepermissions.type
    , permission_name
    , STATE
    , state_desc
    , granteedatabaseprincipal.name AS grantee_name
    , granteedatabaseprincipal.type_desc AS grantee_type_desc
    , granteeserverprincipal.name AS grantee_principal_name
    , granteeserverprincipal.type_desc AS grantee_principal_type_desc
    , grantor.name AS grantor_name
    , granted_on_name
    , permissionstatement + N' TO ' + QUOTENAME(granteedatabaseprincipal.name) + CASE 
        WHEN STATE = N'W'
            THEN N' WITH GRANT OPTION'
        ELSE N''
        END AS permissionstatement
FROM (
    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(CONVERT(NVARCHAR(MAX), DB_NAME())) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS AS permissionstatement
    FROM sys.database_permissions
    WHERE (sys.database_permissions.class = 0)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.schemas.name) + N'.' + QUOTENAME(sys.objects.name) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON ' + QUOTENAME(sys.schemas.name) + N'.' + QUOTENAME(sys.objects.name) + COALESCE(N' (' + QUOTENAME(sys.columns.name) + N')', N'') AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.objects
        ON sys.objects.object_id = sys.database_permissions.major_id
    INNER JOIN sys.schemas
        ON sys.schemas.schema_id = sys.objects.schema_id
    LEFT OUTER JOIN sys.columns
        ON sys.columns.object_id = sys.database_permissions.major_id
            AND sys.columns.column_id = sys.database_permissions.minor_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 1)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.schemas.name) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON SCHEMA::' + QUOTENAME(sys.schemas.name) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.schemas
        ON sys.schemas.schema_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 3)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(targetPrincipal.name) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON ' + targetPrincipal.type_desc + N'::' + QUOTENAME(targetPrincipal.name) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.database_principals AS targetPrincipal
        ON targetPrincipal.principal_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 4)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.assemblies.name) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON ASSEMBLY::' + QUOTENAME(sys.assemblies.name) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.assemblies
        ON sys.assemblies.assembly_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 5)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.types.name) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON TYPE::' + QUOTENAME(sys.types.name) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.types
        ON sys.types.user_type_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 6)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.types.name) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON TYPE::' + QUOTENAME(sys.types.name) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.types
        ON sys.types.user_type_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 6)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.xml_schema_collections.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON XML SCHEMA COLLECTION::' + QUOTENAME(sys.xml_schema_collections.name) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.xml_schema_collections
        ON sys.xml_schema_collections.xml_collection_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 10)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.service_message_types.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON MESSAGE TYPE::' + QUOTENAME(sys.service_message_types.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.service_message_types
        ON sys.service_message_types.message_type_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 15)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.service_contracts.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON CONTRACT::' + QUOTENAME(sys.service_contracts.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.service_contracts
        ON sys.service_contracts.service_contract_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 16)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.services.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON SERVICE::' + QUOTENAME(sys.services.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.services
        ON sys.services.service_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 17)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.remote_service_bindings.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON REMOTE SERVICE BINDING::' + QUOTENAME(sys.remote_service_bindings.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.remote_service_bindings
        ON sys.remote_service_bindings.remote_service_binding_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 18)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.routes.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON ROUTE::' + QUOTENAME(sys.routes.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.routes
        ON sys.routes.route_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 19)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.symmetric_keys.name) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON ASYMMETRIC KEY::' + QUOTENAME(sys.symmetric_keys.name) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.symmetric_keys
        ON sys.symmetric_keys.symmetric_key_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 24)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.certificates.name) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON CERTIFICATE::' + QUOTENAME(sys.certificates.name) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.certificates
        ON sys.certificates.certificate_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 25)

    UNION ALL

    SELECT sys.database_permissions.class
        , sys.database_permissions.class_desc
        , sys.database_permissions.major_id
        , sys.database_permissions.minor_id
        , sys.database_permissions.grantee_principal_id
        , sys.database_permissions.grantor_principal_id
        , sys.database_permissions.type
        , sys.database_permissions.permission_name
        , sys.database_permissions.state
        , sys.database_permissions.state_desc
        , QUOTENAME(sys.asymmetric_keys.name) AS granted_on_name
        , CASE 
            WHEN sys.database_permissions.state = N'W'
                THEN N'GRANT'
            ELSE sys.database_permissions.state_desc
            END + N' ' + sys.database_permissions.permission_name COLLATE SQL_Latin1_General_CP1_CI_AS + N' ON ASYMMETRIC KEY::' + QUOTENAME(sys.asymmetric_keys.name) AS permissionstatement
    FROM sys.database_permissions
    INNER JOIN sys.asymmetric_keys
        ON sys.asymmetric_keys.asymmetric_key_id = sys.database_permissions.major_id
    WHERE (sys.database_permissions.major_id >= 0)
        AND (sys.database_permissions.class = 26)
    ) AS databasepermissions
INNER JOIN sys.database_principals AS granteedatabaseprincipal
    ON granteedatabaseprincipal.principal_id = grantee_principal_id
LEFT OUTER JOIN sys.server_principals AS granteeserverprincipal
    ON granteeserverprincipal.sid = granteedatabaseprincipal.sid
INNER JOIN sys.database_principals AS grantor
    ON grantor.principal_id = grantor_principal_id
ORDER BY grantee_name, granted_on_name
