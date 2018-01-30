-- Create user for gholder@ssbinfo.com account
-- In [SSBRPProduction] database
IF NOT EXISTS(SELECT * FROM SYS.DATABASE_PRINCIPALS WHERE NAME = 'gholder@ssbinfo.com')
BEGIN
	CREATE USER [gholder@ssbinfo.com] FROM EXTERNAL PROVIDER;
END
GO
GRANT SELECT ON SCHEMA::[api] TO [gholder@ssbinfo.com];
GO

