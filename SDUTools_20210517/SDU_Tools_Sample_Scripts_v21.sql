-- SDU_Tools Version 21.0 Sample Scripts 
-- SDU_Tools Copyright Dr Greg Low

USE DATABASE_NAME_HERE;
GO

----------------------------------------------------
-- SDU_Tools Version 21.0 Sample Scripts 

-- Name:          SDU_Tools.WeekdayAcrossYears
-- Function:      Returns a table of days of the week for a given day over a set of years
-- Parameters:    @StartValue int => first value to return
--                @NumberRequired int => number of numbers to return
-- Action:        For a particular day and month, returns the day of the week for a range of years
-- Return:        Rowset with YearNumber as an integer, and WeekDay as a string

SELECT * FROM SDU_Tools.WeekdayAcrossYears(20, 11, 2021, 2030);

-- Function:      Lists any use of deprecated data types
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists any use of deprecated data types (user tables only)
-- Return:        Rowset containing SchemaName, TableName, ColumnName, DataType, Suggested Alternate Type, and Change Script. 
--                Within each table, columns are listed in column ID order

EXEC SDU_Tools.ListUseOfDeprecatedDataTypes @DatabaseName = N'msdb',
                                            @SchemasToList = N'ALL', 
                                            @TablesToList = N'ALL', 
                                            @ColumnsToList = N'ALL';

                                            -- Function:      Returns the type of SQL Server for the current session
-- Parameters:    Nil
-- Action:        Teturns the type of SQL Server for the current session
-- Return:        nvarchar(40)

SELECT SDU_Tools.SQLServerType();

-- Script Analytics View

SET NOCOUNT ON;
DECLARE @SQL nvarchar(max);

EXEC SDU_Tools.ScriptAnalyticsView
    @DatabaseName = N'WideWorldImporters',
    @TableSchemaName = N'Sales', 
    @TableName = N'Customers', 
    @ViewSchemaName = N'Analytics', 
    @ViewName = N'Customer', 
    @ScriptOutput = @SQL OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @SQL;
GO


----------------------------------------------------
-- SDU_Tools Version 20.0 Sample Scripts 
--
-- 20.0                   DateDimensionPeriodColumns now has IsStartOfMonth, IsEndOfMonth,
--                        IsStartOfCalendarYear, IsEndOfCalendarYear, IsStartOfFiscalYear,
--                        IsEndOfFiscalYear and Quarters both Calendar and Fiscal
--                        DateDimensionColumns now has quarters and start and end of month
--
-- Function:      Returns the nominated day of the target week
-- Parameters:    @DayInTargetWeek date - any day in the target week
--                @DayOfWeek int - Sunday = 1, Monday = 2, etc.
-- Action:        Returns the nominated day in the same week as the target date
-- Return:        date

SELECT SDU_Tools.WeekdayOfSameWeek('20201022', 1); -- Sunday in week of 22nd Oct 2020
SELECT SDU_Tools.WeekdayOfSameWeek('20201022', 5); -- Thursday in week of 22nd Oct 2020

-- Function:      Returns the nearest nominated day to the target date
-- Parameters:    @TargetDate date - the date that we're aiming for
--                @DayOfWeek int - Sunday = 1, Monday = 2, etc.
-- Action:        Returns the nominated day closest to the date supplied
-- Return:        date

SELECT SDU_Tools.NearestWeekday('20201022', 1); -- Sunday closest to 22nd Oct 2020
SELECT SDU_Tools.NearestWeekday('20201022', 3); -- Tuesday closest to 22nd Oct 2020
SELECT SDU_Tools.NearestWeekday('20201022', 5); -- Thursday closest to 22nd Oct 2020

-- Function:      Apply Cobol Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Cobol Casing to a string (similar to programming identifiers)
-- Return:        nvarchar(max)

SELECT SDU_Tools.CobolCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.CobolCase(N'janet mcdermott');
SELECT SDU_Tools.CobolCase(N'the case of sherlock holmes and the curly-Haired  company');

-- Function:      Returns the date of Orthodox Easter in a given year
-- Parameters:    @Year int  -> year number
-- Action:        Calculates the date of Orthodox Easter for
--                a given year, adapted from a code example 
--                courtesy of Antonios Chatzipavlis
-- Return:        date

SELECT SDU_Tools.DateOfOrthodoxEaster(2020);
SELECT SDU_Tools.DateOfOrthodoxEaster(1958);

-- Function:      IsLockPagesInMemoryEnabled
-- Parameters:    Nil
-- Action:        Checks if LPIM is enabled
-- Return:        bit

SELECT SDU_Tools.IsLockPagesInMemoryEnabled();

----------------------------------------------------
-- SDU_Tools Version 19.0 Sample Scripts 
--

-- Function:      Returns a table of dates excluding weekends
-- Parameters:    @StartDate date => first date to return
--                @EndDate => last date to return
-- Action:        Returns a table of dates between the two dates supplied (inclusive)
--                but excluding Saturday and Sunday
-- Return:        Rowset with DateNumber as int and DateValue as a date

SELECT * FROM SDU_Tools.DatesBetweenNoWeekends('20200101', '20200131') ORDER BY DateValue;
SELECT * FROM SDU_Tools.DatesBetweenNoWeekends('20200131', '20200101') ORDER BY DateValue;
GO

-- Function:      Returns the initials from a name
-- Parameters:    @Name nvarchar(max) - the string to process
--                @Separator nvarchar(max) - the separator between initials
-- Action:        Returns the initials from a name, separated by a separator
-- Return:        Single string

SELECT SDU_Tools.InitialsFromName(N'Mary Johanssen', N'');
SELECT SDU_Tools.InitialsFromName(N'Mary Johanssen', N' ');
SELECT SDU_Tools.InitialsFromName(N'Thomas', N' ');
SELECT SDU_Tools.InitialsFromName(N'Test Test', NULL);

-- Function:      Returns a table (single row) of date dimension period columns
-- Parameters:    @Date date => date to process
--                @FiscalYearStartMonth int => month number when the financial year starts
--                @Today date => the current day (or the target day)
-- Action:        Returns a single row table with date dimension period columns
-- Return:        Single row rowset with date dimension period columns

SELECT * FROM SDU_Tools.DateDimensionPeriodColumns('20200131', 7, SYSDATETIME());

SELECT db.DateValue, ddpc.* 
FROM SDU_Tools.DatesBetween('20190201', '20200420') AS db
CROSS APPLY SDU_Tools.DateDimensionPeriodColumns(db.DateValue, 7, SYSDATETIME()) AS ddpc
ORDER BY db.DateValue;

SELECT ddc.*, ddpc.* 
FROM SDU_Tools.DatesBetween('20200201', '20200401') AS db
CROSS APPLY SDU_Tools.DateDimensionColumns(db.DateValue, 7) AS ddc
CROSS APPLY SDU_Tools.DateDimensionPeriodColumns(db.DateValue, 7, SYSDATETIME()) AS ddpc
ORDER BY db.DateValue;

-- Function:      Calculates a number of hours from a timezone offset
-- Parameters:    @TimezoneOffset nvarchar(20) => as returned by sys.time_zone_info
-- Action:        Calculates a number of hours from a timezone offset
-- Return:        decimal(18,2)

SELECT SDU_Tools.TimezoneOffsetToHours(N'-11:00');

SELECT * FROM sys.time_zone_info AS tzi;
SELECT *, SDU_Tools.TimezoneOffsetToHours(tzi.current_utc_offset) AS HoursOffset
FROM sys.time_zone_info AS tzi;

-- Function:      Return date of the start of the year
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the first date of the year for any given date 
-- Return:        date

SELECT SDU_Tools.StartOfYear('20180713');
SELECT SDU_Tools.StartOfYear(SYSDATETIME());
SELECT SDU_Tools.StartOfYear(GETDATE());

-- Function:      Return date of the end of the year
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the last date of the year for any given date 
-- Return:        date

SELECT SDU_Tools.EndOfYear('20180713');
SELECT SDU_Tools.EndOfYear(SYSDATETIME());
SELECT SDU_Tools.EndOfYear(GETDATE());

-- Function:      Return date of the start of the week
--                Note: assumption is a Sunday start (easy to modify if needed)
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the first date of the week for any given date 
-- Return:        date

SELECT SDU_Tools.StartOfWeek('20200713');
SELECT SDU_Tools.StartOfWeek(SYSDATETIME());
SELECT SDU_Tools.StartOfWeek(GETDATE());

-- Function:      Return date of the end of the week
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the last date of the week for any given date 
-- Return:        date

SELECT SDU_Tools.EndOfWeek('20200713');
SELECT SDU_Tools.EndOfWeek(SYSDATETIME());
SELECT SDU_Tools.EndOfWeek(GETDATE());

-- Function:      Return date of the start of the working week
--                Note: assumption is working week is Monday to Friday (easy to modify if needed)
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the first date of the working week for any given date 
-- Return:        date

SELECT SDU_Tools.StartOfWorkingWeek('20200713');
SELECT SDU_Tools.StartOfWorkingWeek(SYSDATETIME());
SELECT SDU_Tools.StartOfWorkingWeek(GETDATE());

-- Function:      Return date of the end of the working week
--                Note: assumption is working week is Monday to Friday (easy to modify if needed)
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the last date of the working week for any given date 
-- Return:        date

SELECT SDU_Tools.EndOfWorkingWeek('20200713');
SELECT SDU_Tools.EndOfWorkingWeek(SYSDATETIME());
SELECT SDU_Tools.EndOfWorkingWeek(GETDATE());

-- Function:      Returns the decimal separator for the current session
-- Parameters:    None
-- Action:        Works out what the decimal separator is for the current session
-- Return:        varchar(1)

/* SELECT CAST(FORMAT(123456.789, 'N', 'de-de') AS varchar(20)); */
SELECT SDU_Tools.CurrentSessionDecimalSeparator();

-- Function:      Returns the thousands separator for the current session
-- Parameters:    None
-- Action:        Works out what the thousands separator is for the current session
-- Return:        varchar(1)

SELECT SDU_Tools.CurrentSessionThousandsSeparator();

-- Function:      Strips diacritics (accents, graves, etc.) from a string
-- Parameters:    @InputString nvarchar(max) - string to strip
-- Action:        Strips diacritics (accents, graves, etc.) from a string
-- Return:        nvarchar(max)

SELECT SDU_Tools.StripDiacritics(N'śŚßťŤÄÅàá');

-- Function:      Converts a datetime2 value to Unix time
-- Parameters:    @ValueToConvert datetime2(0) -> the value to convert
-- Action:        Converts a datetime2 value to Unix time
-- Return:        int

SELECT SDU_Tools.DateTime2ToUnixTime(SYSDATETIME());

-- Function:      Converts a Unix time to a datetime2 value
-- Parameters:    @ValueToConvert int -> the value to convert
-- Action:        Converts a Unix time to a datetime2 value
-- Return:        datetime2(0)

SELECT SDU_Tools.UnixTimeToDateTime2(1586689900);

----------------------------------------------------
-- SDU_Tools Version 18.0 Sample Scripts 

-- Note: version 18.0 included some version updates but
-- added no new tools. Primary reason for release was 
-- to add support for Azure SQL DB scripts

----------------------------------------------------
-- SDU_Tools Version 17.0 Sample Scripts 

-- Function:      Returns a table of dates 
-- Parameters:    @StartDate date => first date to return
--                @NumberOfIntervals int => number of intervals to add to first date
--                @IntervalCode varchar(10) => code for the interval YEAR, QUARTER, MONTH, WEEK, DAY
-- Action:        Returns a table of dates 
-- Return:        Rowset with DateNumber as int and DateValue as a date
-- Refer to this video: TODO
--
-- Test examples: 

SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 1, 'YEAR');
SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 3, 'QUARTER');
SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 1, 'MONTH');
SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 3, 'WEEK');
SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 1, 'DAY');
SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 3, 'INVALID');

-- Function:      Returns the maximum database compatibility level for the server (master db)
-- Parameters:    None
-- Action:        Returns the maximum database compatibility level for the server
-- Return:        tinyint

SELECT SDU_Tools.ServerMaximumDBCompatibilityLevel();

-- Function:      Sets the database compability level for all databases to the 
--                maximum supported by the server
-- Parameters:    None
-- Action:        Sets the database compability level for all databases
-- Return:        None

ALTER DATABASE model SET COMPATIBILITY_LEVEL = 140;
GO

SELECT [name], compatibility_level FROM sys.databases ORDER BY database_id;
GO

EXEC SDU_Tools.SetDatabaseCompabilityForAllDatabasesToMaximum;
GO

SELECT [name], compatibility_level FROM sys.databases ORDER BY database_id;
GO

-- Function:      Returns the nth weekday of the month
-- Parameters:    @Year int - the year
--                @Month int - the month
--                @WeekdayNumber int - positive counting from start of month
--                                   - negative counting back from end of month
-- Action:        Returns the maximum database compatibility level for the server
-- Return:        date

SELECT SDU_Tools.WeekdayOfMonth(2020, 2, 1); -- first weekday of Feb 2020
SELECT SDU_Tools.WeekdayOfMonth(2020, 2, -1); -- last weekday of Feb 2020
SELECT SDU_Tools.WeekdayOfMonth(2020, 2, 7); -- seventh weekday of Feb 2020

-- Function:      Returns the nth nominated day of the month
-- Parameters:    @Year int - the year
--                @Month int - the month
--                @DayOfWeek int - Sunday = 1, Monday = 2, etc.
--                @DayNumber int - day number (i.e. 3 for 3rd Monday)
-- Action:        Returns the nth nominated day of the month
-- Return:        date

SELECT SDU_Tools.DayNumberOfMonth(2020, 2, 1, 1); -- first Sunday of Feb 2020
SELECT SDU_Tools.DayNumberOfMonth(2020, 2, 1, 2); -- second Sunday of Feb 2020
SELECT SDU_Tools.DayNumberOfMonth(2020, 2, 3, 2); -- second Tuesday of Feb 2020
SELECT SDU_Tools.DayNumberOfMonth(2020, 2, 4, 3); -- third Wednesday of Feb 2020

-- Function:      Table of countries
-- Parameters:    N/A
-- Action:        Table of countries
-- Return:        Rowset 

SELECT * 
FROM SDU_Tools.Countries
ORDER BY CountryCode;

-- Function:      Table of common world currencies
-- Parameters:    N/A
-- Action:        Table of common world currencies
-- Return:        Rowset 

SELECT * 
FROM SDU_Tools.Currencies
ORDER BY CurrencyCode;

-- Function:      Table of countries and the currencies they use
-- Parameters:    N/A
-- Action:        Table of countries and the currencies they use
-- Return:        Rowset 

SELECT * 
FROM SDU_Tools.CurrenciesByCountry
ORDER BY CountryCode, CurrencyCode;

SELECT c.CountryCode, c.CountryName,
       cur.CurrencyCode, cur.CurrencyName,
       cur.CurrencySymbol
