--Find VLF count for all the databases
CREATE TABLE #stage(
	  RecoveryUnitId INT
	, FileID      INT
	, FileSize    BIGINT
	, StartOffset BIGINT
	, FSeqNo      BIGINT
	, [Status]    BIGINT
	, Parity      BIGINT
	, CreateLSN   NUMERIC(38)
);
 
CREATE TABLE #results(
    Database_Name   sysname
  , VLF_count       INT 
);
 
EXEC sp_msforeachdb N'Use ?; 
            Insert Into #stage 
            Exec sp_executeSQL N''DBCC LogInfo(?)''; 
 
            Insert Into #results 
            Select DB_Name(), Count(*) 
            From #stage; 
 
            Truncate Table #stage;'
 
SELECT * 
FROM #results
ORDER BY VLF_count DESC;
 
DROP TABLE #stage;
DROP TABLE #results;