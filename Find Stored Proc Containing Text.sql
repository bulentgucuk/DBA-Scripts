SELECT Name
FROM sys.procedures
WHERE OBJECT_DEFINITION(OBJECT_ID) LIKE '%requestedleadcredits%'  -- search criteria
ORDER BY NAME