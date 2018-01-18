/* 
============================================================
Quick script to enumerate Active directory users who get permissions from An Active Directory Group
============================================================
*/

--a table variable capturing any errors in the try...catch below
DECLARE @ErrorRecap TABLE
	(
		ID INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, AccountName VARCHAR(256)
	, ErrorMessage VARCHAR(256)
	);

DECLARE @groupname VARCHAR(256)
	, @acctname VARCHAR(256);

IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL
	BEGIN
		DROP TABLE #tmp;
	END

IF OBJECT_ID('tempdb.dbo.#tmpdeeper') IS NOT NULL
	BEGIN
		DROP TABLE #tmpdeeper;
	END

CREATE TABLE [dbo].[#TMP]
	(
		[ACCOUNTNAME] VARCHAR(256) NULL
	, [TYPE] VARCHAR(8) NULL
	, [PRIVILEGE] VARCHAR(8) NULL
	, [MAPPEDLOGINNAME] VARCHAR(256) NULL
	, [PERMISSIONPATH] VARCHAR(256) NULL
	);

CREATE TABLE #tmpdeeper
	(
		[ACCOUNTNAME] VARCHAR(256) NULL
	, [TYPE] VARCHAR(8) NULL
	, [PRIVILEGE] VARCHAR(8) NULL
	, [MAPPEDLOGINNAME] VARCHAR(256) NULL
	, [PERMISSIONPATH] VARCHAR(256) NULL
	);

DECLARE cgroup CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY FOR
	SELECT name
		FROM master.sys.server_principals
		WHERE type_desc = 'WINDOWS_GROUP';

OPEN cgroup;
FETCH NEXT FROM cgroup INTO @groupname;
WHILE @@FETCH_STATUS <> -1
	BEGIN
		BEGIN TRY
			INSERT INTO #TMP ( [ACCOUNTNAME]
							, [TYPE]
							, [PRIVILEGE]
							, [MAPPEDLOGINNAME]
							, [PERMISSIONPATH] )
			EXEC master..xp_logininfo @acctname = @groupname
									, @option = 'members';	-- show group members
		END TRY
		BEGIN CATCH
			--capture the error details
			DECLARE @ErrorSeverity INT
				, @ErrorNumber INT
				, @ErrorMessage VARCHAR(4000)
				, @ErrorState INT;
			SET @ErrorSeverity = ERROR_SEVERITY();
			SET @ErrorNumber = ERROR_NUMBER();
			SET @ErrorMessage = ERROR_MESSAGE();
			SET @ErrorState = ERROR_STATE();

			--put all the errors in a table together
			INSERT INTO @ErrorRecap ( AccountName, ErrorMessage )
						SELECT	@groupname, @ErrorMessage;

			PRINT 'Msg ' + CONVERT(VARCHAR, @ErrorNumber) + ' Level '
				+ CONVERT(VARCHAR, @ErrorSeverity) + ' State '
				+ CONVERT(VARCHAR, @ErrorState);
			PRINT @ErrorMessage;
		END CATCH;
		FETCH NEXT FROM cgroup INTO @groupname;
	END;
CLOSE cgroup;
DEALLOCATE cgroup;


DECLARE cuser CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY FOR
	SELECT DISTINCT ACCOUNTNAME
		FROM #TMP
	UNION
	SELECT sp.name
		FROM sys.server_principals sp
		WHERE type_desc = 'WINDOWS_LOGIN'; --'WINDOWS_GROUP' 

OPEN cuser;
FETCH NEXT FROM cuser INTO @acctname;
WHILE @@FETCH_STATUS <> -1
	BEGIN
		BEGIN TRY
			INSERT INTO #tmpdeeper ( [ACCOUNTNAME]
								, [TYPE]
								, [PRIVILEGE]
								, [MAPPEDLOGINNAME]
								, [PERMISSIONPATH] )
			EXECUTE master..xp_logininfo @acctname = @acctname,@option = 'all';
		END TRY
		BEGIN CATCH
			SET @ErrorSeverity = ERROR_SEVERITY();
			SET @ErrorNumber = ERROR_NUMBER();
			SET @ErrorMessage = ERROR_MESSAGE();
			SET @ErrorState = ERROR_STATE();

			--put all the errors in a table together
			INSERT INTO @ErrorRecap ( AccountName, ErrorMessage )
				SELECT	@acctname, @ErrorMessage;

			--echo out the supressed error, the try catch allows us to continue processing, instead of stopping on the first error
			PRINT 'Msg ' + CONVERT(VARCHAR, @ErrorNumber) + ' Level '
				+ CONVERT(VARCHAR, @ErrorSeverity) + ' State '
				+ CONVERT(VARCHAR, @ErrorState);
			PRINT @ErrorMessage;
		END CATCH;
		FETCH NEXT FROM cuser INTO @acctname;
	END;
CLOSE cuser;
DEALLOCATE cuser;

--display both results and errors
SELECT	*
	FROM	#TMP;
SELECT	*
	FROM	#tmpdeeper;
SELECT	*
	FROM	@ErrorRecap;