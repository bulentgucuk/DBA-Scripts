SELECT @@SERVERNAME;
GO
DROP DATABASE SSBRPProduction;
GO
CREATE DATABASE SSBRPProduction AS COPY OF  [l2oqghb8m9].SSBRPProduction
/**
Msg 40808, Level 16, State 1, Line 5
The edition 'BusinessCritical' does not support the service objective 'S3'.
**/
	(SERVICE_OBJECTIVE = 'P1');




--SELECT @@SERVERNAME;
--GO
--DROP DATABASE SSBRPTest;
--GO
--CREATE DATABASE SSBRPTest AS COPY OF  [ssb-dev-databases].SSBRPTest
--	(SERVICE_OBJECTIVE = 'S0');


-- Reset the user password just in case or test sql login after the database has been copied.


IF (SELECT @@SERVERNAME) = 'ssb-ssb-server'
	BEGIN	
		IF  EXISTS (
		SELECT *
		FROM	sys.databases
		WHERE	name = 'SSBRPProduction_Deploy'
		)
		BEGIN
			DROP DATABASE SSBRPProduction_Deploy;
		END
	END
GO
IF NOT EXISTS (
	SELECT *
	FROM	sys.databases
	WHERE	name = 'SSBRPProduction_Deploy'
	)
	BEGIN
		CREATE DATABASE SSBRPProduction_Deploy
		--(MAXSIZE = 1024 GB, EDITION = 'Hyperscale', SERVICE_OBJECTIVE = 'HS_GEN4_1');
		(MAXSIZE = 100 GB, EDITION = 'Standard', SERVICE_OBJECTIVE = 'S0');
	END
GO