FROM SDU_Tools.CurrenciesByCountry AS cbc
INNER JOIN SDU_Tools.Countries AS c
ON c.CountryCode = cbc.CountryCode 
INNER JOIN SDU_Tools.Currencies AS cur
ON cur.CurrencyCode = cbc.CurrencyCode
WHERE c.CountryName = N'Tuvalu';

----------------------------------------------------
-- SDU_Tools Version 16.0 Sample Scripts 

-- Function:      CheckInstantFileInitializationState
-- Parameters:    Nil
-- Action:        Checks if IFI is enabled (Note: for systems earlier than SQL Server 2014 SP2
--                the procedure must create and drop a database to test this
-- Return:        Single row with one column IsIFIEnabled bit
-- Refer to this video: TODO
--
-- Test examples: 

EXEC SDU_Tools.CheckInstantFileInitializationState;

-- Function:      SQLServerVersion
-- Parameters:    Nil
-- Action:        Returns the version of SQL Server (e.g. 2012, 2014, 2008R2)
-- Return:        SQL Server version as nvarchar(20)
-- Refer to this video: TODO
--
-- Test examples: 

SELECT SDU_Tools.SQLServerVersion();

-- Function:      Scripts all user-defined server roles
-- Parameters:    Nil
-- Action:        Scripts all user-defined server roles, including disabled state where applicable
-- Return:        nvarchar(max)

USE master;
GO

CREATE SERVER ROLE DiagnosticsTeam;
GO

GRANT ALTER TRACE TO DiagnosticsTeam;
GO

USE [DATABASE_NAME_HERE];
GO

SELECT SDU_Tools.ScriptUserDefinedServerRoles();
GO

DROP SERVER ROLE DiagnosticsTeam;
GO

-- Function:      Scripts all permissions for user-defined server roles
-- Parameters:    Nil
-- Action:        Scripts all permissions for user-defined server roles
-- Return:        nvarchar(max)

USE master;
GO

CREATE SERVER ROLE DiagnosticsTeam;
GO

GRANT ALTER TRACE TO DiagnosticsTeam;
GO

USE [DATABASE_NAME_HERE];
GO

SELECT SDU_Tools.ScriptUserDefinedServerRolePermissions();
GO

DROP SERVER ROLE DiagnosticsTeam;
GO

-- Function:      Scripts all user-defined database roles
-- Parameters:    @Database to script
-- Action:        Scripts all user-defined database roles, including disabled state where applicable
-- Return:        Single column called ScriptOutput nvarchar(max)

CREATE ROLE ProcedureWriters;
GO

GRANT CREATE PROCEDURE TO ProcedureWriters;
GRANT VIEW DEFINITION TO ProcedureWriters;
GO

SET NOCOUNT ON;
DECLARE @SQL nvarchar(max);

EXEC SDU_Tools.ScriptUserDefinedDatabaseRoles N'DATABASE_NAME_HERE', @SQL OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @SQL;
GO

DROP ROLE ProcedureWriters;
GO

-- Function:      Scripts all permissions for user-defined database roles
-- Parameters:    @Database to script
-- Action:        Scripts all permissions for user-defined database roles
-- Return:        Single column called ScriptOutput nvarchar(max)


CREATE ROLE ProcedureWriters;
GO

GRANT CREATE PROCEDURE TO ProcedureWriters;
GRANT VIEW DEFINITION TO ProcedureWriters;
GO

SET NOCOUNT ON;
DECLARE @SQL nvarchar(max);

EXEC SDU_Tools.ScriptUserDefinedDatabaseRolePermissions N'DATABASE_NAME_HERE', @SQL OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @SQL;
GO

DROP ROLE ProcedureWriters;
GO

-- Function:      Returns a table of time periods (start of each time period)
-- Parameters:    @StartTime time => first time to return
--                @EndTime => last time that can be returned
--                @MinutesPerPeriod => number of minutes in each time period for the day
-- Action:        Returns a table of times starting at the first time provided, increasing
--                by the number of minutes per period, and ending at or before the last time
--                Calculations are done to the seconds level, not smaller timeperiods
-- Return:        Rowset with TimePeriodKey as int and TimeValue as a time

SELECT * FROM SDU_Tools.TimePeriodsBetween('00:00:00', '23:59:59', 15);
SELECT * FROM SDU_Tools.TimePeriodsBetween('01:00:00', '22:00:00', 15);
GO

-- Note: adapted from standard EmptySchema tool to work only in the current database
--       which makes it useful in Azure SQL DB where you can't use USE

-- Function:      Removes objects in the specified schema in the specified database
-- Parameters:    @SchemaName -> schema to empty (cannot be dbo, sys, or SDU_Tools)
-- Action:        Removes objects in the specified schema in the current database
-- Return:        Nil

USE WideWorldImporters;
GO
CREATE SCHEMA XYZABC AUTHORIZATION dbo;
GO
CREATE TABLE XYZABC.TestTable (TestTableID int IDENTITY(1,1) PRIMARY KEY);
GO
EXEC SDU_Tools.EmptySchemaInCurrentDatabase @SchemaName = N'XYZABC';
GO

-- Function:      Returns NULL if the string contains no characters, else trims the string
-- Parameters:    @InputString nvarchar(max) - the string to process
-- Action:        Returns a NULL string if the string contains no characters, else trims the string
-- Return:        nvarchar(max)

SELECT N'->' + SDU_Tools.NullIfBlank('xx ') + N'<-';
SELECT N'->' + SDU_Tools.NullIfBlank('  xx ') + N'<-';
SELECT N'->' + SDU_Tools.NullIfBlank('   ') + N'<-';

-- Function:      Returns NULL if the value is zero
-- Parameters:    @InputValue decimal(18,2) - the value to process
-- Action:        Returns a NULL decimal if the value is zero
-- Return:        decimal(18,2)

SELECT SDU_Tools.NullIfZero(18.2);
SELECT SDU_Tools.NullIfZero(5);
SELECT SDU_Tools.NullIfZero(0);

----------------------------------------------------
-- SDU_Tools Version 15.0 Sample Scripts 

-- TrimWhitespace now trims a more complete set of whitespace characters
-- including Unicode whitespace characters, not just the ASCII ones

-- Function:      Returns the total number of days in the month for a given date
-- Parameters:    @Date date
-- Action:        Returns the total number of days in the month for a given date
-- Return:        int - Number of days

SELECT SDU_Tools.DaysInMonth(SYSDATETIME());
SELECT SDU_Tools.DaysInMonth('20190204');
SELECT SDU_Tools.DaysInMonth('20160204');

-- Function:      Determines if an input string is a valid IP v2 address
-- Parameters:    @InputString nvarchar(max)
-- Action:        Determines if an input string is a valid IP v2 address
-- Return:        bit with 0 for no, and 1 for yes

SELECT SDU_Tools.IsIPv4Address('alsk.sdfsf..s.dfsdf.s.df');
SELECT SDU_Tools.IsIPv4Address('192.168.170.1');
SELECT SDU_Tools.IsIPv4Address('292.168.170.1050');
SELECT SDU_Tools.IsIPv4Address('a.b.c.d');

-- Function:      Performs ROT-13 encoding or decoding of a string
-- Parameters:    @InputString nvarchar(max)
-- Action:        Performs ROT-13 encoding or decoding of a string
-- Return:        nvarchar(max) - ROT-13 encoded/decoded string

SELECT SDU_Tools.ROT13('This is a fairly standard sentence');
SELECT SDU_Tools.ROT13(N'NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm');
SELECT SDU_Tools.ROT13('This is a test string with 14 values');
SELECT SDU_Tools.ROT13('Guvf vf n snveyl fgnaqneq fragrapr');

-- Function:      Returns a string with all words single-spaced
-- Parameters:    @InputString nvarchar(max)
-- Action:        Removes any whitespace characters and returns words single-spaced
-- Return:        nvarchar(max)

SELECT '-->' + SDU_Tools.SingleSpaceWords('Test String') + '<--';
SELECT '-->' + SDU_Tools.SingleSpaceWords('  Test String     ') + '<--';
SELECT '-->' + SDU_Tools.SingleSpaceWords('  Test     String     Ending') + '<--';

-- Function:      Lists empty user tables
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists the schema and table names for all empty tables
-- Return:        Rowset containing SchemaName, TableName in alphabetical order 

EXEC SDU_Tools.ListEmptyUserTables @DatabaseName = N'WideWorldImporters',
                                   @SchemasToList = N'ALL', 
                                   @TablesToList = N'ALL';

-- Function:      Counts the number of tokens in a delimited string (usually either a CSV or TSV)
-- Parameters:    @StringToTokenize nvarchar(max)    -> string that will be tokenized
--                @Delimiter nvarchar(10)            -> delimited used (usually either N',' or NCHAR(9) for tab)
-- Action:        Tokenizes a delimited string and counts the number of tokens
--                Delimiter can be specified
-- Return:        Count of the number of tokens
-- Refer to this video: TODO

SELECT SDU_Tools.NumberOfTokens(N'hello, there, greg', N',');
SELECT SDU_Tools.NumberOfTokens(N'hello' + NCHAR(9) + N'there' + NCHAR(9) + N'greg', NCHAR(9));
SELECT SDU_Tools.NumberOfTokens(N'Now works, with embedded ,% signs', N',');


-- Function:      Extracts a specific token from a delimited string (usually either a CSV or TSV)
-- Parameters:    @StringToTokenize nvarchar(max)    -> string that will be tokenized
--                @Delimiter nvarchar(10)            -> delimited used (usually either N',' or NCHAR(9) for tab)
--                @TokenNumber int                   -> token that is required - starting at 1
--                @TrimOutput bit                    -> should the output be trimmed?
-- Action:        Extracts a specific token from a delimited string
--                Delimiter can be specified
--                Optionally trims the token
-- Return:        Extracts a specific token as nvarchar(max)

SELECT SDU_Tools.ExtractToken(N'hello, there, greg', N',', 1, 1);
SELECT SDU_Tools.ExtractToken(N'hello' + NCHAR(9) + N'there' + NCHAR(9) + N'greg', NCHAR(9), 2, 0);
SELECT SDU_Tools.ExtractToken(N'Now works, with embedded ,% signs', N',', 3, 1);

-- Function:      Executes a T-SQL Command in each database
-- Parameters:    @DatabasesToInclude nvarchar(max) -> 'ALL' or a comma-delimited list of databases
--                @IncludeSystemDatabases bit       -> Should system databases be included
--                @CommandToExecute                 -> T-SQL command to execute
--                                                     Default is SELECT DB_NAME(), @@VERSION;
-- Action:        Executes a T-SQL Command in each database
-- Return:        Nil 

EXEC SDU_Tools.ExecuteCommandInEachDB;

EXEC SDU_Tools.ExecuteCommandInEachDB 
     @DatabasesToInclude = N'master,AdventureWorks,WideWorldImporters',
     @IncludeSystemDatabases = 1,
     @CommandToExecute = N'SELECT DB_NAME(), USER_NAME()';

-- Function:      Creates a SQL Login with SID retrieved from a database
-- Parameters:    @SQLLoginName sysname             -> Name of the login to create
--                @Password nvarchar(128)           -> Password to assign
--                @SIDDatabaseName sysname          -> Database to retrieve the SID from
--                @DefaultDatabase sysname          -> (Optional) default database for the login
--                @DefaultLanguage sysname          -> (Optional) default language for the login
--                @IsCheckExpiration bit            -> (Optional default 1) is expiration to be checked?
--                @IsCheckPolicy bit                -> (Optional default 1) is policy checked?
--                @SIDDatabaseUserName sysname      -> (Optional default @SQLLoginName) 
--                                                     Username to retrieve SID for 
-- Action:        Creates a SQL Login with SID retrieved from a database
-- Return:        Nil 

CREATE LOGIN TestSIDUser WITH PASSWORD = N'VerySecretStuff1123!', CHECK_POLICY = OFF;
GO

CREATE DATABASE TestSID
ON
( 
    NAME = TestSID_dat,
    FILENAME = 'C:\Temp\TestSID.mdf'
)
LOG ON
( 
    NAME = TestSID_log,
    FILENAME = 'C:\Temp\TestSID.ldf'
);
GO

USE TestSID;
GO

CREATE USER TestSIDUser FOR LOGIN TestSIDUser;
GO

USE master;
EXEC sp_detach_db TestSID;
GO

DROP LOGIN TestSIDUser;
GO

CREATE DATABASE TestSID
ON
( 
    NAME = TestSID_dat,
    FILENAME = 'C:\Temp\TestSID.mdf'
)
LOG ON
( 
    NAME = TestSID_log,
    FILENAME = 'C:\Temp\TestSID.ldf'
)
FOR ATTACH;
GO


USE DATABASE_NAME_HERE;
GO

EXEC SDU_Tools.CreateSQLLoginWithSIDFromDB
     @SQLLoginName = N'TestSIDUser',
     @Password = N'2080492sdfsfdSS!',
     @SIDDatabaseName = N'TestSID';
GO

DROP LOGIN TestSIDUser;
GO

DROP DATABASE TestSID;
GO  

-- Function:      Returns the length of a string
-- Parameters:    @InputString nvarchar(max) - the string whose length to determine
-- Action:        Determines the length of a string 
--                Unlike LEN(), does not ignore trailing blanks
-- Return:        int

SELECT LEN('Hello  '), LEN('Hello');
SELECT SDU_Tools.StringLength('Hello   ');

----------------------------------------------------
-- SDU_Tools Version 14.0 Sample Scripts 

-- View:          LatestSQLServerBuilds
-- Action:        View returning latest release and patch level for all supported
--                SQL Server versions
-- Return:        One or two rows per version; two rows is a patch level exists

-- Already have
SELECT * FROM SDU_Tools.SQLServerProductVersions;
GO

SELECT * 
FROM SDU_Tools.LatestSQLServerBuilds 
ORDER BY SQLServerVersion DESC, Build;

-- Function:      Returns the SDU Tools Version
-- Parameters:    Nil
-- Action:        Returns the SDU Tools Version
-- Return:        nvarchar(max)

SELECT SDU_Tools.SDUToolsVersion() AS [SDU Tools Version];

-- Function:      Adds a number of weekdays (non-weekend-days) to a start date
-- Parameters:    @StartDate date -> date to start calculating from
--                @NumberOfWeekdays int -> number of weekdays to add
-- Action:        Adds a number of weekdays (non-weekend-days) to a start date
-- Return:        date - calculated date

SELECT SDU_Tools.AddWeekdays('20190201', 5);
SELECT SDU_Tools.AddWeekdays('20190201', 32);
SELECT SDU_Tools.AddWeekdays('20190228', 47);

-- Function:      Returns the value converted to a string with trailing zeroes truncated
-- Parameters:    @ValueToTruncate decimal(18, 6) -> the value to be truncated
-- Action:        Returns the value converted to a string with trailing zeroes truncated
-- Return:        nvarchar(40)

SELECT SDU_Tools.TruncateTrailingZeroes(123.11);
SELECT SDU_Tools.TruncateTrailingZeroes(123.00);
SELECT SDU_Tools.TruncateTrailingZeroes(123.010);

-- Function:      RetrustForeignKeys
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Tries to retrust untrusted foreign keys. Ignores disabled foreign keys.
-- Return:        Nil

USE WideWorldImporters;
GO

ALTER TABLE Sales.Invoices 
NOCHECK CONSTRAINT FK_Sales_Invoices_Application_People;
GO

ALTER TABLE Sales.Invoices 
WITH NOCHECK CHECK CONSTRAINT FK_Sales_Invoices_Application_People;
GO

SELECT [name], is_disabled, is_not_trusted 
FROM sys.foreign_keys 
WHERE OBJECT_NAME(parent_object_id) = N'Invoices';
GO

USE DATABASE_NAME_HERE;
GO

EXEC SDU_Tools.RetrustForeignKeys 
     @DatabaseName = N'WideWorldImporters',
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 
GO

USE WideWorldImporters;
GO

SELECT [name], is_disabled, is_not_trusted 
FROM sys.foreign_keys 
WHERE OBJECT_NAME(parent_object_id) = N'Invoices';
GO

-- Function:      RetrustCheckConstraints
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Tries to retrust untrusted check constraints. Ignores disabled constraints.
-- Return:        Nil

USE WideWorldImporters;
GO

ALTER TABLE Sales.Invoices 
NOCHECK CONSTRAINT CK_Sales_Invoices_ReturnedDeliveryData_Must_Be_Valid_JSON;
GO

ALTER TABLE Sales.Invoices 
WITH NOCHECK CHECK CONSTRAINT CK_Sales_Invoices_ReturnedDeliveryData_Must_Be_Valid_JSON;
GO

SELECT [name], is_disabled, is_not_trusted 
FROM sys.check_constraints
WHERE OBJECT_NAME(parent_object_id) = N'Invoices';
GO

USE DATABASE_NAME_HERE;
GO

EXEC SDU_Tools.RetrustCheckConstraints
     @DatabaseName = N'WideWorldImporters',
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 
GO

USE WideWorldImporters;
GO

SELECT [name], is_disabled, is_not_trusted 
FROM sys.check_constraints 
WHERE OBJECT_NAME(parent_object_id) = N'Invoices';
GO

-- Function:      Scripts all database object permissions
-- Parameters:    @Database to script
-- Action:        Scripts all database object premissions
-- Return:        Single column called ScriptOutput nvarchar(max)

SET NOCOUNT ON;
DECLARE @SQL nvarchar(max);

EXEC SDU_Tools.ScriptDatabaseObjectPermissions N'ReportServer', @SQL OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @SQL;
----------------------------------------------------
-- SDU_Tools Version 13.0 Sample Scripts 

-- Function:      Maps login types to names and descriptions
-- Parameters:    N/A
-- Action:        Maps login types to names and descriptions
-- Return:        Rowset 

SELECT * 
FROM SDU_Tools.LoginTypes 
ORDER BY LoginTypeID;

-- Function:      Maps user types to names and descriptions
-- Parameters:    N/A
-- Action:        Maps user types to names and descriptions
-- Return:        Rowset 

SELECT * 
FROM SDU_Tools.UserTypes 
ORDER BY UserTypeID;

-- Function:      Maps Years to Chinese Years
-- Parameters:    N/A
-- Action:        Maps Years to Chinese Years
-- Return:        Rowset 

SELECT * 
FROM SDU_Tools.ChineseYears
ORDER BY [Year];

SELECT ChineseNewYearDate 
FROM SDU_Tools.ChineseYears 
WHERE [Year] = 2019;

-- Function:      Returns the date of Chinese New Year in a given year
-- Parameters:    @Year int  -> year number  (must be between 1900 and 2099)
-- Action:        Calculates the date of Chinese New Year for a given year
-- Return:        date

SELECT SDU_Tools.DateOfChineseNewYear(2019);
SELECT SDU_Tools.DateOfChineseNewYear(1958);

-- Function:      Returns the zodiac animal name for Chinese New Year in a given year
-- Parameters:    @Year int  -> year number  (must be between 1900 and 2099)
-- Action:        Returns the zodiac animal name for Chinese New Year in a given year

SELECT SDU_Tools.ChineseNewYearAnimalName(2019);
SELECT SDU_Tools.ChineseNewYearAnimalName(1958);

-- Function:      Maps reporting services catalog types to names
-- Parameters:    N/A
-- Action:        Maps reporting services catalog types to names
-- Return:        Rowset 

SELECT * 
FROM SDU_Tools.RSCatalogTypes 
ORDER BY CatalogTypeID;

-- Function:      RSListUserAccessToContent
-- Parameters:    @IsOrderedByUserName bit      -> Is the output ordered by user (default yes else by item)
--                @@RSDatabaseName sysname      -> Reporting Services DB name (default is ReportServer)
-- Action:        Details which RS users have access to which content (reports, folders, etc.)
-- Return:        Rowset

EXEC SDU_Tools.RSListUserAccessToContent;

EXEC SDU_Tools.RSListUserAccessToContent
    @IsOrderedByUserName = 0,
    @RSDatabaseName = N'ReportServer';

-- Function:      RSListContentItems
-- Parameters:    @RSDatabaseName sysname      -> Reporting Services DB name (default is ReportServer)
-- Action:        Details of all reporting services content (reports, folders, etc.)
-- Return:        Rowset

EXEC SDU_Tools.RSListContentItems;

EXEC SDU_Tools.RSListContentItems
    @RSDatabaseName = N'ReportServer';

-- Function:      RSListUserAccess
-- Parameters:    @IsOrderedByUserName bit      -> Is the output ordered by user (default yes else by role)
--                @RSDatabaseName sysname       -> Reporting Services DB name (default is ReportServer)
-- Action:        Details RS users and their roles
-- Return:        Rowset

EXEC SDU_Tools.RSListUserAccess;

EXEC SDU_Tools.RSListUserAccess
    @IsOrderedByUserName = 0,
    @RSDatabaseName = N'ReportServer';

-- Update to ProperCase function to add BBQ

SELECT SDU_Tools.ProperCase(N'Now is the time for a bbq folks');

----------------------------------------------------
-- SDU_Tools Version 12.0 Sample Scripts 

-- Function:      SetAnsiNullsQuotedIdentifierForStoredProcedures
-- Parameters:    @DatabaseName sysname                    -> Database name for the procedures to be altered
--                @SchemaName sysname                      -> Schema name for the procedure to be altered or ALL
--                @ProcedureName sysname                   -> Procedure name for the procedure to be altered or ALL
--                @NeedsAnsiNulls bit                      -> Should ANSI_NULLS be turned on?
--                @NeedsQuotedIdentifier bit               -> Should QUOTED_IDENTIFIER be turned on?
--                @IHaveABackup bit                        -> Don't do this without a backup (just in case)
-- Action:        Changes the ANSI_NULLS and QUOTED_IDENTIFIER settings for selected procedures
-- Return:        No rows returned

SET ANSI_NULLS OFF;
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE dbo.GetVersion
AS
BEGIN
    SELECT @@VERSION;
END;
GO

SELECT s.[name] AS SchemaName, o.[name] AS ProcedureName, 
       m.uses_ansi_nulls AS AnsiNulls, 
       m.uses_quoted_identifier AS QuotedIdentifier
FROM sys.sql_modules AS m
INNER JOIN sys.objects AS o 
ON o.object_id = m.object_id
INNER JOIN sys.schemas AS s
ON s.schema_id = o.schema_id 
WHERE o.type_desc = 'SQL_STORED_PROCEDURE'
AND s.[name] = N'dbo'
AND o.[name] = N'GetVersion';
GO

DECLARE @CurrentDatabaseName sysname = DB_NAME();
EXEC SDU_Tools.SetAnsiNullsQuotedIdentifierForStoredProcedures 
    @DatabaseName = @CurrentDatabaseName,
    @SchemaName = 'dbo',
    @ProcedureName = 'GetVersion',
    @NeedsAnsiNulls = 1,
    @NeedsQuotedIdentifier = 1,
    @IHaveABackUp = 1;
GO

SELECT s.[name] AS SchemaName, o.[name] AS ProcedureName, 
       m.uses_ansi_nulls AS AnsiNulls, 
       m.uses_quoted_identifier AS QuotedIdentifier
FROM sys.sql_modules AS m
INNER JOIN sys.objects AS o 
ON o.object_id = m.object_id
INNER JOIN sys.schemas AS s
ON s.schema_id = o.schema_id 
WHERE o.type_desc = 'SQL_STORED_PROCEDURE'
AND s.[name] = N'dbo'
AND o.[name] = N'GetVersion';
GO

DROP PROCEDURE dbo.GetVersion;
GO

-- Function:      Determines if the provided date is a week day (Monday to Friday)
-- Parameters:    @Input date (NULL for today)
-- Action:        Determines if the provided date is a week day (Monday to Friday) 
-- Return:        bit

SELECT SDU_Tools.IsWeekday('20180713');
SELECT SDU_Tools.IsWeekday('20180811');
SELECT SDU_Tools.IsWeekday(SYSDATETIME());
SELECT SDU_Tools.IsWeekday(NULL);

-- Function:      Determines if the provided date is a weekend day (Saturday or Sunday)
-- Parameters:    @Input date (NULL for today)
-- Action:        Determines if the provided date is a weekend day (Saturday or Sunday) 
-- Return:        bit

SELECT SDU_Tools.IsWeekend('20180713');
SELECT SDU_Tools.IsWeekend('20180811');
SELECT SDU_Tools.IsWeekend(SYSDATETIME());
SELECT SDU_Tools.IsWeekend(NULL);

-- Function:      Converts a number to a text string containing Roman Numerals
-- Parameters:    @InputNumber bigint - the value to be converted
-- Action:        Converts a number to a text string containing Roman Numerals
-- Return:        nvarchar(max)

SELECT SDU_Tools.NumberToRomanNumerals(9);
SELECT SDU_Tools.NumberToRomanNumerals(27);
SELECT SDU_Tools.NumberToRomanNumerals(2018);
SELECT SDU_Tools.NumberToRomanNumerals(12342);
SELECT SDU_Tools.NumberToRomanNumerals(657);
SELECT SDU_Tools.NumberToRomanNumerals(342);
SELECT SDU_Tools.NumberToRomanNumerals(53342);

-- Function:      ListDisabledIndexes
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List indexes that are disabled with both key and included column lists
-- Return:        Rowset of indexes

USE WideWorldImporters;
GO

ALTER INDEX FK_Sales_InvoiceLines_InvoiceID
ON Sales.InvoiceLines DISABLE;
GO

USE DATABASE_NAME_HERE;
GO

EXEC SDU_Tools.ListDisabledIndexes @DatabaseName = N'WideWorldImporters',
                                   @SchemasToList = N'ALL', 
                                   @TablesToList = N'ALL'; 

USE WideWorldImporters;
GO

ALTER INDEX FK_Sales_InvoiceLines_InvoiceID
ON Sales.InvoiceLines REBUILD;
GO

USE DATABASE_NAME_HERE;
GO

-- Function:      Lists the user tables that do not have a clustered index declared
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists the user tables that do not have a clustered index declared
-- Return:        Rowset containing SchemaName, TableName

EXEC SDU_Tools.ListUserHeapTables 
    @DatabaseName = N'WideWorldImporters',
    @SchemasToList = N'ALL', 
    @TablesToList = N'ALL';

-- Function:      Lists the user tables that do not have a primary key declared
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists the user tables that do not have a primary key declared
-- Return:        Rowset containing SchemaName, TableName

EXEC SDU_Tools.ListUserTablesWithNoPrimaryKey 
    @DatabaseName = N'WideWorldImporters',
    @SchemasToList = N'ALL', 
    @TablesToList = N'ALL';

-- Function:      ScriptTableAsUnpivot
-- Parameters:    @SourceDatabaseName sysname              -> Database name for the table to be scripted
--                @SourceTableSchemaName sysname           -> Schema name for the table to be scripted
--                @SourceTableName sysname                 -> Table name for the table to be scripted
--                @OutputViewSchemaName sysname            -> Schema name for the output script (defaults to same as existing schema)
--                @OutputViewName sysname                  -> View name for the output script (defaults to same as existing table
--                                                            with _Unpivoted appended)
--                @IsViewScript bit                        -> Is a view being created? If not, a query is created. (defaults to query)
--                @IncludeNullColumns bit                  -> Should columns whose values are NULL be output? (defaults to no)
--                @ColumnIndentSize                        -> How far should columns be indented from the table definition (defaults to 4)
--                @ScriptIndentSize                        -> How far indented should the script be? (defaults to 0)
--                @QueryScript nvarchar(max) OUTPUT        -> The output script
-- Action:        Create a script for a table that unpivots its results. The script can be a view or a query.
-- Return:        No rows returned. Output parameter holds the generated script.

SET NOCOUNT ON;

DECLARE @Script nvarchar(max);

EXEC SDU_Tools.ScriptTableAsUnpivot 
    @SourceDatabaseName = N'WideWorldImporters'
  , @SourceTableSchemaName  = N'Sales'
  , @SourceTableName = N'Orders'
  , @OutputViewSchemaName = N'Sales'
  , @OutputViewName = N'Sales_Unpivoted'
  , @IsViewScript = 0
  , @IncludeNullColumns = 0
  , @ColumnIndentSize = 4
  , @ScriptIndentSize = 0
  , @QueryScript = @Script OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @Script, 1, 0, 0, 0, 'GO';

----------------------------------------------------
-- SDU_Tools Version 11.0 Sample Scripts 

-- Function:      Returns a table (single row) of time period dimension columns
-- Parameters:    @TimeOfDay datetime2 => time of day to process as a time period row
--                @MinutesPerPeriod => number of minutes in each time period for the day
-- Action:        Returns a single row table with time period dimension columns
-- Return:        Single row rowset with time period dimension columns

SELECT * FROM SDU_Tools.TimePeriodDimensionColumns('10:17 AM', 15);
SELECT * FROM SDU_Tools.TimePeriodDimensionColumns('8:34 PM', 15);

-- Function:      Outputs date dimension columns for all dates in the supplied range of dates
-- Parameters:    @FromDate date   -> start date for the period
--                @ToDate date     -> end date for the period
--                @StartOfFinancialYearMonth int -> month of the year that the financial year starts
--                                                  (default is 7)
-- Action:        Outputs date dimension columns for all dates in the range provided
-- Return:        Rowset of date dimension columns

EXEC SDU_Tools.GetDateDimension 
     @FromDate = '20180701', 
     @ToDate = '20180731', 
     @StartOfFinancialYearMonth = 7;

-- Function:      Outputs time period dimension columns for an entire day
-- Parameters:    @MinutesPerPeriod int -> number of minutes per time period (default 15)
-- Action:        Outputs time period dimension columns for an entire day based on the 
--                suppliednumber of minutes per period
-- Return:        Rowset of time period dimension columns

EXEC SDU_Tools.GetTimePeriodDimension 
     @MinutesPerPeriod = 15;

-- Function:      Return date of beginnning of the month
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the first date of the month for any given date 
-- Return:        date

SELECT SDU_Tools.StartOfMonth('20180713');
SELECT SDU_Tools.StartOfMonth(SYSDATETIME());
SELECT SDU_Tools.StartOfMonth(GETDATE());

-- Function:      Return date of end of the month
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the last date of the month for any given date 
-- Return:        date

SELECT SDU_Tools.EndOfMonth('20160205');
SELECT SDU_Tools.EndOfMonth(SYSDATETIME());
SELECT SDU_Tools.EndOfMonth(GETDATE());

-- Function:      Traverse the foreign key relationships within a database 
--                and work out which order tables need to be loaded in
-- Parameters:    @DatabaseName sysname   -> name of the database containing the tables
-- Action:        Work out dependency between tables and work out loading order
-- Return:        Rowset describing tables

EXEC SDU_Tools.CalculateTableLoadingOrder
    @DatabaseName = N'WideWorldImporters';

-- View:          SQLServerProductVersions
-- Action:        View returning Product Versions for SQL Server
-- Return:        One row per SQL Server product version

SELECT * 
FROM SDU_Tools.SQLServerProductVersions 
ORDER BY MajorVersionNumber, MinorVersionNumber, BuildNumber;

-- Function:      Extracts a product major version from a build number (product version)
-- Parameters:    @ProductVersion varchar(20)
-- Action:        Extracts a product major version from a build number (product version)
--                in the form MM.mm.BBBB.RRR (MM = Major, mm = minor, BBBB = build, RRR = release)
-- Return:        int

SELECT SDU_Tools.ProductVersionToMajorVersion('13.0.4435.0');
SELECT SDU_Tools.ProductVersionToMajorVersion('   13.0.4435.0 ');

-- Function:      Extracts a product minor version from a build number (product version)
-- Parameters:    @ProductVersion varchar(20)
-- Action:        Extracts a product minor version from a build number (product version)
--                in the form MM.mm.BBBB.RRR (MM = Major, mm = minor, BBBB = build, RRR = release)
-- Return:        int

SELECT SDU_Tools.ProductVersionToMinorVersion('13.0.4435.0');
SELECT SDU_Tools.ProductVersionToMinorVersion('   13.0.4435.0 ');

-- Function:      Extracts a product build from a build number (product version)
-- Parameters:    @ProductVersion varchar(20)
-- Action:        Extracts a product build from a build number (product version)
--                in the form MM.mm.BBBB.RRR (MM = Major, mm = minor, BBBB = build, RRR = release)
-- Return:        int

SELECT SDU_Tools.ProductVersionToBuild('13.0.4435.0');
SELECT SDU_Tools.ProductVersionToBuild('   13.0.4435.0 ');

-- Function:      Extracts a product release from a build number (product version)
-- Parameters:    @ProductVersion varchar(20)
-- Action:        Extracts a product release from a build number (product version)
--                in the form MM.mm.BBBB.RRR (MM = Major, mm = minor, BBBB = build, RRR = release)
-- Return:        int

SELECT SDU_Tools.ProductVersionToRelease('13.0.4435.0');
SELECT SDU_Tools.ProductVersionToRelease('   13.0.4435.0 ');

-- Function:      Extracts the components of a product version
--                from a build number (product version)
-- Parameters:    @ProductVersion varchar(20)
-- Action:        Extracts the components of a product version from a build number (product version)
--                in the form MM.mm.BBBB.RRR (MM = Major, mm = minor, BBBB = build, RRR = release)
-- Return:        Rowset with product version components

SELECT * FROM SDU_Tools.ProductVersionComponents('  13.0.4435.0 ');

-- ExtractSQLTemplate enhanced to support sp_prepexec

SELECT SDU_Tools.ExtractSQLTemplate('select * from customers where customerid = 12 and customername = ''fred'' order by customerid;', 4000);
SELECT SDU_Tools.ExtractSQLTemplate(N'Declare @P1 int;  EXEC sp_prepexec @P1 output,   N''@P1 nvarchar(128), @P2 nvarchar(100)'',  N''SELECT database_id, name FROM sys.databases  WHERE name=@P1 AND state_desc = @P2'', @P1 = ''tempdb'', @P2 = ''ONLINE'';', 4000);

-- View:          OperatingSystemVersions
-- Action:        View returning names of operating systems by versions
-- Return:        One row per operating system version

SELECT * FROM SDU_Tools.OperatingSystemVersions ORDER BY OS_Family, OS_Version;

-- View:          OperatingSystemLocales
-- Action:        View returning locales used by operating systems
-- Return:        One row per operating system locale

SELECT * FROM SDU_Tools.OperatingSystemLocales ORDER BY OS_Family, LocaleID, LanguageName;

-- View:          OperatingSystemSKUs
-- Action:        View returning SKUs used by operating systems
-- Return:        One row per operating system SKU

SELECT * FROM SDU_Tools.OperatingSystemSKUs ORDER BY OS_Family, SKU, SKU_Name;

-- View:          OperatingSystemConfiguration
-- Action:        Configuration of the current operating system
-- Return:        One row with operating system details

SELECT * FROM SDU_Tools.OperatingSystemConfiguration;

----------------------------------------------------
-- SDU_Tools Version 10.0 Sample Scripts 

-- Function:      Converts a number to a text string
-- Parameters:    @InputNumber bigint - the value to be converted
-- Action:        Converts a number to a text string (using English words)
-- Return:        nvarchar(max)

SELECT SDU_Tools.NumberAsText(2);
SELECT SDU_Tools.NumberAsText(12342);
SELECT SDU_Tools.NumberAsText(322342);
SELECT SDU_Tools.NumberAsText(13);
SELECT SDU_Tools.NumberAsText(34);

SELECT SDU_Tools.NumberAsText(345543234242);

DECLARE @Dollars int = 1847;
DECLARE @Cents int = 42;
DECLARE @TextValue nvarchar(max)
    = SDU_Tools.NumberAsText(@Dollars) 
      + N' dollars ' 
      + SDU_Tools.NumberAsText(@Cents) 
      + N' cents';
SELECT @TextValue;
SELECT UPPER(@TextValue);
SELECT REPLACE(UPPER(@TextValue), N'LARS', N'LARS,');
SELECT REPLACE(UPPER(@TextValue), N' AND ', N' ');

-- Function:      Apply Kebab Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Kebab Casing to a string (similar to programming identifiers)
-- Return:        nvarchar(max)

SELECT SDU_Tools.KebabCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.KebabCase(N'janet mcdermott');
SELECT SDU_Tools.KebabCase(N'the case of sherlock holmes and the curly-Haired  company');

-- Function:      Apply Train Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Train Casing to a string 
-- Return:        nvarchar(max)

SELECT SDU_Tools.TrainCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.TrainCase(N'janet mcdermott');
SELECT SDU_Tools.TrainCase(N'the case of sherlock holmes and the curly-Haired  company');

-- Function:      Apply Screaming Snake Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Screaming Snake Casing to a string (similar to programming identifiers)
-- Return:        nvarchar(max)

SELECT SDU_Tools.ScreamingSnakeCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.ScreamingSnakeCase(N'janet mcdermott');
SELECT SDU_Tools.ScreamingSnakeCase(N'the case of sherlock holmes and the curly-Haired  company');

-- Function:      Apply SpongeBob Snake Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply SpongeBob Snake Casing to a string

SELECT SDU_Tools.SpongeBobSnakeCase(N'SpongeBob SnakeCase');
SELECT SDU_Tools.SpongeBobSnakeCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.SpongeBobSnakeCase(N'janet mcdermott');
SELECT SDU_Tools.SpongeBobSnakeCase(N'the case of sherlock holmes and the curly-Haired  company');

----------------------------------------------------
-- SDU_Tools Version 9.0 Sample Scripts 

-- Function:      Lists the columns that are used in primary keys for all tables
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists the columns that are used in primary keys for all tables
-- Return:        Rowset containing SchemaName, TableName, PrimaryKeyName, ColumnList
--                in order of SchemaName, TableName


EXEC SDU_Tools.ListPrimaryKeyColumns @DatabaseName = N'WideWorldImporters',
                                     @SchemasToList = N'ALL', 
                                     @TablesToList = N'ALL';

GO

-- Function:      ReservedWords, FutureReservedWords, ODBCReservedWords, SystemDataTypeNames, SystemWords
-- Parameters:    Nil
-- Action:        View returning SQL Server reserved words, future reserved words, ODBC 
--                reserved words, and system data type names, and the color they normally appear in SSMS
-- Return:        One row per system word.

SELECT * FROM SDU_Tools.ReservedWords;

SELECT * FROM SDU_Tools.FutureReservedWords;

SELECT * FROM SDU_Tools.ODBCReservedWords;

SELECT * FROM SDU_Tools.SystemDataTypeNames;

SELECT * FROM SDU_Tools.SystemWords ORDER BY SystemWord;

-- Function:      Creates a linked server that points to an Azure SQL Database
-- Parameters:    @LinkedServerName sysname - name that will be assigned to the linked server
--                                          - defaults to AzureSQLDB
--                @AzureSQLServerName nvarchar(max) - name for the Azure SQL Server eg: myserver.database.windows.net
--                @AzureSQLServerTCPPort int - port number for the Azure SQL Server (defaults to 1433)
--                @AzureSQLDatabaseName sysname - name of the database (defaults to master)
--                @RemoteLoginName sysname - login name for the Azure database
--                @RemotePassword nvarchar(max) - password for the Azure database
--                @SetCollationCompatible bit - is the remote server collation compatible (default is true)
--                @SetRPCIn bit - should rpc (remote procedure calls = stored procedure calls) be allowed (default is true)
--                @SetRPCOut bit - should rpc output be allowed (default is true)
-- Action:        Creates a linked server pointing to an Azure SQL DB
-- Return:        Nil


EXEC SDU_Tools.CreateLinkedServerToAzureSQLDatabase @LinkedServerName= N'AzureSQLDB',
                                                    @AzureSQLServerName = N'myserver',
                                                    @AzureSQLServerTCPPort = 1433,
                                                    @AzureSQLDatabaseName = N'mydatabase',
                                                    @RemoteLoginName = N'Fred',
                                                    @RemotePassword = N'very secret stuff',
                                                    @SetCollationCompatible = 1,
                                                    @SetRPCIn = 1,
                                                    @SetRPCOut = 1;
GO

-- Function:      SystemConfigurationOptionDefaults
-- Parameters:    Nil
-- Action:        View returning SQL Server Configuration Option Default values
-- Return:        One row per configuration open

SELECT * FROM SDU_Tools.SystemConfigurationOptionDefaults;
GO

-- Function:      NonDefaultSystemConfigurationOptions
-- Parameters:    Nil
-- Action:        View returning SQL Server Configuration options 
--                that are not at their default values
-- Return:        One row per altered configuration option

SELECT * FROM SDU_Tools.NonDefaultSystemConfigurationOptions;
GO

-- Function:      Converts a database compatibility level to a SQL Server version
-- Parameters:    @DatabaseCompatibilityLevel tinyint
-- Action:        Converts a database compatibility level to a SQL Server version
--                and returns NULL if not recognized
-- Return:        nvarchar(4)

SELECT SDU_Tools.SQLServerVersionForCompatibilityLevel(110);
SELECT SDU_Tools.SQLServerVersionForCompatibilityLevel(140);
GO

-- Function:      Converts a Julian day number to a date
-- Parameters:    @JulianDayNumber int - value to be converted
-- Action:        Converts the Julian day number to a date
--                The value must be between 1721426 ('00010101') and 5373120 ('99990101')
-- Return:        date

SELECT SDU_Tools.JulianDayNumberToDate(2451545);
SELECT SDU_Tools.JulianDayNumberToDate(1721426);
GO

-- Function:      Converts a date to a Julian day number
-- Parameters:    @DateToConvert date - date to be converted
-- Action:        Converts the date to a Julian day number
-- Return:        int

SELECT SDU_Tools.DateToJulianDayNumber('20000101');
SELECT SDU_Tools.DateToJulianDayNumber('00010101');
GO

-- Function:      Returns a table of dates
-- Parameters:    @StartDate date => first date to return
--                @EndDate => last date to return
-- Action:        Returns a table of dates between the two dates supplied (inclusive)
-- Return:        Rowset with DateNumber as int and DateValue as a date

SELECT * FROM SDU_Tools.DatesBetween('20170101', '20170131');
SELECT * FROM SDU_Tools.DatesBetween('20170131', '20170101');
GO

-- Function:      Returns a table (single row) of date dimension columns
-- Parameters:    @Date date => date to process
--                @FiscalYearStartMonth int => month number when the financial year starts
-- Action:        Returns a single row table with date dimension columns
-- Return:        Single row rowset with date dimension columns

SELECT * FROM SDU_Tools.DateDimensionColumns('20170131', 7);

SELECT ddc.* 
FROM SDU_Tools.DatesBetween('20180201', '20180401') AS db
CROSS APPLY SDU_Tools.DateDimensionColumns(db.DateValue, 7) AS ddc
ORDER BY db.DateValue;
GO

-----------------------------------------------------------------------------
-- SDU_Tools Version 8.0 Sample Scripts 

-- Function:      ScriptTable
-- Parameters:    @DatabaseName sysname                    -> Database name for the table to be scripted
--                @ExistingSchemaName sysname              -> Schema name for the table to be scripted
--                @ExistingTableName sysname               -> Table name for the table to be scripted
--                @OutputSchemaName sysname                -> Schema name for the output script (defaults to same as existing schema)
--                @OutputTableName sysname                 -> Table name for the output script (defaults to same as existing table)
--                @OutputDataCompressionStyle nvarchar(10) -> must be one of SAME, NONE, ROW, PAGE (SAME uses whatever the table's first partition currently has)
--                @AreCollationsScripted bit               -> Should all collations be scripted (default is 0 for no)
--                @AreUsingBaseTypes bit                   -> Should the table use the underlying base types instead of alias types (default is 1 for yes)
--                @AreForcingAnsiNulls bit                 -> Should the script include code to force ANSI_NULLS on (default is 1 for yes)
--                @AreForcingAnsiPadding bit               -> Should hte script include code to force ANSI_PADDING on (default is 1 for yes)
--                @ColumnIndentSize                        -> How far should columns be indented from the table definition (defaults to 4)
--                @ScriptIndentSize                        -> How far indented should the script be? (defaults to 0)
--                @TableScript nvarchar(max) OUTPUT        -> The output script
-- Action:        Create a script for a table
-- Return:        No rows returned. Output parameter holds the generated script.

SET NOCOUNT ON;

DECLARE @Script nvarchar(max);

EXEC SDU_Tools.ScriptTable @DatabaseName = N'WideWorldImporters'
                                         , @ExistingSchemaName = N'Sales'
                                         , @ExistingTableName = N'Orders'
                                         , @OutputSchemaName = N'InhouseSales'
                                         , @OutputTableName = N'CustomerOrders'
                                         , @OutputDataCompressionStyle = N'SAME'
                                         , @AreCollationsScripted = 0
                                         , @AreUsingBaseTypes = 1
                                         , @AreForcingAnsiNulls = 1
                                         , @AreForcingAnsiPadding = 1
                                         , @ColumnIndentSize = 4
                                         , @ScriptIndentSize = 0
                                         , @TableScript = @Script OUTPUT;
EXEC SDU_Tools.ExecuteOrPrint @Script, 1, 0, 0, 0, 'GO';
GO

-- Function:      SetAnsiNullsOnForTable
-- Parameters:    @DatabaseName sysname                    -> Database name for the table to be scripted
--                @ExistingSchemaName sysname              -> Schema name for the table to be scripted
--                @ExistingTableName sysname               -> Table name for the table to be scripted
--                @IHaveABackup bit                        -> Ensure you have a backup before running this command as it could be destructive
--                @workingTableName sysname                -> Temporary working table name that can be used. Default is table name with ANSI_NULLS suffix
-- Action:        Changes the ANSI Nulls setting for a table to ON
-- Return:        No rows returned

SET ANSI_NULLS OFF;

CREATE TABLE dbo.TestTable
(
    TestTableID int IDENTITY(1,1) PRIMARY KEY,
    TestTableDescription varchar(50)
);
GO

SELECT * FROM sys.tables WHERE [name] = N'TestTable';
GO

DECLARE @CurrentDatabaseName sysname = DB_NAME();
EXEC SDU_Tools.SetAnsiNullsOnForTable @DatabaseName = @CurrentDatabaseName
                                    , @ExistingSchemaName = 'dbo'
                                    , @ExistingTableName = 'TestTable'
                                    , @IHaveABackUp = 1;
GO

SELECT * FROM sys.tables WHERE [name] = N'TestTable';
GO

DROP TABLE dbo.TestTable;
GO

-- Function:      Determines if a SQL Server Agent job is running
-- Parameters:    @JobName sysname - the name of the job
-- Action:        Returns 1 (bit) if the job exists and is running, else 0 (bit)
-- Return:        bit 

SELECT SDU_Tools.IsJobRunning('Daily ETL Processing');

-- Function:      Removes all non-alphanumeric characters in a string
-- Parameters:    @InputString nvarchar(max) - String to be processed (unicode or single byte)
-- Action:        Removes all non-alphanumeric characters in a string
-- Return:        varchar(max)

SELECT SDU_Tools.AlphanumericOnly('Hello20834There  234');

-- Function:      Removes all non-alphabetic characters in a string
-- Parameters:    @InputString nvarchar(max) - String to be processed (unicode or single byte)
-- Action:        Removes all non-alphabetic characters in a string
-- Return:        varchar(max)

SELECT SDU_Tools.AlphabeticOnly('Hello20834There  234');

-- Function:      ReseedSequenceBeyondTableValues
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemaName sysname           -> Schema for the sequence to process
--                @SequenceName sysname         -> Sequence to process
-- Action:        Sets the sequence to a value beyond any column value that uses it as a default
-- Return:        Nil


EXEC SDU_Tools.ReseedSequenceBeyondTableValues @DatabaseName = N'WideWorldImporters',
                                               @SchemaName = N'Sequences', 
                                               @SequenceName = N'CustomerID'; 

-- Function:      ReseedSequences
-- Parameters:    @DatabaseName sysname            -> Database to process
--                @SchemasToList nvarchar(max)     -> Schemas to process (comma-delimited list) or ALL
--                @SequencesToList nvarchar(max)   -> Schemas to process (comma-delimited list) or ALL
-- Action:        Sets the sequences to a value beyond any column value that uses them as a default
-- Return:        Nil

EXEC SDU_Tools.ReseedSequences @DatabaseName = N'WideWorldImporters';

EXEC SDU_Tools.ReseedSequences @DatabaseName = N'WideWorldImporters',
                                               @SchemasToList = N'Sequences',
                                               @SequencesToList = N'TransactionID,CustomerID';


-- Function:      Returns the date of Easter Sunday in a given year
-- Parameters:    @Year int  -> year number
-- Action:        Calculates the date of Easter Sunday (Christian Easter) for
--                a given year, adapted from the wonderful calculation described
--                on this page: http://www.tondering.dk/claus/cal/easter.php#wheneasterlong
--                contained in the highly recommended Calendar FAQ by Claus Tondering
-- Return:        date

SELECT SDU_Tools.DateOfEasterSunday(2018);
SELECT SDU_Tools.DateOfEasterSunday(1958);

----------------------------------------------------------------------------------------------
-- SDU Tools Version 7.0 Sample Scripts
--

-- Function:      Returns a table of numbers
-- Parameters:    @StartValue int => first value to return
--                @NumberRequired int => number of numbers to return
-- Action:        Returns a table of numbers with a specified number of rows
--                from the specified starting value
--                Note: if more than 100 numbers are required 
--                OPTION (MAXRECURSION 0) should be added to the query that uses this function
-- Return:        Rowset with Number as an integer

SELECT * FROM SDU_Tools.TableOfNumbers(12, 90);
SELECT * FROM SDU_Tools.TableOfNumbers(12, 5000) OPTION (MAXRECURSION 0);

-- Function:      Extracts words from a string and trims them
-- Parameters:    @InputValue varchar(max) -> the string to extract words from
-- Action:        Returns an ordered table of trimmed words extracted from the string
-- Return:        Rowset with WordNumber and TrimmedWord

SELECT * FROM SDU_Tools.ExtractTrimmedWords('fre john   C10');
SELECT * FROM SDU_Tools.ExtractTrimmedWords('fre john   C10');

-- Function:      Extracts all trigrams (up to 3 character substrings) from a string
-- Parameters:    @InputValue varchar(max) -> the string to extract the trigrams from
-- Action:        Returns an ordered table of distinct trigrams extracted from the string
-- Return:        Rowset with TrigramNumber and Trigram


SELECT * FROM SDU_Tools.ExtractTrigrams('1846 Hudecova Crescent');

-- Function:      ListIncomingForeignKeys
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @ReferencedSchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @ReferencedTablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List foreign keys with column lists filtered by the target schemas and tables
-- Return:        Rowset of foreign keys

EXEC SDU_Tools.ListIncomingForeignKeys @DatabaseName = N'WideWorldImporters',
                                       @ReferencedSchemasToList = N'Application,Sales', 
                                       @ReferencedTablesToList = N'Cities,Orders'; 

----------------------------------------------------------------------------------------------
-- SDU Tools Version 6.0 Sample Scripts
--

-- Function:      UpdateStatistics
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToUpdate nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to process
--                @TablesToUpdate nvarchar(max)   -> 'ALL' or comma-delimited list of tables to process
--                @SamplePercentage int           -> default is 100 meaning FULLSCAN or percentage for sample only
--                                                -> if @SamplePercentage < 0 or > 100 then FULLSCAN performed
-- Action:        Update statistics for selected set of user tables (excluding Microsoft-shipped tables)
-- Return:        Nil

EXEC SDU_Tools.UpdateStatistics @DatabaseName = N'WideWorldImporters';

EXEC SDU_Tools.UpdateStatistics @DatabaseName = N'WideWorldImporters',
                                @SchemasToUpdate = N'ALL', 
                                @TablesToUpdate = N'Cities,People', 
                                @SamplePercentage = 30;


-- Function:      Counts words in a string
-- Parameters:    @InputString nvarchar(max)
-- Action:        Counts words in a string, using English syntax
-- Return:        int as number of words
 
SELECT SDU_Tools.CountWords('Hello  there');
SELECT SDU_Tools.CountWords('Hello, there: now');
SELECT SDU_Tools.CountWords('words;words;words');
SELECT SDU_Tools.CountWords('Jane Hyde-Smythe');
SELECT SDU_Tools.CountWords('Jane D''Angelo');

-- Function:      Sleep for a number of seconds 
-- Parameters:    @NumberOfSeconds int -> The time to sleep for
-- Action:        Sleeps for the given number of seconds
-- Return:        Nil

EXEC SDU_Tools.Sleep 10;

-- Function:      Translate one series of characters to another series of characters
-- Parameters:    @InputString varchar(max) - string to process
--                @CharactersToReplace varchar(max) - list of characters to be replaced
--                @ReplacementCharacters varchar(max) - list of replacement characters
-- Action:        Replace a set of characters in a string with a replacement set of characters
-- Return:        nvarchar(max)
 
SELECT SDU_Tools.Translate(N'[08] 7777,9876', N'[],', N'()-');

-- Function:      Determines the number of days (Monday to Friday) between two dates
-- Parameters:    @FromDate date -> date to start calculating from
--                @ToDate date -> date to calculate to
-- Action:        Determines the number of days (Monday to Friday) between two dates
-- Return:        int number of days

SELECT SDU_Tools.DateDiffNoWeekends('20170101', '20170131');
SELECT SDU_Tools.DateDiffNoWeekends('20170101', '20170101');
SELECT SDU_Tools.DateDiffNoWeekends('20170131', '20170101');

-- Function:      Inverts a string
-- Parameters:    @InputString nvarchar(max) - String to be processed (unicode or single byte)
-- Action:        Inverts a string by using USD Encoding as per https://en.wikipedia.org/wiki/Transformation_of_text#Upside-down_text
-- Return:        nvarchar(max)

SELECT SDU_Tools.InvertString('Hello There');
SELECT SDU_Tools.InvertString('Can you read this?');
SELECT SDU_Tools.InvertString('Some punctuation, also works !');
SELECT REVERSE(SDU_Tools.InvertString('Hello There'));

----------------------------------------------------------------------------------------------
-- SDU Tools Version 5.0 Sample Scripts
--

-- Function:      Determines if a given year is a leap year
-- Parameters:    @YearNumber int -> year number to calculate from
-- Action:        Returns 1 (bit) if the year is a leap year, else 0 (bit)
-- Return:        bit 

SELECT SDU_Tools.IsLeapYear(1901);
SELECT SDU_Tools.IsLeapYear(2000);
SELECT SDU_Tools.IsLeapYear(2100);
GO

-- Function:      ListPotentialDateColumnsByValue
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists columns that are defined with datatypes that include a time component
--                but no time value is present in any row (can take a while to check)
-- Return:        Rowset of columns

EXEC SDU_Tools.ListPotentialDateColumnsByValue @DatabaseName = N'WideWorldImporters',
                                               @SchemasToList = N'ALL', 
                                               @TablesToList = N'ALL', 
                                               @ColumnsToList = N'ALL';
GO

-- Function:      Drops the temporary table if it exists
-- Parameters:    @TemporaryTableName sysname    -> table to drop if it exists (with or without #)
-- Action:        If the temporary table is defined in the current session,
--                the table is dropped
-- Return:        Nil

EXEC SDU_Tools.DropTemporaryTableIfExists N'#Accounts';

CREATE TABLE #Accounts
(
    AccountID int NOT NULL
);
GO

SELECT * FROM #Accounts;
GO

EXEC SDU_Tools.DropTemporaryTableIfExists N'#Accounts';
GO

SELECT * FROM #Accounts;
GO

CREATE TABLE #Accounts
(
    AccountID int NOT NULL
);
GO

SELECT * FROM #Accounts;
GO

EXEC SDU_Tools.DropTemporaryTableIfExists N'Accounts';
GO

SELECT * FROM #Accounts;
GO

-- Function:      ReadCSVFile
-- Parameters:    @Filepath nvarchar(max) - full path to the CSV or TSV file
--                @Delimiter nvarchar(1)  - delimiter used (default is comma)
--                @TrimOutput bit         - should all output values be trimmed before returned
--                @IsFileUnicode bit      - 1 if the file is unicode, 0 for ASCII
--                @RowsToSkip int         - should rows be skipped (eg: 1 for a single header row)
-- Action:        Reads a CSV file's data and outputs it as a set of columns
-- Return:        Rowset with up to 50 columns

EXEC SDU_Tools.ReadCSVFile N'C:\Temp\NewProspects.csv', ';', 1, 0, 0;
EXEC SDU_Tools.ReadCSVFile N'C:\Temp\NewProspects.csv', ';', 1, 0, 1;

-- Function:      DigitsOnly
-- Parameters:    @InputString nvarchar(max) - String to be processed (unicode or single byte)
--                @StripLeadingSign - If the string contains a leading + or - sign, is it stripped as well?
-- Action:        Removes all non-digit characters in a string optionally retains or removes any leading sign
-- Return:        varchar(max)

SELECT SDU_Tools.DigitsOnly('Hello20834There  234', 1);
SELECT SDU_Tools.DigitsOnly('(425) 902-2322', 1);
SELECT SDU_Tools.DigitsOnly('+1 (425) 902-2322', 1);
SELECT SDU_Tools.DigitsOnly('+1 (425) 902-2322', 0);
GO

-- Function:      ListPotentialDateColumns
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        ListPotentialDateColumns (user tables only) - Lists columns that are named as dates but use datatypes with time
-- Return:        Rowset of columns

ALTER TABLE WideWorldImporters.Warehouse.StockItems 
ADD ExpiryDate datetime;
GO

EXEC SDU_Tools.ListPotentialDateColumns @DatabaseName = N'WideWorldImporters',
                                        @SchemasToList = N'ALL', 
                                        @TablesToList = N'ALL', 
                                        @ColumnsToList = N'ALL';
GO

ALTER TABLE WideWorldImporters.Warehouse.StockItems 
DROP COLUMN ExpiryDate;
GO

-- Function:      Converts a hexadecimal character string to an integer
-- Parameters:    @@HexadecimalCharacterString - a character string to be converted to an integer
-- Action:        Converts a hexadecimal character string to an integer - must be a two character hex string
-- Return:        int

SELECT SDU_Tools.HexCharStringToInt(N'32');
SELECT SDU_Tools.HexCharStringToInt(N'2F');
GO

-- Function:      Converts a hexadecimal character string to a character
-- Parameters:    @@HexadecimalCharacterString - a character string to be converted to character eg: 5F becomes _
-- Action:        Converts a hexadecimal character string to a character - must be a two character hex string
-- Return:        nchar

SELECT SDU_Tools.HexCharStringToChar(N'41');
SELECT SDU_Tools.HexCharStringToChar(N'5F');
GO

-- Function:      XML encodes a string
-- Parameters:    @StringToEncode - a character string to be XML encoded
-- Action:        XML encodes a string. In particular, code the following characters "'<>&/_ 
-- Return:        nvarchar(max)

SELECT SDU_Tools.XMLEncodeString(N'Hello there John & Mary. This is <X> only a token');
SELECT SDU_Tools.XMLEncodeString(N'<hello there></hello there>');
GO

-- Function:      XML decodes a string
-- Parameters:    @StringToDecode - a character string to be XML decoded
-- Action:        XML decodes a string. In particular, processes &quot; &lt; &gt; &apos; &amp; and any hex character encoding 
--                via &#xHH where HH is a hex character string
-- Return:        nvarchar(max)

SELECT SDU_Tools.XMLDecodeString(N'Hello there John &amp; Mary. This is &lt;X&gt; only a token');
SELECT SDU_Tools.XMLDecodeString(N'&lt;hello there&gt;&lt;&#x2Fhello there&gt;');
GO

-- Function:      Splits a delimited string (usually either a CSV or TSV)
-- Parameters:    @StringToSplit nvarchar(max)       -> string that will be split
--                @Delimiter nvarchar(10)            -> delimited used (usually either N',' or NCHAR(9) for tab)
--                @TrimOutput bit                    -> if 1 then trim strings before returning them
-- Action:        Splits delimited strings - usually comma-delimited strings CSVs or tab-delimited strings (TSVs)
--                Delimiter can be specified
--                Optionally, the output strings can be trimmed
-- Return:        Table containing a column called StringValue nvarchar(max)

DECLARE @TAB nchar(1) = NCHAR(9);
DECLARE @MyTabDelimitedString nvarchar(max) = N'hello' + @TAB + N'there' + @TAB + N'greg';

SELECT * FROM SDU_Tools.SplitDelimitedString(@MyTabDelimitedString, @TAB, 1);
GO

SELECT * FROM SDU_Tools.SplitDelimitedString(N'hello, there, greg', N',', 0);
SELECT * FROM SDU_Tools.SplitDelimitedString(N'Now works, with embedded ,% signs', N',', 1);
GO

-- Function:      Splits a delimited string into columns (usually either a CSV or TSV)
-- Parameters:    @StringToSplit nvarchar(max)       -> string (probably a row) that will be split
--                @Delimiter nvarchar(10)            -> delimited used (usually either N',' or NCHAR(9) for tab)
--                @TrimOutput bit                    -> if 1 then trim strings before returning them
-- Action:        Splits delimited strings - usually entire rows as comma-delimited strings CSVs or tab-delimited strings (TSVs)
--                Delimiter can be specified
--                Optionally, the output strings can be trimmed
-- Return:        Table containing 50 columns called Column01, Column02, etc. nvarchar(max)

DECLARE @RowData nvarchar(max) = N'210.4,John Doe,327.32,2234242,Current,1';

SELECT @RowData;
SELECT * FROM SDU_Tools.SplitDelimitedStringIntoColumns(@RowData, N',', 1);
GO

DECLARE @RowData nvarchar(max) = N'210.4|John Doe|327.32|2234242|Current|1';

SELECT @RowData;
SELECT * FROM SDU_Tools.SplitDelimitedStringIntoColumns(@RowData, N'|', 1);
GO

DECLARE @TAB nchar(1) = NCHAR(9);
DECLARE @RowData nvarchar(max) = N'210.4' + @TAB + N'John Doe' + @TAB + N'327.32' + @TAB + N'2234242' + @TAB + N'Current' + @TAB + N'1';

SELECT @RowData;
SELECT * FROM SDU_Tools.SplitDelimitedStringIntoColumns(@RowData, @TAB, 1);
GO

-- Function:      ListMismatchedDatabaseCollations
-- Parameters:    @ExcludeSystemDatabases bit            -- should system databases be excluded
--                @ExcludeReportingServicesDatabases bit -- should reporting services databases be excluded
-- Action:        List databases with collations that don't match the server's collation
-- Return:        Rowset a list of mismatched databases and their collations

CREATE DATABASE Different COLLATE Latin1_General_CS_AS;
GO

EXEC SDU_Tools.ListMismatchedDatabaseCollations @ExcludeSystemDatabases = 0, 
                                                @ExcludeReportingServicesDatabases = 1;
GO

DROP DATABASE Different;
GO

-- Function:      ClearServiceBrokerTransmissionQueue
-- Parameters:    Nil
-- Action:        Removes all messages in the service broker transmission queue by ending all existing conversations.
--                This is mostly useful in development and debugging of services.
-- Return:        Status (0 = success)

ALTER DATABASE Development SET ENABLE_BROKER;
GO

USE Development;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'SomeSecret$$'; 
GO

CREATE QUEUE PaymentQueue WITH STATUS = ON;
GO

CREATE SERVICE PaymentService ON QUEUE PaymentQueue;
GO

DECLARE @DialogHandle uniqueidentifier;

BEGIN DIALOG @DialogHandle  
FROM SERVICE PaymentService 
TO SERVICE 'NonexistentService'  
ON CONTRACT [DEFAULT];  

SEND ON CONVERSATION @DialogHandle  
    MESSAGE TYPE [DEFAULT]  
    (CAST(N'<Hello/>' AS xml));
GO

SELECT * FROM sys.transmission_queue;
GO

EXEC SDU_Tools.ClearServiceBrokerTransmissionQueue;
GO

SELECT * FROM sys.transmission_queue;
GO

DROP SERVICE PaymentService;
GO

DROP QUEUE PaymentQueue;
GO

-- Function:      ListForeignKeys
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List foreign keys with column lists
--                components of at least one index
-- Return:        Rowset of foreign keys

EXEC SDU_Tools.ListForeignKeys @DatabaseName = N'WideWorldImporters',
                               @SchemasToList = N'ALL', 
                               @TablesToList = N'ALL'; 
GO

EXEC SDU_Tools.ListForeignKeys @DatabaseName = N'WideWorldImporters',
                               @SchemasToList = N'Application', 
                               @TablesToList = N'ALL'; 
GO

-- Function:      ListForeignKeyColumns
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List foreign keys with both source and referenced columns
-- Return:        Rowset of foreign key columns

EXEC SDU_Tools.ListForeignKeyColumns @DatabaseName = N'WideWorldImporters',
                                     @SchemasToList = N'ALL', 
                                     @TablesToList = N'ALL'; 
GO

EXEC SDU_Tools.ListForeignKeyColumns @DatabaseName = N'WideWorldImporters',
                                     @SchemasToList = N'Application', 
                                     @TablesToList = N'ALL'; 
GO

-- Function:      ListNonIndexedForeignKeys
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List foreign keys where the foreign key columns are not present as the first
--                components of at least one index
-- Return:        Rowset of non indexed foreign keys

EXEC SDU_Tools.ListNonIndexedForeignKeys @DatabaseName = N'WideWorldImporters',
                                         @SchemasToList = N'ALL', 
                                         @TablesToList = N'ALL'; 
GO

EXEC SDU_Tools.ListNonIndexedForeignKeys @DatabaseName = N'WideWorldImporters',
                                         @SchemasToList = N'Purchasing', 
                                         @TablesToList = N'ALL'; 
GO

-- Function:      ListIndexes
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List indexes with both key and included column lists
-- Return:        Rowset of indexes

EXEC SDU_Tools.ListIndexes @DatabaseName = N'WideWorldImporters',
                           @SchemasToList = N'ALL', 
                           @TablesToList = N'ALL'; 
GO

EXEC SDU_Tools.ListIndexes @DatabaseName = N'WideWorldImporters',
                           @SchemasToList = N'Application', 
                           @TablesToList = N'ALL'; 
GO

EXEC SDU_Tools.ListIndexes @DatabaseName = N'WideWorldImporters',
                           @SchemasToList = N'Application', 
                           @TablesToList = N'DeliveryMethods,PaymentMethods'; 
GO

-----------------------------------------------------------------------------------
-- SDU Tools Version 4.0 Sample Scripts

-- Name:          SDU_Tools.CalculateAge
-- Function:      Return an age in years from a starting date to a calculation date
-- Parameters:    @StartingDate date -> when the calculation begins (often a date of birth)
--                @CalculationDate date -> when the age is calculated to (often the current date)
-- Action:        Return an age in years from a starting date to a calculation date 
-- Return:        int    (NULL if @StartingDate is later than @CalculationDate)
--

SELECT SDU_Tools.CalculateAge('1968-11-20', SYSDATETIME());
SELECT SDU_Tools.CalculateAge('1942-09-16', '2017-12-31');
GO

-- Name:          SDU_Tools.AsciiOnly
-- Function:      Removes or replaces all non-ASCII characters in a string
-- Parameters:    @InputString nvarchar(max) - String to be processed (unicode or single byte)
--                @ReplacementCharacters varchar(10) - Up to 10 characters to replace non-ASCII 
--                                                     characters with - can be blank
--                @AreControlCharactersRemoved bit - Should all control characters also be replaced
-- Action:        Finds all non-ASCII characters in a string and either removes or replaces them
-- Return:        varchar(max)
--

SELECT SDU_Tools.AsciiOnly('Hello°â€¢ There', '', 0);
SELECT SDU_Tools.AsciiOnly('Hello° There', '?', 0);
SELECT SDU_Tools.AsciiOnly('Hello° There' + CHAR(13) + CHAR(10) + ' John', '', 1);
GO

-- Name:          SDU_Tools.FormatDataTypeName 
-- Function:      Converts data type components into an output string
-- Parameters:    @DataTypeName sysname - the name of the data type
--                @Precision int - the decimal or numeric precision
--                @Scale int - the scale for the value
--                @MaximumLength - the maximum length of string values
-- Action:        Converts data type, precision, scale, and maximum length
--                into the standard format used in scripts
-- Return:        nvarchar(max)
--

SELECT SDU_Tools.FormatDataTypeName(N'decimal', 18, 2, NULL);
SELECT SDU_Tools.FormatDataTypeName(N'nvarchar', NULL, NULL, 12);
SELECT SDU_Tools.FormatDataTypeName(N'bigint', NULL, NULL, NULL);

-- Name:          SDU_Tools.PGObjectName 
-- Function:      Converts a SQL Server object name to a PostgreSQL object name
-- Parameters:    @SQLObjectName sysname
-- Action:        Converts a Pascal-cased or camel-cased SQL Server object name
--                to a name suitable for a database engine like PostgreSQL that
--                likes snake-cased names. Limits the identifier to 63 characters
--                and copes with a number of common abbreviations like ID that
--                would otherwise cause issues with the formation of the name.
-- Return:        varchar(63)
--

SELECT SDU_Tools.PGObjectName(N'CustomerTradingName');
SELECT SDU_Tools.PGObjectName(N'AccountID');
GO

-- Name:          SDU_Tools.ListMismatchedDataTypes
-- Function:      ListMismatchedDataTypes
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        List columns with the same name that are defined with different data types (user tables only)
-- Return:        Rowset a list of mismatched DataTypes
--

EXEC SDU_Tools.ListMismatchedDataTypes @DatabaseName = N'WideWorldImporters',
                                       @SchemasToList = N'ALL', 
                                       @TablesToList = N'ALL', 
                                       @ColumnsToList = N'ALL';

-- Name:          SDU_Tools.ExecuteJobAndWaitForCompletion
-- Function:      Executes a SQL Server Agent job synchronously (waits for it to complete)
-- Parameters:    @JobName sysname         -> Job to execute
--                @MaximumWaitSecondsForJobStart int -> Timeout for waiting for job start
--                @MaximumWaitSecondsForJobCompletion int -> Timeout waiting for job completion
--                @PrintDebugOutput bit -> set to 1 for more verbose output
-- Action:        Starts an agent job and waits for it to complete
-- Return:        Error on unable to execute job or timeout
--

EXEC SDU_Tools.ExecuteJobAndWaitForCompletion @JobName = 'Job that does not exist', @PrintDebugOutput = 1;
EXEC SDU_Tools.ExecuteJobAndWaitForCompletion @JobName = 'Daily ETL', @PrintDebugOutput = 1;

-- Name:          SDU_Tools.CapturePerformanceTuningTrace
-- Function:      Captures a performance tuning trace file
-- Parameters:    @DurationInMinutes -- (default is 15 minutes) Length of time the trace should run for
--                @TraceFileName -- (default is SDU_Trace) Name of the output trace file (.trc will be added if not present)
--                @OutputFolderName -- (default is C:\Temp) Name of the folder that the trace file will be created in
--                @DatabasesToCheck -- either ALL (default) or a comma-delimited list of database names
--                                     Note that if database level filtering is used (ie: not the value ALL) then
--                                     the trace will filter queries executed in the context of the database, not those
--                                     accessing the database from another context
--                @MaximumFileSizeMB -- (default is 4096) Maximum size of the trace file 
-- Action:        Captures a performance tuning trace file then terminates
-- Return:        Status (0 = success)
--

EXEC SDU_Tools.CapturePerformanceTuningTrace @DurationInMinutes = 2,
                                             @TraceFileName = N'SDU_Trace',
                                             @OutputFolderName = N'C:\Temp',
                                             @DatabasesToCheck = N'WideWorldImporters,WideWorldImportersDW',
                                             @MaximumFileSizeMB = 8192;


-- Name:          SDU_Tools.LoadPerformanceTuningTrace
-- Function:      Loads a performance tuning trace file
-- Parameters:    @TraceFileName nvarchar(256) -- (default is SDU_Trace) Name of the output trace file (.trc will be added if not present)
--                @TraceFileFolderName nvarchar(256) -- (default is C:\Temp) Name of the folder that the trace file will be created in
--                @ExportDatabaseName sysname -- (default is current database) Database to load the trace file into
--                @ExportSchemaName sysname -- (default is dbo) Schema for the table to load the trace file into
--                @ExportTableName sysname -- (default is the trace file name) Table to load the trace file into (must not already exist)
--                @IncludeNormalizedCommand bit -- (default is 1) Should a normalized command be added to the trace (takes time)
--                @IgnoreSPReset bit -- (default is 1) Should sp_reset commands be ignored
-- Action:        Loads a performance tuning trace file and optionally normalizes the queries in it
-- Return:        Status (0 = success)

EXEC SDU_Tools.LoadPerformanceTuningTrace @TraceFileName = N'SDU_Trace',
                                          @TraceFileFolderName = N'C:\Temp',
                                          @ExportDatabaseName = N'Development',
                                          @ExportSchemaName = N'dbo',
                                          @ExportTableName = N'SDU_Trace',
                                          @IncludeNormalizedCommand = 1,
                                          @IgnoreSPReset = 1;

-- Name:          SDU_Tools.AnalyzePerformanceTuningTrace
-- Function:      Analyze a loaded performance tuning trace file
-- Parameters:    @TraceDatabaseName sysname -- (default is current database) Database that the trace was loaded into
--                @TraceSchemaName sysname -- (default is dbo) Schema for the table that the trace was loaded into
--                @TraceTableName sysname -- (default is SDU_Trace) Name of the table that the trace was loaded into
-- Action:        Analyzes a loaded performance tuning trace file in terms of both normalized and unnormalized queries
-- Return:        Status (0 = success)
--

EXEC SDU_Tools.AnalyzePerformanceTuningTrace @TraceDatabaseName = NULL,
                                             @TraceSchemaName = N'dbo',
                                             @TraceTableName = N'SDU_Trace';

-----------------------------------------------------------------------------------
-- SDU Tools Version 3.0 Sample Scripts

-- Name:          SDU_Tools.FindSubsetIndexes
-- Function:      Finds indexes that appear to be subsets of other indexes
-- Parameters:    @DatabasesToCheck -- either ALL (default) or a comma-delimited list of database names
-- Action:        Finds indexes that appear to be subsets of other indexes
-- Return:        One rowset with details of each subset index

USE WWI_Production;
GO
CREATE INDEX IX_dbo_Customers_TradingName_CreditLimit
ON dbo.Customers 
(
	TradingName,
	CreditLimit
);
GO
USE Development;
GO
EXEC SDU_Tools.ListSubsetIndexes N'WWI_Production';
GO

-- Name:          SDU_Tools.QuoteString
-- Function:      Quotes a string
-- Parameters:    @InputString varchar(max)
-- Action:        Quotes a string (also doubles embedded quotes)
-- Return:        nvarchar(max)

DECLARE @Him nvarchar(max) = N'his name';
DECLARE @Them nvarchar(max) = N'they''re here';

SELECT @Him AS Him, SDU_Tools.QuoteString(@Him) AS QuotedHim
     , @Them AS Them, SDU_Tools.QuoteString(@Them) AS QuotedThem;

GO

-- Name:          SDU_Tools.LeftPad 
-- Function:      Left pads a string
-- Parameters:    @DateWithinYear date (use GETDATE() or SYSDATETIME() for today)
--                @FirstMonthOfFinancialYear int
-- Action:        Left pads a string to a target length with a given padding character.
--                Truncates the data if it is too large. With implicitly cast numeric
--                and other data types if not passed as strings.
-- Return:        nvarchar(max)

SELECT SDU_Tools.LeftPad(N'Hello', 14, N'o');
SELECT SDU_Tools.LeftPad(18, 10, N'0');

-- Name:          SDU_Tools.RightPad
-- Function:      Right pads a string
-- Parameters:    @DateWithinYear date (use GETDATE() or SYSDATETIME() for today)
--                @FirstMonthOfFinancialYear int
-- Action:        Right pads a string to a target length with a given padding character.
--                Truncates the data if it is too large. With implicitly cast numeric
--                and other data types if not passed as strings.
-- Return:        nvarchar(max)

SELECT SDU_Tools.RightPad(N'Hello', 14, N'o');
SELECT SDU_Tools.RightPad(18, 10, N'.');

-- Name:          SDU_Tools.SeparateByCase
-- Function:      Insert a separator between Pascal cased or Camel cased words
-- Parameters:    @InputString varchar(max)
-- Action:        Insert a separator between Pascal cased or Camel cased words
-- Return:        nvarchar(max)

SELECT SDU_Tools.SeparateByCase(N'APascalCasedSentence', N' ');
SELECT SDU_Tools.SeparateByCase(N'someCamelCasedWords', N' ');

-- Name:          SDU_Tools.SecondsToDuration
-- Function:      Convert a number of seconds to a SQL Server duration string
-- Parameters:    @NumberOfSeconds int 
-- Action:        Converts a number of seconds to a SQL Server duration string (similar to programming identifiers)
--                The value must be less than 24 hours (between 0 and 86399) otherwise the return value is NULL
-- Return:        varchar(8)

SELECT SDU_Tools.SecondsToDuration(910);   -- 15 minutes 10 seconds
SELECT SDU_Tools.SecondsToDuration(88000);   -- should return NULL

-- Name:          SDU_Tools.AnalyzeTableColumns
-- Function:      Analyze a table's columns
-- Parameters:    @DatabaseName sysname            -> (default current database) database to check
--                @SchemaName sysname              -> (default dbo) schema for the table
--                @TableName sysname               -> the table to analyze
--                @OrderByColumnName bit           -> if 1, output is in column name order, otherwise in column_id order
--                @OutputSampleValues bit          -> if 1 (default), outputs sample values from each column
--                @MaximumValuesPerColumn int      -> (default 100) if outputting sample values, up to how many
-- Action:        Provide metadata for a table's columns and list the distinct values held in the column (up to 
--                a maximum number of values). Note that filestream columns are not sampled, nor are any
--                columns of geometry, geography, or hierarchyid data types.
-- Return:        Rowset for table details, rowset for columns, rowsets for each column

EXEC SDU_Tools.AnalyzeTableColumns N'WideWorldImporters', N'Warehouse', N'StockItems', 1, 1, 100; 

-- Name:          SDU_Tools.PrintMessage
-- Function:      Print a message immediately 
-- Parameters:    @MessageToPrint nvarchar(max) -> The message to be printed
-- Action:        Prints a message immediately rather than waiting for PRINT to be returned
-- Return:        Nil

EXEC SDU_Tools.PrintMessage N'Hello';

-- Name:          SDU_Tools.StartOfFinancialYear
-- Function:      Return date of beginnning of financial year
-- Parameters:    @DateWithinYear date (use GETDATE() or SYSDATETIME() for today)
--                @FirstMonthOfFinancialYear int
-- Action:        Calculates the first date of the financial year for any given date 
-- Return:        date

SELECT SDU_Tools.StartOfFinancialYear(SYSDATETIME(), 7);
SELECT SDU_Tools.StartOfFinancialYear(GETDATE(), 11);

-- Name:          SDU_Tools.EndOfFinancialYear
-- Function:      Return last date of financial year
-- Parameters:    @DateWithinYear date (use GETDATE() or SYSDATETIME() for today)
--                @FirstMonthOfFinancialYear int
-- Action:        Calculates the last date of the financial year for any given date 
-- Return:        date

SELECT SDU_Tools.EndOfFinancialYear(SYSDATETIME(), 7);
SELECT SDU_Tools.EndOfFinancialYear(GETDATE(), 11);

GO

-----------------------------------------------------------------------------------
-- SDU Tools Version 2.0 Sample Scripts

-- Create the sample database for the examples

USE master;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE [name] = N'WWI_Production')
BEGIN
	ALTER DATABASE WWI_Production SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE WWI_Production;
END;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE [name] = N'WWI_UAT')
BEGIN
	ALTER DATABASE WWI_UAT SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE WWI_UAT;
