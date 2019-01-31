--l2oqghb8m9.database.windows.net
--SSBRPProduction
SELECT DISTINCT s.ServerName, ds.FriendlyName, s.FQDN, ds.DBName, d.DBType, ds.Username,  ds.EncryptedPassword
FROM dbo.TenantDataSource ds
	INNER JOIN dbo.Server s ON ds.ServerID = s.ServerID
	INNER JOIN dbo.Tenant t ON ds.TenantID = t.TenantID
	INNER JOIN dbo.DBType d ON ds.DBTypeID = d.DBTypeID 
WHERE t.Active = 1
AND ds.IsActive = 1
AND ds.EnvTypeID = 'B9DF5979-0D04-42E2-A641-BEB7E1F70A61' -- Production
AND ds.DBTypeID = '0B23D482-99FE-4127-961E-EB5402DEB7DC' -- Client DW
ORDER BY d.DBType, s.FQDN
