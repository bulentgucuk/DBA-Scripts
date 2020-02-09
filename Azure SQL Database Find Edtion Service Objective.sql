-- Execute in master to see all the databases
SELECT  d.name,
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