END;
GO

CREATE DATABASE WWI_Production;
GO

USE WWI_Production;
GO

CREATE TABLE dbo.Customers
(
	CustomerID int IDENTITY(1,1) 
		CONSTRAINT PK_dbo_Customers PRIMARY KEY,
	TradingName nvarchar(30) NOT NULL,
	PrimaryPhoneNumber nvarchar(20) NULL,
	CreditLimit decimal(18,2) NULL
);

CREATE INDEX IX_dbo_Customers_TradingName 
ON dbo.Customers 
(
	TradingName
);
GO

INSERT dbo.Customers (TradingName, PrimaryPhoneNumber, CreditLimit)
VALUES ('ACM Cinemas Oz', '+61 7 3423-9929', 4000);
GO

CREATE DATABASE WWI_UAT;
GO

USE WWI_UAT;
GO

CREATE TABLE dbo.Customers
(
	CustomerID int IDENTITY(1,1) 
		CONSTRAINT PK_dbo_Customers PRIMARY KEY,
	TradingName nvarchar(50) NOT NULL,
	CreditLimit decimal(18,2) NULL,
	PrimaryPhoneNumber text NULL
);

CREATE INDEX IX_dbo_Customers_TradingName 
ON dbo.Customers 
(
	TradingName
)
INCLUDE
(
	CreditLimit
);
GO

