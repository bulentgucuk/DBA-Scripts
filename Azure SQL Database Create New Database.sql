--Execute in master db

--IF NOT EXISTS (
--	SELECT *
--	FROM	sys.databases
--	WHERE	name = 'SSB_Import_Test1'
--	)
--	BEGIN
--		CREATE DATABASE SSB_Import_Test1
--		(MAXSIZE = 1024 GB, EDITION = 'Hyperscale', SERVICE_OBJECTIVE = 'HS_GEN4_1');
--		(MAXSIZE = 4096 GB, EDITION = 'Premium', SERVICE_OBJECTIVE = 'P11');
--	END
--GO
SELECT name, create_date FROM SYS.databases
WHERE	name = 'SSB_Import_Test1'
