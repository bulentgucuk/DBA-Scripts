/***
This script will creae a database (if the database does not exists) with 3 file groups.
	File group 1 is the primary file group to host the system objects.
	File group 2 is the data file group to host all the user tables and clustered indexes.
	File group 3 is the index file group to host non clustered indexes to support queries.

All the file groups will be created with single file for local development.
Data and log files will be created in where the master database files are.
If that's not wanted then assign a value to @defaultDataLocation and @defaultLogLocation.

Just assign a value to variable @DBName and execute to scripts.
You will get error message if the operation fails.

***/
USE master

DECLARE	@DBName SYSNAME,
		@Str NVARCHAR(MAX),
		@DataFG1 SYSNAME,
		@IndexFG1 SYSNAME;

SELECT	@DBName = 'TestLocalTEST';  --- UPDATE THE NAME OF THE DATABASE

SELECT	@DataFG1 = @DBName + '_DataFG1',
		@IndexFG1 = @DBName + '_IndexFG1';

DECLARE @defaultDataLocation nvarchar(4000),
		@defaultLogLocation nvarchar(4000);

SELECT	@defaultDataLocation = physical_name
FROM	sys.master_files
WHERE	database_id =1
AND		file_id = 1;

SELECT	@defaultLogLocation = physical_name
FROM	sys.master_files
WHERE	database_id =1
AND		file_id = 1;

SELECT	@defaultDataLocation = SUBSTRING(@defaultDataLocation,1, (LEN(@defaultDataLocation) - CHARINDEX ('\',REVERSE (@defaultLogLocation))+1 )),
		@defaultLogLocation = SUBSTRING(@defaultLogLocation,1, (LEN(@defaultLogLocation) - CHARINDEX ('\',REVERSE (@defaultLogLocation))+1 ))

--SELECT	@defaultDataLocation,@defaultLogLocation

-- Build the string to be executed to create the database
SELECT	@Str = 'CREATE DATABASE ' + @DBName + ' ON PRIMARY (NAME = ' + @DBName + '_Primary, FILENAME = ' + '''' +
			@defaultDataLocation  + '\' + @DBName + '.mdf' + '''' + ',' +
			'SIZE = 256MB,FILEGROWTH = 256MB), ' +
			'FILEGROUP ' + @DataFG1 + ' (NAME = ' + @DBName + '_Data_File1, FILENAME = ' + '''' +
			@defaultDataLocation  + '\' + @DBName + '_df1.ndf' + '''' + ',' +
			'SIZE = 512MB,FILEGROWTH = 512MB), ' +
			'FILEGROUP ' + @IndexFG1 + ' (NAME = ' + @DBName + '_Index_File1, FILENAME = ' + '''' +
			@defaultDataLocation  + '\' + @DBName + '_if1.ndf' + '''' + ',' +
			'SIZE = 256MB,FILEGROWTH = 256MB) ' +
			'LOG ON (NAME = ' + @DBName + '_Log, FILENAME = ' + '''' +
			@defaultLogLocation  + '\' + @DBName + '_log.ldf' + '''' + ',' +
			'SIZE = 512MB,FILEGROWTH = 512MB); ' +
			'ALTER AUTHORIZATION ON DATABASE::' + @DBName + ' TO SA;' +
			'ALTER DATABASE ' + @DBName + ' SET RECOVERY SIMPLE;' +
			'ALTER DATABASE ' + @DBName + ' MODIFY FILEGROUP ' + @DataFG1 + ' DEFAULT;'

BEGIN TRY
	PRINT @Str
	EXEC (@Str)
END TRY
BEGIN CATCH
	    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() as ErrorState,
        ERROR_PROCEDURE() as ErrorProcedure,
        ERROR_LINE() as ErrorLine,
        ERROR_MESSAGE() as ErrorMessage;
	
	-- Test XACT_STATE for 1 or -1.
    -- XACT_STATE = 0 means there is no transaction and
    -- a commit or rollback operation would generate an error.

    -- Test whether the transaction is uncommittable.
    IF (XACT_STATE()) = -1
    BEGIN
        PRINT
            N'The transaction is in an uncommittable state. ' +
            'Rolling back transaction.'
        ROLLBACK TRANSACTION;
    END;

    -- Test whether the transaction is active and valid.
    IF (XACT_STATE()) = 1
    BEGIN
        PRINT
            N'The transaction is committable. ' +
            'Committing transaction.'
        COMMIT TRANSACTION;   
    END;
END CATCH;