SELECT *
INTO dbo.Customers_Backup
FROM dbo.Customers;
GO

USE Development;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE [name] = N'Development')
BEGIN
	ALTER DATABASE Development SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE Development;
END;
GO

CREATE DATABASE Development;
GO

USE Development;
GO

SET NOCOUNT ON;
GO

-- Name:          SDU_Tools.ProperCase
-- Function:      Apply Proper Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Proper Casing to a string !!! (also removes multiple spaces)
-- Return:        varchar(max)

SELECT SDU_Tools.ProperCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.ProperCase(N'janet mcdermott');
SELECT SDU_Tools.ProperCase(N'the curly-Haired  company');
SELECT SDU_Tools.ProperCase(N'po Box 1086');
GO

-- Name:          SDU_Tools.TitleCase
-- Function:      Apply Title Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Title Casing to a string (similar to book titles)
-- Return:        nvarchar(max)

SELECT SDU_Tools.TitleCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.TitleCase(N'janet mcdermott');
SELECT SDU_Tools.TitleCase(N'the case of sherlock holmes and the curly-Haired  company');
GO

-- Name:          SDU_Tools.CamelCase
-- Function:      Apply Camel Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Camel Casing to a string (also removes spaces)
-- Return:        varchar(max)

SELECT SDU_Tools.CamelCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.CamelCase(N'janet mcdermott');
SELECT SDU_Tools.CamelCase(N'the curly-Haired  company');
SELECT SDU_Tools.CamelCase(N'po Box 1086');
GO

