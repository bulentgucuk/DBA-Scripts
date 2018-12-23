--Creating a database

CREATE DATABASE [MeeTwoDB]
(MAXSIZE = 5GB, EDITION = 'standard', SERVICE_OBJECTIVE = 'S2') ;


--Checking details

SELECT Edition = DATABASEPROPERTYEX('MeeTwoDB', 'Edition'),
    ServiceObjective = DATABASEPROPERTYEX('MeeTwoDB', 'ServiceObjective');


--Upgrading a database	   

ALTER DATABASE [MeeTwoDB] MODIFY (EDITION = 'Premium',  SERVICE_OBJECTIVE = 'P1');


-- Recheck
SELECT Edition = DATABASEPROPERTYEX('MeeTwoDB', 'Edition'),
    ServiceObjective = DATABASEPROPERTYEX('MeeTwoDB', 'ServiceObjective');

--Database names and service tiers
--Execute in the master database

SELECT d.name,
    s.database_id,
    s.edition,
    s.service_objective,
    (CASE WHEN s.elastic_pool_name  IS NULL
                THEN 'No Elastic Pool used'
                ELSE s.elastic_pool_name
                END) AS [Elastic Pool details]
FROM sys.databases d
    JOIN sys.database_service_objectives s
    ON d.database_id = s.database_id;


--Move a database into an Elastic Pool

ALTER DATABASE MeeTwoDB
MODIFY ( SERVICE_OBJECTIVE = ELASTIC_POOL ( name = SQLPOOL ) ) ;

--Checking operations 

SELECT *
FROM sys.dm_operation_status
ORDER BY start_time DESC;

--Renaming a database

ALTER DATABASE  facedb_restored
Modify Name = facedb;

--Indexing Information

EXEC sp_BlitzIndex @mode = 4;