-- Name:          SDU_Tools.PascalCase
-- Function:      Apply Pascal Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Pascal Casing to a string (also removes spaces)
-- Return:        varchar(max)

SELECT SDU_Tools.PascalCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.PascalCase(N'janet mcdermott');
SELECT SDU_Tools.PascalCase(N'the curly-Haired  company');
SELECT SDU_Tools.PascalCase(N'po Box 1086');
GO

-- Name:          SDU_Tools.SnakeCase
-- Function:      Apply Snake Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Snake Casing to a string !!! (also removes multiple spaces)
-- Return:        varchar(max)

SELECT SDU_Tools.SnakeCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.SnakeCase(N'janet mcdermott');
SELECT SDU_Tools.SnakeCase(N'the curly-Haired  company');
SELECT SDU_Tools.SnakeCase(N'po Box 1086');
GO

-- Name:          SDU_Tools.KebabCase
-- Function:      Apply Kebab Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Kebab Casing to a string !!! (also removes multiple spaces)
-- Return:        varchar(max)

SELECT SDU_Tools.KebabCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.KebabCase(N'janet mcdermott');
SELECT SDU_Tools.KebabCase(N'the curly-Haired  company');
SELECT SDU_Tools.KebabCase(N'po Box 1086');
GO

-- Name:          SDU_Tools.PercentEncode
-- Function:      Apply percent encoding to a string (could be used for URL Encoding)
-- Parameters:    @StringToEncode varchar(max)
-- Action:        Encodes reserved characters that might be used in HTML or URL encoding
--                Encoding is based on PercentEncoding article https://en.wikipedia.org/wiki/Percent-encoding
--                Only characters allowed unencoded are A-Z,a-z,0-9,-,_,.,~     (note: not the comma)
-- Return:        varchar(max)

SELECT SDU_Tools.PercentEncode('www.sqldownunder.com/podcasts');
SELECT SDU_Tools.PercentEncode('this should be a URL but it contains spaces and special characters []{}234');
GO

-- Name:          SDU_Tools.SplitDelimitedString
-- Function:      Splits a delimited string (usually either a CSV or TSV)
-- Parameters:    @StringToSplit nvarchar(max)       -> string that will be split
--                @Delimiter nvarchar(10)            -> delimited used (usually either N',' or NCHAR(9) for tab)
--                @TrimOutput bit                    -> if 1 then trim strings before returning them
-- Action:        Splits delimited strings - usually comma-delimited strings CSVs or tab-delimited strings (TSVs)
--                Delimiter can be specified
--                Optionally, the output strings can be trimmed
-- Return:        Table containing a column called StringValue nvarchar(max)

SELECT * FROM SDU_Tools.SplitDelimitedString(N'hello, there, greg', N',', 0);
SELECT * FROM SDU_Tools.SplitDelimitedString(N'hello' + NCHAR(9) + N'there' + NCHAR(9) + N'greg', NCHAR(9), 1);
GO

-- Name:          SDU_Tools.TrimWhitespace
-- Function:      Trims all whitespace around a string
-- Parameters:    @InputString nvarchar(max)
-- Action:        Removes any leading or trailing space, tab, carriage return, 
--                linefeed characters.
-- Return:        nvarchar(max)

DECLARE @CR_LF nchar(2) = NCHAR(13) + NCHAR(10);
DECLARE @TAB char(1) = NCHAR(9);

SELECT '-->' + SDU_Tools.TrimWhitespace(N'Test String') + '<--';
SELECT '-->' + SDU_Tools.TrimWhitespace(N'  Test String     ') + '<--';
SELECT '-->' + SDU_Tools.TrimWhitespace(N'  Test String  ' + @CR_LF + N' ' + @TAB + N'   ') + '<--';
GO

-- Name:          SDU_Tools.PreviousNonWhitespaceCharacter
-- Function:      Locates the previous non-whitespace character in a string
-- Parameters:    @StringToTest nvarchar(max)
--                @CurrentPosition int
-- Action:        Finds the previous non-whitespace character backwards from the 
--                current position.
-- Return:        nvarchar(1)

DECLARE @CR_LF nchar(2) = NCHAR(13) + NCHAR(10);
DECLARE @TAB char(1) = NCHAR(9);
DECLARE @TestString nvarchar(max) = N'Hello there ' + @TAB + ' fred ' + @CR_LF + 'again';
--                                    123456789112      3     456789     2  1     23456

SELECT SDU_Tools.PreviousNonWhitespaceCharacter(@TestString,11); -- should be r
SELECT SDU_Tools.PreviousNonWhitespaceCharacter(@TestString,15); -- should be e
SELECT SDU_Tools.PreviousNonWhitespaceCharacter(@TestString,22); -- should be d
SELECT SDU_Tools.PreviousNonWhitespaceCharacter(@TestString,1);  -- should be blank
SELECT SDU_Tools.PreviousNonWhitespaceCharacter(@TestString,0);  -- should be blank
GO

-- Name:          SDU_Tools.Base64ToVarbinary
-- Function:      Converts a base 64 value to varbinary
-- Parameters:    @Base64ValueToConvert varchar(max)
-- Action:        Converts a base 64 value to varbinary
-- Return:        varbinary(max)

SELECT SDU_Tools.Base64ToVarbinary('qrvM3e7/');
GO

-- Name:          SDU_Tools.BarbinaryToBase64
-- Function:      Converts a varbinary value to base 64 encoding
-- Parameters:    @VarbinaryValueToConvert varbinary(max)
-- Action:        Converts a varbinary value to base 64 encoding
-- Return:        varchar(max)

SELECT SDU_Tools.VarbinaryToBase64(0xAABBCCDDEEFF);
GO

-- Name:          SDU_Tools.CharToHexadecimal
-- Function:      Converts a single character to a hexadecimal string
-- Parameters:    CharacterToConvert char(1)
-- Action:        Converts a single character to a hexadecimal string
-- Return:        char(2)

SELECT SDU_Tools.CharToHexadecimal('A');
SELECT SDU_Tools.CharToHexadecimal('K');
SELECT SDU_Tools.CharToHexadecimal('1');
SELECT SDU_Tools.CharToHexadecimal('/');
GO

-- Name:          SDU_Tools.SQLVariantInfo
-- Function:      Returns information about a sql_variant value
-- Parameters:    @SQLVariantValue sql_variant
-- Action:        Returns information about a sql_variant value
-- Return:        Rowset with BaseType, MaximumLength

DECLARE @Value sql_variant;

SET @Value = 'hello';
SELECT * FROM SDU_Tools.SQLVariantInfo(@Value);
GO

-- Name:          SDU_Tools.GetDBSchemaCoreComparison
-- Function:      Checks the schema of two databases, looking for basic differences (user objects only)
-- Parameters:    @Database1 sysname              -> name of the first database to check
--                @Database2 sysname              -> name of the second database to compare
--                @IgnoreColumnID bit             -> set to 1 if tables with the same columns but in different order
--                                                   are considered equivalent, otherwise set to 0
--                @IgnoreFillFactor bit           -> set to 1 if index fillfactors are to be ignored, otherwise
--                                                   set to 0
-- Action:        Performs a comparison of the schema of two databases
-- Return:        Rowset describing differences

EXEC SDU_Tools.GetDBSchemaCoreComparison N'WWI_Production', N'WWI_UAT', 1, 1;
GO

-- Name:          SDU_Tools.GetTableSchemaComparison
-- Function:      Check the schema of two tables, looking for basic differences
-- Parameters:    @Table1DatabaseName sysname   -> name of the database containing the first table
--                @Table1SchemaName sysname     -> schema name for the first table
--                @Table1TableName sysname      -> table name for the first table
--                @Table2DatabaseName sysname   -> name of the database containing the second table
--                @Table2SchemaName sysname     -> schema name for the second table
--                @Table2TableName sysname      -> table name for the second table
--                @IgnoreColumnID bit           -> set to 1 if tables with the same columns but in different order
--                                                 are considered equivalent, otherwise set to 0
--                @IgnoreFillFactor bit         -> set to 1 if index fillfactors are to be ignored, otherwise
--                                                 set to 0
-- Action:        Performs a comparison of the schema of two tables
-- Return:        Rowset describing differences

EXEC SDU_Tools.GetTableSchemaComparison N'WWI_Production', N'dbo', N'Customers', N'WWI_UAT', N'dbo', N'Customers', 1, 1;
GO

EXEC SDU_Tools.GetTableSchemaComparison N'WWI_Production', N'dbo', N'Customers', N'WWI_UAT', N'dbo', N'Customers', 0, 1;
GO

-- Name:          SDU_Tools.FindStringWithinADatabase
-- Function:      Finds a string anywhere within a database
-- Parameters:    @DatabaseName sysname            -> database to check
--                @StringToSearchFor nvarchar(max) -> string we're looking for
--                @IncludeActualRows bit           -> should the rows containing it be output
-- Action:        Finds a string anywhere within a database. Can be useful for testing masking 
--                of data. Checks all string type columns and XML columns.
-- Return:        Rowset for found locations, optionally also output the rows

EXEC SDU_Tools.FindStringWithinADatabase N'WideWorldImporters', N'Kayla', 0; 
EXEC SDU_Tools.FindStringWithinADatabase N'WideWorldImporters', N'Kayla', 1; 
GO

-- Name:          SDU_Tools.ListAllDataTypesInUse
-- Function:      Lists every distinct data type being used
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        ListAllDataTypesInUse (user tables only)
-- Return:        Rowset a distinct list of DataTypes

EXEC SDU_Tools.ListAllDataTypesInUse @DatabaseName = N'WWI_Production',
                                     @SchemasToList = N'ALL', 
                                     @TablesToList = N'ALL', 
                                     @ColumnsToList = N'ALL';

EXEC SDU_Tools.ListAllDataTypesInUse @DatabaseName = N'WideWorldImporters',
                                     @SchemasToList = N'ALL', 
                                     @TablesToList = N'ALL', 
                                     @ColumnsToList = N'ALL';
GO

-- Name:          SDU_Tools.ListColumnsAndDataTypes
-- Function:      Lists the data types for all columns
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists the data types for all columns (user tables only)
-- Return:        Rowset containing SchemaName, TableName, ColumnName, and DataType. Within each 
--                table, columns are listed in column ID order

EXEC SDU_Tools.ListColumnsAndDataTypes @DatabaseName = N'WWI_Production',
                                       @SchemasToList = N'ALL', 
                                       @TablesToList = N'ALL', 
                                       @ColumnsToList = N'ALL';

EXEC SDU_Tools.ListColumnsAndDataTypes @DatabaseName = N'WideWorldImporters',
                                       @SchemasToList = N'ALL', 
                                       @TablesToList = N'ALL', 
                                       @ColumnsToList = N'ALL';
GO

-- Name:          SDU_Tools.ListUnusedIndexes
-- Function:      List indexes that appear to be unused
-- Parameters:    @DatabaseName sysname         -> Database to process
-- Action:        List indexes that appear to be unused (user tables only)
--                These indexes might be candidates for reconsideration and removal
--                but be careful about doing so, particularly for unique indexes
-- Return:        Rowset of schema name, table, name, index name, and is unique

EXEC SDU_Tools.ListUnusedIndexes @DatabaseName = N'WWI_Production';
GO

-- Name:          SDU_Tools.ListUseOfDeprecatedDataTypes
-- Function:      Lists any use of deprecated data types
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists any use of deprecated data types (user tables only)
-- Return:        Rowset containing SchemaName, TableName, ColumnName, and DataType. Within each 
--                table, columns are listed in column ID order

EXEC SDU_Tools.ListUseOfDeprecatedDataTypes @DatabaseName = N'msdb',
                                            @SchemasToList = N'ALL', 
                                            @TablesToList = N'ALL', 
                                            @ColumnsToList = N'ALL';
GO

-- Name:          SDU_Tools.ListUserTableSizes
-- Function:      Lists the size and number of rows for all or selected user tables
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ExcludeEmptyTables bit       -> 0 for list all, 1 for don't list empty objects
--                @IsOutputOrderedBySize bit    -> 0 for alphabetical, 1 for size descending
-- Action:        Lists the size and number of rows for all or selected user tables
-- Return:        Rowset containing SchemaName, TableName, TotalRows, TotalReservedMB, TotalUsedMB,
--                   TotalFreeMB in either alphabetical order or size descending order 

EXEC SDU_Tools.ListUserTableSizes @DatabaseName = N'WideWorldImporters',
                                  @SchemasToList = N'ALL', 
                                  @TablesToList = N'ALL', 
                                  @ExcludeEmptyTables = 0,
                                  @IsOutputOrderedBySize = 0;
GO

-- Name:          SDU_Tools.ListUserTableAndIndexSizes
-- Function:      Lists the size and number of rows for all or selected user tables and indexes
-- Parameters:    @DatabaseName sysname         -> Database to process
--                @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ExcludeEmptyIndexes bit      -> 0 for list all, 1 for don't list empty objects
--                @ExcludeTableStructure bit    -> 0 for list all, 1 for don't list base table (clustered index or heap)
--                @IsOutputOrderedBySize bit    -> 0 for alphabetical, 1 for size descending
-- Action:        Lists the size and number of rows for all or selected user tables and indexes
-- Return:        Rowset containing SchemaName, TableName, IndexName, TotalRows, TotalReservedMB, 
--                TotalUsedMB, TotalFreeMB in either alphabetical order or size descending order 

EXEC SDU_Tools.ListUserTableAndIndexSizes @DatabaseName = N'WideWorldImporters',
                                          @SchemasToList = N'ALL', 
                                          @TablesToList = N'ALL', 
                                          @ExcludeEmptyIndexes = 0,
										  @ExcludeTableStructure = 0,
                                          @IsOutputOrderedBySize = 0;
GO

-- Name:          SDU_Tools.EmptySchema
-- Function:      Removes objects in the specified schema in the specified database
-- Parameters:    @DatabaseName -> database containing the schema
--                @SchemaName -> schema to empty (cannot be dbo, sys, or SDU_Tools)
-- Action:        Removes objects in the specified schema in the current database
--                Note: must be run from within the same database as the schema
-- Return:        One rowset with details of each currently executing backup

USE WideWorldImporters;
GO
CREATE SCHEMA XYZABC AUTHORIZATION dbo;
GO
CREATE TABLE XYZABC.TestTable (TestTableID int IDENTITY(1,1) PRIMARY KEY);
GO
USE Development;
GO
EXEC SDU_Tools.EmptySchema @DatabaseName = N'WideWorldImporters', @SchemaName = N'XYZABC';
GO

-- Name:          SDU_Tools.IsXActAbortON
-- Function:      Checks if XACT_ABORT is on
-- Parameters:    None
-- Action:        Checks if XACT_ABORT is on
-- Return:        bit

SET XACT_ABORT OFF;
SELECT SDU_Tools.IsXActAbortON();
SET XACT_ABORT ON;
SELECT SDU_Tools.IsXActAbortON();
SET XACT_ABORT OFF;
GO

-- Name:          SDU_Tools.ShowBackupCompletionEstimates
-- Function:      Shows completion estimates for any currently executing backups
-- Parameters:    None
-- Action:        Shows completion estimates for any currently executing backups
-- Return:        One rowset with details of each currently executing backup
-- Test examples: 

-- BACKUP DATABASE WideWorldImporters TO DISK = 'C:\temp\WWI.bak' WITH FORMAT, INIT;
EXEC SDU_Tools.ShowBackupCompletionEstimates;
GO

-- Name:          SDU_Tools.ShowCurrentBlocking
-- Function:      Looks for requests that are blocking right now
-- Parameters:    @DatabaseName sysname         -> Database to process
-- Action:        Lists sessions holding locks, the SQL they are executing, then 
--                lists blocked items and the SQL they are trying to execute
-- Return:        Two rowsets

EXEC SDU_Tools.ShowCurrentBlocking @DatabaseName = N'WWI_Production';
GO
-- USE WWI_Production; BEGIN TRAN; UPDATE dbo.Customers SET CreditLimit += 100;
-- USE WWI_Production; SELECT * FROM dbo.Customers;
-- ROLLBACK;

EXEC SDU_Tools.ShowCurrentBlocking @DatabaseName = N'WWI_Production';
GO

-- Name:          SDU_Tools.ScriptSQLLogins
-- Function:      Scripts all SQL Logins
-- Parameters:    @LoginsToScript nvarchar(max) - comma-delimited list of login names to script or ALL
-- Action:        Scripts all specified SQL logins, with password hashes, security IDs, default 
--                databases and languages
-- Return:        nvarchar(max)

DECLARE @SQL nvarchar(max) = SDU_Tools.ScriptSQLLogins(N'ALL');
PRINT @SQL;
GO
CREATE LOGIN GregInternal WITH PASSWORD = N'BigSecret01';
GO
DECLARE @SQL nvarchar(max) = SDU_Tools.ScriptSQLLogins(N'GregInternal,sa');
PRINT @SQL;
GO
DROP LOGIN GregInternal;
GO

-- Name:          SDU_Tools.ScriptWindowsLogins
-- Function:      Scripts all Windows Logins
-- Parameters:    @LoginsToScript nvarchar(max) - comma-delimited list of login names to script or ALL
-- Action:        Scripts all specified Windows logins, with default databases and languages
-- Return:        nvarchar(max)

DECLARE @SQL nvarchar(max) = SDU_Tools.ScriptWindowsLogins(N'ALL');
PRINT @SQL;
GO
DECLARE @SQL nvarchar(max) = SDU_Tools.ScriptWindowsLogins(N'NT AUTHORITY\SYSTEM,NT SERVICE\SQLWriter');
PRINT @SQL;
GO

-- Name:          SDU_Tools.ScriptServerRoleMembers
-- Function:      Scripts all Server Role Members
-- Parameters:    @LoginsToScript nvarchar(max) - comma-delimited list of login names to script or ALL
-- Action:        Scripts all server role members for the selected logins
-- Return:        nvarchar(max)

DECLARE @SQL nvarchar(max) = SDU_Tools.ScriptServerRoleMembers(N'ALL');
PRINT @SQL;
GO
CREATE LOGIN GregInternal WITH PASSWORD = N'BigSecret01';
GO
ALTER SERVER ROLE diskadmin ADD MEMBER GregInternal;
GO
DECLARE @SQL nvarchar(max) = SDU_Tools.ScriptServerRoleMembers(N'GregInternal,sa');
PRINT @SQL;
GO
DROP LOGIN GregInternal;
GO

-- Name:          SDU_Tools.ScriptServerPermissions
-- Function:      Scripts all Server Permissions
-- Parameters:    @LoginsToScript nvarchar(max) - comma-delimited list of login names to script or ALL
-- Action:        Scripts all server permissions for the selected logins
-- Return:        nvarchar(max)

DECLARE @SQL nvarchar(max) = SDU_Tools.ScriptServerPermissions(N'ALL');
PRINT @SQL;
GO
DECLARE @SQL nvarchar(max) = SDU_Tools.ScriptServerPermissions(N'GregInternal,sa');
PRINT @SQL;
GO

-- Name:          SDU_Tools.ExecuteOrPrint
-- Function:      Execute or Print One or More SQL Commands in a String
-- Parameters:    @StringToExecuteOrPrint nvarchar(max) -> String containing SQL commands
--                @PrintOnly bit = 1                    -> If set to 1 commands are printed only not executed
--                @NumberOfCrLfBeforeGO int = 0         -> Number of carriage return linefeeds added before the
--                                                         batch separator (normally GO)
--                @IncludeGO bit = 0                    -> If 1 the batch separator (normally GO) will be added
--                @NumberOfCrLfAfterGO int = 0          -> Number of carriage return linefeeds added after the
--                                                         batch separator (normally GO)
--                @BatchSeparator nvarchar(20) = N'GO'  -> Batch separator to use (defaults to GO)
-- Action:        Either prints the SQL code or executes it batch by batch.
-- Return:        int 0 on success

DECLARE @SQL nvarchar(max) = N'
SELECT ''Hello Greg'';
SELECT 2 + 3;
GO
SELECT ''Wow'';
';

EXEC SDU_Tools.ExecuteOrPrint @StringToExecuteOrPrint = @SQL,
                              @PrintOnly = 1,
                              @IncludeGO = 1,
                              @NumberOfCrLfAfterGO = 1;

SET @SQL = N'SELECT ''Another statement'';';

EXEC SDU_Tools.ExecuteOrPrint @StringToExecuteOrPrint = @SQL,
                              @PrintOnly = 1,
                              @IncludeGO = 1,
                              @NumberOfCrLfAfterGO = 1;
GO

DECLARE @SQL nvarchar(max) = N'
SELECT ''Hello Greg'';
SELECT 2 + 3;
GO
SELECT ''Wow'';
';

EXEC SDU_Tools.ExecuteOrPrint @StringToExecuteOrPrint = @SQL,
                              @PrintOnly = 0,
                              @IncludeGO = 1,
                              @NumberOfCrLfAfterGO = 1;
GO

-- Name:          SDU_Tools.ExtractSQLTemplate
-- Function:      Extracts a query template from a SQL command string
-- Parameters:    @InputCommand nvarchar(max)      -> SQL Command (likely captured from Profiler 
--                                                    or Extended Events)
--                @MaximumReturnLength int         -> Limits the number of characters returned
-- Action:        Normalizes a SQL Server command, mostly for helping with performance tuning 
--                work. It extracts the underlying template of the command. If the command 
--                includes an exec sp_executeSQL statement, it tries to undo that statement 
--                as well. It will not be able to do so if that isn't the last statement 
--                in the batch being processed. Works even on invalid SQL syntax
-- Return:        nvarchar(max) output templated SQL

SELECT SDU_Tools.ExtractSQLTemplate('select * from customers where customerid = 12 and customername = ''fred'' order by customerid;', 4000);
SELECT SDU_Tools.ExtractSQLTemplate('select * from customers where customerid = 12', 4000);
SELECT SDU_Tools.ExtractSQLTemplate('select (2+2);', 4000);
SELECT SDU_Tools.ExtractSQLTemplate('select * from customers where sid = 0x12AEBCDEF2342AE2', 4000);




