--==================================================================================
-- Install or recreate the SDU_Tools Schema
-- Copyright Dr Greg Low
-- Version 21.0 Azure SQL DB Edition
--==================================================================================
--
-- What are the SDU Tools? 
--
-- This script contains a number of utility functions and procedures. These are 
-- created in a schema called SDU_Tools in the current database. Ensure that you 
-- are running this script from within the database where the tools should be installed.

-- When this script is executed, it first removes any existing objects from the 
-- SDU_Tools schema, then recreates all the tools with the latest versions. It 
-- can be re-run without issue. (Yes it's idempotent for the geeks).
-- Many of the functions are useful when performing troubleshooting but others 
-- are just general purpose functions. 
--
-- For a general overview of SDU Tools, refer to this video: https://youtu.be/o0im4sE5lsA
-- For information on installing the tools, refer to this video: https://youtu.be/zRPvryGYYXU
--
-- Note that string manipulation in T-SQL and scalar functions are slow. Many of 
-- these functions would be much faster as SQLCLR based implementations but not all 
-- system have SQLCLR integration enabled. To make them work wherever possible, all
-- these functions are written in pure T-SQL. We also don't assume that you're 
-- using the latest version of SQL Server, so the functions are written to work
-- on all currently-supported versions.
-- 
-- Not all functions and procedures from the full SDU Tools set are available in this 
-- Azure SQL DB edition. We've kept the ones that are relevant and have started adding 
-- some Azure SQL DB specific tools. Where a function or procedure could work across different
-- databases, we've often replaced it with a single database version with a 
-- name suffix like "InCurrentDatabase".
--
-- This toolset is updated regularly. Find the latest version or sign up to be
-- notified of updates at http://www.sqldownunder.com and for suggestions or 
-- bug reports, please email sdutoolsATsqldownunder.com 
--
--==================================================================================
-- Disclaimer and License
--==================================================================================
--
-- We try our hardest to make these tools as useful and bug free as possible, but like
-- any software, we can never guarantee that there won't be any issues. We hope you'll
-- decide to use the tools but all liability for using them is with you, not us.
--
-- You are free to download and use for these tools for personal, educational, and 
-- internal corporate purposes, as long as this header is retained, as long
-- as they are kept in the SDU_Tools schema as a single set of tools, and as long as 
-- this notice is kept in any script file copies of the tools. 
--
-- You may not repurpose them, redistribute, or resell them without written consent
-- from the author. We hope you'll find them really useful.
--
--==================================================================================
-- Fixes by version
--==================================================================================
-- 21.0                   StartOfFinancialYear - fixed scenario where wrong year could be returned
--                        ChineseYears - fixed typo in years of the goat (thanks Dave Dustin)
--                        UnixTimeToDateTime2, DateTime2ToUnixTime - now use bigint values
--                        to avoid Unix 2038 problem with int (thanks Bob Roberts)
--                        Fixes to max column lengths in nchar and nvarchar scripting
--
-- 20.0                   PascalCase examples were using CamelCase - thanks Wilfred van Dijk
--
-- 19.0                   TableOfNumbers no longer requires MAXRECURSION option
--
-- 18.0                   Nil
--
-- 17.0                   CheckInstantFileInitializationState now uses a more reliable 
--                        method on all versions (thanks Andy Kelly)
--
-- 16.2                   Server role scripting functions allow for older servers
--
-- 16.1                   Corrected issue with is_external for SQL Server versions
--                        prior to 2016 (Thanks Leon Carpay)
--
-- 16.0                   ProductVersionComponents can now be called from other databases
--                        apart from the one with SDU_Tools installed
--                        EmptySchema now works with external tables and synonyms
--                        GPO added to ProperCase
--
-- 15.0                   Added whitespace characters to TrimWhitespace
--                        Fixed parameter names in RetrustForeignKeys and RetrustCheckConstraints
--                        Fixed syntax error for selections of tables and schemas in 
--                        several commands (thanks Steven Hirth)
--                        ScriptTableAsUnpivot now outputs the attribute ID with a
--                        fixed column name (AttributeID) instead of the original column
--                        name and has an option to decide if a WHERE clause is needed when
--                        outputting as a table
--                        Fixed setup issues with case-sensitive instances (thanks Róbert Virág)
--
-- 14.0                   Additional short words excluded in TitleCase (like with and by)
--                        Corrected algorithm in DateDiffNoWeekends
--                        Tools that format data type names now deal correctly with varbinary(max)
--
-- 13.0                   Nil
--
-- 12.0                   Nil
--            12.1        Corrected double spacing in OperatingSystemSKUs for SKU 48
--                        Corrected link for SQL Server 2008 SP4 KB article
--
-- 11.0                   Corrected remote query timeout default for system configurations
--            11.1        Corrected detection of temporal tables in CalculateTableLoadingOrder 
--                        (thanks to Eberhard Meisel for finding it)
--            11.3        Replaced use of THROW with RAISERROR so the code still works on SQL 2008
--
-- 10.0                   Replaced KebabCase with TrainCase (see video)
--
-- 9.0                    Nil
--
-- 8.0                    Fixed error with EmptySchema not deleting table types
--
-- 6.0                    Nil
--
-- 5.0                    Fixed a further issue with semicolon delimiters in string
--                        splitting - reverted to a more reliable but slower option
--
-- 4.0                    Nil
--            4.1         Replaced use of THROW with RAISERROR (to ensure 2008 support)
--                        Moved reference to open_transaction_count to sys.dm_exec_requests
--                        instead of sys.dm_exec_sessions (to ensure 2008 support)
--                        (thanks to Simon Hall for finding this)
--            4.2         Added missing semicolons in XML encoding (thanks again to 
--                        Simon Hall for finding this)
--
-- 3.0                    Fixed some filtering options for list related stored procedures.
--                        Removed "CREATE OR ALTER" in a function header
--                        
-- 2.0                    Fixed some collation issues for databases with different
--                        collations to the server
--
--==================================================================================
-- Enhanced/Altered tools by version
--==================================================================================
-- 21.0                   ProperCase now excludes ETA, SPA, LLC (thanks John Reitter)
--                        SplitDelimitedString now is much faster
--                        ListUseOfDeprecatedDataTypes now includes a ChangeScript (thanks Michael Miller)
--                        GREATER, LEAST added to reserved words
-- 20.0                   DateDimensionPeriodColumns now has IsStartOfMonth, IsEndOfMonth,
--                        IsStartOfCalendarYear, IsEndOfCalendarYear, IsStartOfFiscalYear,
--                        IsEndOfFiscalYear and quarters both calendar and fiscal
--                        DateDimensionColumns now has quarters and start and end of month
--                        and a DateKey
-- 16.0                   ScriptSQLLogins and ScriptWindowsLogins now also script 
--                        disabled state when a login is disabled
-- 13.0                   BBQ added as a known uppercase word in ProperCase (thanks Andy Eggers)
-- 11.2                   Added sample command column to AnalyzePerformanceTuningTrace
-- 11.0                   ExtractSQLTemplate now includes support for sp_prepexec
--
--==================================================================================
-- String-Related Functions
--==================================================================================
--
-- ProperCase                      Converts a string to Proper Case
--                                 Refer to this video: https://youtu.be/OZ-ozo7R9eU
--
-- TitleCase                       Converts a string to Title Case (Like a Book Title)
--                                 Refer to this video: https://youtu.be/OZ-ozo7R9eU
--
-- CamelCase                       Converts a string to camelCase
--                                 Refer to this video: https://youtu.be/OZ-ozo7R9eU
--
-- PascalCase                      Converts a string to PascalCase
--                                 Refer to this video: https://youtu.be/OZ-ozo7R9eU
--
-- SnakeCase                       Converts a string to snake_case
--                                 Refer to this video: https://youtu.be/OZ-ozo7R9eU
--
-- KebabCase                       Converts a string to kebab-case
--                                 Refer to this video: https://youtu.be/6IcLkMEQtkY
--
-- TrainCase                       Converts a string to Train-Case
--                                 Refer to this video: https://youtu.be/6IcLkMEQtkY
--
-- ScreamingSnakeCase              Converts a string to SCREAMING_SNAKE_CASE
--                                 Refer to this video: https://youtu.be/6IcLkMEQtkY
--
-- CobolCase                       Converts a string to COBOL-CASE
--                                 Refer to this video: https://youtu.be/i1rnVlOR760
--
-- SpongeBobSnakeCase              Converts a string to sPoNgEbOb_sNaKe_CaSe
--                                 Refer to this video: https://youtu.be/6IcLkMEQtkY
--
-- PercentEncode                   Encodes reserved characters that are used in 
--                                 HTML or URL encoding
--                                 Refer to this video: https://youtu.be/pNjaasXYvEQ
--
-- XMLEncodeString                 XML encodes a string
--                                 Refer to this video: https://youtu.be/zZiCxGHyGsY
--
-- XMLDecodeString                 XML decodes a string
--                                 Refer to this video: https://youtu.be/zZiCxGHyGsY
--
-- StringLength                    Returns the actual length of a string (unlike LEN)
--                                 Refer to this video: https://youtu.be/ztzQ7SLQWlE
--
-- QuoteString                     Quotes a string 
--                                 Refer to this video: https://youtu.be/uIj-hTIhIZo
--
-- SplitDelimitedString            Splits a delimited string (usually either a CSV or TSV)
--                                 Refer to this video: https://youtu.be/Ubt4HSKE2QI
--
-- SplitDelimitedStringIntoColumns Splits a delimited string into columns (usually a whole row of data from either a CSV or TSV)
--                                 Refer to this video: https://youtu.be/yigwHDzPST0
--
-- NumberOfTokens                  Counts the number of tokens in a delimited string (like CSV, TSV)
--                                 Refer to this video: https://youtu.be/vT8GpbwaKzU
--
-- ExtractToken                    Extracts a specific token number from a delimited string (like CSV, TSV)
--                                 Refer to this video: https://youtu.be/vT8GpbwaKzU
--
-- TrimWhitespace                  Removes any leading or trailing space, tab, 
--                                 carriage return, and linefeed characters
--                                 Refer to this video: https://youtu.be/cYaUC053Elo
--
-- LeftPad                         Left pad a string to a target length with a given
--                                 padding character
--                                 Refer to this video: https://youtu.be/P-r1zmX1MpY
--
-- RightPad                        Right pad a string to a target length with a given
--                                 padding character
--                                 Refer to this video: https://youtu.be/P-r1zmX1MpY
--
-- SeparateByCase                  Insert a separator between Pascal cased or Camel cased words
--                                 Refer to this video: https://youtu.be/kyr8C2hY5HY
--
-- AsciiOnly                       Removes (and optionally replaces) any non-ASCII characters
--                                 Refer to this video: https://youtu.be/0YFYPN0Bivo
-- 
-- DigitsOnly                      Removes all non-digit characters in a string
--                                 Refer to this video: https://youtu.be/28e8p1oz7D4
--
-- AlphanumericOnly                Removes all non-alphanumeric characters in a string
--                                 Refer to this video: https://youtu.be/R51509NbAf0
--
-- AlphabeticOnly                  Removes all non-alphabetic characters in a string
--                                 Refer to this video: https://youtu.be/R51509NbAf0
--
-- StripDiacritics                 Removes all diacritics (accents, graves, etc.)
--                                 from a string
--                                 Refer to this video: https://youtu.be/Aqiqa9OXNqQ
--
-- InitialsFromName                Returns the initials from a name
--                                 Refer to this video: https://youtu.be/bWPsidPGrCQ
--
-- NullIfBlank                     Returns NULL if a string is blank or trims the string
--                                 Refer to this video: https://youtu.be/u1fCB08407s
--
-- PreviousNonWhitespaceCharacter  Finds the previous non-whitespace character working
--                                 backwards from the current position
--                                 Refer to this video: https://youtu.be/rY5-eLlzuKU
--
-- CountWords                      Counts words in a string
--                                 Refer to this video: https://youtu.be/H_BUVEqZy0c
--
-- SingleSpaceWords                Removes any whitespace characters and returns words single-spaced
--                                 Refer to this video: https://youtu.be/h5SGwS-uHzI
--
-- ExtractTrimmedWords             Extracts words from a string and trims them
--                                 Refer to this video: https://youtu.be/wkSF0VWZwOs
--
-- ExtractTrigrams                 Extracts distinct trigrams (substrings of up to 3 characters) 
--                                 from a string
--                                 Refer to this video: https://youtu.be/Bx8tijrm84E
--
-- Translate                       Translate one series of characters to another series of characters
--                                 Refer to this video: https://youtu.be/k8zbN1f8fgI
--
-- InvertString                    Inverts a string by using USD Encoding
--                                 Refer to this video: https://youtu.be/GhNOr0p1-lM
--
--==================================================================================
-- Data Conversion Functions
--==================================================================================
--
-- NumberAsText                    Converts a number to the English text equivalent
--                                 Refer to this video: https://youtu.be/_jgU-5jUUA8
--
-- NumberToRomanNumerals           Converts a number to a Roman Numerals string
--                                 Refer to this video: https://youtu.be/msCDdOdYwAo
--
-- Base64ToVarbinary               Converts a base 64 value to varbinary
--                                 Refer to this video: https://youtu.be/k6yHYdHn7NA
--
-- VarbinaryToBase64               Converts a varbinary value to base 64 encoding
--                                 Refer to this video: https://youtu.be/k6yHYdHn7NA
--
-- CharToHexadecimal               Converts a character to a hexadecimal string
--                                 Refer to this video: https://youtu.be/aT4viskU7fE
--
-- SQLVariantInfo                  Returns information about a SQL_variant value
--                                 Refer to this video: https://youtu.be/em62I-GBCEY
--
-- CurrentSessionDecimalSeparator  Returns the decimal separator for the current session
--                                 Refer to this video: https://youtu.be/Jy_qVDOjUzI
--
-- CurrentSessionThousandsSeparator Returns the thousands separator for the current session
--                                 Refer to this video: https://youtu.be/Jy_qVDOjUzI
--
-- SecondsToDuration               Converts a number of seconds to a duration string
--                                 Refer to this video: https://youtu.be/beANzSe1-jE
--
-- HexCharStringToInt              Converts a hexadecimal character string to an integer
--                                 Refer to this video: https://youtu.be/2BMd9uYjHVQ
--
-- HexCharStringToChar             Converts a hexadecimal character string to a character
--                                 Refer to this video: https://youtu.be/2BMd9uYjHVQ
--
-- ROT13                           Performs ROT-13 encoding or decoding of a string
--                                 Refer to this video: https://youtu.be/xZt__QIPEzA
--
-- TruncateTrailingZeroes          Converts a decimal value to a string with trailing 
--                                 zeroes truncated
--                                 Refer to this video: https://youtu.be/DGnUdJVIxmU
--
-- SQLServerVersionForCompatibilityLevel Converts a database compatibility level to
--                                 a SQL Server version 
--                                 Refer to this video: https://youtu.be/3i6xB7guzVM
--
--==================================================================================
-- Database and Table Comparison Tools
--==================================================================================
--
-- GetDBSchemaCoreComparison       Not appropriate for the Azure SQL DB version
--
--
-- GetTableSchemaComparison        Checks the schema of two tables, looking for basic 
--                                 differences. Azure SQL DB version is
--                                 GetTableSchemaComparisonInCurrentDatabase
--                                 Refer to this video: https://youtu.be/8Q8dsxBU6XQ
--
--==================================================================================
-- Date and Financial Functions
--==================================================================================
--
-- AddWeekdays                     Adds a number of week days (ie: non-weekend days)
--                                 to a starting date
--                                 Refer to this video: https://youtu.be/P7-nGcDOVyI
--
-- StartOfFinancialYear            Calculates the date for the beginning of a 
--                                 financial year
--                                 Refer to this video: https://youtu.be/wc8ZS_XPKZs
--
-- EndOfFinancialYear              Calculates the date for the end of a 
--                                 financial year
--                                 Refer to this video: https://youtu.be/wc8ZS_XPKZs
--
-- StartOfMonth                    Calculates the date for the start of a month
--                                 Refer to this video: https://youtu.be/ZZ9NR8M5lRc
--
-- EndOfMonth                      Calculates the date for the end of a month
--                                 Refer to this video: https://youtu.be/ZZ9NR8M5lRc
--
-- StartOfYear                     Calculates the date for the start of a year
--                                 Refer to this video: https://youtu.be/8ITn30E8240
--
-- EndOfYear                       Calculates the date for the end of a year
--                                 Refer to this video: https://youtu.be/8ITn30E8240
--
-- StartOfWeek                     Calculates the date for the start of a week
--                                 Refer to this video: https://youtu.be/8ITn30E8240
--
-- EndOfWeek                       Calculates the date for the end of a week
--                                 Refer to this video: https://youtu.be/8ITn30E8240
--
-- StartOfWorkingWeek              Calculates the date for the start of a working week
--                                 Refer to this video: https://youtu.be/8ITn30E8240
--
-- EndOfWorkingWeek                Calculates the date for the end of a working week
--                                 Refer to this video: https://youtu.be/8ITn30E8240
--
-- DaysInMonth                     Calculates the total number of days in the month for a given date
--                                 Refer to this video: https://youtu.be/BWl2jdNzjJU
--
-- DateOfEasterSunday              Calculates the date of Easter Sunday (Christian
--                                 Calendar)
--                                 Refer to this video: https://youtu.be/Cru9RVZqFZU
--
-- DateOfOrthodoxEaster            Calculates the date of Orthodox Easter
--                                 Refer to this video: https://youtu.be/QbYx4k0ey8k
--
-- DateOfChineseNewYear            Calculates the date of Chinese New Year 
--                                 Refer to this video: https://youtu.be/FM-SPBzXCYM
--
-- ChineseNewYearAnimalName        Calculates the zodiac animal name for a 
--                                 given year
--                                 Refer to this video: https://youtu.be/FM-SPBzXCYM
--
-- CalculateAge                    Calculates the age of anything based on 
--                                 starting date (such as date of birth) and 
--                                 ending date (such as today)
--                                 Refer to this video: https://youtu.be/4XTubsQKPlw
--
-- IsWeekday                       Determines if a given date is a weekday
--                                 Refer to this video: https://youtu.be/yizREK9tCZA
--
-- IsWeekend                       Determines if a given date is on a weekend
--                                 Refer to this video: https://youtu.be/yizREK9tCZA
--
-- IsLeapYear                      Determines if a given year is a leap year
--                                 Refer to this video: https://youtu.be/zVwRSJIYz2A
--
-- DateDiffNoWeekends              Determines the number of days (Monday to Friday) between two dates
--                                 Refer to this video: https://youtu.be/BhPtrYEWT6I
--
-- DateToJulianDayNumber           Converts a date to a Julian day number
--                                 Refer to this video: https://youtu.be/eLk2Bgj-aPo
--
-- JulianDayNumberToDate           Converts a Julian day number to a date
--                                 Refer to this video: https://youtu.be/eLk2Bgj-aPo
--
-- UnixTimeToDateTime2             Converts a Unix time to a datetime2 value
--                                 Refer to this video: https://youtu.be/tGplVv-G3E4
--
-- DateTime2ToUnixTime             Converts a datetime2 value to a Unix time
--                                 Refer to this video: https://youtu.be/tGplVv-G3E4
--
-- DatesBetween                    Function that returns a specified set of dates
--                                 Refer to this video: https://youtu.be/oxJi41TnE94
--
-- DatesBetweenNoWeekends          Function that returns a specified set of dates
--                                 but excluding weekends
--                                 Refer to this video: https://youtu.be/m5GtvUHXOFQ
--
-- DatesInPeriod                   Function that returns a set of dates for a number of periods
--                                 Refer to this function: https://youtu.be/D_abxiKmOHY
--
-- DateDimensionColumns            Function that returns common date dimension columns for a date
--                                 Refer to this video: https://youtu.be/oxJi41TnE94
--
-- DateDimensionPeriodColumns      Function that returns common date dimension period columns
--                                 (eg IsToday, IsLastCalendarYear, etc.) for a date
--                                 Refer to this video: https://youtu.be/pcoaHYK70nU
--
-- GetDateDimension                Outputs date dimension columns for all dates in the supplied range of dates
--                                 Refer to this video: https://youtu.be/jYKkh52TEqo
--
-- TimePeriodsBetween              Function that returns a list of time periods in the supplied range of times
--                                 Refer to this video: https://youtu.be/YAHLiGHjtfw
--
-- TimePeriodDimensionColumns      Function that returns common time dimension columns for a time of the day
--                                 Refer to this video: https://youtu.be/14UrzoIgrwA
--
-- GetTimePeriodDimension          Outputs time period dimension columns for an entire day
--                                 Refer to this video: https://youtu.be/jYKkh52TEqo
--
-- TimezoneOffsetToHours           Converts a timezone offset value (as returned by
--                                 the sys.time_zone_info view in 2012+) to hours
--                                 Refer to this video: https://youtu.be/2JRKZeNEIrE
--
-- ChineseYears                    View that returns details of Chinese Years including
--                                 date of new year, zodiac animal, and characters for the animals
--                                 Refer to this video: https://youtu.be/FM-SPBzXCYM
--
-- WeekdayOfMonth                  Returns the nth weekday of a month (negative for backwards)
--                                 Refer to this video: https://youtu.be/VFNJLTiqBnY
--
-- WeekdayOfSameWeek               Returns the nominated day of the target week
--                                 Refer to this video: https://youtu.be/XHMrwNvqwdQ
--
-- NearestWeekday                  Returns the nearest nominated day to the target date
--                                 Refer to this video: https://youtu.be/YSkWiD5Sfeg
--
-- DayNumberOfMonth                Returns the nth instance of a specific day in a month
--                                 i.e. 2nd Tuesday
--                                 Refer to this video: https://youtu.be/BeVXs-J4soo
--
-- WeekDayAcrossYears              For a particular day and month, returns the day of the week 
--                                 for a range of years
--                                 Refer to this video: https://youtu.be/k4wY1isY1G0
--
--==================================================================================
-- General Purpose Functions
--==================================================================================
--
-- TableOfNumbers                  Function that returns a specified set of numbers
--                                 from a given starting value.
--                                 Refer to this video: https://youtu.be/Ox-Ig043oeg
--
-- IsIPv4Address                   Function that determines if a string is a valid IPv4 address
--                                 Refer to this video: https://youtu.be/lTyVkgjL7wo
--
-- NULLIfZero                      Function that returns NULL on zero input otherwise decimal(18,2) output
--                                 Refer to this video: https://youtu.be/u1fCB08407s

-- ProductVersionToMajorVersion    Extracts a product major version from a build number (product version) 
--                                 Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- ProductVersionToMinorVersion    Extracts a product minor version from a build number (product version)
--                                 Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- ProductVersionToBuild           Extracts a product build from a build number (product version)
--                                 Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- ProductVersionToRelease         Extracts a product release from a build number (product version)
--                                 Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- ProductVersionComponents        Extracts the components of a product version
--                                 Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- SQLServerVersion                Returns the SQL Server Version as a string (e.g. 2008R2)
--                                 Refer to this video: https://youtu.be/_5DzK4ywxOU
--
-- SQLServerType                   Returns the type of Server as a string
--                                 Refer to this video: https://youtu.be/tASWb2eN-8w
--
-- SDUToolsVersion                 Returns the version of SDU Tools
--                                 Refer to this video: https://youtu.be/AsYA9Bd0t0k
--
--==================================================================================
-- Database Utilities
--==================================================================================
--
-- AnalyzeTableColumns              Provide metadata for a table's columns and list
--                                  the distinct values held in the column (up to 
--                                  a maximum number of values). Azure SQL DB version 
--                                  is AnalyzeTableColumnsInCurrentDatabase
--                                  Refer to this video: https://youtu.be/V-jCAT-TCXM
--    
-- CalculateTableLoadingOrder       Work out the order that related tables need to 
--                                  be loaded in by traversing foreign key relationships
--                                  Azure SQL DB version is CalculateTableLoadingOrderInCurrentDatabase
--                                  Refer to this video: https://youtu.be/7p5RXUplO40
--
-- CheckInstantFileInitializationState Not appropriate for the Azure SQL DB version

-- CreateLinkedServerToAzureSQLDatabase Not appropriate for the Azure SQL DB version
--         
-- CreateSQLLoginWithSIDFromDB      Not appropriate for the Azure SQL DB version
--
-- DropTemporaryTableIfExists       Drops a temporary table by name if it exists
--                                  and can be called with/without the #
--                                  Refer to this video: https://youtu.be/lbbjm-k8Axc
--   
-- ExecuteCommandInEachDB           Not appropriate for the Azure SQL DB version
--
-- FindStringWithinADatabase        Finds a string anywhere within a database. Can be 
--                                  useful for testing masking of sensitive data. Checks 
--                                  all string type columns and XML columns. Azure SQL DB
--                                  version is FindStringWithinCurrentDatabase
--                                  Refer to this video: https://youtu.be/OpTdjMMjy8w
--  
-- IsLockPagesInMemoryEnabled       Not appropriate for the Azure SQL DB version
--
-- ListSubsetIndexes                Lists indexes that appear to be subsets of other 
--                                  indexes in all databases or selected databases. Azure SQL DB
--                                  version is ListSubsetIndexesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/aICj46bmKJs
--                                  
-- ListAllDataTypesInUse            A distinct list of each data type (and size) used 
--                                  with the selected database
--                                  Azure SQL DB version is ListAllDataTypesInUseInCurrentDatabase
--                                  Refer to this video: https://youtu.be/1MzqnkLeoNM
--                                  
-- ListColumnsAndDataTypes          Lists all columns and their data types for a database
--                                  Azure SQL DB version is ListColumnsAndDataTypesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/FlkRho_Hngk
--                                  
-- ListDisabledIndexes              Lists all disabled indexes along with key column 
--                                  and included column lists
--                                  Azure SQL DB version is ListDisabledIndexesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/oLfp8y7XRdE
--
-- ListEmptyUserTables              Lists all user tables with no rows
--                                  Azure SQL DB version is ListEmptyUserTablesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/31uOTcyljWY
--
-- ListForeignKeys                  List foreign keys with column lists
--                                  Azure SQL DB version is ListForeignKeysInCurrentDatabase
--                                  Refer to this video: https://youtu.be/NC1na-Jn0ck
--
-- ListIncomingForeignKeys          List foreign keys with column lists filtered by references tables
--                                  Azure SQL DB version is ListIncomingForeignKeysInCurrentDatabase
--                                  Refer to this video: https://youtu.be/NnkAcm_b9ks
--
-- ListForeignKeyColumns            List foreign columns from both source and referenced tables
--                                  Azure SQL DB version is ListForeignKeyColumnsInCurrentDatabase
--                                  Refer to this video: https://youtu.be/NC1na-Jn0ck
--
-- ListIndexes                      List indexes with key column lists and include column lists
--                                  Azure SQL DB version is ListIndexesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/Mgwjw5mXnN8
--
-- ListMismatchedDatabaseCollations Not appropriate for the Azure SQL DB version
--                                  
-- ListMismatchedDataTypes          List columns with the same name that are defined with 
--                                  different data types
--                                  Azure SQL DB version is ListMismatchedDataTypesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/i6mmzhu4T9g
--   
-- ListNonIndexedForeignKeys        List foreign keys declared but not supported by at least one index
--                                  Azure SQL DB version is ListNonIndexedForeignKeysInCurrentDatabase
--                                  Refer to this video: https://youtu.be/VAD8PyQ1RUs
--
-- ListPotentialDateColumns         List columns that are named as dates but are defined with a data type 
--                                  that includes time
--                                  Azure SQL DB version is ListPotentialDateColumnsInCurrentDatabase
--                                  Refer to this video: https://www.youtube.com/watch?v=X2F82WmcgIg
--
-- ListPotentialDateColumnsByValue  List columns that are defined with a data type that includes time but 
--                                  no time is present in the data (this can take a while to check)
--                                  Azure SQL DB version is ListPotentialDateColumnsByValueInCurrentDatabase
--                                  Refer to this video: https://youtu.be/2bmhVXq_02Y
--                           
-- ListPrimaryKeyColumns            Lists the columns that are used in primary keys for all tables
--                                  Azure SQL DB version is ListPrimaryKeyColumnsInCurrentDatabase
--                                  Refer to this video: https://youtu.be/usTlhzOJj9o
--     
-- ListUnusedIndexes                Lists unused indexes for a database
--                                  Azure SQL DB version is ListUnusedIndexesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/SNVSBWPsBnw
--                                  
-- ListUseOfDeprecatedDataTypes     Lists all columns and their data types for a database
--                                  where the data type is deprecated
--                                  Azure SQL DB version is ListUseOfDeprecatedDataTypesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/XaRtOR1m8QI
--                                  
-- ListUserTableSizes               Lists the size and number of rows for all or selected 
--                                  user tables
--                                  Azure SQL DB version is ListUserTableSizesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/mwOpnit0zqg
--                                  
-- ListUserHeapTables               Lists user tables that have no clustered index
--                                  Azure SQL DB version is ListUserHeapTablesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/hhrLzkSY3pQ
--
-- ListUserTablesWithNoPrimaryKey   Lists user tables that do not have a primary key
--                                  declared
--                                  Azure SQL DB version is ListUserTablesWithNoPrimaryKeyInCurrentDatabase
--                                  Refer to this video: https://youtu.be/HVMEBhJS-GQ
--
-- ListUserTableAndIndexSizes       Lists the size and number of rows for all or selected 
--                                  user tables and indexes
--                                  Azure SQL DB version is ListUserTableAndIndexSizesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/mwOpnit0zqg
--                
-- ReseedSequenceBeyondTableValues  Reseeds a sequence above any existing table value that uses 
--                                  it as a default                  
--                                  Azure SQL DB version is ReseedSequenceBeyondTableValuesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/q-Ng3vQRo50
--
-- ReseedSequences                  Reseeds all the sequences in a database or a specified
--                                  list of schemas and sequences
--                                  Azure SQL DB version is ReseedSequencesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/q-Ng3vQRo50
--
-- EmptySchema                      Empties a schema (removes all user objects in the schema)
--                                  WARNING: obviously destructive
--                                  Azure SQL DB version is EmptySchemaInCurrentDatabase
--                                  Refer to this video: https://youtu.be/ygQNeirGdlM
--              
-- ReadCSVFile                      Not appropriate for the Azure SQL DB version
--          
-- RetrustForeignKeys               Retrusts foreign keys that were untrusted
--                                  Azure SQL DB version is RetrustForeignKeysInCurrentDatabase
--                                  Refer to this video: https://youtu.be/UM1NFlu4z28
--
-- RetrustCheckConstraints          Retrusts check constraints that were untrusted
--                                  Azure SQL DB version is RetrustCheckConstraintsInCurrentDatabase
--                                  Refer to this video: https://youtu.be/UM1NFlu4z28
--
-- ServerMaximumDBCompatibilityLevel Not appropriate for the Azure SQL DB version
--
-- SetAnsiNullsOnForTable           Turns on ANSI nulls for a table
--                                  WARNING: potentially destructive
--                                           constraints and nonclustered indexes need 
--                                           be dropped first and recreated later
--                                  Azure SQL DB version is SetAnsiNullsOnForTableInCurrentDatabase
--                                  Refer to this video: https://youtu.be/dQGBjchJYzc
--  
-- SetAnsiNullsQuotedIdentifierForStoredProcedures     
--                                  Turns on or off ANSI_NULLS and QUOTED_IDENTIFIER for
--                                  selected stored procedures
--                                  Azure SQL DB version is SetAnsiNullsQuotedIdentifierForStoredProceduresInCurrentDatabase
--                                  Refer to this video: https://youtu.be/EoYV_FbvkZQ
--
-- SetDatabaseCompabilityForAllDatabasesToMaximum Not appropriate for the Azure SQL DB version
--
-- PrintMessage                     Prints an output message immediately (not waiting for PRINT)
--                                  Refer to this video: https://youtu.be/Coabe1oY8Vg
--                                  
-- IsXActAbortON                    Determines if XACT_ABORT is currently on
--                                  Refer to this video: https://youtu.be/Bx81-MTqr1k
--                                  
-- ShowBackupCompletionEstimates    Not appropriate for the Azure SQL DB version
--                                  
-- ShowCurrentBlocking              Lists sessions (and their last queries) for all sessions
--                                  holding locks, then lists blocked sessions, with 
--                                  the queries they are trying to execute, and which
--                                  sessions are blocking them
--                                  Azure SQL DB version is ShowCurrentBlockingInCurrentDatabase
--                                  Refer to this video: https://youtu.be/utIPkuqfTu0
--                                  
-- ExecuteJobAndWaitForCompletion   Not appropriate for the Azure SQL DB version
--
-- IsJobRunning                     Not appropriate for the Azure SQL DB version
--
-- ClearServiceBrokerTransmissionQueue Not appropriate for the Azure SQL DB version
--
-- UpdateStatistics                 Update statistics for selected set of user tables 
--                                  (excluding Microsoft-shipped tables)
--                                  Azure SQL DB version is UpdateStatisticsInCurrentDatabase
--                                  Refer to this video: https://youtu.be/MW8pFHb4DhQ
--
-- Sleep                            Sleep for a number of seconds
--                                  Refer to this video: https://youtu.be/csUCf2GWGec
--
--==================================================================================
-- Reporting Services Functions
--==================================================================================
--
-- RSListUserAccessToContent        Not appropriate for the Azure SQL DB version
--
-- RSListUserAccess                 Not appropriate for the Azure SQL DB version
--
-- RSListContentItems               Not appropriate for the Azure SQL DB version
--
-- RSCatalogTypes                   View that details the different types of catalog
--                                  objects
--                                  Refer to this video: https://youtu.be/1eSKt2E0rbY
--
--==================================================================================
-- Scripting Functions
--==================================================================================
--
-- ScriptSQLLogins                  Not appropriate for the Azure SQL DB version
--                                  
-- ScriptWindowsLogins              Not appropriate for the Azure SQL DB version
--                                  
-- ScriptServerRoleMembers          Not appropriate for the Azure SQL DB version
--                                  
-- ScriptServerPermissions          Not appropriate for the Azure SQL DB version
--  
-- ScriptDatabaseUsers              Scripts all users associated with a login for 
--                                  a particular database
--                                  Refer to this video: https://youtu.be/IbsUyfLh2Po
--  
-- ScriptDatabaseObjectPermissions  Scripts all object permission for a database
--                                  Azure SQL DB version is ScriptDatabaseObjectPermissionsInCurrentDatabase
--                                  Refer to this video: https://youtu.be/Yz_869V-hRw
--
-- ScriptUserDefinedServerRoles     Not appropriate for the Azure SQL DB version
--
-- ScriptUserDefinedServerRolePermissions Not appropriate for the Azure SQL DB version
--
-- ScriptUserDefinedDatabaseRoles   Scripts all user-defined database roles
--                                  Azure SQL DB version is ScriptUserDefinedDatabaseRolesInCurrentDatabase
--                                  Refer to this video: https://youtu.be/EHMbDKFOS-E
--
-- ScriptUserDefinedDatabaseRolePermissions Scripts all permissions for user-defined database roles
--                                  Azure SQL DB version is ScriptUserDefinedDatabaseRolePermissionsInCurrentDatabase
--                                  Refer to this video: https://youtu.be/EHMbDKFOS-E
--
-- ScriptTable                      Scripts a table with many configurable options
--                                  Azure SQL DB version is ScriptTableInCurrentDatabase
--                                  Refer to this video: https://youtu.be/U62ACZQUDk4
--                                
-- FormatDataTypeName               Converts data type, maximum length, precision, and scale
--                                  into the standard format used in scripts
--                                  Refer to this video: https://youtu.be/Cn3jK3roWLg
--                                  
-- ScriptTableAsUnpivot             Scripts a table as an unpivoted query or view
--                                  Azure SQL DB version is ScriptTableAsUnpivotInCurrentDatabase
--                                  Refer to this video: https://youtu.be/03f6NDB19ms
--
-- ScriptAnalyticsView              Scripts a data model table as an analytics view
--                                  Azure SQL DB version is ScriptAnalyticsViewInCurrentDatabase
--                                  Refer to this video: https://youtu.be/lodq1ZvS51s
--
-- ExecuteOrPrint                   Either prints the generated code or executes it 
--                                  batch by batch. (Unless specified, it assumes that GO 
--                                  is the batch separator. One limitation is that it
--                                  doesn't accept inline comments on the batch separator
--                                  line).
--                                  Refer to this video: https://youtu.be/cABGotl_yHY
--                                  
-- PGObjectName                     Converts a Pascal-cased or camel-cased SQL Server object
--                                  name to a suitable snake-cased object name for use
--                                  with database engines like PostgreSQL
--                                  Refer to this video: https://youtu.be/2ZPa1dgOZew
--
--==================================================================================
-- Performance Tuning Related Functions and Procedures
--==================================================================================
--
-- CapturePerformanceTuningTrace    Not appropriate for the Azure SQL DB version
--                                  
-- LoadPerformanceTuningTrace       Not appropriate for the Azure SQL DB version
--                                  
-- AnalyzePerformanceTuningTrace    Not appropriate for the Azure SQL DB version
--                                  
-- ExtractSQLTemplate               Used to normalize a SQL Server command, mostly for 
--                                  helping with performance tuning work. Extracts the 
--                                  underlying template of the command. If the command 
--                                  includes an exec sp_executeSQL or sp_prepexec statement, 
--                                  tries to undo that statement as well. (Cannot do so if that 
--                                  isn't the last statement in the batch being processed)
--                                  Refer to this video: https://youtu.be/yX5q00m_uCA
--                                  
-- DeExecuteSQLString               Used internally by ExtractSQLTemplate
--                                  Assists with debugging and performance troubleshooting 
--                                  of sp_executeSQL commands, particularly those captured
--                                  in Profiler or Extended Events traces. Takes a valid 
--                                  exec sp_executeSQL string and extracts the embedded 
--                                  command from within it. Optionally, can extract 
--                                  the parameters and either embed them directly back 
--                                  into the code, or create them as variable declarations
--                                  Refer to this video: https://youtu.be/yX5q00m_uCA
--                                  
-- LastParameterStartPosition       Used internally by ExtractSQLTemplate
--                                  Starting at the end of the string, finds the last 
--                                  location where a parameter is defined, based 
--                                  on a @ prefix
--                                  Refer to this video: https://youtu.be/yX5q00m_uCA
--
--==================================================================================
-- General Utility Views
--==================================================================================
-- Countries                        Table of the world's countries
--                                  Refer to this video: https://youtu.be/5HnBk323Lis
--
-- Currencies                       Table of the world's currencies
--                                  Refer to this video: https://youtu.be/VuKJEtZ44WY
--
-- CurrenciesByCountry              Table of the currencies used by countries
--                                  Refer to this video: https://youtu.be/VuKJEtZ44WY
--
-- ReservedWords                    Lists SQL Server reserved words and their display
--                                  colors in SSMS
--                                  Refer to this video: https://youtu.be/WITnoiWRPsI
--
-- FutureReservedWords              Lists SQL Server declared future reserved words and
--                                  their display colors in SSMS
--                                  Refer to this video: https://youtu.be/WITnoiWRPsI
--
-- ODBCReservedWords                Lists ODBC reserved words and their display
--                                  colors in SSMS
--                                  Refer to this video: https://youtu.be/WITnoiWRPsI
--
-- SystemDataTypeNames              Lists SQL Server system data type names and their 
--                                  display colors in SSMS  
--                                  Refer to this video: https://youtu.be/WITnoiWRPsI
--
-- SystemWords                      Lists all SQL Server reserved words, future reserved
--                                  words, ODBC reserved words, and system data type names
--                                  and their display colors in SSMS
--                                  Refer to this video: https://youtu.be/WITnoiWRPsI
--
-- SystemConfigurationOptionDefaults Lists all SQL Server system configuration default values
--                                  Refer to this video: https://youtu.be/PZy2zWH0Nzc
--
-- NonDefaultSystemConfigurationOptions Lists all SQL Server system configuration options
--                                  that are not at their default values
--                                  Refer to this video: https://youtu.be/PZy2zWH0Nzc
--
-- OperatingSystemVersions          Lists operating system versions and their names
--                                  Refer to this video: https://youtu.be/vppwkKyWCwQ
--
-- OperatingSystemLocales           Lists operating system locales
--                                  Refer to this video: https://youtu.be/vppwkKyWCwQ
--
-- OperatingSystemSKUs              Lists SKUs (editions) sold for operating systems
--                                  Refer to this video: https://youtu.be/vppwkKyWCwQ
--
-- OperatingSystemConfiguration     Not appropriate for the Azure SQL DB version
--
-- SQLServerProductVersions         Lists Product Versions for SQL Server
--                                  Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- LatestSQLServerBuilds            Lists the latest releases and builds for each
--                                  supported SQL Server version
--                                  Refer to this video: https://youtu.be/iukl9tItxJ0
--
-- LoginTypes                       Maps LoginTypes to names and descriptions
--                                  Refer to this video: https://youtu.be/DFo9Yl2M3P0
--
-- UserTypes                        Maps UserTypes to names and descriptions
--                                  Refer to this video: https://youtu.be/DFo9Yl2M3P0
--
--============================================================================================
-- Start by recreating the schema
--

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @SQL nvarchar(max);
DECLARE @SchemaID int = SCHEMA_ID('SDU_Tools');

IF @SchemaID IS NULL
BEGIN
    SET @SQL = N'CREATE SCHEMA SDU_Tools AUTHORIZATION dbo;';
    EXECUTE (@SQL);
END
ELSE 
BEGIN -- drop all existing objects in the SDU_Tools schema
    DECLARE @ObjectCounter as int = 1;
    DECLARE @ObjectName sysname;
    DECLARE @TableName sysname;
    DECLARE @ObjectTypeCode varchar(10);
    DECLARE @IsExternalTable bit;
    DECLARE @IsVersionWithExternalTables bit 
      = CASE WHEN CAST(REPLACE(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 1, 2), '.', '') AS int) >= 13
             THEN 1
             ELSE 0
        END;

    DECLARE @ObjectsToRemove TABLE
    ( 
        ObjectRemovalOrder int IDENTITY(1,1) NOT NULL,
        ObjectTypeCode varchar(10) NOT NULL,
        ObjectName sysname NOT NULL,
        TableName sysname NULL,
        IsExternalTable bit
    );
    
    SET @SQL = N'
    SELECT o.[type], COALESCE(tt.[name], o.[name]), t.[name]'
    + CASE WHEN @IsVersionWithExternalTables <> 0 
           THEN N', COALESCE(tab.is_external, 0) '
           ELSE N', 0 '
      END + N'
    FROM sys.objects AS o 
    LEFT OUTER JOIN sys.objects AS t
        ON o.parent_object_id = t.[object_id]
    LEFT OUTER JOIN sys.table_types AS tt
        ON tt.type_table_object_id = o.object_id 
    LEFT OUTER JOIN sys.tables AS tab 
        ON tab.object_id = o.object_id 
    WHERE COALESCE(tt.[schema_id], o.[schema_id]) = ' + CAST(@SchemaID AS nvarchar(10)) + N'
    AND NOT (o.[type] IN (''PK'', ''UQ'', ''C'', ''F'') AND t.[type] <> ''U'') -- don''t want constraints on table types etc
    ORDER BY CASE o.[type] WHEN ''V'' THEN 1    -- view
                           WHEN ''P'' THEN 2    -- stored procedure
                           WHEN ''PC'' THEN 3   -- clr stored procedure
                           WHEN ''FN'' THEN 4   -- scalar function
                           WHEN ''FS'' THEN 5   -- clr scalar function
                           WHEN ''AF'' THEN 6   -- clr aggregate
                           WHEN ''FT'' THEN 7   -- clr table-valued function
                           WHEN ''TF'' THEN 8   -- table-valued function
                           WHEN ''IF'' THEN 9   -- inline table-valued function
                           WHEN ''TR'' THEN 10  -- trigger
                           WHEN ''TA'' THEN 11  -- clr trigger
                           WHEN ''D'' THEN 12   -- default
                           WHEN ''F'' THEN 13   -- foreign key constraint
                           WHEN ''C'' THEN 14   -- check constraint
                           WHEN ''UQ'' THEN 15  -- unique constraint
                           WHEN ''PK'' THEN 16  -- primary key constraint
                           WHEN ''U'' THEN 17   -- table
                           WHEN ''TT'' THEN 18  -- table type
                           WHEN ''SO'' THEN 19  -- sequence
                           WHEN ''SN'' THEN 20  -- synonym
             END;';

    INSERT @ObjectsToRemove (ObjectTypeCode, ObjectName, TableName, IsExternalTable)
    EXEC (@SQL);    
    
    WHILE @ObjectCounter <= (SELECT MAX(ObjectRemovalOrder) FROM @ObjectsToRemove)
    BEGIN
        SELECT @ObjectTypeCode = otr.ObjectTypeCode,
               @ObjectName = otr.ObjectName,
               @TableName = otr.TableName,
               @IsExternalTable = otr.IsExternalTable 
        FROM @ObjectsToRemove AS otr 
        WHERE otr.ObjectRemovalOrder = @ObjectCounter;

        SET @SQL = CASE WHEN @ObjectTypeCode = 'V' 
                        THEN N'DROP VIEW SDU_Tools.' + QUOTENAME(@ObjectName) + N';'
                        WHEN @ObjectTypeCode IN ('P' , 'PC')
                        THEN N'DROP PROCEDURE SDU_Tools.' + QUOTENAME(@ObjectName) + N';'
                        WHEN @ObjectTypeCode IN ('FN', 'FS', 'FT', 'TF', 'IF')
                        THEN N'DROP FUNCTION SDU_Tools.' + QUOTENAME(@ObjectName) + N';'
                        WHEN @ObjectTypeCode IN ('TR', 'TA')
                        THEN N'DROP TRIGGER SDU_Tools.' + QUOTENAME(@ObjectName) + N';'
                        WHEN @ObjectTypeCode IN ('C', 'D', 'F', 'PK', 'UQ')
                        THEN N'ALTER TABLE SDU_Tools.' + QUOTENAME(@TableName) 
                             + N' DROP CONSTRAINT ' + QUOTENAME(@ObjectName) + N';'
                        WHEN @ObjectTypeCode = 'U' AND @IsExternalTable = 0
                        THEN N'DROP TABLE SDU_Tools.' + QUOTENAME(@ObjectName) + N';'
                        WHEN @ObjectTypeCode = 'U' AND @IsExternalTable <> 0
                        THEN N'DROP EXTERNAL TABLE SDU_Tools.' + QUOTENAME(@ObjectName) + N';'
                        WHEN @ObjectTypeCode = 'AF'
                        THEN N'DROP AGGREGATE SDU_Tools.' + QUOTENAME(@ObjectName) + N';'
                        WHEN @ObjectTypeCode = 'TT'
                        THEN N'DROP TYPE SDU_Tools.' + QUOTENAME(@ObjectName) + N';'
                        WHEN @ObjectTypeCode = 'SO'
                        THEN N'DROP SEQUENCE SDU_Tools.' + QUOTENAME(@ObjectName) + N';'
                        WHEN @ObjectTypeCode = 'SN'
                        THEN N'DROP SYNONYM SDU_Tools.' + QUOTENAME(@ObjectName) + N';'
                   END;

            IF @SQL IS NOT NULL
            BEGIN
                EXECUTE(@SQL);
            END;

        SET @ObjectCounter += 1;
    END;
END; -- of if we need to empty the schema first
GO

--==================================================================================
-- SDU Tools Version
--==================================================================================

CREATE FUNCTION SDU_Tools.SDUToolsVersion()
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Returns the SDU Tools Version
-- Parameters:    Nil
-- Action:        Returns the SDU Tools Version
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/AsYA9Bd0t0k
--
-- Test examples: 
/*

SELECT SDU_Tools.SDUToolsVersion() AS [SDU Tools Version];

*/
    RETURN N'21.0 Azure SQL DB';
END;
GO

--==================================================================================
-- String Functions and Procedures
--==================================================================================

CREATE FUNCTION SDU_Tools.PascalCase
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Apply Pascal Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Pascal Casing to a string (similar to programming identifiers)
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/OZ-ozo7R9eU
--
-- Test examples: 
/*

SELECT SDU_Tools.PascalCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.PascalCase(N'janet mcdermott');
SELECT SDU_Tools.PascalCase(N'the case of sherlock holmes and the curly-Haired  company');

*/
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @WordCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    DECLARE @CurrentWord nvarchar(max);
    DECLARE @NumberOfWords int;
    
    DECLARE @Words TABLE
    (
        WordNumber int IDENTITY(1,1),
        Word nvarchar(max)
    );
    
    SET @StringToProcess = LOWER(LTRIM(RTRIM(@InputString)));
    SET @InAWord = 0;
    SET @CurrentWord = N'';
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', N'-', NCHAR(9)) -- whitespace or hyphens
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
                INSERT @Words VALUES (@CurrentWord);
                SET @CurrentWord = N'';
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                SET @CurrentWord = @Character;
            END ELSE BEGIN -- part of a word
                SET @CurrentWord += @Character;
            END;
        END;
    END;
    IF @InAWord <> 0 
    BEGIN
        INSERT @Words VALUES (@CurrentWord);
    END;
    
    UPDATE @Words SET Word = UPPER(SUBSTRING(Word, 1, 1)) + SUBSTRING(Word, 2, LEN(Word) - 1);

    SET @NumberOfWords = (SELECT COUNT(*) FROM @Words);
    SET @WordCounter = 0;
    
    WHILE @WordCounter < @NumberOfWords
    BEGIN
        SET @WordCounter += 1;
        SET @CurrentWord = (SELECT Word FROM @Words WHERE WordNumber = @WordCounter);
        SET @Response += @CurrentWord;
    END;
    
    RETURN @Response;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION [SDU_Tools].[KebabCase]
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Apply Kebab Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Kebab Casing to a string (similar to programming identifiers)
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/6IcLkMEQtkY
--
-- Test examples: 
/*

SELECT SDU_Tools.KebabCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.KebabCase(N'janet mcdermott');
SELECT SDU_Tools.KebabCase(N'the case of sherlock holmes and the curly-Haired  company');

*/
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @WordCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    DECLARE @CurrentWord nvarchar(max);
    DECLARE @NumberOfWords int;
    
    DECLARE @Words TABLE
    (
        WordNumber int IDENTITY(1,1),
        Word nvarchar(max)
    );
    
    SET @StringToProcess = LOWER(LTRIM(RTRIM(@InputString)));
    SET @InAWord = 0;
    SET @CurrentWord = N'';
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', N'-', NCHAR(9)) -- whitespace or hyphens
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
                INSERT @Words VALUES (@CurrentWord);
                SET @CurrentWord = N'';
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                SET @CurrentWord = @Character;
            END ELSE BEGIN -- part of a word
                SET @CurrentWord += @Character;
            END;
        END;
    END;
    IF @InAWord <> 0 
    BEGIN
        INSERT @Words VALUES (@CurrentWord);
    END;
    
    SET @NumberOfWords = (SELECT COUNT(*) FROM @Words);
    SET @WordCounter = 0;
    
    WHILE @WordCounter < @NumberOfWords
    BEGIN
        SET @WordCounter += 1;
        SET @CurrentWord = (SELECT Word FROM @Words WHERE WordNumber = @WordCounter);
        SET @Response += CASE WHEN @WordCounter > 1 THEN N'-' ELSE N'' END + @CurrentWord;
    END;
    
    RETURN @Response;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.CamelCase
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Apply Pascal Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Pascal Casing to a string (similar to programming identifiers)
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/OZ-ozo7R9eU
--
-- Test examples: 
/*

SELECT SDU_Tools.CamelCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.CamelCase(N'janet mcdermott');
SELECT SDU_Tools.CamelCase(N'the case of sherlock holmes and the curly-Haired  company');

*/
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @WordCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    DECLARE @CurrentWord nvarchar(max);
    DECLARE @NumberOfWords int;
    
    DECLARE @Words TABLE
    (
        WordNumber int IDENTITY(1,1),
        Word nvarchar(max)
    );
    
    SET @StringToProcess = LOWER(LTRIM(RTRIM(@InputString)));
    SET @InAWord = 0;
    SET @CurrentWord = N'';
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', N'-', NCHAR(9)) -- whitespace or hyphens
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
                INSERT @Words VALUES (@CurrentWord);
                SET @CurrentWord = N'';
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                SET @CurrentWord = @Character;
            END ELSE BEGIN -- part of a word
                SET @CurrentWord += @Character;
            END;
        END;
    END;
    IF @InAWord <> 0 
    BEGIN
        INSERT @Words VALUES (@CurrentWord);
    END;
    
    UPDATE @Words SET Word = CASE WHEN WordNumber > 1 THEN UPPER(SUBSTRING(Word, 1, 1)) + SUBSTRING(Word, 2, LEN(Word) - 1)
                                  ELSE Word 
                             END;

    SET @NumberOfWords = (SELECT COUNT(*) FROM @Words);
    SET @WordCounter = 0;
    
    WHILE @WordCounter < @NumberOfWords
    BEGIN
        SET @WordCounter += 1;
        SET @CurrentWord = (SELECT Word FROM @Words WHERE WordNumber = @WordCounter);
        SET @Response += @CurrentWord;
    END;
    
    RETURN @Response;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.PercentEncode(@StringToEncode varchar(max))
RETURNS varchar(max)
AS
BEGIN;

-- Function:      Apply percent encoding to a string (could be used for URL Encoding)
-- Parameters:    @StringToEncode varchar(max)
-- Action:        Encodes reserved characters that might be used in HTML or URL encoding
--                Encoding is based on PercentEncoding article https://en.wikipedia.org/wiki/Percent-encoding
--                Only characters allowed unencoded are A-Z,a-z,0-9,-,_,.,~     (note: not the comma)
-- Return:        varchar(max)
-- Refer to this video: https://youtu.be/pNjaasXYvEQ
--
-- Test examples: 
/*

SELECT SDU_Tools.PercentEncode('www.SQLdownunder.com/podcasts');
SELECT SDU_Tools.PercentEncode('this should be a URL but it contains {}234');

*/
    DECLARE @ReservedCharacterPattern varchar(max) = '%[^A-Za-z0-9\-\_\.\~]%';
    DECLARE @NextReservedCharacterLocation int;
    DECLARE @CharacterToEncode char(1);
    DECLARE @StringToReturn varchar(max) = '';
    DECLARE @RemainingString varchar(max) = @StringToEncode;
    
    SET @NextReservedCharacterLocation = PATINDEX(@ReservedCharacterPattern, @RemainingString);
    WHILE @NextReservedCharacterLocation > 0 
    BEGIN
        SET @StringToReturn += LEFT(@RemainingString, @NextReservedCharacterLocation - 1)
                            + '%' 
                            + SDU_Tools.CharToHexadecimal(SUBSTRING(@RemainingString, @NextReservedCharacterLocation, 1));
        SET @RemainingString = SUBSTRING(@RemainingString, @NextReservedCharacterLocation + 1, LEN(@RemainingString));

        SET @NextReservedCharacterLocation = PATINDEX(@ReservedCharacterPattern, @RemainingString);
    END;

    SET @StringToReturn += @RemainingString;

    RETURN (@StringToReturn);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.XMLEncodeString
(
    @StringToEncode nvarchar(max)
)
RETURNS varchar(max)
AS 

-- Function:      XML encodes a string
-- Parameters:    @StringToEncode - a character string to be XML encoded
-- Action:        XML encodes a string. In particular, code the following characters "'<>&/_ 
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/zZiCxGHyGsY
--
-- Test examples: 
/*

SELECT SDU_Tools.XMLEncodeString(N'Hello there John & Mary. This is <X> only a token');
SELECT SDU_Tools.XMLEncodeString(N'<hello there></hello there>');

*/
BEGIN
    DECLARE @ReturnString nvarchar(max) = '';
    DECLARE @Counter int = 1;
    DECLARE @Character nchar(1);

    WHILE @Counter <= LEN(@StringToEncode)
    BEGIN
        SET @Character = SUBSTRING(@StringToEncode, @Counter, 1);
        SET @ReturnString = @ReturnString 
                          + CASE @Character WHEN N'"' THEN N'&quot;'
                                            WHEN N'''' THEN N'&#x27;'
                                            WHEN N'<' THEN N'&lt;'
                                            WHEN N'>' THEN N'&gt;'
                                            WHEN N'&' THEN N'&#x26;'
                                            WHEN N'/' THEN N'&#x2F;'
                                            WHEN N'_' THEN N'&#x5F;'
                                            ELSE @Character
                             END;
        SET @Counter = @Counter + 1;
    END;
    RETURN @ReturnString;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.XMLDecodeString
(
    @StringToDecode nvarchar(max)
)
RETURNS nvarchar(max)
AS 

-- Function:      XML decodes a string
-- Parameters:    @StringToDecode - a character string to be XML decoded
-- Action:        XML decodes a string. In particular, processes &quot; &lt; &gt; &apos; &amp; and any hex character encoding 
--                via &#xHH where HH is a hex character string
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/zZiCxGHyGsY
--
-- Test examples: 
/*

SELECT SDU_Tools.XMLDecodeString(N'Hello there John &amp; Mary. This is &lt;X&gt; only a token');
SELECT SDU_Tools.XMLDecodeString(N'&lt;hello there&gt;&lt;&#x2F;hello there&gt;');

*/
BEGIN
    DECLARE @ReturnString nvarchar(max) = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@StringToDecode, N'&quot;', N'"'), 
                                                                                                   N'&lt;', N'<'), 
                                                                                                   N'&gt;', N'>'), 
                                                                                                   N'&apos;', N''''), 
                                                                                                   N'&amp;', N'&');
    DECLARE @CurrentPosition int = 1;
    DECLARE @NextPosition int = PATINDEX(N'%&#x[0-9,A-F,a-f][0-9,A-F,a-f][;]%', @ReturnString);
    
    WHILE @NextPosition > 0
    BEGIN
        SET @ReturnString = LEFT(@ReturnString, @NextPosition - 1)
                          + SDU_Tools.HexCharStringToChar(SUBSTRING(@ReturnString, @NextPosition + 3, 2))
                          + RIGHT(@ReturnString, LEN(@ReturnString) - @NextPosition - 5);
        SET @NextPosition = PATINDEX(N'%&#x[0-9,A-F,a-f][0-9,A-F,a-f][;]%', @ReturnString);
    END;

    RETURN @ReturnString;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.PreviousNonWhitespaceCharacter
( 
    @StringToTest nvarchar(max), 
    @CurrentPosition int
)
RETURNS nvarchar(1)
AS
BEGIN

-- Function:      Locates the previous non-whitespace character in a string
-- Parameters:    @StringToTest nvarchar(max)
--                @CurrentPosition int
-- Action:        Finds the previous non-whitespace character backwards from the 
--                current position.
-- Return:        nvarchar(1)
-- Refer to this video: https://youtu.be/rY5-eLlzuKU
--
-- Test examples: 
/*

DECLARE @TestString nvarchar(max) = N'Hello there ' + CHAR(9) + ' fred ' + CHAR(13) + CHAR(10) + 'again';
--                                    123456789112         3     456789         2          1      23456

SELECT SDU_Tools.PreviousNonWhitespaceCharacter(@TestString,11); -- should be r
SELECT SDU_Tools.PreviousNonWhitespaceCharacter(@TestString,15); -- should be e
SELECT SDU_Tools.PreviousNonWhitespaceCharacter(@TestString,22); -- should be d
SELECT SDU_Tools.PreviousNonWhitespaceCharacter(@TestString,1);  -- should be blank
SELECT SDU_Tools.PreviousNonWhitespaceCharacter(@TestString,0);  -- should be blank

*/
    DECLARE @NonWhitespaceCharacterPattern nvarchar(9) = N'%[^ ' + NCHAR(9) + NCHAR(13) + NCHAR(10) + N']%';
    DECLARE @ReverseStringSegment nvarchar(max) = CASE WHEN @CurrentPosition <= 0 THEN ''
                                                       ELSE REVERSE(SUBSTRING(@StringToTest, 1, @CurrentPosition - 1))
                                                  END;
    DECLARE @LastCharacter int = PATINDEX(@NonWhitespaceCharacterPattern, @ReverseStringSegment);

    RETURN CASE WHEN @LastCharacter = 0 THEN N''
                ELSE SUBSTRING(@ReverseStringSegment, @LastCharacter, 1)
           END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ProperCase
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Apply Proper Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Proper Casing to a string
-- Return:        varchar(max)
-- Refer to this video: https://youtu.be/OZ-ozo7R9eU
--
-- Test examples: 
/*

SELECT SDU_Tools.ProperCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.ProperCase(N'janet mcdermott');
SELECT SDU_Tools.ProperCase(N'the curly-Haired  company');
SELECT SDU_Tools.ProperCase(N'po Box 1086');
SELECT SDU_Tools.ProperCase(N'now is the time for a bbq folks');

*/
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @WordCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    DECLARE @CurrentWord nvarchar(max);
    DECLARE @ModifiedWord nvarchar(max);
    DECLARE @NumberOfWords int;
    
    DECLARE @Words TABLE
    (
        WordNumber int IDENTITY(1,1),
        Word nvarchar(max)
    );
    
    SET @StringToProcess = LOWER(LTRIM(RTRIM(@InputString)));
    SET @InAWord = 0;
    SET @CurrentWord = N'';
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', NCHAR(9)) -- whitespace
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
                INSERT @Words VALUES (@CurrentWord);
                SET @CurrentWord = N'';
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                SET @CurrentWord = @Character;
            END ELSE BEGIN -- part of a word
                SET @CurrentWord += @Character;
            END;
        END;
    END;
    IF @InAWord <> 0 
    BEGIN
        INSERT @Words VALUES (@CurrentWord);
    END;
    
    SET @NumberOfWords = (SELECT COUNT(*) FROM @Words);
    SET @WordCounter = 0;
    
    WHILE @WordCounter < @NumberOfWords
    BEGIN
        SET @WordCounter += 1;
        SET @CurrentWord = (SELECT Word FROM @Words WHERE WordNumber = @WordCounter);

        IF @CurrentWord IN ('PO', 'DC', 'NY', 'BBQ', 'GPO', 'ETA', 'SPA', 'LLC')
        BEGIN
            SET @ModifiedWord = UPPER(@CurrentWord);
        END ELSE BEGIN
            SET @ModifiedWord = UPPER(SUBSTRING(@CurrentWord, 1, 1)) + SUBSTRING(@CurrentWord, 2, LEN(@CurrentWord) - 1);
        END;
        IF LEFT(@CurrentWord, 2) = N'mc' AND LEN(@CurrentWord) >= 3
        BEGIN
            SET @ModifiedWord = N'Mc' + UPPER(SUBSTRING(@CurrentWord, 3, 1)) + SUBSTRING(@CurrentWord, 4, LEN(@CurrentWord) - 3);
        END;
        IF LEFT(@CurrentWord, 3) = N'mac' AND LEN(@CurrentWord) >= 4
        BEGIN
            SET @ModifiedWord = N'Mac' + UPPER(SUBSTRING(@CurrentWord, 4, 1)) + SUBSTRING(@CurrentWord, 5, LEN(@CurrentWord) - 4);
        END;
        
        SET @CharacterCounter = 0;
        WHILE @CharacterCounter <= LEN(@ModifiedWord)
        BEGIN
            SET @CharacterCounter += 1;
            SET @Character = SUBSTRING(@ModifiedWord, @CharacterCounter, 1);
            IF @Character IN (N'.', N'-', N';', N':', N'&', N'$', N'#', N'@', N'!', N'*', N'%', N'(', N')', N'''')
            BEGIN
                IF LEN(@ModifiedWord) > @CharacterCounter 
                BEGIN
                    SET @ModifiedWord = SUBSTRING(@ModifiedWord, 1, @CharacterCounter)
                                      + UPPER(SUBSTRING(@ModifiedWord, @CharacterCounter + 1, 1))
                                      + SUBSTRING(@ModifiedWord, @CharacterCounter + 2, LEN(@ModifiedWord) - @CharacterCounter - 1);
                END;
            END;
        END;
        
        SET @Response += @ModifiedWord;
        IF @WordCounter < @NumberOfWords SET @Response += N' ';
    END;
    
    RETURN @Response;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.SnakeCase
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Apply Snake Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Snake Casing to a string (similar to programming identifiers)
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/OZ-ozo7R9eU
--
-- Test examples: 
/*

SELECT SDU_Tools.SnakeCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.SnakeCase(N'janet mcdermott');
SELECT SDU_Tools.SnakeCase(N'the case of sherlock holmes and the curly-Haired  company');

*/
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @WordCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    DECLARE @CurrentWord nvarchar(max);
    DECLARE @NumberOfWords int;
    
    DECLARE @Words TABLE
    (
        WordNumber int IDENTITY(1,1),
        Word nvarchar(max)
    );
    
    SET @StringToProcess = LOWER(LTRIM(RTRIM(@InputString)));
    SET @InAWord = 0;
    SET @CurrentWord = N'';
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', N'-', NCHAR(9)) -- whitespace or hyphens
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
                INSERT @Words VALUES (@CurrentWord);
                SET @CurrentWord = N'';
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                SET @CurrentWord = @Character;
            END ELSE BEGIN -- part of a word
                SET @CurrentWord += @Character;
            END;
        END;
    END;
    IF @InAWord <> 0 
    BEGIN
        INSERT @Words VALUES (@CurrentWord);
    END;
    
    SET @NumberOfWords = (SELECT COUNT(*) FROM @Words);
    SET @WordCounter = 0;
    
    WHILE @WordCounter < @NumberOfWords
    BEGIN
        SET @WordCounter += 1;
        SET @CurrentWord = (SELECT Word FROM @Words WHERE WordNumber = @WordCounter);
        SET @Response += CASE WHEN @WordCounter > 1 THEN N'_' ELSE N'' END + @CurrentWord;
    END;
    
    RETURN @Response;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.QuoteString
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Quotes a string
-- Parameters:    @InputString varchar(max)
-- Action:        Quotes a string (also doubles embedded quotes)
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/uIj-hTIhIZo
--
-- Test examples: 
/*

DECLARE @Him nvarchar(max) = N'his name';
DECLARE @Them nvarchar(max) = N'they''re here';

SELECT @Him AS Him, SDU_Tools.QuoteString(@Him) AS QuotedHim
     , @Them AS Them, SDU_Tools.QuoteString(@Them) AS QuotedThem;

*/
    RETURN N'''' + REPLACE(@InputString, N'''', N'''''') + N'''';
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.SplitDelimitedString
(
    @StringToSplit nvarchar(max),
    @Delimiter nvarchar(10),
    @TrimOutput bit
)
RETURNS @StringTable TABLE 
(
    RowNumber int IDENTITY(1,1),
    StringValue nvarchar(max)
)
AS
BEGIN

-- Function:      Splits a delimited string (usually either a CSV or TSV)
-- Parameters:    @StringToSplit nvarchar(max)       -> string that will be split
--                @Delimiter nvarchar(10)            -> delimited used (usually either N',' or NCHAR(9) for tab)
--                @TrimOutput bit                    -> if 1 then trim strings before returning them
-- Action:        Splits delimited strings - usually comma-delimited strings CSVs or tab-delimited strings (TSVs)
--                Delimiter can be specified
--                Optionally, the output strings can be trimmed
-- Return:        Table containing a column called StringValue nvarchar(max)
-- Refer to this video: https://youtu.be/Ubt4HSKE2QI
-- Test examples: 
/*

SELECT * FROM SDU_Tools.SplitDelimitedString(N'hello, there, greg', N',', 0);
SELECT * FROM SDU_Tools.SplitDelimitedString(N'hello' + NCHAR(9) + N'there' + NCHAR(9) + N'greg', NCHAR(9), 1);
SELECT * FROM SDU_Tools.SplitDelimitedString(N'Now works, with embedded ,% signs', N',', 1);

*/

    DECLARE @LastDelimiterLocation int = 0;
    DECLARE @NextDelimiterLocation int = CHARINDEX(@Delimiter, @StringToSplit, 1);
    WHILE @NextDelimiterLocation > 0
    BEGIN
        INSERT @StringTable VALUES (CASE WHEN @TrimOutput <> 0 
                                         THEN LTRIM(RTRIM(SUBSTRING(@StringToSplit, @LastDelimiterLocation + 1, @NextDelimiterLocation - @LastDelimiterLocation - 1))) 
                                         ELSE SUBSTRING(@StringToSplit, @LastDelimiterLocation + 1, @NextDelimiterLocation - @LastDelimiterLocation - 1) 
                                    END);
        SET @LastDelimiterLocation = @NextDelimiterLocation;
        SET @NextDelimiterLocation = CHARINDEX(@Delimiter, @StringToSplit, @LastDelimiterLocation + 1);
    END;

    IF LEN(@StringToSplit) > @LastDelimiterLocation
    BEGIN
        INSERT @StringTable 
        VALUES (CASE WHEN @TrimOutput <> 0 
                     THEN LTRIM(RTRIM(SUBSTRING(@StringToSplit, @LastDelimiterLocation + 1, LEN(@StringToSplit)))) 
                     ELSE SUBSTRING(@StringToSplit, @LastDelimiterLocation + 1, LEN(@StringToSplit)) 
                END);
    END;

    RETURN;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.SplitDelimitedStringIntoColumns  
(
    @StringToSplit nvarchar(max), 
    @Delimiter nvarchar(1), 
    @TrimOutput bit
)
RETURNS TABLE
AS 

-- Function:      Splits a delimited string into columns (usually either a CSV or TSV)
-- Parameters:    @StringToSplit nvarchar(max)       -> string (probably a row) that will be split
--                @Delimiter nvarchar(10)            -> delimited used (usually either N',' or NCHAR(9) for tab)
--                @TrimOutput bit                    -> if 1 then trim strings before returning them
-- Action:        Splits delimited strings - usually entire rows as comma-delimited strings CSVs or tab-delimited strings (TSVs)
--                Delimiter can be specified
--                Optionally, the output strings can be trimmed
-- Return:        Table containing 50 columns called Column01, Column02, etc. nvarchar(max)
-- Refer to this video: https://youtu.be/yigwHDzPST0
-- Test examples: 
/*

DECLARE @TAB nchar(1) = NCHAR(9);
DECLARE @RowData nvarchar(max);

SET @RowData = N'210.4,John Doe,327.32,2234242,Current,1';

SELECT @RowData;
SELECT * FROM SDU_Tools.SplitDelimitedStringIntoColumns(@RowData, N',', 1);

SET @RowData = N'210.4|John Doe|327.32|2234242|Current|1';

SELECT @RowData;
SELECT * FROM SDU_Tools.SplitDelimitedStringIntoColumns(@RowData, N'|', 1);

SET @RowData = N'210.4' + @TAB + N'John Doe' + @TAB + N'327.32' + @TAB + N'2234242' + @TAB + N'Current' + @TAB + N'1';

SELECT @RowData;
SELECT * FROM SDU_Tools.SplitDelimitedStringIntoColumns(@RowData, @TAB, 1);

*/

RETURN ( 
            WITH ColumnsAsRows
            AS
            (
                SELECT N'Column' + RIGHT(N'0' + CAST(sds.RowNumber AS nvarchar(20)), 2) AS ColumnName, StringValue 
                FROM SDU_Tools.SplitDelimitedString(@StringToSplit, @Delimiter, @TrimOutput) AS sds
                WHERE sds.RowNumber <= 50
            )
            SELECT Column01, Column02, Column03, Column04, Column05, Column06, Column07, Column08, Column09, Column10,
                   Column11, Column12, Column13, Column14, Column15, Column16, Column17, Column18, Column19, Column20,
                   Column21, Column22, Column23, Column24, Column25, Column26, Column27, Column28, Column29, Column30,
                   Column31, Column32, Column33, Column34, Column35, Column36, Column37, Column38, Column39, Column40,
                   Column41, Column42, Column43, Column44, Column45, Column46, Column47, Column48, Column49, Column50
            FROM ColumnsAsRows AS car
            PIVOT
            (
                MAX(StringValue) FOR ColumnName IN 
                (
                    Column01, Column02, Column03, Column04, Column05, Column06, Column07, Column08, Column09, Column10,
                    Column11, Column12, Column13, Column14, Column15, Column16, Column17, Column18, Column19, Column20,
                    Column21, Column22, Column23, Column24, Column25, Column26, Column27, Column28, Column29, Column30,
                    Column31, Column32, Column33, Column34, Column35, Column36, Column37, Column38, Column39, Column40,
                    Column41, Column42, Column43, Column44, Column45, Column46, Column47, Column48, Column49, Column50
                )
            ) AS pt
       );
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DigitsOnly
(
    @InputString nvarchar(max),
    @StripLeadingSign bit
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Removes all non-digit characters in a string
-- Parameters:    @InputString nvarchar(max) - String to be processed (unicode or single byte)
--                @StripLeadingSign - If the string contains a leading + or - sign, is it stripped as well?
-- Action:        Removes all non-digit characters in a string optionally retains or removes any leading sign
-- Return:        varchar(max)
-- Refer to this video: https://youtu.be/28e8p1oz7D4
--
-- Test examples: 
/*

SELECT SDU_Tools.DigitsOnly('Hello20834There  234', 1);
SELECT SDU_Tools.DigitsOnly('(425) 902-2322', 1);
SELECT SDU_Tools.DigitsOnly('+1 (425) 902-2322', 1);
SELECT SDU_Tools.DigitsOnly('+1 (425) 902-2322', 0);

*/

    DECLARE @Counter int = 1;
    DECLARE @ReturnValue nvarchar(max) = '';
    DECLARE @CharacterCode int;
    DECLARE @StringToProcess nvarchar(max) = LTRIM(RTRIM(@InputString)); -- cast all unicode to single byte
    DECLARE @NextCharacter nchar(1);

    IF LEFT(@StringToProcess, 1) IN (N'+', N'-')
    BEGIN
        IF @StripLeadingSign <> 0
        BEGIN
            SET @StringToProcess = SUBSTRING(@StringToProcess, 2, LEN(@StringToProcess));
        END;
    END;

    WHILE @Counter <= LEN(@StringToProcess)
    BEGIN
        SET @NextCharacter = SUBSTRING(@StringToProcess, @Counter, 1);
        SET @ReturnValue = @ReturnValue
                         + CASE WHEN @NextCharacter BETWEEN N'0' AND N'9'
                                OR (@NextCharacter IN (N'+', N'-') AND @Counter = 1)
                                THEN @NextCharacter
                                ELSE N''
                           END;
        SET @Counter = @Counter + 1;
    END;

    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.TitleCase
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Apply Title Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Title Casing to a string (similar to book titles)
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/OZ-ozo7R9eU
--
-- Test examples: 
/*

SELECT SDU_Tools.TitleCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.TitleCase(N'janet mcdermott');
SELECT SDU_Tools.TitleCase(N'the case of sherlock holmes and the curly-Haired  company');

*/
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @WordCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    DECLARE @CurrentWord nvarchar(max);
    DECLARE @ModifiedWord nvarchar(max);
    DECLARE @NumberOfWords int;
    
    DECLARE @Words TABLE
    (
        WordNumber int IDENTITY(1,1),
        Word nvarchar(max)
    );
    
    SET @StringToProcess = LOWER(LTRIM(RTRIM(@InputString)));
    SET @InAWord = 0;
    SET @CurrentWord = N'';
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', NCHAR(9)) -- whitespace
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
                INSERT @Words VALUES (@CurrentWord);
                SET @CurrentWord = N'';
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                SET @CurrentWord = @Character;
            END ELSE BEGIN -- part of a word
                SET @CurrentWord += @Character;
            END;
        END;
    END;
    IF @InAWord <> 0 
    BEGIN
        INSERT @Words VALUES (@CurrentWord);
    END;
    
    SET @NumberOfWords = (SELECT COUNT(*) FROM @Words);
    SET @WordCounter = 0;
    
    WHILE @WordCounter < @NumberOfWords
    BEGIN
        SET @WordCounter += 1;
        SET @CurrentWord = (SELECT Word FROM @Words WHERE WordNumber = @WordCounter);
        IF @WordCounter = 1
        BEGIN
            SET @ModifiedWord = UPPER(SUBSTRING(@CurrentWord, 1, 1)) + SUBSTRING(@CurrentWord, 2, LEN(@CurrentWord) - 1);
        END ELSE BEGIN
            IF @CurrentWord IN (N'a', N'an', N'and', N'are', N'at', N'by', N'for', N'from', N'if', 
                                N'in', N'is', N'of', N'on', N'than', N'the', N'this', 
                                N'to', N'with')
            BEGIN
                SET @ModifiedWord = @CurrentWord;
            END ELSE BEGIN
                IF LEFT(@CurrentWord, 2) = N'mc' AND LEN(@CurrentWord) >= 3
                BEGIN
                    SET @ModifiedWord = N'Mc' + UPPER(SUBSTRING(@CurrentWord, 3, 1)) + SUBSTRING(@CurrentWord, 4, LEN(@CurrentWord) - 3);
                END ELSE BEGIN
                    IF LEFT(@CurrentWord, 3) = N'mac' AND LEN(@CurrentWord) >= 4
                    BEGIN
                        SET @ModifiedWord = N'Mac' + UPPER(SUBSTRING(@CurrentWord, 4, 1)) + SUBSTRING(@CurrentWord, 5, LEN(@CurrentWord) - 4);
                    END ELSE BEGIN
                        SET @ModifiedWord = UPPER(SUBSTRING(@CurrentWord, 1, 1)) + SUBSTRING(@CurrentWord, 2, LEN(@CurrentWord) - 1);
                    END;
                END;
            END;
        END;
        
        SET @CharacterCounter = 0;
        WHILE @CharacterCounter <= LEN(@ModifiedWord)
        BEGIN
            SET @CharacterCounter += 1;
            SET @Character = SUBSTRING(@ModifiedWord, @CharacterCounter, 1);
            IF @Character IN (N'.', N'-', N';', N':', N'&', N'$', N'#', N'@', N'!', N'*', N'%', N'(', N')', N'''')
            BEGIN
                IF LEN(@ModifiedWord) > @CharacterCounter 
                BEGIN
                    SET @ModifiedWord = SUBSTRING(@ModifiedWord, 1, @CharacterCounter)
                                      + UPPER(SUBSTRING(@ModifiedWord, @CharacterCounter + 1, 1))
                                      + SUBSTRING(@ModifiedWord, @CharacterCounter + 2, LEN(@ModifiedWord) - @CharacterCounter - 1);
                END;
            END;
        END;
        
        SET @Response += @ModifiedWord;
        IF @WordCounter < @NumberOfWords SET @Response += N' ';
    END;
    
    RETURN @Response;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.TrimWhitespace
( 
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Trims all whitespace around a string
-- Parameters:    @InputString nvarchar(max)
-- Action:        Removes any leading or trailing space, tab, carriage return, 
--                linefeed characters.
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/cYaUC053Elo
--
-- Test examples: 
/*

SELECT '-->' + SDU_Tools.TrimWhitespace('Test String') + '<--';
SELECT '-->' + SDU_Tools.TrimWhitespace('  Test String     ') + '<--';
SELECT '-->' + SDU_Tools.TrimWhitespace('  Test String  ' + char(13) + char(10) + ' ' + char(9) + '   ') + '<--';
SELECT '-->' + SDU_Tools.TrimWhitespace(N'  Test String  ' + nchar(13) + nchar(10) + N' ' + nchar(8232) + N'   ') + N'<--';

*/

    DECLARE @NonWhitespaceCharacterPattern nvarchar(30) 
      = N'%[^'
      + NCHAR(9) + NCHAR(10) + NCHAR(11) + NCHAR(12) + NCHAR(13) 
      + NCHAR(32) + NCHAR(133) + NCHAR(160) + NCHAR(5760) + NCHAR(8192) 
      + NCHAR(8193) + NCHAR(8194) + NCHAR(8195) + NCHAR(8196) 
      + NCHAR(8197) + NCHAR(8198) + NCHAR(8199) + NCHAR(8200) 
      + NCHAR(8201) + NCHAR(8202) + NCHAR(8232) + NCHAR(8233) 
      + NCHAR(8239) + NCHAR(8287) + NCHAR(12288)
      + N']%';

    DECLARE @StartCharacter int = PATINDEX(@NonWhitespaceCharacterPattern, @InputString);
    DECLARE @LastCharacter int = PATINDEX(@NonWhitespaceCharacterPattern, REVERSE(@InputString));

    RETURN CASE WHEN @StartCharacter = 0 THEN N''
                ELSE SUBSTRING(@InputString, @StartCharacter, DATALENGTH(@InputString) / 2 + 2 - @StartCharacter - @LastCharacter)
           END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.LeftPad
(
    @InputString nvarchar(max),
    @TargetLength int,
    @PaddingCharacter nvarchar(1)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Left pads a string
-- Parameters:    @DateWithinYear date (use GETDATE() or SYSDATETIME() for today)
--                @FirstMonthOfFinancialYear int
-- Action:        Left pads a string to a target length with a given padding character.
--                Truncates the data if it is too large. With implicitly cast numeric
--                and other data types if not passed as strings.
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/P-r1zmX1MpY
--
-- Test examples: 
/*

SELECT SDU_Tools.LeftPad(N'Hello', 14, N'o');
SELECT SDU_Tools.LeftPad(18, 10, N'0');

*/
    RETURN RIGHT(REPLICATE(@PaddingCharacter, @TargetLength) + @InputString, @TargetLength);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.RightPad
(
    @InputString nvarchar(max),
    @TargetLength int,
    @PaddingCharacter nvarchar(1)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Right pads a string
-- Parameters:    @DateWithinYear date (use GETDATE() or SYSDATETIME() for today)
--                @FirstMonthOfFinancialYear int
-- Action:        Right pads a string to a target length with a given padding character.
--                Truncates the data if it is too large. With implicitly cast numeric
--                and other data types if not passed as strings.
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/P-r1zmX1MpY
--
-- Test examples: 
/*

SELECT SDU_Tools.RightPad(N'Hello', 14, N'o');
SELECT SDU_Tools.RightPad(18, 10, N'.');

*/
    RETURN LEFT(@InputString + REPLICATE(@PaddingCharacter, @TargetLength), @TargetLength);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION [SDU_Tools].[SeparateByCase]
(
    @InputString nvarchar(max),
    @Separator nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Insert a separator between Pascal cased or Camel cased words
-- Parameters:    @InputString varchar(max)
-- Action:        Insert a separator between Pascal cased or Camel cased words
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/kyr8C2hY5HY
--
-- Test examples: 
/*

SELECT SDU_Tools.SeparateByCase(N'APascalCasedSentence', N' ');
SELECT SDU_Tools.SeparateByCase(N'someCamelCasedWords', N' ');

*/
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @CharacterCounter int = 0;
    DECLARE @Character nchar(1);
    
    WHILE @CharacterCounter < LEN(@InputString)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@InputString, @CharacterCounter, 1);
        IF @CharacterCounter > 1
        BEGIN
            IF ASCII(UPPER(@Character)) = ASCII(@Character) 
            BEGIN
                SET @Response += @Separator;
            END;
        END;
        SET @Response += @Character;
    END;
    
    RETURN @Response;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION [SDU_Tools].[AsciiOnly]
(
    @InputString nvarchar(max),
    @ReplacementCharacters varchar(10),
    @AreControlCharactersRemoved bit
)
RETURNS varchar(max)
AS
BEGIN

-- Function:      Removes or replaces all non-ASCII characters in a string
-- Parameters:    @InputString nvarchar(max) - String to be processed (unicode or single byte)
--                @ReplacementCharacters varchar(10) - Up to 10 characters to replace non-ASCII 
--                                                     characters with - can be blank
--                @AreControlCharactersRemoved bit - Should all control characters also be replaced
-- Action:        Finds all non-ASCII characters in a string and either removes or replaces them
-- Return:        varchar(max)
-- Refer to this video: https://youtu.be/0YFYPN0Bivo
--
-- Test examples: 
/*

SELECT SDU_Tools.AsciiOnly('Hello° There', '', 0);
SELECT SDU_Tools.AsciiOnly('Hello° There', '?', 0);
SELECT SDU_Tools.AsciiOnly('Hello° There' + CHAR(13) + CHAR(10) + ' John', '', 1);

*/

    DECLARE @Counter int = 1;
    DECLARE @ReturnValue varchar(max) = '';
    DECLARE @CharacterCode int;
    DECLARE @StringToProcess varchar(max) = @InputString; -- cast all unicode to single byte

    WHILE @Counter <= LEN(@StringToProcess)
    BEGIN
        SET @ReturnValue = @ReturnValue
                         + CASE WHEN ASCII(SUBSTRING(@StringToProcess, @Counter, 1)) BETWEEN 32 AND 127
                                THEN SUBSTRING(@StringToProcess, @Counter, 1)
                                WHEN ASCII(SUBSTRING(@StringToProcess, @Counter, 1)) < 127
                                AND @AreControlCharactersRemoved = 0
                                THEN SUBSTRING(@StringToProcess, @Counter, 1)
                                ELSE @ReplacementCharacters
                           END;
        SET @Counter = @Counter + 1;
    END;

    RETURN @ReturnValue;
END;
GO

--==================================================================================
-- Data Conversion Functions and Procedures
--==================================================================================

SET ANSI_NULLS ON;
GO

CREATE FUNCTION SDU_Tools.Base64ToVarbinary
(
    @Base64ValueToConvert varchar(max)
)
RETURNS varbinary(max)
AS
BEGIN
-- Function:      Converts a base 64 value to varbinary
-- Parameters:    @Base64ValueToConvert varchar(max)
-- Action:        Converts a base 64 value to varbinary
-- Return:        varbinary(max)
-- Refer to this video: https://youtu.be/k6yHYdHn7NA
--
-- Test examples: 
/*

SELECT SDU_Tools.Base64ToVarbinary('qrvM3e7/');

*/
    RETURN CAST('' as xml).value('xs:base64Binary(sql:variable("@Base64ValueToConvert"))', 'varbinary(max)');
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.CharToHexadecimal(@CharacterToConvert char(1))
RETURNS char(2)
AS
BEGIN

-- Function:      Converts a single character to a hexadecimal string
-- Parameters:    CharacterToConvert char(1)
-- Action:        Converts a single character to a hexadecimal string
-- Return:        char(2)
-- Refer to this video: https://youtu.be/aT4viskU7fE
--
-- Test examples: 
/*

SELECT SDU_Tools.CharToHexadecimal('A');
SELECT SDU_Tools.CharToHexadecimal('K');
SELECT SDU_Tools.CharToHexadecimal('1');

*/
    DECLARE @HexadecimalCharacters char(16) = '0123456789ABCDEF';
    DECLARE @AsciiCharacter int = ASCII(@CharacterToConvert);

    RETURN (SUBSTRING(@HexadecimalCharacters, (@AsciiCharacter / 16) + 1, 1)
           + SUBSTRING(@HexadecimalCharacters, (@AsciiCharacter % 16) + 1, 1));
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.SQLVariantInfo
(
    @SQLVariantValue SQL_variant 
)
RETURNS TABLE
AS
-- Function:      Returns information about a SQL_variant value
-- Parameters:    @SQLVariantValue SQL_variant
-- Action:        Returns information about a SQL_variant value
-- Return:        Rowset with BaseType, MaximumLength
-- Refer to this video: https://youtu.be/em62I-GBCEY
--
-- Test examples: 
/*

DECLARE @Value SQL_variant;
SET @Value = 'hello';
SELECT * FROM SDU_Tools.SQLVariantInfo(@Value);

*/
    RETURN (SELECT CAST(SQL_VARIANT_PROPERTY(@SQLVariantValue, 'BaseType') AS sysname) AS BaseType,
                   CAST(SQL_VARIANT_PROPERTY(@SQLVariantValue, 'Precision') AS int) AS Precision,
                   CAST(SQL_VARIANT_PROPERTY(@SQLVariantValue, 'Scale') AS int) AS Scale,
                   CAST(SQL_VARIANT_PROPERTY(@SQLVariantValue, 'TotalBytes') AS bigint) AS TotalBytes,
                   CAST(SQL_VARIANT_PROPERTY(@SQLVariantValue, 'Collation') AS sysname) AS Collation,
                   CAST(SQL_VARIANT_PROPERTY(@SQLVariantValue, 'MaxLength') AS int) AS MaximumLength);
GO

------------------------------------------------------------------------------------

SET ANSI_NULLS ON;
GO

CREATE FUNCTION SDU_Tools.VarbinaryToBase64
(
    @VarbinaryValueToConvert varbinary(max)
)
RETURNS varchar(max)
AS
BEGIN
-- Function:      Converts a varbinary value to base 64 encoding
-- Parameters:    @VarbinaryValueToConvert varbinary(max)
-- Action:        Converts a varbinary value to base 64 encoding
-- Return:        varchar(max)
-- Refer to this video: https://youtu.be/k6yHYdHn7NA
--
-- Test examples: 
/*

SELECT SDU_Tools.VarbinaryToBase64(0xAABBCCDDEEFF);

*/
    RETURN LTRIM(RTRIM(CAST('' as xml).value('xs:base64Binary(xs:hexBinary(sql:variable("@VarbinaryValueToConvert")))', 'varchar(max)')));
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.SecondsToDuration
(
    @NumberOfSeconds int
)
RETURNS varchar(8)
AS
BEGIN

-- Function:      Convert a number of seconds to a SQL Server duration string
-- Parameters:    @NumberOfSeconds int 
-- Action:        Converts a number of seconds to a SQL Server duration string (similar to programming identifiers)
--                The value must be less than 24 hours (between 0 and 86399) otherwise the return value is NULL
-- Return:        varchar(8)
-- Refer to this video: https://youtu.be/beANzSe1-jE
--
-- Test examples: 
/*

SELECT SDU_Tools.SecondsToDuration(910);   -- 15 minutes 10 seconds
SELECT SDU_Tools.SecondsToDuration(88000);   -- should return NULL

*/
    RETURN CASE WHEN @NumberOfSeconds BETWEEN 0 AND 86399 
                   THEN LEFT(CONVERT(varchar(20), DATEADD(second, @NumberOfSeconds, CAST(CAST(SYSDATETIME() AS date) AS datetime)), 14), 8)
                 END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.HexCharStringToInt 
(
    @HexadecimalCharacterString nvarchar(2)
)
RETURNS int
AS

-- Function:      Converts a hexadecimal character string to an integer
-- Parameters:    @@HexadecimalCharacterString - a character string to be converted to an integer
-- Action:        Converts a hexadecimal character string to an integer - must be a two character hex string
-- Return:        int
-- Refer to this video: https://youtu.be/2BMd9uYjHVQ
--
-- Test examples: 
/*

SELECT SDU_Tools.HexCharStringToInt(N'32');
SELECT SDU_Tools.HexCharStringToInt(N'2F');

*/
BEGIN
    RETURN CAST(CONVERT(varbinary, @HexadecimalCharacterString, 2) AS int);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.HexCharStringToChar
(
    @HexadecimalCharacterString nvarchar(2)
)
RETURNS nchar
AS

-- Function:      Converts a hexadecimal character string to a character
-- Parameters:    @@HexadecimalCharacterString - a character string to be converted to character eg: 5F becomes _
-- Action:        Converts a hexadecimal character string to a character - must be a two character hex string
-- Return:        nchar
-- Refer to this video: https://youtu.be/2BMd9uYjHVQ
--
-- Test examples: 
/*

SELECT SDU_Tools.HexCharStringToChar(N'41');
SELECT SDU_Tools.HexCharStringToChar(N'5F');

*/
BEGIN
    RETURN NCHAR(SDU_Tools.HexCharStringToInt(@HexadecimalCharacterString));
END;
GO

--==================================================================================
-- Scripting Utiltiies
--==================================================================================

CREATE FUNCTION SDU_Tools.FormatDataTypeName
( 
       @DataTypeName sysname,
       @Precision int,
       @Scale int,
       @MaximumLength int
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Converts data type components into an output string
-- Parameters:    @DataTypeName sysname - the name of the data type
--                @Precision int - the decimal or numeric precision
--                @Scale int - the scale for the value
--                @MaximumLength - the maximum length of string values
-- Action:        Converts data type, precision, scale, and maximum length
--                into the standard format used in scripts
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/Cn3jK3roWLg
-- Test examples: 
/*

SELECT SDU_Tools.FormatDataTypeName(N'decimal', 18, 2, NULL);
SELECT SDU_Tools.FormatDataTypeName(N'nvarchar', NULL, NULL, 12);
SELECT SDU_Tools.FormatDataTypeName(N'bigint', NULL, NULL, NULL);

*/
       RETURN LOWER(@DataTypeName) 
              + CASE WHEN LOWER(@DataTypeName) IN (N'decimal', N'numeric')
                  THEN N'(' + CAST(@Precision AS nvarchar(20)) + N', ' + CAST(@Scale AS nvarchar(20)) + N')'
                  WHEN LOWER(@DataTypeName) IN (N'varchar', N'nvarchar', N'char', N'nchar', N'binary', N'varbinary')
                  THEN N'(' + CASE WHEN @MaximumLength < 0 
                                   THEN N'max' 
                                   ELSE CAST(@MaximumLength AS nvarchar(20)) 
                              END + N')'
                  WHEN LOWER(@DataTypeName) IN (N'time', N'datetime2', N'datetimeoffset')
                  THEN N'(' + CAST(@Scale AS nvarchar(20)) + N')'
                  ELSE N''
             END;
END;
GO

------------------------------------------------------------------------------------

-- CREATE PROCEDURE SDU_Tools.ScriptDatabaseUsers (Not appropriate for Azure SQL DB

------------------------------------------------------------------------------------
GO

CREATE PROCEDURE SDU_Tools.ExecuteOrPrint
@StringToExecuteOrPrint nvarchar(max),
@PrintOnly bit = 1,
@NumberOfCrLfBeforeGO int = 0,
@IncludeGO bit = 0,
@NumberOfCrLfAfterGO int = 0,
@BatchSeparator nvarchar(20) = N'GO'
AS BEGIN

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
-- Refer to this video: https://youtu.be/cABGotl_yHY
--
-- Test examples: 
/*

DECLARE @SQL nvarchar(max) = N'SELECT ''Hello Greg'';';

EXEC SDU_Tools.ExecuteOrPrint @StringToExecuteOrPrint = @SQL,
                              @IncludeGO = 1,
                              @NumberOfCrLfAfterGO = 1;
SET @SQL = N'SELECT ''Another statement'';';

EXEC SDU_Tools.ExecuteOrPrint @StringToExecuteOrPrint = @SQL,
                              @IncludeGO = 1,
                              @NumberOfCrLfAfterGO = 1;

*/
    SET NOCOUNT ON;

    DECLARE @LineFeed nchar(1) = NCHAR(10);
    DECLARE @CarriageReturn nchar(1) = NCHAR(13);
    DECLARE @CRLF nchar(2) = @CarriageReturn + @LineFeed;
    
    DECLARE @RemainingString nvarchar(max) = REPLACE(SDU_Tools.TrimWhitespace(@StringToExecuteOrPrint), @LineFeed, N'');
    DECLARE @FullLine nvarchar(max);
    DECLARE @TrimmedLine nvarchar(max);
    DECLARE @StringToExecute nvarchar(max) = N'';
    DECLARE @NextLineEnd int;
    DECLARE @Counter int;

    WHILE LEN(@RemainingString) > 0
    BEGIN
        SET @NextLineEnd = CHARINDEX(@CarriageReturn, @RemainingString, 1);
        IF @NextLineEnd <> 0 -- more than one line left
        BEGIN
            SET @FullLine = RTRIM(SUBSTRING(@RemainingString, 1, @NextLineEnd - 1));
            PRINT @FullLine;
            SET @TrimmedLine = SDU_Tools.TrimWhitespace(@FullLine);
            IF @TrimmedLine = @BatchSeparator -- line just contains GO
            BEGIN
                SET @StringToExecute = SDU_Tools.TrimWhitespace(@StringToExecute);
                IF @StringToExecute <> N'' AND @PrintOnly = 0
                BEGIN
                    EXECUTE (@StringToExecute); -- Execute if non-blank
                END;
                SET @StringToExecute = N'';
            END ELSE BEGIN
                SET @StringToExecute += @CRLF + @FullLine;
            END;
            SET @RemainingString = RTRIM(SUBSTRING(@RemainingString, @NextLineEnd + 1, LEN(@RemainingString)));
        END ELSE BEGIN -- on the last line
            SET @FullLine = RTRIM(@RemainingString);
            PRINT @FullLine;
            SET @TrimmedLine = SDU_Tools.TrimWhitespace(@FullLine);
            IF @TrimmedLine <> @BatchSeparator -- not just a line with GO
            BEGIN
                SET @StringToExecute += @CRLF + @FullLine;
                SET @StringToExecute = SDU_Tools.TrimWhitespace(@StringToExecute);
                IF @StringToExecute <> N'' AND @PrintOnly = 0
                BEGIN
                    EXECUTE (@StringToExecute); -- Execute if non-blank
                END;
                SET @StringToExecute = N'';
            END;

            SET @RemainingString = N'';
        END;
    END;

    SET @Counter = 0;
    WHILE @Counter < @NumberOfCrLfBeforeGO
    BEGIN
        PRINT N' ';
        SET @Counter += 1;
    END;
    IF @IncludeGO <> 0 PRINT @BatchSeparator;

    SET @Counter = 0;
    WHILE @Counter < @NumberOfCrLfAfterGO
    BEGIN
        PRINT N' ';
        SET @Counter += 1;
    END;

END;
GO

------------------------------------------------------------------------------------

-- CREATE FUNCTION SDU_Tools.ScriptServerPermissions (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------

-- CREATE FUNCTION SDU_Tools.ScriptServerRoleMembers (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------

-- CREATE FUNCTION SDU_Tools.ScriptSQLLogins (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------

-- CREATE FUNCTION SDU_Tools.ScriptWindowsLogins (Not appropriate for Azure SQL DB)
GO

--==================================================================================
-- PerformanceTuning Utiltiies
--==================================================================================

CREATE FUNCTION SDU_Tools.DeExecuteSQLString
( 
    @InputSQL nvarchar(max),
    @EmbedParameters bit,
    @IncludeVariableDeclarations bit 
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Locates the command and reorganizes parameters from within an sp_executeSQL string
-- Parameters:    @InputSQL nvarchar(max)          -> Captured sp_executeSQL string
--                @EmbedParameters bit             -> If 1, parameters are re-embedded into the SQL
--                                                    (this is usually best for performance tuning)
--                @IncludeVariableDeclarations bit -> If not embedding parameters, should they be
--                                                    converted to variables (easier to work with 
--                                                    but not as good for performance tuning)
-- Action:        Assist with debugging and performance troubleshooting of sp_executeSQL commands. 
--                Takes a valid exec sp_executeSQL string (like captured in Profiler or Extended
--                Events) and extracts the embedded command from within it. Optionally, can 
--                extract the parameters and either embed them directly back into the code, or 
--                create them as variable declarations
-- Return:        nvarchar(max) output SQL
-- Test examples: 
/*

SELECT SDU_Tools.DeExecuteSQLString('blah', 0, 0); -- should return invalid input query
SELECT SDU_Tools.DeExecuteSQLString('exec sp_executeSQL N''some query goes here''', 0, 1);
SELECT SDU_Tools.DeExecuteSQLString('exec sp_executeSQL N''some query goes here with a parameter @range'',N''@range varchar(10)'',@range = N''hello''', 0, 1);

*/
    DECLARE @MaximumParametersPerQuery int = 1000;
    DECLARE @SQL nvarchar(max) = SDU_Tools.TrimWhitespace(@InputSQL);
    DECLARE @ReturnValue nvarchar(max) = N'';
    DECLARE @ErrorHasOccurred bit = 0;
    DECLARE @ParameterStart int;
    DECLARE @EqualsLocation int;
    DECLARE @SpaceLocation int;
    DECLARE @QuoteLocation int;
    DECLARE @FoundAllParameters bit = 0;
    DECLARE @ParameterDeclaration nvarchar(max);
    DECLARE @NumberOfParameters int = 0;
    DECLARE @NumberOfParameterDataTypesFound int = 0;
    DECLARE @LocatedParameterName nvarchar(max);
    DECLARE @LocatedParameterDataType nvarchar(max);
    DECLARE @MaximumParameterNameLength int;
    DECLARE @DebugErrorReason nvarchar(max) = N'';
    DECLARE @Counter int;
    DECLARE @LengthCounter int;
    DECLARE @Parameters TABLE ( ParameterNumber int,
                                ParameterName nvarchar(max),
                                ParameterValue nvarchar(max),
                                ParameterDataType nvarchar(max)
                              );

    -- Extract the trailing parameter list

    WHILE (@FoundAllParameters = 0) AND (@NumberOfParameters < @MaximumParametersPerQuery) AND (@ErrorHasOccurred = 0)
    BEGIN
        IF RIGHT(@SQL, 1) = N','
        BEGIN
            SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);
        END;
        SET @ParameterStart = SDU_Tools.LastParameterStartPosition(@SQL);
        IF @ParameterStart < 0
        BEGIN
            SET @FoundAllParameters = 1;
        END ELSE BEGIN
            SET @ParameterDeclaration = SDU_Tools.TrimWhitespace(SUBSTRING(@SQL, @ParameterStart, LEN(@SQL) - @ParameterStart + 1));
            SET @EqualsLocation = CHARINDEX(N'=', @ParameterDeclaration);
            IF @EqualsLocation < 1
            BEGIN
                SET @ErrorHasOccurred = 1;
                SET @DebugErrorReason += N'Equals not located in trailing parameter list processing, ';
            END ELSE BEGIN
                SET @NumberOfParameters += 1;
                INSERT @Parameters ( ParameterNumber, ParameterName, ParameterValue )
                VALUES ( @NumberOfParameters, 
                         SDU_Tools.TrimWhitespace(SUBSTRING(@ParameterDeclaration, 1, @EqualsLocation - 1)),
                         SDU_Tools.TrimWhitespace(SUBSTRING(@ParameterDeclaration, @EqualsLocation + 1, 
                                                      LEN(@ParameterDeclaration) - @EqualsLocation)));
                SET @SQL = LEFT(@SQL, @ParameterStart - 1);                                      
            END;
        END;
    END;

    -- Remove trailing quote which should be present

    IF @ErrorHasOccurred = 0 
    BEGIN
        IF RIGHT(@SQL, 1) <> N''''
        BEGIN
            SET @ErrorHasOccurred = 1;
            SET @DebugErrorReason += N'Trailing quote not located, ';
        END ELSE BEGIN
            SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);
        END;
    END;

    -- Next locate the data types

    IF @ErrorHasOccurred = 0
    BEGIN
        SET @FoundAllParameters = 0;
        WHILE @FoundAllParameters = 0 AND @ErrorHasOccurred = 0 AND @NumberOfParameterDataTypesFound < @NumberOfParameters 
        BEGIN
            IF RIGHT(@SQL, 1) = N','
                BEGIN
                SET @SQL = LEFT(@SQL, LEN(@SQL) - 1);
            END;
            SET @ParameterStart = SDU_Tools.LastParameterStartPosition(@SQL);
            IF @ParameterStart < 0
            BEGIN
                SET @FoundAllParameters = 1;
            END ELSE BEGIN
                SET @ParameterDeclaration = SDU_Tools.TrimWhitespace(SUBSTRING(@SQL, @ParameterStart, LEN(@SQL) - @ParameterStart + 1));
                SET @ParameterDeclaration = REPLACE(REPLACE(@ParameterDeclaration, N',', N''), N'''', N'');
                SET @SpaceLocation = CHARINDEX(N' ', @ParameterDeclaration);
                IF @SpaceLocation <= 0
                BEGIN
                    SET @ErrorHasOccurred = 1;
                    SET @DebugErrorReason += N'Space not located in data type search, ';
                END ELSE BEGIN
                    SET @LocatedParameterName = SDU_Tools.TrimWhitespace(LEFT(@ParameterDeclaration, @SpaceLocation - 1));
                    SET @LocatedParameterDataType = SDU_Tools.TrimWhitespace(SUBSTRING(@ParameterDeclaration, 
                                                                                 @SpaceLocation + 1, 
                                                                                 LEN(@ParameterDeclaration) - @SpaceLocation + 1));
                    UPDATE @Parameters 
                        SET ParameterDataType = @LocatedParameterDataType 
                        WHERE ParameterName = @LocatedParameterName;
                    SET @SQL = SDU_Tools.TrimWhitespace(LEFT(@SQL, @ParameterStart - 1));
                    SET @NumberOfParameterDataTypesFound += 1;
                END;
            END;
        END;

        IF EXISTS(SELECT 1 FROM @Parameters WHERE ParameterDataType IS NULL)
        BEGIN
            SET @ErrorHasOccurred = 1;
            SET @DebugErrorReason += N'Not all parameter data types located, ';
        END;
    END;

    -- Remove beginning of query, then tidy up the tail end 
    -- then replace double quotes in queries with single

    IF @ErrorHasOccurred = 0
    BEGIN
        SET @QuoteLocation = CHARINDEX(N'''', @SQL);
        IF @QuoteLocation <= 0
        BEGIN
            SET @ErrorHasOccurred = 1;
            SET @DebugErrorReason += N'No leading quote found, ';
        END ELSE BEGIN
            SET @SQL = SUBSTRING(@SQL, @QuoteLocation + 1, LEN(@SQL) - @QuoteLocation);
            IF RIGHT(@SQL, 2) = N'N'''
            BEGIN
                SET @SQL = SDU_Tools.TrimWhitespace(LEFT(@SQL, LEN(@SQL) - 2));
            END;
            IF RIGHT(@SQL, 1) = ','
            BEGIN
                SET @SQL = SDU_Tools.TrimWhitespace(LEFT(@SQL, LEN(@SQL) - 1));
            END;
            IF RIGHT(@SQL, 1) = ''''
            BEGIN
                SET @SQL = SDU_Tools.TrimWhitespace(LEFT(@SQL, LEN(@SQL) - 1));
            END;
        END
        SET @SQL = SDU_Tools.TrimWhitespace(REPLACE(@SQL, '''''',''''));
    END;

    IF @ErrorHasOccurred = 0
    BEGIN
        IF @EmbedParameters = 0
        BEGIN
            IF @IncludeVariableDeclarations = 1
            BEGIN
                SET @Counter = 1;
                WHILE @Counter <= @NumberOfParameters 
                BEGIN
                    SET @ReturnValue = @ReturnValue 
                                     + N'DECLARE '
                                     + (SELECT ParameterName FROM @Parameters WHERE ParameterNumber = @Counter)
                                     + N' '
                                     + (SELECT ParameterDataType FROM @Parameters WHERE ParameterNumber = @Counter)
                                     + N' = '
                                     + (SELECT ParameterValue FROM @Parameters WHERE ParameterNumber = @Counter)
                                     + N';'
                                     + NCHAR(13) + NCHAR(10);
                    SET @Counter += 1;
                END;
                SET @ReturnValue = SDU_Tools.TrimWhitespace(@ReturnValue 
                                                                + ' ' 
                                                                + NCHAR(13) + NCHAR(10)
                                                                + @SQL);
            END ELSE BEGIN
                SET @ReturnValue = SDU_Tools.TrimWhitespace(@SQL);
            END;
        END ELSE BEGIN
            -- Need to substitute parameter names but must do this in descending length order
            SET @MaximumParameterNameLength = (SELECT MAX(LEN(ParameterName)) FROM @Parameters);
            SET @LengthCounter = @MaximumParameterNameLength;
            WHILE @LengthCounter > 0
            BEGIN
                SET @Counter = @NumberOfParameters;
                WHILE @Counter >= 0
                BEGIN
                    IF EXISTS(SELECT 1 FROM @Parameters WHERE ParameterNumber = @Counter 
                                                        AND LEN(ParameterName) = @LengthCounter)
                    BEGIN
                        SET @SQL = REPLACE(@SQL,
                                           (SELECT ParameterName FROM @Parameters WHERE ParameterNumber = @Counter),
                                           (SELECt ParameterValue FROM @Parameters WHERE ParameterNumber = @Counter));
                    END;
                    SET @Counter -= 1;
                END;
                SET @LengthCounter -= 1;
            END;
            SET @ReturnValue = SDU_Tools.TrimWhitespace(@SQL);
        END;
    END ELSE BEGIN
        SET @ReturnValue = N'Invalid input query';
    END;

    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION [SDU_Tools].[ExtractSQLTemplate]
(
    @InputCommand nvarchar(max),
    @MaximumReturnLength int
)
RETURNS nvarchar(max)
AS 
BEGIN

-- Function:      Extracts a query template from a SQL command string
-- Parameters:    @InputCommand nvarchar(max)      -> SQL Command (likely captured from Profiler 
--                                                    or Extended Events)
--                @MaximumReturnLength int         -> Limits the number of characters returned
-- Action:        Normalizes a SQL Server command, mostly for helping with performance tuning 
--                work. It extracts the underlying template of the command. If the command 
--                includes an exec sp_executeSQL statement, or an sp_prepexec statement,
--                it tries to undo those statements as well. 
--                It will not be able to do so if it isn't the last statement 
--                in the batch being processed. Works even on invalid SQL syntax
-- Return:        nvarchar(max) output templated SQL
-- Refer to this video: https://youtu.be/yX5q00m_uCA
--
-- Test examples: 
/*

SELECT SDU_Tools.ExtractSQLTemplate('select * from customers where customerid = 12 and customername = ''fred'' order by customerid;', 4000);
SELECT SDU_Tools.ExtractSQLTemplate('select * from customers where customerid = 12', 4000);
SELECT SDU_Tools.ExtractSQLTemplate('select (2+2);', 4000);
SELECT SDU_Tools.ExtractSQLTemplate('select * from customers where sid = 0x12AEBCDEF2342AE2', 4000);
SELECT SDU_Tools.ExtractSQLTemplate(N'Declare @P1 int;  EXEC sp_prepexec @P1 output,   N''@P1 nvarchar(128), @P2 nvarchar(100)'',  N''SELECT database_id, name FROM sys.databases  WHERE name=@P1 AND state_desc = @P2'', @P1 = ''tempdb'', @P2 = ''ONLINE'';', 4000);

*/
    DECLARE @ReturnValue nvarchar(max) = N'';
    DECLARE @DecimalSeparator nvarchar(1) = N'.';
    DECLARE @StringToken nvarchar(1) = N'$';
    DECLARE @NumberToken nvarchar(1) = N'#';
    DECLARE @BinaryToken nvarchar(1) = N'B';

    DECLARE @CurrentPosition int = 1;
    DECLARE @CurrentCharacter nvarchar(1) = N'';
    DECLARE @PreviousCharacter nvarchar(1) = N'';
    DECLARE @LastTwoCharacters nvarchar(2) = N'';
    DECLARE @NextCharacter nvarchar(1) = N'';
    DECLARE @InAString bit = 0;
    DECLARE @InANumber bit = 0;
    DECLARE @InABinaryNumber bit = 0;

    DECLARE @InputSQL varchar(max) = SDU_Tools.TrimWhitespace(@InputCommand);
    DECLARE @LowerStatement varchar(max) = LOWER(@InputSQL);
    DECLARE @InputLength int = LEN(@InputSQL);
    DECLARE @SPExecuteSQLLocation int = 0;
    DECLARE @SPExecuteSQL varchar(max) = N'';
    DECLARE @IsValidSPExecuteSQL bit = 0;
    
    DECLARE @IsValidSPPrepExec bit = 0;
    DECLARE @SPPrepExecLocation int = 0;
    DECLARE @HandleCommaLocation int;
    DECLARE @ParameterCommaLocation int;
    DECLARE @OpeningQuoteLocation int;
    DECLARE @ClosingQuoteLocation int;
    DECLARE @CharacterCounter int;
        
    SET @SPExecuteSQLLocation = CHARINDEX('sp_executeSQL', @LowerStatement);
    SET @SPPrepExecLocation = CHARINDEX(N'sp_prepexec', @LowerStatement);

    IF @SPExecuteSQLLocation > 0 
    BEGIN
        SET @SPExecuteSQL = SUBSTRING(@InputSQL, @SPExecuteSQLLocation, @InputLength - @SPExecuteSQLLocation + 1);
        SET @SPExecuteSQL = SDU_Tools.DeExecuteSQLString(@SPExecuteSQL, 0, 0);
        IF @SPExecuteSQL <> N'Invalid input query'
        BEGIN
           SET @IsValidSPExecuteSQL = 1;
           SET @ReturnValue = @SPExecuteSQL;
        END;
    END;

    IF @IsValidSPExecuteSQL = 0 AND @SPPrepExecLocation > 0
    BEGIN
        SET @HandleCommaLocation = CHARINDEX(N',', @LowerStatement, @SPPrepExecLocation);
        SET @InAString = 0;
 
        -- search for the next comma (ignoring commas inside quotes)
        SET @CharacterCounter = @HandleCommaLocation + 1;
        
        WHILE (@CharacterCounter <= @InputLength) AND (@ParameterCommaLocation IS NULL)
        BEGIN
            SET @NextCharacter = SUBSTRING(@LowerStatement, @CharacterCounter, 1);
            IF @NextCharacter = N'''' 
            BEGIN
                IF @InAString <> 0 
                BEGIN
                    SET @InAString = 0;
                END ELSE BEGIN
                    SET @InAString = 1;
                END;
            END ELSE BEGIN -- not a quote
                IF (@InAString = 0) AND (@NextCharacter = N',')
                BEGIN
                    SET @ParameterCommaLocation = @CharacterCounter;
                END;
            END;
            SET @CharacterCounter = @CharacterCounter + 1;
        END;
 
        -- find opening quote after parameter comma
        
        SET @OpeningQuoteLocation = CHARINDEX(N'''', @LowerStatement, @ParameterCommaLocation);
        
        -- find closing quote location
        
        SET @CharacterCounter = @OpeningQuoteLocation + 1;
        
        WHILE (@CharacterCounter <= @InputLength) AND (@ClosingQuoteLocation IS NULL)
        BEGIN
            SET @NextCharacter = SUBSTRING(@LowerStatement, @CharacterCounter, 1);
            IF @NextCharacter = N'''' 
            BEGIN
                IF @CharacterCounter = @InputLength -- last character of statement
                BEGIN
                    SET @ClosingQuoteLocation = @CharacterCounter;
                END ELSE BEGIN -- more characters after
                    IF SUBSTRING(@LowerStatement, @CharacterCounter + 1, 1) = N'''' -- this is just an embedded quote
                    BEGIN
                        SET @CharacterCounter = @CharacterCounter + 1; -- skip ahead
                    END ELSE BEGIN
                        SET @ClosingQuoteLocation = @CharacterCounter; -- we've found what we're looking for
                    END;
                END;
            END;
            SET @CharacterCounter = @CharacterCounter + 1;
        END;
        
        IF @ClosingQuoteLocation > @OpeningQuoteLocation 
            AND @OpeningQuoteLocation BETWEEN 1 AND @InputLength 
            AND @ClosingQuoteLocation BETWEEN 1 AND @InputLength 
        BEGIN
           SET @IsValidSPPrepExec = 1;
           SET @ReturnValue = SUBSTRING(@InputSQL, @OpeningQuoteLocation + 1, @ClosingQuoteLocation - @OpeningQuoteLocation - 1);
        END;
    END;
 
    IF @IsValidSPExecuteSQL = 0 AND @IsValidSPPrepExec = 0
    BEGIN -- if not an sp_executeSQL or sp_prepexec command that could be processed
        WHILE @CurrentPosition <= @InputLength 
        BEGIN
            SET @CurrentCharacter = SUBSTRING(@InputCommand, @CurrentPosition, 1);
            IF @CurrentPosition > 1 SET @PreviousCharacter = SUBSTRING(@InputCommand, @CurrentPosition - 1, 1);
            IF @CurrentPosition > 2 SET @LastTwoCharacters = SUBSTRING(@InputCommand, @CurrentPosition - 2, 2);
            IF @CurrentPosition < @InputLength SET @NextCharacter = SUBSTRING(@InputCommand, @CurrentPosition + 1, 1) ELSE SET @NextCharacter = N'';

            IF @InAString = 1
            BEGIN
                IF @CurrentCharacter = N'''' 
                BEGIN -- processing a single quote = end of string or double quote
                    IF @CurrentPosition < @InputLength AND @NextCharacter = N'''' 
                    BEGIN -- double quote so skip both chars
                        SET @CurrentPosition += 1;
                    END ELSE BEGIN -- end of a string
                        SET @ReturnValue = @ReturnValue + @StringToken;
                        SET @InAString = 0;
                    END;
                END;
             END ELSE BEGIN -- of if not in a string
                IF @CurrentCharacter = N'''' 
                BEGIN
                    SET @InAString = 1;
                END ELSE BEGIN
                    IF @InANumber = 1
                    BEGIN -- we are in a number
                        IF @CurrentCharacter NOT BETWEEN N'0' AND N'9' AND @CurrentCharacter <> @DecimalSeparator 
                        BEGIN -- no longer in a number
                            SET @InANumber = 0;
                            SET @ReturnValue = @ReturnValue + @NumberToken + @CurrentCharacter;
                        END;
                    END ELSE BEGIN -- of if not in a number
                        IF @InABinaryNumber = 1
                        BEGIN
                            IF @CurrentCharacter NOT BETWEEN N'0' AND N'9' AND @CurrentCharacter NOT BETWEEN N'A' AND N'F'
                            BEGIN -- no longer in a binary number
                                SET @InABinaryNumber = 0;
                                  SET @ReturnValue = @ReturnValue + @BinaryToken + @CurrentCharacter;
                            END;
                        END ELSE BEGIN -- of if not in a number or a binary number
                            IF @LastTwoCharacters = N'0x' AND (@CurrentCharacter BETWEEN N'0' AND N'9'
                                                               OR @CurrentCharacter BETWEEN N'A' AND N'F')
                            BEGIN
                                SET @InABinaryNumber = 1;
                            END ELSE BEGIN -- not the start of a binary number
                                IF @CurrentCharacter BETWEEN N'0' AND N'9' OR @CurrentCharacter = @DecimalSeparator
                                BEGIN -- start of a number if previous character is space, minus, plus, bracket, separator or equals
                                    IF @PreviousCharacter IN (N' ', N'-', N'+', N'(', N'=', @DecimalSeparator)
                                        AND NOT (@CurrentCharacter = N'0' AND @NextCharacter = N'x')
                                    BEGIN
                                        SET @InANumber = 1;
                                    END ELSE BEGIN -- possibly just another part of an identifier
                                        SET @ReturnValue = @ReturnValue + @CurrentCharacter;
                                    END;
                                END ELSE BEGIN -- any old character
                                       SET @ReturnValue = @ReturnValue + @CurrentCharacter;
                                END;
                            END;
                        END;
                    END;
                END;
            END;
            SET @CurrentPosition += 1;
        END;
    END;

    IF @InANumber = 1 
    BEGIN -- might be still in the middle of a number
        SET @ReturnValue = @ReturnValue + @NumberToken;
    END;

    IF @InABinaryNumber = 1
    BEGIN -- might be still in the middle of a binary number
        SET @ReturnValue = @ReturnValue + @BinaryToken;
    END;

    RETURN LEFT(@ReturnValue, @MaximumReturnLength);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.LastParameterStartPosition
( 
    @StringToTest nvarchar(max) 
)
RETURNS int
AS
BEGIN

-- Function:      Locates the starting position of the last parameter in an sp_executeSQL string
-- Parameters:    @StringToTest nvarchar(max)
-- Action:        Starts at the end of the string and finds the last location where
--                a parameter is defined, based on @ characters.
-- Return:        int location of where the last parameter in the command starts
-- Test examples: 
/*

DECLARE @TestString nvarchar(max) 
    = 'exec sp_executeSQL N''SELECT something FROM somewhere
                             WHERE somethingelse = @range
                                AND somedate = @date 
                             AND someteam = @team'''
                             + ',N''@range nvarchar(5),@date datetime,@team nvarchar(27)'''
                             + ',@range=N''month'',@date=''2014-10-01 00:00:00'',@team=N''Test team''';

SELECT SDU_Tools.LastParameterStartPosition(@TestString); -- should be 281

*/
    DECLARE @PositionToReturn int = -1;
    DECLARE @Counter int = LEN(@StringToTest);
    DECLARE @NextCharacter nvarchar(1);
    DECLARE @InAString bit = 0;

    WHILE (@Counter > 0) AND (@PositionToReturn = -1)
    BEGIN
        SET @NextCharacter = SUBSTRING(@StringToTest, @Counter, 1);
        IF @NextCharacter = N'''' 
        BEGIN
            IF @InAString = 1 
            BEGIN
                SET @InAString = 0;
            END ELSE BEGIN
                SET @InAString = 1;
            END;
        END ELSE BEGIN
            IF @NextCharacter = N'@' AND @InAString = 0
            BEGIN
                IF SDU_Tools.PreviousNonWhitespaceCharacter(@StringToTest, @Counter) <> N'='
                BEGIN
                    SET @PositionToReturn = @Counter;
                END;
            END;
        END;
        SET @Counter -= 1;
    END;

    RETURN @PositionToReturn;
END;
GO

------------------------------------------------------------------------------------

-- CREATE PROCEDURE SDU_Tools.CapturePerformanceTuningTrace (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------

-- CREATE PROCEDURE SDU_Tools.LoadPerformanceTuningTrace  (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------

-- CREATE PROCEDURE SDU_Tools.AnalyzePerformanceTuningTrace  (Not appropriate for Azure SQL DB)

--==================================================================================
-- Database Comparison Utiltiies
--==================================================================================

-- CREATE PROCEDURE SDU_Tools.GetDBSchemaCoreComparison  (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------
GO

CREATE PROCEDURE SDU_Tools.GetTableSchemaComparisonInCurrentDatabase
@Table1SchemaName sysname,
@Table1TableName sysname,
@Table2SchemaName sysname,
@Table2TableName sysname,
@IgnoreColumnID bit,
@IgnoreFillFactor bit
AS
BEGIN

-- Function:      Check the schema of two tables in the current database, looking for basic differences
-- Parameters:    @Table1SchemaName sysname     -> schema name for the first table
--                @Table1TableName sysname      -> table name for the first table
--                @Table2SchemaName sysname     -> schema name for the second table
--                @Table2TableName sysname      -> table name for the second table
--                @IgnoreColumnID bit           -> set to 1 if tables with the same columns but in different order
--                                                 are considered equivalent, otherwise set to 0
--                @IgnoreFillFactor bit         -> set to 1 if index fillfactors are to be ignored, otherwise
--                                                 set to 0
-- Action:        Performs a comparison of the schema of two tables
-- Return:        Rowset describing differences
-- Refer to video: https://youtu.be/8Q8dsxBU6XQ
--
-- Test examples: 
/*

-- EXEC SDU_Tools.GetTableSchemaComparisonInCurrentDatabase N'dbo', N'TABLE1', N'dbo', N'TABLE2', 1, 1;

*/
  DECLARE @SQL nvarchar(max);
  DECLARE @SelectColumnsQuery nvarchar(max)
    = N'SELECT s.[name] AS SchemaName,
               t.[name] AS TableName,
               c.column_id AS ColumnID,
               c.[name] AS ColumnName,
               CASE WHEN typ.[name] IN (''char'', ''nchar'', ''varchar'', ''nvarchar'', ''binary'', ''varbinary'') 
                    THEN typ.[name] + ''('' + CASE WHEN c.max_length < 0 THEN ''max'' ELSE CAST(CASE WHEN typ.[name] IN (''nchar'', ''nvarchar'')
                                                                                                     THEN c.max_length / 2
                                                                                                     ELSE c.max_length 
                                                                                                END AS varchar(10)) END + '')''
                    WHEN typ.[name] IN (''decimal'',''numeric'') 
                    THEN typ.[name] + ''('' + CAST(c.precision AS varchar(10)) + '','' + CAST(c.scale AS varchar(10)) + '')''
                    ELSE typ.[name] 
               END AS DataType
        FROM sys.tables AS t
        INNER JOIN sys.schemas AS s
        ON t.[schema_id] = s.[schema_id]
        INNER JOIN sys.columns AS c
        ON t.[object_id] = c.[object_id]
        INNER JOIN sys.[types] AS typ
        ON c.system_type_id = typ.system_type_id 
        AND c.user_type_id = typ.user_type_id
        WHERE t.is_ms_shipped = 0';

  DECLARE @SelectIndexesQuery nvarchar(max)
    = N'SELECT s.[name] AS SchemaName,
               t.[name] AS TableName,
               i.[name] AS IndexName,
               i.[type_desc] AS IndexType,
               i.is_primary_key AS IsPrimaryKey,
               i.is_unique AS IsUnique,
               i.is_unique_constraint As IsUniqueConstraint,
               i.is_disabled AS IsDisabled,
               i.fill_factor AS [FillFactor],
               i.ignore_dup_key AS IsIgnoreDupKey,
               i.allow_row_locks AS AllowsRowLocks,
               i.allow_page_locks AS AllowsPageLocks,
               i.has_filter AS IsFiltered,
               COALESCE(i.filter_definition,N'''') AS FilterDefinition
        FROM sys.indexes AS i
        INNER JOIN sys.tables AS t
        ON i.[object_id] = t.[object_id] 
        INNER JOIN sys.schemas AS s
        ON t.[schema_id] = s.[schema_id] 
        WHERE t.is_ms_shipped = 0
        AND i.index_id > 0
        AND i.is_hypothetical = 0';
  
  DECLARE @SelectIndexColumnsQuery nvarchar(max)
    = N'SELECT s.[name] AS SchemaName,
               t.[name] AS TableName,
               i.[name] AS IndexName,
               ic.index_column_id AS IndexColumnID,
               c.[name] AS ColumnName,
               ic.is_included_column AS IsIncludedColumn
        FROM sys.indexes AS i
        INNER JOIN sys.index_columns AS ic 
        ON i.[object_id] = ic.[object_id]
        AND i.index_id = ic.index_id 
        INNER JOIN sys.columns AS c
        ON ic.[object_id] = c.[object_id] 
        AND ic.column_id = c.column_id 
        INNER JOIN sys.tables AS t
        ON i.[object_id] = t.[object_id] 
        INNER JOIN sys.schemas AS s
        ON t.[schema_id] = s.[schema_id] 
        WHERE t.is_ms_shipped = 0
        AND i.index_id > 0';

  DECLARE @Table1WherePredicate nvarchar(max)
    = ' AND s.[name] = ''' + @Table1SchemaName 
      + ''' AND t.[name] = ''' + @Table1TableName 
      + '''';
  
  DECLARE @Table2WherePredicate nvarchar(max)
    = ' AND s.[name] = ''' + @Table2SchemaName 
      + ''' AND t.[name] = ''' + @Table2TableName 
      + '''';
  
  DECLARE @TableSchemas TABLE
  ( 
      TableSchemaID int IDENTITY(1,1) PRIMARY KEY,
      SchemaName sysname NOT NULL,
      TableName sysname NOT NULL,
      ColumnID int NOT NULL,
      ColumnName sysname NOT NULL,
      Datatype varchar(50) NOT NULL
  );
  
  DECLARE @IndexSchemas TABLE
  ( 
      IndexSchemaID int IDENTITY(1,1) PRIMARY KEY,
      SchemaName sysname NOT NULL,
      TableName sysname NOT NULL,
      IndexName sysname NOT NULL,
      IndexType nvarchar(60) NOT NULL,
      IsPrimaryKey bit NOT NULL,
      IsUnique bit NOT NULL,
      IsUniqueConstraint bit NOT NULL,
      IsDisabled bit NOT NULL,
      FillFactorInUse int NOT NULL,
      IsIgnoreDupKey bit NOT NULL,
      AllowsRowLocks bit NOT NULL,
      AllowsPageLocks bit NOT NULL,
      IsFiltered bit NOT NULL,
      FilterDefinition nvarchar(max) NOT NULL
  );
  
  DECLARE @IndexColumnSchemas TABLE
  ( 
      IndexColumnSchemaID int IDENTITY(1,1) PRIMARY KEY,
      SchemaName sysname NOT NULL,
      TableName sysname NOT NULL,
      IndexName sysname NOT NULL,
      IndexColumnID int NOT NULL,
      ColumnName sysname NOT NULL,
      IsIncludedColumn bit NOT NULL
  );
  
  SET @SQL = @SelectColumnsQuery + @Table1WherePredicate;
  INSERT @TableSchemas 
  EXEC (@SQL);
  
  SET @SQL = @SelectColumnsQuery + @Table2WherePredicate;
  INSERT @TableSchemas 
  EXEC (@SQL);
  
  SET @SQL = @SelectIndexesQuery + @Table1WherePredicate;
  INSERT @IndexSchemas 
  EXEC (@SQL);
  
  SET @SQL = @SelectIndexesQuery + @Table2WherePredicate;
  INSERT @IndexSchemas 
  EXEC (@SQL);
  
  SET @SQL = @SelectIndexColumnsQuery + @Table1WherePredicate;
  INSERT @IndexColumnSchemas 
  EXEC (@SQL);
  
  SET @SQL = @SelectIndexColumnsQuery + @Table2WherePredicate;
  INSERT @IndexColumnSchemas 
  EXEC (@SQL);
  
  WITH Table1TableStructures
  AS
  ( SELECT *
    FROM @TableSchemas 
    WHERE SchemaName = @Table1SchemaName 
    AND TableName = @Table1TableName 
  ),
  Table2TableStructures 
  AS
  ( SELECT *
    FROM @TableSchemas 
    WHERE SchemaName = @Table2SchemaName 
    AND TableName = @Table2TableName 
  ),
  Table1IndexSchemas
  AS
  ( SELECT *
    FROM @IndexSchemas 
    WHERE SchemaName = @Table1SchemaName 
    AND TableName = @Table1TableName   
  ),
  Table2IndexSchemas
  AS
  ( SELECT *
    FROM @IndexSchemas 
    WHERE SchemaName = @Table2SchemaName 
    AND TableName = @Table2TableName 
  ),
  Table1IndexColumnSchemas
  AS
  ( SELECT *
    FROM @IndexColumnSchemas 
    WHERE SchemaName = @Table1SchemaName 
    AND TableName = @Table1TableName   
  ),
  Table2IndexColumnSchemas
  AS
  ( SELECT * 
    FROM @IndexColumnSchemas 
    WHERE SchemaName = @Table2SchemaName 
    AND TableName = @Table2TableName 
  ),
  Table1OnlyIndexes
  AS
  ( SELECT DISTINCT ics1.SchemaName,
                    ics1.TableName,
                    ics1.IndexName
    FROM @IndexColumnSchemas AS ics1
    WHERE NOT EXISTS (SELECT 1
                      FROM @IndexColumnSchemas AS ics2
                      WHERE ics2.SchemaName = ics1.SchemaName 
                      AND ics2.TableName = ics1.TableName 
                      AND ics2.IndexName = ics1.IndexName)
  ),
  Table2OnlyIndexes
  AS
  ( SELECT DISTINCT ics2.SchemaName,
                    ics2.TableName,
                    ics2.IndexName
    FROM @IndexColumnSchemas AS ics2
    WHERE NOT EXISTS (SELECT 1
                      FROM @IndexColumnSchemas AS ics1
                      WHERE ics1.SchemaName = ics2.SchemaName 
                      AND ics1.TableName = ics2.TableName 
                      AND ics1.IndexName = ics2.IndexName)
  ),
  CommonIndexes
  AS
  ( SELECT DISTINCT @Table1SchemaName AS Table1SchemaName,
                    @Table1TableName AS Table1TableName,
                    @Table2SchemaName AS Table2SchemaName,
                    @Table2TableName AS Table2TableName,
                    ics1.IndexName
    FROM @IndexColumnSchemas AS ics1
    INNER JOIN @IndexColumnSchemas AS ics2
    ON ics2.IndexName = ics1.IndexName
    WHERE ics1.SchemaName = @Table1SchemaName 
    AND ics1.TableName = @Table1TableName 
    AND ics2.SchemaName = @Table2SchemaName
    AND ics2.TableName = @Table2TableName 
  )
  SELECT 10 AS IssueCategory,
         CAST(N'TABLE' AS nvarchar(20)) AS IssueObject,
         CAST(N'TABLE1 ONLY' AS nvarchar(40)) AS IssueType,
         @Table1SchemaName AS Table1SchemaName,
         @Table1TableName AS Table1TableName,
         CAST(NULL AS sysname) AS Table2SchemaName,
         CAST(NULL AS sysname) AS Table2TableName,
         CAST(NULL AS sysname) AS IndexName,
         CAST(NULL AS sysname) AS ColumnName,
         CAST(NULL AS int) AS Table1ColumnID,
         CAST(NULL AS int) AS Table2ColumnID,
         CAST(NULL AS varchar(50)) AS Table1Datatype,
         CAST(NULL AS varchar(50)) AS Table2Datatype
  WHERE EXISTS (SELECT 1 
                FROM @TableSchemas
                WHERE SchemaName = @Table1SchemaName 
                AND TableName = @Table1TableName)
  AND NOT EXISTS (SELECT 1 
                  FROM @TableSchemas
                  WHERE SchemaName = @Table2SchemaName 
                  AND TableName = @Table2TableName)
  UNION ALL
  SELECT 20 AS IssueCategory,
         N'TABLE', N'TABLE2 ONLY',
         NULL,
         NULL,
         @Table2SchemaName,
         @Table2TableName,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL
  WHERE EXISTS (SELECT 1 
                FROM @TableSchemas
                WHERE SchemaName = @Table2SchemaName 
                AND TableName = @Table2TableName)
  AND NOT EXISTS (SELECT 1 
                  FROM @TableSchemas
                  WHERE SchemaName = @Table1SchemaName 
                  AND TableName = @Table1TableName)
  UNION ALL
  SELECT 30, N'INDEX', N'TABLE1 ONLY',
         db1oi.SchemaName,
         db1oi.TableName,
         NULL,
         NULL,
         db1oi.IndexName,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL
  FROM Table1OnlyIndexes AS db1oi
  UNION ALL
  SELECT 40, N'INDEX', N'TABLE2 ONLY',
         NULL,
         NULL,
         db2oi.SchemaName,
         db2oi.TableName,
         db2oi.IndexName,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL
  FROM Table2OnlyIndexes AS db2oi
  UNION ALL
  SELECT 50, N'COLUMN', N'TABLE1 ONLY',
         d1ts.SchemaName,
         d1ts.TableName,
         NULL,
         NULL,
         NULL,
         d1ts.ColumnName,
         d1ts.ColumnID,
         NULL,
         d1ts.Datatype,
         NULL
  FROM Table1TableStructures AS d1ts
  WHERE NOT EXISTS (SELECT 1 
                    FROM Table2TableStructures AS d2ts
                    WHERE d1ts.SchemaName = d2ts.SchemaName 
                    AND d1ts.TableName = d2ts.TableName 
                    AND d1ts.ColumnName = d2ts.ColumnName)
  UNION ALL
  SELECT 60, N'COLUMN', N'TABLE2 ONLY',
         NULL,
         NULL,
         d2ts.SchemaName,
         d2ts.TableName,
         NULL,
         d2ts.ColumnName,
         NULL,
         d2ts.ColumnID,
         NULL,
         d2ts.Datatype 
  FROM Table2TableStructures AS d2ts
  WHERE NOT EXISTS (SELECT 1 
                    FROM Table1TableStructures AS d1ts
                    WHERE d2ts.SchemaName = d1ts.SchemaName 
                    AND d2ts.TableName = d1ts.TableName 
                    AND d2ts.ColumnName = d1ts.ColumnName)
  UNION ALL
  SELECT 70, N'COLUMN', N'TYPE MISMATCH',
         d1ts.SchemaName,
         d1ts.TableName,
         d2ts.SchemaName,
         d2ts.TableName,
         NULL,
         d1ts.ColumnName,
         d1ts.ColumnID,
         d2ts.ColumnID,
         d1ts.Datatype,
         d2ts.Datatype 
  FROM Table1TableStructures AS d1ts
  INNER JOIN Table2TableStructures AS d2ts
  ON d1ts.SchemaName = d2ts.SchemaName 
  AND d1ts.TableName = d2ts.TableName 
  AND d1ts.ColumnName = d2ts.ColumnName
  WHERE d1ts.Datatype <> d2ts.DataType 
  UNION ALL
  SELECT 80, N'COLUMN', N'COLUMNID MISMATCH',
         d1ts.SchemaName,
         d1ts.TableName,
         d2ts.SchemaName,
         d2ts.TableName,
         NULL,
         d1ts.ColumnName,
         d1ts.ColumnID,
         d2ts.ColumnID,
         d1ts.Datatype,
         d2ts.Datatype 
  FROM Table1TableStructures AS d1ts
  INNER JOIN Table2TableStructures AS d2ts
  ON d1ts.SchemaName = d2ts.SchemaName 
  AND d1ts.TableName = d2ts.TableName 
  AND d1ts.ColumnName = d2ts.ColumnName
  WHERE d1ts.ColumnID <> d2ts.ColumnID
  AND @IgnoreColumnID = 0
  UNION ALL
  SELECT 90, N'INDEX', N'DIFFERENT CONFIGURATION',
         ci.Table1SchemaName,
         ci.Table1TableName,
         ci.Table2SchemaName,
         ci.Table2TableName,
         ci.IndexName,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL
  FROM CommonIndexes AS ci
  WHERE EXISTS (SELECT IndexType,
                       IsPrimaryKey,
                       IsUnique,
                       IsUniqueConstraint,
                       IsDisabled,
                       CASE WHEN @IgnoreFillFactor <> 0 THEN 0 ELSE FillFactorInUse END,
                       IsIgnoreDupKey,
                       AllowsRowLocks,
                       AllowsPageLocks,
                       IsFiltered,
                       FilterDefinition
                FROM Table1IndexSchemas
                WHERE SchemaName = ci.Table1SchemaName 
                AND TableName = ci.Table1TableName 
                AND IndexName = ci.IndexName
                EXCEPT
                SELECT IndexType,
                       IsPrimaryKey,
                       IsUnique,
                       IsUniqueConstraint,
                       IsDisabled,
                       CASE WHEN @IgnoreFillFactor <> 0 THEN 0 ELSE FillFactorInUse END,
                       IsIgnoreDupKey,
                       AllowsRowLocks,
                       AllowsPageLocks,
                       IsFiltered,
                       FilterDefinition
                FROM Table2IndexSchemas 
                WHERE SchemaName = ci.Table2SchemaName 
                AND TableName = ci.Table2TableName 
                AND IndexName = ci.IndexName)
  UNION ALL
  SELECT 100, N'INDEX', N'DIFFERENT COLUMNS',
         ci.Table1SchemaName,
         ci.Table1TableName,
         ci.Table2SchemaName,
         ci.Table2TableName,
         ci.IndexName,
         NULL,
         NULL,
         NULL,
         NULL,
         NULL
  FROM CommonIndexes AS ci
  WHERE EXISTS (SELECT IndexColumnID,
                       ColumnName,
                       IsIncludedColumn
                FROM Table1IndexColumnSchemas
                WHERE SchemaName = ci.Table1SchemaName 
                AND TableName = ci.Table1TableName 
                AND IndexName = ci.IndexName
                EXCEPT
                SELECT IndexColumnID,
                       ColumnName,
                       IsIncludedColumn
                FROM Table2IndexColumnSchemas 
                WHERE SchemaName = ci.Table2SchemaName 
                AND TableName = ci.Table2TableName  
                AND IndexName = ci.IndexName);
END;   
GO

--==================================================================================
-- Database Utility Functions and Procedures
--==================================================================================

CREATE PROCEDURE SDU_Tools.AnalyzeTableColumnsInCurrentDatabase
@SchemaName sysname = N'dbo',
@TableName sysname,
@OrderByColumnName bit = 1,
@OutputSampleValues bit = 1,
@MaximumValuesPerColumn int = 100
AS
BEGIN

-- Function:      Analyze a table's columns in current database
-- Parameters:    @SchemaName sysname              -> (default dbo) schema for the table
--                @TableName sysname               -> the table to analyze
--                @OrderByColumnName bit           -> if 1, output is in column name order, otherwise in column_id order
--                @OutputSampleValues bit          -> if 1 (default), outputs sample values from each column
--                @MaximumValuesPerColumn int      -> (default 100) if outputting sample values, up to how many
-- Action:        Provide metadata for a table's columns and list the distinct values held in the column (up to 
--                a maximum number of values). Note that filestream columns are not sampled, nor are any
--                columns of geometry, geography, or hierarchyid data types.
-- Return:        Rowset for table details, rowset for columns, rowsets for each column
-- Refer to this video: https://youtu.be/V-jCAT-TCXM
--
-- Test examples: 
/*

EXEC SDU_Tools.AnalyzeTableColumnsInCurrentDatabase N'Warehouse', N'StockItems', 1, 1, 100; 

*/
    SET XACT_ABORT ON;
    SET NOCOUNT ON;

    DECLARE @SQL nvarchar(max);
    DECLARE @Counter int;
    DECLARE @ColumnName sysname;

    DECLARE @ColumnList TABLE
    (
        ColumnListID int IDENTITY(1,1) PRIMARY KEY,
        ColumnName sysname NOT NULL,
        ColumnID int NOT NULL,
        DataType sysname NOT NULL,
        MaximumLength int NOT NULL,
        [Precision] int NOT NULL,
        [Scale] int NOT NULL,
        IsNullable bit NOT NULL,
        IsIdentity bit NOT NULL,
        IsComputed bit NOT NULL,
        IsFilestream bit NOT NULL,
        IsSparse bit NOT NULL,
        [CollationName] sysname NULL
    );
    
    SET @SQL = N'
SELECT c.[name], c.column_id, typ.[name], c.max_length, c.[precision], c.[scale], c.is_nullable, c.is_identity, c.is_computed, c.is_filestream, c.is_sparse, c.[collation_name]
FROM sys.columns AS c
INNER JOIN sys.tables AS t
ON t.object_id = c.object_id 
INNER JOIN sys.schemas AS s
ON s.schema_id = t.schema_id 
INNER JOIN sys.types AS typ
ON typ.system_type_id = c.system_type_id AND typ.user_type_id = c.user_type_id
WHERE s.[name] = ''' + @SchemaName + N'''
AND t.[name] = ''' + @TableName + N'''
AND t.is_ms_shipped = 0
ORDER BY ' + CASE WHEN @OrderByColumnName <> 0 THEN N'c.[name]' ELSE N'c.column_id' END + N';';

    INSERT @ColumnList (ColumnName, ColumnID, DataType, MaximumLength, [Precision], [Scale], IsNullable, IsIdentity, IsComputed, IsFilestream, IsSparse, [CollationName])    
    EXEC (@SQL);

    SELECT @SchemaName AS SchemaName, @TableName AS TableName;
    SELECT ColumnName, ColumnID, DataType, MaximumLength, [Precision], [Scale], IsNullable, IsIdentity, IsComputed, IsFilestream, IsSparse, [CollationName] 
    FROM @ColumnList
    ORDER BY ColumnListID;

    IF @OutputSampleValues <> 0
    BEGIN
        SET @Counter = 1;
        WHILE @Counter <= (SELECT MAX(ColumnListID) FROM @ColumnList)
        BEGIN
            SET @ColumnName = (SELECT ColumnName 
                               FROM @ColumnList 
                               WHERE ColumnListID = @Counter 
                               AND IsFilestream = 0
                               AND DataType NOT IN (N'geography', N'geometry', N'hierarchyid'));
            IF @ColumnName IS NOT NULL
            BEGIN
                SET @SQL = N'
SELECT TOP(' + CAST(@MaximumValuesPerColumn AS nvarchar(20)) + N') ''' + @ColumnName + N''' AS ColumnName, ' + QUOTENAME(@ColumnName) + N' AS Value
FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N'
GROUP BY ' + QUOTENAME(@ColumnName) + N'
ORDER BY ' + QUOTENAME(@ColumnName) + N';';
                EXEC (@SQL);
            END;
            SET @Counter += 1;
        END;


    END;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.DropTemporaryTableIfExists
@TemporaryTableName sysname
AS
BEGIN

-- Function:      Drops the temporary table if it exists
-- Parameters:    @TemporaryTableName sysname    -> table to drop if it exists (with or without #)
-- Action:        If the temporary table is defined in the current session,
--                the table is dropped
-- Return:        Nil
-- Refer to this video: https://youtu.be/lbbjm-k8Axc
--
-- Test examples: 
/*

EXEC SDU_Tools.DropTemporaryTableIfExists N'#Accounts';
EXEC SDU_Tools.DropTemporaryTableIfExists N'Accounts';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @QuotedTableName sysname = QUOTENAME(CASE WHEN LEFT(@TemporaryTableName, 1) = N'#'
                                                      THEN @TemporaryTableName
                                                      ELSE N'#' + @TemporaryTableName
                                                 END);
    DECLARE @SQL nvarchar(max) = N'
IF OBJECT_ID(N''tempdb..' + @QuotedTableName + N''') IS NOT NULL
BEGIN
        DROP TABLE ' + @QuotedTableName + N';
END;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.FindStringWithinTheCurrentDatabase
@StringToSearchFor nvarchar(max),
@IncludeActualRows bit = 1
AS
BEGIN

-- Function:      Finds a string anywhere within the current database
-- Parameters:    @StringToSearchFor nvarchar(max) -> string we're looking for
--                @IncludeActualRows bit           -> should the rows containing it be output
-- Action:        Finds a string anywhere within the current database. Can be useful for testing masking 
--                of data. Checks all string type columns and XML columns.
-- Return:        Rowset for found locations, optionally also output the rows
-- Refer to this video: https://youtu.be/OpTdjMMjy8w
--
-- Test examples: 
/*

EXEC SDU_Tools.FindStringWithinTheCurrentDatabase N'Kayla', 0; 
EXEC SDU_Tools.FindStringWithinTheCurrentDatabase N'Kayla', 1; 
EXEC SDU_Tools.FindStringWithinTheCurrentDatabase N'Ken', 1; 

*/
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @DatabaseSQL nvarchar(max) = N'
SET NOCOUNT ON;

DECLARE @SchemaName sysname;
DECLARE @TableName sysname;
DECLARE @ColumnName sysname;
DECLARE @IsNullable bit;
DECLARE @TableObjectID int;
DECLARE @Message nvarchar(max);
DECLARE @FullTableName nvarchar(max);
DECLARE @BaseDataTypeName sysname;
DECLARE @WereStringColumnsFound bit;
DECLARE @Predicate nvarchar(max);
DECLARE @SQL nvarchar(max);
DECLARE @SummarySQL nvarchar(max) = N'''';
DECLARE @NumberOfTables int;
DECLARE @TableCounter int = 0;
DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);
DECLARE @StringToSearchFor nvarchar(max) = N''' + REPLACE(@StringToSearchFor, N'''', N'''''') + N''';
DECLARE @IncludeActualRows bit = ' + CASE WHEN @IncludeActualRows = 0 THEN N'0' ELSE N'1' END + N';

IF OBJECT_ID(N''tempdb..#FoundLocations'') IS NOT NULL
BEGIN
       DROP TABLE #FoundLocations;
END;

CREATE TABLE #FoundLocations
(
    FullTableName nvarchar(max),
    NumberOfRows bigint
);

SET @NumberOfTables = (SELECT COUNT(*) FROM sys.tables AS t
                                       WHERE t.is_ms_shipped = 0
                                       AND t.[type] = N''U'');

DECLARE TableList CURSOR FAST_FORWARD READ_ONLY
FOR 
SELECT SCHEMA_NAME(schema_id) AS SchemaName, name AS TableName, object_id AS TableObjectID
FROM sys.tables AS t
WHERE t.is_ms_shipped = 0
AND t.[type] = N''U''
ORDER BY SchemaName, TableName;

OPEN TableList;
FETCH NEXT FROM TableList INTO @SchemaName, @TableName, @TableObjectID;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @TableCounter += 1;
    SET @FullTableName = QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@TableName);
    SET @Message = N''Checking table '' 
                 + CAST(@TableCounter AS nvarchar(20)) 
                 + N'' of '' 
                 + CAST(@NumberOfTables AS nvarchar(20)) 
                 + N'': '' 
                 + @FullTableName;
    PRINT @Message;
    
    SET @WereStringColumnsFound = 0;
    SET @Predicate = N'''';
    
    DECLARE ColumnList CURSOR FAST_FORWARD READ_ONLY
    FOR
    SELECT c.[name] AS ColumnName, t.[name] AS BaseDataTypeName
    FROM sys.columns AS c
    INNER JOIN sys.[types] AS t
    ON t.system_type_id = c.system_type_id 
    AND t.user_type_id = c.system_type_id -- note: want the base type not the actual type
    WHERE c.[object_id] = @TableObjectID 
    AND t.[name] IN (N''text'', N''ntext'', N''varchar'', N''nvarchar'', N''char'', N''nchar'', N''xml'')
    AND (c.max_length >= LEN(@StringToSearchFor) OR c.max_length < 0) -- allow for max types
    ORDER BY ColumnName;
    
    OPEN ColumnList;
    FETCH NEXT FROM ColumnList INTO @ColumnName, @BaseDataTypeName;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @WereStringColumnsFound = 1;
        IF @Predicate <> N''''
        BEGIN
        SET @Predicate += N'' OR '';
        END;
        SET @Predicate += CASE WHEN @BaseDataTypeName = N''xml''
                               THEN N''CAST('' + QUOTENAME(@ColumnName) + N'' AS nvarchar(max))''
                               ELSE QUOTENAME(@ColumnName) 
                          END
                        + N'' LIKE N''''%'' + @StringToSearchFor + N''%'''''';
        FETCH NEXT FROM ColumnList INTO @ColumnName, @BaseDataTypeName;
    END;
    
    CLOSE ColumnList;
    DEALLOCATE ColumnList;
    
    IF @WereStringColumnsFound <> 0
    BEGIN
        SET @SQL = N''SET NOCOUNT ON; 
                 INSERT #FoundLocations (FullTableName, NumberOfRows)
                 SELECT N'''''' + @FullTableName + N'''''', COUNT_BIG(*) FROM '' 
                        + @FullTableName 
                        + N'' WHERE '' 
                        + @Predicate
                        + N'';'';
        EXECUTE (@SQL);
        
        IF (SELECT NumberOfRows FROM #FoundLocations WHERE FullTableName = @FullTableName) > 0
        BEGIN
            SET @SummarySQL += N''SELECT * FROM '' + @FullTableName + N'' WHERE '' + @Predicate + N'';'' + @CRLF;
        END;
    END;
    
    FETCH NEXT FROM TableList INTO @SchemaName, @TableName, @TableObjectID;
END;

CLOSE TableList;
DEALLOCATE TableList;

SELECT * 
FROM #FoundLocations 
WHERE NumberOfRows > 0 
ORDER BY FullTableName;

DROP TABLE #FoundLocations;

IF @SummarySQL <> N'''' AND @IncludeActualRows <> 0
BEGIN
    EXECUTE (@SummarySQL);
END;' + @CRLF;
    EXECUTE (@DatabaseSQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListSubsetIndexesInCurrentDatabase
AS
BEGIN

-- Function:      Lists indexes that appear to be subsets of other indexes
-- Parameters:    Nil
-- Action:        Finds indexes that appear to be subsets of other indexes
-- Return:        One rowset with details of each subset index
-- Refer to this video: https://youtu.be/aICj46bmKJs
--
-- Test examples: 
/*

EXEC SDU_Tools.ListSubsetIndexesInCurrentDatabase;

*/
    DECLARE @SQLCommandPart1 nvarchar(4000);
    DECLARE @SQLCommandPart2 nvarchar(4000);
    DECLARE @SQLCommandPart3 nvarchar(4000);
    DECLARE @SQLCommandPart4 nvarchar(4000);
    
    IF OBJECT_ID(N'tempdb..#RowsToReport') IS NOT NULL 
    BEGIN
        DROP TABLE #RowsToReport;
    END;
    
    CREATE TABLE #RowsToReport 
    ( RowNumber int IDENTITY(1,1),
      SchemaName sysname,
      TableName sysname,
      IndexName sysname
    );
         
    SET NOCOUNT ON;
    
    SET @SQLCommandPart1 = N' 
    DECLARE @MaxOutputWidth int = 4000;
    DECLARE @SchemaName sysname;
    DECLARE @TableName sysname;
    DECLARE @IndexName sysname;
    DECLARE @IndexType nvarchar(128);
    DECLARE @ColumnName sysname;
    DECLARE @IndexColumnID int;
    DECLARE @IsIncluded bit;
    DECLARE @IsUnique bit;
    DECLARE @IsPrimaryKey bit;
    DECLARE @LastIndexName sysname = N'''';
    DECLARE @Output nvarchar(max);
    DECLARE @NameColumnWidth int = (SELECT MAX(LEN(i.[name])) 
                                    FROM sys.indexes AS i 
                                    INNER JOIN sys.tables AS t 
                                              ON i.[object_id] = t.[object_id] 
                                    WHERE t.is_ms_shipped = 0) + 12;
    DECLARE @OutputRows TABLE 
    ( 
        RowNumber int IDENTITY(1,1), 
        OutputRow varchar(max) 
    );
    DECLARE TableList CURSOR FAST_FORWARD READ_ONLY
    FOR 
    SELECT SCHEMA_NAME(t.[schema_id]) AS SchemaName,
           t.[name] AS TableName 
    FROM sys.tables AS t
    WHERE t.is_ms_shipped = 0
    AND EXISTS (SELECT 1 FROM sys.indexes AS i 
                         WHERE t.[object_id] = i.[object_id] 
                         AND i.index_id > 0)
    ORDER BY SchemaName, TableName;
    
    OPEN TableList;
    FETCH NEXT FROM TableList INTO @SchemaName, @TableName;
    WHILE @@FETCH_STATUS = 0
    BEGIN
    
        SET @LastIndexName = N'''';
    
        DECLARE IndexColumnList CURSOR FAST_FORWARD READ_ONLY
        FOR
        SELECT i.[name] AS IndexName, 
               i.[type_desc] AS IndexType,
               c.[name] AS ColumnName, 
               ic.index_column_id AS IndexColumnID,
               ic.is_included_column AS IsIncluded,
               i.is_unique AS IsUnique,
               i.is_primary_key AS IsPrimaryKey 
        FROM sys.indexes AS i
        INNER JOIN sys.index_columns AS ic
            ON i.[object_id] = ic.[object_id] 
            AND i.index_id = ic.index_id 
        INNER JOIN sys.columns AS c
            ON ic.[object_id] = c.[object_id] 
            AND ic.column_id = c.column_id 
        INNER JOIN sys.tables AS t
            ON i.[object_id] = t.[object_id] 
        WHERE SCHEMA_NAME(t.[schema_id]) = @SchemaName 
        AND t.[name] = @TableName 
        ORDER BY IndexType, IndexName, IsIncluded, IndexColumnID, ColumnName;
             
        DELETE @OutputRows;';

        SET @SQLCommandPart2 = '
    
        OPEN IndexColumnList;
        FETCH NEXT FROM IndexColumnList 
            INTO @IndexName, @IndexType, @ColumnName, @IndexColumnID, @IsIncluded, @IsUnique, @IsPrimaryKey;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @LastIndexName <> @IndexName BEGIN
                IF @LastIndexName <> '''' INSERT @OutputRows VALUES (@Output);
                SET @Output = LEFT(CASE WHEN @IsPrimaryKey <> 0 
                                        THEN ''PK'' 
                                        ELSE ''  '' 
                                   END 
                                   + CASE WHEN @IndexType = ''CLUSTERED'' 
                                          THEN ''CL'' 
                                          ELSE ''NC'' 
                                     END 
                                   + CASE WHEN @IsUnique <> 0 
                                          THEN ''UQ'' 
                                          ELSE ''  '' 
                                     END
                                   + '' '' + @IndexName 
                                   + SPACE(128), @NameColumnWidth);
                SET @LastIndexName = @IndexName;
            END;  
            SET @Output += CASE WHEN @IsIncluded <> 0 
                                THEN ''(Incl) '' 
                                ELSE '''' 
                           END + @ColumnName + '', '';
            FETCH NEXT FROM IndexColumnList 
                INTO @IndexName, @IndexType, @ColumnName, @IndexColumnID, @IsIncluded, @IsUnique, @IsPrimaryKey;
        END;
             
        IF @LastIndexName <> '''' INSERT @OutputRows VALUES (@Output);
             
        CLOSE IndexColumnList;
        DEALLOCATE IndexColumnList;';

        SET @SQLCommandPart3 = '             
                          
        PRINT N''Table: '' + @SchemaName + N''.'' + @TableName;
        PRINT '' '';
    
        DECLARE RowList CURSOR FAST_FORWARD READ_ONLY
        FOR 
        SELECT CASE WHEN EXISTS (SELECT 1 FROM @OutputRows AS or2 
                                          WHERE SUBSTRING(or2.OutputRow, 
                                                          @NameColumnWidth + 1, 
                                                          LEN(SUBSTRING(or1.OutputRow, 
                                                                        @NameColumnWidth + 1,
                                                                        @MaxOutputWidth))) 
                                                          = SUBSTRING(or1.OutputRow, 
                                                                      @NameColumnWidth + 1, 
                                                                      @MaxOutputWidth)
                                          AND or1.OutputRow <> or2.OutputRow)
                                 AND or1.OutputRow NOT LIKE ''PK%''
                    THEN N''* '' 
                    ELSE N''  ''
                END 
                + SUBSTRING(OutputRow, 1, @MaxOutputWidth - 5) AS OutputRow 
        FROM @OutputRows AS or1
        ORDER BY RowNumber;
    
        OPEN RowList;
        FETCH NEXT FROM RowList INTO @Output;';

        SET @SQLCommandPart4 = '            
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF RIGHT(@Output, 2) = N'', '' SET @Output = LEFT(@Output, LEN(@Output) - 1);
            PRINT @Output;
            IF LEFT(@Output, 1) = N''*'' 
            BEGIN
                INSERT #RowsToReport (SchemaName, TableName, IndexName)
                VALUES (@SchemaName, @TableName, LTRIM(RTRIM(SUBSTRING(@Output, 10, @NameColumnWidth - 7))));
            END;
            FETCH NEXT FROM RowList INTO @Output;
        END;
        CLOSE RowList;
        DEALLOCATE RowList;
    
        PRINT '' '';
    
        FETCH NEXT FROM TableList INTO @SchemaName, @TableName;
    END;
    
    CLOSE TableList;
    DEALLOCATE TableList;';

    EXECUTE(@SQLCommandPart1 + @SQLCommandPart2 + @SQLCommandPart3 + @SQLCommandPart4);
    
    SELECT SchemaName, TableName, IndexName 
    FROM #RowsToReport 
    ORDER BY RowNumber;

    IF OBJECT_ID(N'tempdb..#RowsToReport') IS NOT NULL 
    BEGIN
        DROP TABLE #RowsToReport;
    END;
END;
GO

------------------------------------------------------------------------------------

-- CREATE PROCEDURE SDU_Tools.ShowBackupCompletionEstimates (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------

-- CREATE PROCEDURE SDU_Tools.EmptySchema (Not appropriate for Azure SQL DB)
-- Use EmptySchemaInCurrentDatabase instead

------------------------------------------------------------------------------------
GO

CREATE PROCEDURE SDU_Tools.PrintMessage
@MessageToPrint nvarchar(max) 
AS
BEGIN

-- Function:      Print a message immediately 
-- Parameters:    @MessageToPrint nvarchar(max) -> The message to be printed
-- Action:        Prints a message immediately rather than waiting for PRINT to be returned
-- Return:        Nil
-- Refer to this video: https://youtu.be/Coabe1oY8Vg
--
-- Test examples: 
/*

EXEC SDU_Tools.PrintMessage N'Hello';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    RAISERROR (@MessageToPrint, 10, 1) WITH NOWAIT;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ShowCurrentBlockingInCurrentDatabase
AS
BEGIN

-- Function:      Looks for requests that are blocking right now
-- Parameters:    Nil
-- Action:        Lists sessions holding locks, the SQL they are executing, then 
--                lists blocked items and the SQL they are trying to execute
-- Return:        Two rowsets
-- Refer to this video: https://youtu.be/utIPkuqfTu0
--
-- Test examples: 
/*

EXEC SDU_Tools.ShowCurrentBlockingInCurrentDatabase;

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT tl.request_session_id AS SessionID,
           s.login_name AS LoginName,
           tl.resource_type AS ObjectType,
           tl.request_mode AS RequestMode,
           tl.request_type AS RequestType,
           tl.request_status AS RequestStatus,
           r.open_transaction_count AS OpenTransactionCount,
           st.text AS SQLText,
           mrsh.text AS LastSQLText,
           tl.resource_associated_entity_id AS AssociatedEntityID
    FROM sys.dm_tran_locks AS tl 
    LEFT OUTER JOIN sys.dm_exec_sessions AS s
        ON tl.request_session_id = s.session_id 
    LEFT OUTER JOIN sys.dm_exec_requests AS r
        ON tl.request_session_id = r.request_id
    LEFT OUTER JOIN sys.dm_exec_connections AS c
        ON tl.request_session_id = c.session_id 
    OUTER APPLY sys.dm_exec_SQL_text(r.SQL_handle) AS st
    OUTER APPLY sys.dm_exec_SQL_text(c.most_recent_SQL_handle) AS mrsh;
    
    WITH BlockedSessions
    AS
    ( SELECT s.session_id AS BlockedSessionID, 
             r.blocking_session_id AS BlockedBy,
             st.text AS BlockedSQLText
      FROM sys.dm_exec_requests AS r
      INNER JOIN sys.dm_exec_sessions AS s
        ON r.session_id = s.session_id 
      INNER JOIN sys.dm_exec_connections AS c
        ON s.session_id = c.session_id 
      OUTER APPLY sys.dm_exec_SQL_text(c.most_recent_SQL_handle) AS st
      WHERE r.blocking_session_id <> 0
    ),
    BlockingSessions
    AS
    ( SELECT s.session_id AS BlockingSessionID, st.text AS BlockingSQLText
      FROM BlockedSessions AS bs
      INNER JOIN sys.dm_exec_sessions AS s
        ON s.session_id = s.session_id 
      INNER JOIN sys.dm_exec_connections AS c
        ON s.session_id = c.session_id 
      OUTER APPLY sys.dm_exec_SQL_text(c.most_recent_SQL_handle) AS st
    )
    SELECT s.BlockingSessionID, 
           s.BlockingSQLText,
           b.BlockedSessionID, 
           b.BlockedBy, 
           b.BlockedSQLText
    FROM BlockingSessions AS s
    INNER JOIN BlockedSessions AS b
        ON s.BlockingSessionID  = b.BlockedBy
    ORDER BY b.BlockedBy, b.BlockedSessionID;
END;
GO

------------------------------------------------------------------------------------

-- CREATE PROCEDURE SDU_Tools.ExecuteJobAndWaitForCompletion (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------

-- CREATE PROCEDURE SDU_Tools.ClearServiceBrokerTransmissionQueue (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------
GO

CREATE PROCEDURE SDU_Tools.ListAllDataTypesInUseInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL',   -- N'ALL' for all
@ColumnsToList nvarchar(max) = N'ALL'   -- N'ALL' for all
AS
BEGIN

-- Function:      ListAllDataTypesInUse
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        ListAllDataTypesInUse (user tables only)
-- Return:        Rowset a distinct list of DataTypes
-- Refer to this video: https://youtu.be/1MzqnkLeoNM
--
-- Test examples: 
/*

EXEC SDU_Tools.ListAllDataTypesInUseInCurrentDatabase
    @SchemasToList = N'ALL', 
    @TablesToList = N'ALL', 
    @ColumnsToList = N'ALL';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'   SELECT DISTINCT
           typ.[name] + CASE WHEN typ.[name] IN (N''decimal'', N''numeric'')
                             THEN N''('' + CAST(c.precision AS nvarchar(20)) + N'', '' 
                                  + CAST(c.scale AS nvarchar(20)) + N'')''
                             WHEN typ.[name] IN (N''varchar'', N''nvarchar'', N''char'', N''nchar'', N''binary'', N''varbinary'')
                             THEN N''('' + CASE WHEN c.max_length < 0 
                                              THEN N''max'' 
                                                WHEN typ.[name] IN (N''nvarchar'', N''char'')
                                                THEN CAST(c.max_length / 2 AS nvarchar(20)) 
                                                ELSE CAST(c.max_length AS nvarchar(20)) 
                                         END + N'')''
                             WHEN typ.[name] IN (N''time'', N''datetime2'', N''datetimeoffset'')
                             THEN N''('' + CAST(c.scale AS nvarchar(20)) + N'')''
                             ELSE N''''
                        END AS DataType
    FROM sys.schemas AS s
    INNER JOIN sys.tables AS t
        ON s.[schema_id] = t.[schema_id]
    INNER JOIN sys.columns AS c
        ON t.[object_id] = c.[object_id] 
    INNER JOIN sys.[types] AS typ 
        ON c.system_type_id = typ.system_type_id
        AND c.user_type_id = typ.user_type_id 
    WHERE t.[type] = N''U'''
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @ColumnsToList = N'ALL' 
           THEN N''
           ELSE N'    AND c.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @ColumnsToList + ''', N'','', 1))'
      END + @CRLF 
    + N'    ORDER BY DataType;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListColumnsAndDataTypesInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL',   -- N'ALL' for all
@ColumnsToList nvarchar(max) = N'ALL'   -- N'ALL' for all
AS
BEGIN

-- Function:      Lists the data types for all columns
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists the data types for all columns (user tables only)
-- Return:        Rowset containing SchemaName, TableName, ColumnName, and DataType. Within each 
--                table, columns are listed in column ID order
-- Refer to this video: https://youtu.be/FlkRho_Hngk
--
-- Test examples: 
/*

EXEC SDU_Tools.ListColumnsAndDataTypesInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ColumnsToList = N'ALL';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'   SELECT s.[name] AS SchemaName, 
           t.[name] AS TableName, 
           c.[name] AS ColumnName,
           typ.[name] + CASE WHEN typ.[name] IN (N''decimal'', N''numeric'')
                             THEN N''('' + CAST(c.precision AS nvarchar(20)) + N'', '' 
                                  + CAST(c.scale AS nvarchar(20)) + N'')''
                             WHEN typ.[name] IN (N''varchar'', N''nvarchar'', N''char'', N''nchar'', N''binary'', N''varbinary'')
                             THEN N''('' + CASE WHEN c.max_length < 0 
                                              THEN N''max'' 
                                                WHEN typ.[name] IN (N''nvarchar'', N''char'')
                                                THEN CAST(c.max_length / 2 AS nvarchar(20)) 
                                                ELSE CAST(c.max_length AS nvarchar(20)) 
                                         END + N'')''
                             WHEN typ.[name] IN (N''time'', N''datetime2'', N''datetimeoffset'')
                             THEN N''('' + CAST(c.scale AS nvarchar(20)) + N'')''
                             ELSE N''''
                        END AS DataType
    FROM sys.schemas AS s
    INNER JOIN sys.tables AS t
        ON s.[schema_id] = t.[schema_id]
    INNER JOIN sys.columns AS c
        ON t.[object_id] = c.[object_id] 
    INNER JOIN sys.[types] AS typ 
        ON c.system_type_id = typ.system_type_id
        AND c.user_type_id = typ.user_type_id 
    WHERE t.[type] = N''U'''
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @ColumnsToList = N'ALL' 
           THEN N''
           ELSE N'    AND c.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @ColumnsToList + ''', N'','', 1))'
      END + @CRLF 
    + N'    ORDER BY SchemaName, TableName, c.column_id;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListMismatchedDataTypesInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL',   -- N'ALL' for all
@ColumnsToList nvarchar(max) = N'ALL'   -- N'ALL' for all
AS
BEGIN

-- Function:      ListMismatchedDataTypes
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        List columns with the same name that are defined with different data types (user tables only)
-- Return:        Rowset a list of mismatched DataTypes
-- Refer to this video: https://youtu.be/i6mmzhu4T9g
--
-- Test examples: 
/*

EXEC SDU_Tools.ListMismatchedDataTypesInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'InvoiceLines,StockItemTransactions', 
     @ColumnsToList = N'ALL';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'WITH ColumnDataTypes
AS
(
    SELECT s.[name] AS SchemaName, 
           t.[name] AS TableName,
           c.[name] AS ColumnName,
           typ.[name] + CASE WHEN typ.[name] IN (N''decimal'', N''numeric'')
                             THEN N''('' + CAST(c.[precision] AS nvarchar(20)) + N'', '' + CAST(c.[scale] AS nvarchar(20)) + N'')''
                             WHEN typ.[name] IN (N''varchar'', N''nvarchar'', N''char'', N''nchar'', N''binary'', N''varbinary'')
                             THEN N''('' + CASE WHEN c.max_length < 0 
                                              THEN N''max'' 
                                                WHEN typ.[name] IN (N''nvarchar'', N''char'')
                                                THEN CAST(c.max_length / 2 AS nvarchar(20)) 
                                                ELSE CAST(c.max_length AS nvarchar(20)) 
                                         END + N'')''
                             WHEN typ.[name] IN (N''time'', N''datetime2'', N''datetimeoffset'')
                             THEN N''('' + CAST(c.[scale] AS nvarchar(20)) + N'')''
                             ELSE N''''
                        END AS DataType
    FROM sys.columns AS c
    INNER JOIN sys.tables AS t 
    ON t.object_id = c.object_id 
    INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id 
    INNER JOIN sys.types AS typ 
    ON typ.system_type_id = c.system_type_id 
    AND typ.user_type_id = c.user_type_id 
    WHERE t.is_ms_shipped = 0
    AND t.[type] = N''U'''
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @ColumnsToList = N'ALL' 
           THEN N''
           ELSE N'    AND c.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @ColumnsToList + ''', N'','', 1))'
      END + @CRLF + N'
)
SELECT cdt.ColumnName, cdt.DataType, N''('' + cdt.SchemaName + N''.'' + cdt.TableName + N'')'' AS TableSchema
FROM ColumnDataTypes AS cdt
WHERE EXISTS (SELECT 1 FROM ColumnDataTypes AS cdtl WHERE cdtl.ColumnName = cdt.ColumnName AND cdtl.DataType <> cdt.DataType)
ORDER BY ColumnName, cdt.DataType, TableSchema;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListForeignKeysInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL'    -- N'ALL' for all
AS
BEGIN

-- Function:      ListForeignKeys
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List foreign keys with column lists
-- Return:        Rowset of foreign keys
-- Refer to this video: https://youtu.be/NC1na-Jn0ck
--
-- Test examples: 
/*

EXEC SDU_Tools.ListForeignKeysInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'WITH DeclaredForeignKeys
AS
(
       SELECT ss.[name] AS SourceSchemaName, st.[name] AS SourceTableName, 
              fk.[name] AS ForeignKeyName,
              LEFT(fkcl.ColumnList, LEN(fkcl.ColumnList) - 1) AS SourceColumnList,
              rs.[name] AS ReferencedSchemaName, rt.[name] AS ReferencedTableName,
              LEFT(rtcl.ColumnList, LEN(rtcl.ColumnList) - 1) AS ReferencedColumnList,
              fk.is_not_trusted AS IsNotTrusted,
             fk.is_disabled AS IsDisabled
       FROM sys.foreign_keys AS fk
       INNER JOIN sys.tables AS st 
       ON st.object_id = fk.parent_object_id
       INNER JOIN sys.schemas AS ss
       ON ss.schema_id = st.schema_id
       INNER JOIN sys.tables AS rt
       ON rt.object_id = fk.referenced_object_id
       INNER JOIN sys.schemas AS rs
       ON rs.schema_id = rt.schema_id 
       CROSS APPLY 
       (
           SELECT c.[name] + N'','' 
           FROM sys.foreign_key_columns AS fkc 
           INNER JOIN sys.columns AS c 
           ON fkc.parent_object_id = c.object_id 
           AND fkc.parent_column_id = c.column_id
           WHERE fkc.constraint_object_id = fk.object_id 
           ORDER BY fkc.constraint_column_id
           FOR XML PATH ('''')
       ) AS fkcl (ColumnList)
       CROSS APPLY 
       (
           SELECT c.[name] + N'','' 
           FROM sys.foreign_key_columns AS fkc 
           INNER JOIN sys.columns AS c 
           ON fkc.referenced_object_id = c.object_id 
           AND fkc.referenced_column_id = c.column_id
           WHERE fkc.constraint_object_id = fk.object_id 
           ORDER BY fkc.constraint_column_id
           FOR XML PATH ('''')
       ) AS rtcl (ColumnList)
       WHERE st.is_ms_shipped = 0
       AND st.[name] <> N''sysdiagrams''
)
SELECT dfk.SourceSchemaName, dfk.SourceTableName, dfk.ForeignKeyName, dfk.SourceColumnList,
       dfk.ReferencedSchemaName, dfk.ReferencedTableName, dfk.ReferencedColumnList,
       dfk.IsNotTrusted, dfk.IsDisabled
FROM DeclaredForeignKeys AS dfk 
WHERE 1 = 1 '
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND dfk.SourceSchemaName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND dfk.SourceTableName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF + N'
ORDER BY dfk.SourceSchemaName, dfk.SourceTableName, dfk.ForeignKeyName;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListForeignKeyColumnsInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL'    -- N'ALL' for all
AS
BEGIN

-- Function:      ListForeignKeyColumns
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List foreign keys with both source and referenced columns
-- Return:        Rowset of foreign key columns
-- Refer to this video: https://youtu.be/NC1na-Jn0ck
--
-- Test examples: 
/*

EXEC SDU_Tools.ListForeignKeyColumnsInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'SELECT fk.[name] AS ForeignKeyName, fk.is_disabled AS IsDisabled, fk.is_not_trusted AS IsNotTrusted, fk.is_system_named AS IsSystemNamed,
       s.[name] AS SchemaName, t.[name] AS TableName,
       fkc.constraint_column_id AS ColumnID, c.[name] AS ColumnName,
       rs.[name] AS ReferencedSchemaName, rt.[name] AS ReferencedTableName,
       rc.[name] AS ReferencedColumnName 
FROM sys.foreign_keys AS fk
INNER JOIN sys.tables AS t 
ON t.object_id = fk.parent_object_id
INNER JOIN sys.schemas AS s
ON s.schema_id = t.schema_id 
INNER JOIN sys.tables AS rt 
ON rt.object_id = fk.referenced_object_id
INNER JOIN sys.schemas AS rs
ON rs.schema_id = rt.schema_id 
INNER JOIN sys.foreign_key_columns AS fkc 
ON fkc.constraint_object_id = fk.object_id 
INNER JOIN sys.columns AS c
ON c.object_id = t.object_id 
AND c.column_id = fkc.parent_column_id 
INNER JOIN sys.columns AS rc
ON rc.object_id = rt.object_id 
AND rc.column_id = fkc.referenced_column_id
WHERE fk.is_ms_shipped = 0
AND t.[name] <> N''sysdiagrams'''
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF + N'
ORDER BY SchemaName, TableName, ForeignKeyName, ColumnID;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListIndexesInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL'    -- N'ALL' for all
AS
BEGIN

-- Function:      ListIndexes
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List indexes with both key and included column lists
-- Return:        Rowset of indexes
-- Refer to this video: https://youtu.be/Mgwjw5mXnN8
--
-- Test examples: 
/*

EXEC SDU_Tools.ListIndexesInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'WITH IndexKeys
AS
(
       SELECT s.[name] AS SchemaName, t.[name] AS TableName, i.[name] AS IndexName,
              LEFT(icl.KeyColumnList, LEN(icl.KeyColumnList) - 1) AS KeyColumnList,
              LEFT(inccl.IncludedColumnList, LEN(inccl.IncludedColumnList) - 1) AS IncludedColumnList
       FROM sys.indexes AS i
       INNER JOIN sys.tables AS t 
       ON t.object_id = i.object_id
       INNER JOIN sys.schemas AS s
       ON s.schema_id = t.schema_id
       CROSS APPLY 
       (
           SELECT c.[name] + N'','' 
           FROM sys.index_columns AS ic 
           INNER JOIN sys.columns AS c 
           ON c.object_id = ic.object_id 
           AND c.column_id = ic.column_id
           WHERE ic.object_id = i.object_id 
           AND ic.index_id = i.index_id 
           AND ic.is_included_column = 0
           ORDER BY ic.index_column_id
           FOR XML PATH ('''')
       ) AS icl (KeyColumnList)
       CROSS APPLY 
       (
           SELECT c.[name] + N'','' 
           FROM sys.index_columns AS ic 
           INNER JOIN sys.columns AS c 
           ON c.object_id = ic.object_id 
           AND c.column_id = ic.column_id
           WHERE ic.object_id = i.object_id 
           AND ic.index_id = i.index_id 
           AND ic.is_included_column = 1
           ORDER BY ic.index_column_id
           FOR XML PATH ('''')
       ) AS inccl (IncludedColumnList)       
       WHERE t.is_ms_shipped = 0
       AND t.[name] <> N''sysdiagrams''
       AND i.is_hypothetical = 0
)
SELECT ik.SchemaName, ik.TableName, ik.IndexName, ik.KeyColumnList, ik.IncludedColumnList
FROM IndexKeys AS ik
WHERE 1 = 1 '
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND ik.SchemaName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND ik.TableName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF + N'
ORDER BY ik.SchemaName, ik.TableName, ik.IndexName;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListNonIndexedForeignKeysInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL'    -- N'ALL' for all
AS
BEGIN

-- Function:      ListNonIndexedForeignKeys
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List foreign keys where the foreign key columns are not present as the first
--                components of at least one index
-- Return:        Rowset of non indexed foreign keys
-- Refer to this video: https://youtu.be/VAD8PyQ1RUs
--
-- Test examples: 
/*

EXEC SDU_Tools.ListNonIndexedForeignKeysInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'WITH DeclaredForeignKeys
AS
(
       SELECT s.[name] AS SchemaName, t.[name] AS TableName, fk.[name] AS ForeignKeyName,
              LEFT(fkcl.ColumnList, LEN(fkcl.ColumnList) - 1) AS ColumnList
       FROM sys.foreign_keys AS fk
       INNER JOIN sys.tables AS t 
       ON t.object_id = fk.parent_object_id
       INNER JOIN sys.schemas AS s
       ON s.schema_id = t.schema_id
       CROSS APPLY (
                                  SELECT c.[name] + N'','' 
                                  FROM sys.foreign_key_columns AS fkc 
                                  INNER JOIN sys.columns AS c 
                                  ON fkc.parent_object_id = c.object_id 
                                  AND fkc.parent_column_id = c.column_id
                                  WHERE fkc.constraint_object_id = fk.object_id 
                                  ORDER BY fkc.constraint_column_id
                                  FOR XML PATH ('''')
                   ) AS fkcl (ColumnList)
       WHERE t.is_ms_shipped = 0
       AND t.[name] <> N''sysdiagrams''
),
IndexKeys
AS
(
       SELECT s.[name] AS SchemaName, t.[name] AS TableName, i.[name] AS IndexName,
              LEFT(icl.KeyColumnList, LEN(icl.KeyColumnList) - 1) AS KeyColumnList
       FROM sys.indexes AS i
       INNER JOIN sys.tables AS t 
       ON t.object_id = i.object_id
       INNER JOIN sys.schemas AS s
       ON s.schema_id = t.schema_id
       CROSS APPLY (
                                  SELECT c.[name] + N'','' 
                                  FROM sys.index_columns AS ic 
                                  INNER JOIN sys.columns AS c 
                                  ON c.object_id = ic.object_id 
                                  AND c.column_id = ic.column_id
                                  WHERE ic.object_id = i.object_id 
                                  AND ic.index_id = i.index_id 
                                  AND ic.is_included_column = 0
                                  ORDER BY ic.index_column_id
                                  FOR XML PATH ('''')
                   ) AS icl (KeyColumnList)
       WHERE t.is_ms_shipped = 0
       AND t.[name] <> N''sysdiagrams''
       AND i.is_hypothetical = 0
)
SELECT dfk.SchemaName, dfk.TableName, dfk.ForeignKeyName, dfk.ColumnList
FROM DeclaredForeignKeys AS dfk
WHERE NOT EXISTS (SELECT 1 FROM IndexKeys AS ik
                           WHERE ik.SchemaName = dfk.SchemaName
                                            AND ik.TableName = dfk.TableName
                                            AND ik.KeyColumnList LIKE (dfk.ColumnList + N''%'') COLLATE DATABASE_DEFAULT)'
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND dfk.SchemaName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND dfk.TableName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF + N'
ORDER BY dfk.SchemaName, dfk.TableName, dfk.ForeignKeyName;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListPotentialDateColumnsInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL',   -- N'ALL' for all
@ColumnsToList nvarchar(max) = N'ALL'   -- N'ALL' for all
AS
BEGIN

-- Function:      ListPotentialDateColumns
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        ListPotentialDateColumns (user tables only) - Lists columns that are named as dates but use datatypes with time
-- Return:        Rowset of columns
-- Refer to this video: https://youtu.be/X2F82WmcgIg
--
-- Test examples: 
/*

EXEC SDU_Tools.ListPotentialDateColumnsInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ColumnsToList = N'ALL';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'   SELECT s.[name] AS SchemaName,
           t.[name] AS TableName,
              c.[name] AS ColumnName,
              typ.[name] + CASE WHEN typ.[name] = N''datetime2'' 
                            THEN N''('' + CAST(c.scale AS nvarchar(20)) + N'')''
                                         ELSE N''''
                               END AS DataType
    FROM sys.schemas AS s
    INNER JOIN sys.tables AS t
        ON s.[schema_id] = t.[schema_id]
    INNER JOIN sys.columns AS c
        ON t.[object_id] = c.[object_id] 
    INNER JOIN sys.[types] AS typ 
        ON c.system_type_id = typ.system_type_id
        AND c.user_type_id = typ.user_type_id 
    WHERE t.[type] = N''U''
       AND typ.[name] LIKE N''%datetime%'' 
    AND c.[name] LIKE N''%date%''
    AND c.[name] NOT LIKE N''%datetime%'''
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @ColumnsToList = N'ALL' 
           THEN N''
           ELSE N'    AND c.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @ColumnsToList + ''', N'','', 1))'
      END + @CRLF 
    + N'    ORDER BY SchemaName, TableName, ColumnName;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListPotentialDateColumnsByValueInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL',   -- N'ALL' for all
@ColumnsToList nvarchar(max) = N'ALL'   -- N'ALL' for all
AS
BEGIN

-- Function:      ListPotentialDateColumnsByValue
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists columns that are defined with datatypes that include a time component
--                but no time value is present in any row (can take a while to check)
-- Return:        Rowset of columns
-- Refer to this video: https://youtu.be/2bmhVXq_02Y
--
-- Test examples: 
/*

EXEC SDU_Tools.ListPotentialDateColumnsByValueInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ColumnsToList = N'ALL';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    IF OBJECT_ID(N'tempdb..#Columns') IS NOT NULL
    BEGIN
        DROP TABLE #Columns;
    END;

    CREATE TABLE #Columns
    ( 
        SchemaName sysname,
        TableName sysname, 
        ColumnName sysname,
        DataTypeName sysname 
    );

    DECLARE @CRLF nvarchar(2) = NCHAR(13) + CHAR(10);
    DECLARE @SQL nvarchar(max) = N'
DECLARE DateColumnList CURSOR FAST_FORWARD READ_ONLY
FOR
SELECT s.[name] AS SchemaName, t.[name] AS TableName, c.[name] As ColumnName, 
       typ.[name] + CASE WHEN typ.[name] = N''datetime2'' THEN ''('' + CAST(typ.[scale] AS nvarchar(20)) + '')'' ELSE N'''' END AS DataTypeName
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
ON s.schema_id = t.schema_id
INNER JOIN sys.columns AS c
ON c.object_id = t.object_id 
INNER JOIN sys.types AS typ
ON typ.system_type_id = c.system_type_id 
AND typ.user_type_id = c.user_type_id
WHERE t.is_ms_shipped = 0
AND t.type = ''U'' 
AND t.[name] <> ''sysdiagrams'''
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM ' + QUOTENAME(DB_NAME()) + N'.SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM ' + QUOTENAME(DB_NAME()) + N'.SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @ColumnsToList = N'ALL' 
           THEN N''
           ELSE N'    AND c.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM ' + QUOTENAME(DB_NAME()) + N'.SDU_Tools.SplitDelimitedString('''
                + @ColumnsToList + ''', N'','', 1))'
      END + @CRLF + N'
AND typ.[name] IN (N''smalldatetime'', N''datetime'', N''datetime2'')
ORDER BY SchemaName, TableName, ColumnName;

DECLARE @SchemaName sysname;
DECLARE @TableName sysname;
DECLARE @ColumnName sysname;
DECLARE @DataTypeName sysname;

DECLARE @SQL nvarchar(max);

OPEN DateColumnList;
FETCH NEXT FROM DateColumnList INTO @SchemaName, @TableName, @ColumnName, @DataTypeName;
WHILE @@FETCH_STATUS = 0 
BEGIN
    SET @SQL = N''
IF EXISTS (SELECT 1 FROM '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@TableName) + N'')
AND NOT EXISTS (SELECT 1 FROM '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@TableName) + N'' AS t
                         WHERE CAST(t.'' + QUOTENAME(@ColumnName) + N'' AS date) <> t.'' + QUOTENAME(@ColumnName) + N'')
BEGIN
    INSERT #Columns (SchemaName, TableName, ColumnName, DataTypeName)
    VALUES ('''''' + @SchemaName + '''''','''''' + @TableName + '''''','''''' + @ColumnName + '''''','''''' + @DataTypeName + '''''');                         
END;'';
    EXEC (@SQL);
    FETCH NEXT FROM DateColumnList INTO @SchemaName, @TableName, @ColumnName, @DataTypeName;
END;

CLOSE DateColumnList;
DEALLOCATE DateColumnList;';
    EXEC (@SQL);

    SELECT c.SchemaName, c.TableName, c.ColumnName, c.DataTypeName
    FROM #Columns AS c
    ORDER BY c.SchemaName, c.TableName, c.ColumnName; 

    IF OBJECT_ID(N'tempdb..#Columns') IS NOT NULL
    BEGIN
        DROP TABLE #Columns;
    END;
END;
GO

------------------------------------------------------------------------------------

-- CREATE PROCEDURE SDU_Tools.ListMismatchedDatabaseCollations (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------
GO

CREATE PROCEDURE SDU_Tools.ListUnusedIndexesInCurrentDatabase
AS
BEGIN

-- Function:      List indexes that appear to be unused
-- Parameters:    Nil
-- Action:        List indexes that appear to be unused (user tables only)
--                These indexes might be candidates for reconsideration and removal
--                but be careful about doing so, particularly for unique indexes
-- Return:        Rowset of schema name, table, name, index name, and is unique
-- Refer to this video: https://youtu.be/SNVSBWPsBnw
-- Test examples: 
/*

EXEC SDU_Tools.ListUnusedIndexesInCurrentDatabase;

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'   SELECT s.[name] AS SchemaName, t.[name] AS TableName, i.[name] AS IndexName, i.is_unique AS IsUnique
    FROM sys.indexes AS i
    INNER JOIN sys.tables AS t
        ON t.[object_id] = i.[object_id] 
    INNER JOIN sys.schemas AS s
        ON t.[schema_id] = s.[schema_id]
    LEFT OUTER JOIN sys.dm_db_index_usage_stats AS ius
    ON i.[object_id] = ius.[object_id] 
    AND i.index_id = ius.index_id 
    WHERE ius.last_user_seek IS NULL 
    AND ius.last_user_scan IS NULL
    AND ius.last_user_lookup IS NULL
    AND i.[name] IS NOT NULL
    AND i.index_id > 1
    AND t.is_ms_shipped = 0
    AND i.is_primary_key = 0
    AND i.is_hypothetical = 0
    AND i.is_disabled = 0
    ORDER BY SchemaName, TableName, IndexName;' + @CRLF;
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListUserTableSizesInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL',   -- N'ALL' for all
@ExcludeEmptyTables bit = 0,            -- 1 for yes
@IsOutputOrderedBySize bit = 0          -- 1 for yes
AS
BEGIN

-- Function:      Lists the size and number of rows for all or selected user tables
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ExcludeEmptyTables bit       -> 0 for list all, 1 for don't list empty objects
--                @IsOutputOrderedBySize bit    -> 0 for alphabetical, 1 for size descending
-- Action:        Lists the size and number of rows for all or selected user tables
-- Return:        Rowset containing SchemaName, TableName, TotalRows, TotalReservedMB, TotalUsedMB,
--                   TotalFreeMB in either alphabetical order or size descending order 
-- Refer to this video: https://youtu.be/mwOpnit0zqg
--
-- Test examples: 
/*

EXEC SDU_Tools.ListUserTableSizesInCurrentDatabase 
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ExcludeEmptyTables = 0,
     @IsOutputOrderedBySize = 1;

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = N'
SELECT s.[name] AS SchemaName,
       t.[name] AS TableName,
       p.rows AS TotalRows,
       CAST(ISNULL(SUM(au.total_pages), 0) * 8192.0 / 1024.0 / 1024.0 AS decimal(18,2)) AS TotalReservedMB,
       CAST(ISNULL(SUM(au.used_pages), 0) * 8192.0 / 1024.0 / 1024.0 AS decimal(18,2)) AS TotalUsedMB,
       CAST(ISNULL(SUM(au.total_pages - au.used_pages), 0) * 8192.0 / 1024.0 / 1024.0 AS decimal(18,2)) AS TotalFreeMB
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.[schema_id] = t.[schema_id] 
INNER JOIN sys.indexes AS i 
    ON t.[object_id] = i.[object_id]
INNER JOIN sys.partitions AS p 
    ON i.[object_id] = p.[object_id] AND i.index_id = p.index_id
INNER JOIN sys.allocation_units AS au 
    ON au.container_id = p.partition_id
WHERE t.is_ms_shipped = 0
AND t.[name] NOT LIKE ''dt%'' 
AND t.[name] <> ''sysdiagrams''' + @CRLF
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))' + @CRLF
      END 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))' + @CRLF
      END
    + N'GROUP BY s.[name], t.[name], p.rows' + @CRLF
    + CASE WHEN @ExcludeEmptyTables = 0
           THEN N''
           ELSE N'HAVING p.rows > 0' + @CRLF 
      END
    + CASE WHEN @IsOutputOrderedBySize = 0 
           THEN N'ORDER BY SchemaName, TableName;'
           ELSE N'ORDER BY TotalUsedMB DESC, SchemaName, TableName;'
      END;
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListUserTableAndIndexSizesInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',    -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL',     -- N'ALL' for all
@ExcludeEmptyIndexes bit = 0,             -- 1 for yes
@ExcludeTableStructure bit = 0,           -- 1 for yes
@IsOutputOrderedBySize bit = 0            -- 1 for yes
AS
BEGIN

-- Function:      Lists the size and number of rows for all or selected user tables and indexes
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ExcludeEmptyIndexes bit      -> 0 for list all, 1 for don't list empty objects
--                @ExcludeTableStructure bit    -> 0 for list all, 1 for don't list base table (clustered index or heap)
--                @IsOutputOrderedBySize bit    -> 0 for alphabetical, 1 for size descending
-- Action:        Lists the size and number of rows for all or selected user tables and indexes
-- Return:        Rowset containing SchemaName, TableName, IndexName, TotalRows, TotalReservedMB, 
--                TotalUsedMB, TotalFreeMB in either alphabetical order or size descending order 
-- Refer to this video: https://youtu.be/mwOpnit0zqg
--
-- Test examples: 
/*

EXEC SDU_Tools.ListUserTableAndIndexSizesInCurrentDatabase 
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ExcludeEmptyIndexes = 0,
	 @ExcludeTableStructure = 0,
     @IsOutputOrderedBySize = 0;

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = N'
SELECT s.[name] AS SchemaName,
       t.[name] AS TableName,
       i.[name] AS IndexName,
       p.rows AS TotalRows,
       CAST(ISNULL(SUM(au.total_pages), 0) * 8192.0 / 1024.0 / 1024.0 AS decimal(18,2)) AS TotalReservedMB,
       CAST(ISNULL(SUM(au.used_pages), 0) * 8192.0 / 1024.0 / 1024.0 AS decimal(18,2)) AS TotalUsedMB,
       CAST(ISNULL(SUM(au.total_pages - au.used_pages), 0) * 8192.0 / 1024.0 / 1024.0 AS decimal(18,2)) AS TotalFreeMB
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.[schema_id] = t.[schema_id] 
INNER JOIN sys.indexes AS i 
    ON t.[object_id] = i.[object_id]
INNER JOIN sys.partitions AS p 
    ON i.[object_id] = p.[object_id] AND i.index_id = p.index_id
INNER JOIN sys.allocation_units AS au 
    ON au.container_id = p.partition_id
WHERE t.is_ms_shipped = 0
AND t.[name] NOT LIKE ''dt%'' 
AND t.[name] <> ''sysdiagrams''' + @CRLF
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))' + @CRLF
      END 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))' + @CRLF
      END
    + CASE WHEN @ExcludeTableStructure = 0
           THEN N''
           ELSE N'    AND i.index_id > 1' + @CRLF
      END
    + N'GROUP BY s.[name], t.[name], i.[name], p.rows' + @CRLF
    + CASE WHEN @ExcludeEmptyIndexes = 0
           THEN N''
           ELSE N'HAVING p.rows > 0' + @CRLF 
      END
    + CASE WHEN @IsOutputOrderedBySize = 0 
           THEN N'ORDER BY SchemaName, TableName, IndexName;'
           ELSE N'ORDER BY TotalUsedMB DESC, SchemaName, TableName, IndexName;'
      END;
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListUseOfDeprecatedDataTypesInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL',   -- N'ALL' for all
@ColumnsToList nvarchar(max) = N'ALL'   -- N'ALL' for all
AS
BEGIN

-- Function:      Lists any use of deprecated data types
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
--                @ColumnsToList nvarchar(max)  -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists any use of deprecated data types (user tables only)
-- Return:        Rowset containing SchemaName, TableName, ColumnName, DataType, Suggested Alternate Type, and Change Script. 
--                Within each table, columns are listed in column ID order
-- Refer to this video: https://youtu.be/XaRtOR1m8QI
--
-- Test examples: 
/*

EXEC SDU_Tools.ListUseOfDeprecatedDataTypesInCurrentDatabase 
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ColumnsToList = N'ALL';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'   SELECT s.[name] AS SchemaName, 
           t.[name] AS TableName, 
           c.[name] AS ColumnName,
           typ.[name] + CASE WHEN typ.[name] IN (N''decimal'', N''numeric'')
                             THEN N''('' + CAST(c.precision AS nvarchar(20)) + N'', '' 
                                  + CAST(c.scale AS nvarchar(20)) + N'')''
                             WHEN typ.[name] IN (N''varchar'', N''nvarchar'', N''char'', N''nchar'', N''binary'', N''varbinary'')
                             THEN N''('' + CASE WHEN c.max_length < 0 
                                              THEN N''max'' 
                                                WHEN typ.[name] IN (N''nvarchar'', N''char'')
                                                THEN CAST(c.max_length / 2 AS nvarchar(20)) 
                                                ELSE CAST(c.max_length AS nvarchar(20)) 
                                         END + N'')''
                             WHEN typ.[name] IN (N''time'', N''datetime2'', N''datetimeoffset'')
                             THEN N''('' + CAST(c.scale AS nvarchar(20)) + N'')''
                             ELSE N''''
                        END AS DataType,
            CASE typ.[name] WHEN N''image'' THEN ''varbinary(max)''
                            WHEN N''text'' THEN ''varchar(max)''
                            WHEN N''ntext'' THEN ''nvarchar(max)''
            END AS SuggestedReplacementType,
            N''ALTER TABLE '' + QUOTENAME(s.[name]) + N''.'' + QUOTENAME(t.[name]) 
                + N'' ALTER COLUMN '' + QUOTENAME(c.[name]) + N'' ''
                + CASE typ.[name] WHEN N''image'' THEN ''varbinary(max)''
                            WHEN N''text'' THEN ''varchar(max)''
                            WHEN N''ntext'' THEN ''nvarchar(max)''
                  END
                + CASE WHEN c.is_nullable = 0 THEN N'' NOT NULL'' ELSE N'' NULL'' END
                + N'';'' AS ChangeScript
    FROM sys.schemas AS s
    INNER JOIN sys.tables AS t
        ON s.[schema_id] = t.[schema_id]
    INNER JOIN sys.columns AS c
        ON t.[object_id] = c.[object_id] 
    INNER JOIN sys.[types] AS typ 
        ON c.system_type_id = typ.system_type_id
        AND c.user_type_id = typ.user_type_id 
    WHERE t.[type] = N''U''
    AND typ.[name] IN (''image'', ''text'', ''ntext'')' + @CRLF
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @ColumnsToList = N'ALL' 
           THEN N''
           ELSE N'    AND c.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @ColumnsToList + ''', N'','', 1))'
      END + @CRLF 
    + N'    ORDER BY SchemaName, TableName, c.column_id;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.IsXActAbortON()
RETURNS bit
AS
BEGIN

-- Function:      Checks if XACT_ABORT is on
-- Parameters:    None
-- Action:        Checks if XACT_ABORT is on
-- Return:        bit
-- Refer to this video: https://youtu.be/Bx81-MTqr1k
-- 
-- Test examples: 
/*

SET XACT_ABORT OFF;
SELECT SDU_Tools.IsXActAbortON();
SET XACT_ABORT ON;
SELECT SDU_Tools.IsXActAbortON();
SET XACT_ABORT OFF;

*/
    RETURN CASE WHEN (16384 & @@OPTIONS) = 16384 
                THEN CAST(1 AS bit) 
                ELSE CAST(0 AS bit)
           END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.StartOfFinancialYear
(
    @DateWithinYear date,
    @FirstMonthOfFinancialYear int
 
)
RETURNS date
AS
BEGIN

-- Function:      Return date of beginnning of financial year
-- Parameters:    @DateWithinYear date (use GETDATE() or SYSDATETIME() for today)
--                @FirstMonthOfFinancialYear int
-- Action:        Calculates the first date of the financial year for any given date 
-- Return:        date
-- Refer to this video: https://youtu.be/wc8ZS_XPKZs
--
-- Test examples: 
/*

SELECT SDU_Tools.StartOfFinancialYear(SYSDATETIME(), 7);
SELECT SDU_Tools.StartOfFinancialYear(GETDATE(), 11);

*/
    RETURN CAST(CAST(YEAR(ISNULL(@DateWithinYear, SYSDATETIME())) 
                     - CASE WHEN MONTH(@DateWithinYear) < @FirstMonthOfFinancialYear 
                            THEN 1 
                            ELSE 0 
                       END AS varchar(4)) 
                + RIGHT('00' + CAST(@FirstMonthOfFinancialYear AS varchar(2)), 2)
                + '01' AS date);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.EndOfFinancialYear
(
    @DateWithinYear date,
    @FirstMonthOfFinancialYear int
 
)
RETURNS date
AS
BEGIN

-- Function:      Return last date of financial year
-- Parameters:    @DateWithinYear date (use GETDATE() or SYSDATETIME() for today)
--                @FirstMonthOfFinancialYear int
-- Action:        Calculates the last date of the financial year for any given date 
-- Return:        date
-- Refer to this video: https://youtu.be/wc8ZS_XPKZs
--
-- Test examples: 
/*

SELECT SDU_Tools.EndOfFinancialYear(SYSDATETIME(), 7);
SELECT SDU_Tools.EndOfFinancialYear(GETDATE(), 11);

*/
    RETURN DATEADD(day, -1, DATEADD(year, 1, SDU_Tools.StartOfFinancialYear(@DateWithinYear, @FirstMonthOfFinancialYear)));
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.CalculateAge
(
    @StartingDate date,
    @CalculationDate date
)
RETURNS int
AS
BEGIN

-- Function:      Return an age in years from a starting date to a calculation date
-- Parameters:    @StartingDate date -> when the calculation begins (often a date of birth)
--                @CalculationDate date -> when the age is calculated to (often the current date)
-- Action:        Return an age in years from a starting date to a calculation date 
-- Return:        int    (NULL if @StartingDate is later than @CalculationDate)
-- Refer to this video: https://youtu.be/4XTubsQKPlw
--
-- Test examples: 
/*

SELECT SDU_Tools.CalculateAge('1968-11-20', SYSDATETIME());
SELECT SDU_Tools.CalculateAge('1942-09-16', '2017-12-31');

*/
    RETURN CASE WHEN @CalculationDate >= @StartingDate
                THEN DATEDIFF(year, @StartingDate, @CalculationDate) 
                     - CASE WHEN DATEADD(day, DATEDIFF(day, @StartingDate, @CalculationDate), @StartingDate) 
                                 < DATEADD(year, DATEDIFF(year, @StartingDate, @CalculationDate), @StartingDate)
                            THEN 1
                            ELSE 0
                        END
            END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.IsLeapYear
(
    @YearNumber int
)
RETURNS bit
AS
BEGIN

-- Function:      Determines if a given year is a leap year
-- Parameters:    @YearNumber int -> year number to calculate from
-- Action:        Returns 1 (bit) if the year is a leap year, else 0 (bit)
-- Return:        bit 
-- Refer to this video: https://youtu.be/zVwRSJIYz2A
--
-- Test examples: 
/*

SELECT SDU_Tools.IsLeapYear(1901);
SELECT SDU_Tools.IsLeapYear(2000);
SELECT SDU_Tools.IsLeapYear(1900);

*/
    RETURN CASE DAY(DATEADD(day, -1, CAST(RIGHT('0000' + @YearNumber, 4) + '0301' AS date)))
           WHEN 29 THEN CAST(1 AS bit)
           ELSE CAST(0 AS bit)
           END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.PGObjectName(@SQLObjectName sysname)
RETURNS nvarchar(63)
AS 
BEGIN

-- Function:      Converts a SQL Server object name to a PostgreSQL object name
-- Parameters:    @SQLObjectName sysname
-- Action:        Converts a Pascal-cased or camel-cased SQL Server object name
--                to a name suitable for a database engine like PostgreSQL that
--                likes snake-cased names. Limits the identifier to 63 characters
--                and copes with a number of common abbreviations like ID that
--                would otherwise cause issues with the formation of the name.
-- Return:        varchar(63)
-- Refer to this video: https://youtu.be/2ZPa1dgOZew
--
-- Test examples: 
/*

SELECT SDU_Tools.PGObjectName(N'CustomerTradingName');
SELECT SDU_Tools.PGObjectName(N'AccountID');

*/
    RETURN SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                     SDU_Tools.SnakeCase(
                         SDU_Tools.SeparateByCase(@SQLObjectName, N' ')) COLLATE DATABASE_DEFAULT, 
                     N'i_d', N'id'), N'u_r_l', N'url'), N'b_i', N'bi'), N'f_k', N'fk'), N'd_f', N'df'), N'__', N'_'), N'__', N'_'), 1, 63);
END;
GO

------------------------------------------------------------------------------------

-- CREATE PROC SDU_Tools.ReadCSVFile (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------
GO

CREATE PROCEDURE SDU_Tools.UpdateStatisticsInCurrentDatabase
@SchemasToUpdate nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToUpdate nvarchar(max) = N'ALL',   -- N'ALL' for all
@SamplePercentage int = 100
AS
BEGIN

-- Function:      UpdateStatistics
-- Parameters:    @SchemasToUpdate nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to process
--                @TablesToUpdate nvarchar(max)   -> 'ALL' or comma-delimited list of tables to process
--                @SamplePercentage int           -> default is 100 meaning FULLSCAN or percentage for sample only
--                                                -> if @SamplePercentage < 0 or > 100 then FULLSCAN performed
-- Action:        Update statistics for selected set of user tables (excluding Microsoft-shipped tables)
--                Prints actions as it executes them
-- Return:        Nil
-- Refer to this video: https://youtu.be/MW8pFHb4DhQ
--
-- Test examples: 
/*

EXEC SDU_Tools.UpdateStatisticsInCurrentDatabase 
     @SchemasToUpdate = N'ALL', 
     @TablesToUpdate = N'Cities,People', 
     @SamplePercentage = 30;

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @SchemaName sysname;
    DECLARE @TableName sysname;
    DECLARE @SQLCommand nvarchar(max);
    DECLARE @TableCounter int;

    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);
    
    DECLARE @TablesToProcess TABLE
    (
        TableToProcessID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        SchemaName sysname NOT NULL,
        TableName sysname NOT NULL
    );
    
    SET @SQLCommand = N'
SELECT s.[name] AS SchemaName,
       t.[name] AS TableName   
FROM sys.tables AS t 
INNER JOIN sys.schemas AS s
ON s.schema_id = t.schema_id 
WHERE t.is_ms_shipped = 0
AND t.[type] = N''U'''
    + CASE WHEN @SchemasToUpdate = N'ALL' 
           THEN N''
           ELSE N'AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToUpdate + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToUpdate = N'ALL' 
           THEN N''
           ELSE N'AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToUpdate + ''', N'','', 1))'
      END + @CRLF 
    + N'ORDER BY SchemaName, TableName;';
    
    INSERT @TablesToProcess (SchemaName, TableName) 
    EXEC (@SQLCommand);
    
    SET @TableCounter = 1;

    WHILE @TableCounter <= (SELECT MAX(TableToProcessID) FROM @TablesToProcess)
    BEGIN
        SELECT @SchemaName = ttp.SchemaName,
               @TableName = ttp.TableName 
        FROM @TablesToProcess AS ttp
        WHERE ttp.TableToProcessID = @TableCounter;
            
       SET @SQLCommand = N'UPDATE STATISTICS '  
                       + QUOTENAME(@SchemaName) 
                       + N'.' 
                       + QUOTENAME(@TableName) 
                       + CASE WHEN @SamplePercentage > 0 AND @SamplePercentage < 100 
                              THEN N' WITH SAMPLE ' + CAST(@SamplePercentage AS nvarchar(20)) + N' PERCENT;'
                              ELSE N' WITH FULLSCAN;' 
                         END;
    
       PRINT @SQLCommand;
       EXEC sp_executesql @SQLCommand;
    
       SET @TableCounter = @TableCounter + 1;
    END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.CountWords
(
    @InputString nvarchar(max)
)
RETURNS int
AS
BEGIN
 
-- Function:      Counts words in a string
-- Parameters:    @InputString nvarchar(max)
-- Action:        Counts words in a string, using English syntax
-- Return:        int as number of words
-- Refer to this video: https://youtu.be/H_BUVEqZy0c
--
-- Test examples:
/*
 
SELECT SDU_Tools.CountWords('Hello  there');
SELECT SDU_Tools.CountWords('Hello, there: now');
SELECT SDU_Tools.CountWords('words;words;words');
SELECT SDU_Tools.CountWords('Jane Hyde-Smythe');
SELECT SDU_Tools.CountWords('Jane D''Angelo');
 
*/
 
    DECLARE @WordCount int = 0;
    DECLARE @InAWord bit = 0;
    DECLARE @Counter int = 1;
    DECLARE @NextCharacter nchar(1);
 
    WHILE @Counter <= LEN(@InputString)
    BEGIN
        SET @NextCharacter = UPPER(SUBSTRING(@InputString, @Counter, 1));
        IF @NextCharacter BETWEEN N'A' AND N'Z' OR @NextCharacter BETWEEN N'0' AND N'9' OR @NextCharacter = N'-' OR @NextCharacter = N''''
        BEGIN -- character in a word
            IF @InAWord = 0
            BEGIN
                SET @InAWord = 1;
                SET @WordCount = @WordCount + 1;
            END;
        END ELSE BEGIN -- character not in a word
            SET @InAWord = 0;
        END;
        SET @Counter = @Counter + 1;
    END;
 
    RETURN @WordCount;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.Sleep
@NumberOfSeconds int
AS
BEGIN

-- Function:      Sleep for a number of seconds 
-- Parameters:    @NumberOfSeconds int -> The time to sleep for
-- Action:        Sleeps for the given number of seconds
-- Return:        Nil
-- Refer to this video: https://youtu.be/csUCf2GWGec
--
-- Test examples: 
/*

EXEC SDU_Tools.Sleep 10;

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Duration varchar(8) = SDU_Tools.SecondsToDuration(@NumberOfSeconds);
    
    WAITFOR DELAY @Duration;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.[Translate]
(
    @InputString nvarchar(max),
    @CharactersToReplace nvarchar(max),
    @ReplacementCharacters nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
 
-- Function:      Translate one series of characters to another series of characters
-- Parameters:    @InputString varchar(max) - string to process
--                @CharactersToReplace varchar(max) - list of characters to be replaced
--                @ReplacementCharacters varchar(max) - list of replacement characters
-- Action:        Replace a set of characters in a string with a replacement set of characters
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/k8zbN1f8fgI
--
-- Test examples:
/*
 
SELECT SDU_Tools.Translate(N'[08] 7777,9876', N'[],', N'()-');
 
*/
    DECLARE @ReturnValue nvarchar(max) = @InputString;
    DECLARE @Counter int = 1;
   
    WHILE @Counter <= LEN(@CharactersToReplace)
    BEGIN
        SET @ReturnValue = REPLACE(@ReturnValue, SUBSTRING(@CharactersToReplace, @Counter, 1), SUBSTRING(@ReplacementCharacters, @Counter, 1));
        SET @Counter = @Counter + 1;
    END;
   
    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DateDiffNoWeekends
(
    @FromDate date,
    @ToDate date
)
RETURNS int
AS
BEGIN

-- Function:      Determines the number of days (Monday to Friday) between two dates
-- Parameters:    @FromDate date -> date to start calculating from
--                @ToDate date -> date to calculate to
-- Action:        Determines the number of days (Monday to Friday) between two dates
-- Return:        int number of days
-- Refer to this video: https://youtu.be/BhPtrYEWT6I
--
-- Test examples: 
/*

SELECT SDU_Tools.DateDiffNoWeekends('20170101', '20170131');
SELECT SDU_Tools.DateDiffNoWeekends('20170101', '20170101');
SELECT SDU_Tools.DateDiffNoWeekends('20170131', '20170101');

*/
    DECLARE @FullWeeks int = DATEDIFF(day, @FromDate, @ToDate) / 7;
    DECLARE @Weekdays int = @FullWeeks * 5;
    DECLARE @StartTestDate date = DATEADD(day, @FullWeeks * 7, @FromDate);

    WHILE @StartTestDate < @ToDate 
    BEGIN
        IF DATEPART(weekday, @StartTestDate) NOT IN (DATEPART(weekday, '19000107'), DATEPART(weekday, '19000106'))
        BEGIN
			SET @Weekdays = @Weekdays + 1;
		END;
        SET @StartTestDate = DATEADD(day, 1, @StartTestDate);
    END;

	RETURN @Weekdays;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.InvertString
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Inverts a string
-- Parameters:    @InputString nvarchar(max) - String to be processed (unicode or single byte)
-- Action:        Inverts a string by using USD Encoding as per https://en.wikipedia.org/wiki/Transformation_of_text#Upside-down_text
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/GhNOr0p1-lM
--
-- Test examples: 
/*

SELECT SDU_Tools.InvertString('Hello There');
SELECT SDU_Tools.InvertString('Can you read this?');
SELECT SDU_Tools.InvertString('Some punctuation, also works !');
SELECT REVERSE(SDU_Tools.InvertString('Hello There'));

*/

    DECLARE @Counter int = 1;
    DECLARE @ReturnValue nvarchar(max) = '';
    DECLARE @Character char(1);
    DECLARE @StringToProcess nvarchar(max) = REVERSE(@InputString);

    DECLARE @USDEncodings TABLE
    (
        ASCIIValue int NOT NULL PRIMARY KEY,
        ReplacementValue int NOT NULL
    );
    INSERT INTO @USDEncodings (ASCIIValue, ReplacementValue)
    VALUES (ASCII('a'), 0x250), (ASCII('b'), 0x71), (ASCII('c'), 0x254), (ASCII('d'), 0x70), (ASCII('e'), 0x1DD),
           (ASCII('f'), 0x25F), (ASCII('g'), 0x253), (ASCII('h'), 0x265), (ASCII('i'), 0x131), (ASCII('j'), 0x27E),
           (ASCII('k'), 0x29E), (ASCII('l'), 0x6C), (ASCII('m'), 0x26F), (ASCII('n'), 0x75), (ASCII('o'), 0x6F),
           (ASCII('p'), 0x64), (ASCII('q'), 0x62), (ASCII('r'), 0x279), (ASCII('s'), 0x73), (ASCII('t'), 0x287),
           (ASCII('u'), 0x6E), (ASCII('v'), 0x28C), (ASCII('w'), 0x28D), (ASCII('x'), 0x78), (ASCII('y'), 0x28E), 
           (ASCII('z'), 0x7A),
           (ASCII('A'), 0x2200), (ASCII('B'), 0x10412), (ASCII('C'), 0x186), (ASCII('D'), 0x15E1), (ASCII('E'), 0x18E),
           (ASCII('F'), 0x2132), (ASCII('G'), 0x2141), (ASCII('H'), 0x48), (ASCII('I'), 0x49), (ASCII('J'), 0x17F),
           (ASCII('K'), 0x22CA), (ASCII('L'), 0x2142), (ASCII('M'), 0x57), (ASCII('N'), 0x4E), (ASCII('O'), 0x4F),
           (ASCII('P'), 0x500), (ASCII('Q'), 0x38C), (ASCII('R'), 0x1D1A), (ASCII('S'), 0x53), (ASCII('T'), 0x22A5),
           (ASCII('U'), 0x2229), (ASCII('V'), 0x39B), (ASCII('W'), 0x4D), (ASCII('X'), 0x58), (ASCII('Y'), 0x2144), 
           (ASCII('Z'), 0x5A),
           (ASCII('0'), 0x30), (ASCII('1'), 0x21C2), (ASCII('2'), 0x218A), (ASCII('3'), 0x218B), (ASCII('4'), 0x7C8),
           (ASCII('5'), 0x3DA), (ASCII('6'), 0x39), (ASCII('7'), 0x3125), (ASCII('8'), 0x38), (ASCII('9'), 0x36),
           (ASCII('&'), 0x214B), (ASCII('_'), 0x203E), (ASCII('?'), 0xBF), (ASCII('!'), 0xA1), (ASCII('"'), 0x201E),
           (ASCII(''''), 0x2C), (ASCII('.'), 0x2D9), (ASCII(','), 0x27), (ASCII(';'), 0x61B);

    WHILE @Counter <= LEN(@StringToProcess)
    BEGIN
        SET @Character = SUBSTRING(@StringToProcess, @Counter, 1); 
        SET @ReturnValue = @ReturnValue
                         + ISNULL((SELECT NCHAR(ReplacementValue) FROM @USDEncodings WHERE ASCIIValue = ASCII(@Character)), @Character);
        SET @Counter = @Counter + 1;
    END;

    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.TableOfNumbers
(
    @StartValue int,
    @NumberRequired int
)
RETURNS TABLE
AS
-- Function:      Returns a table of numbers
-- Parameters:    @StartValue int => first value to return
--                @NumberRequired int => number of numbers to return
-- Action:        Returns a table of numbers with a specified number of rows
--                from the specified starting value
-- Return:        Rowset with Number as an integer
-- Refer to this video: https://youtu.be/Ox-Ig043oeg
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.TableOfNumbers(12, 90);
SELECT * FROM SDU_Tools.TableOfNumbers(12, 5000);

*/
RETURN 
(
    WITH Tens(NumberValue) 
    AS 
    (
        SELECT *
        FROM (VALUES (1), (1), (1), (1), (1),
                     (1), (1), (1), (1), (1)) AS Ones(NumberValue)
    ),
    Thousands(NumberValue) 
    AS 
    (
        SELECT 1 
        FROM Tens AS Units 
        CROSS JOIN Tens AS Squared
        CROSS JOIN Tens AS Cubed   
    ),
    ThousandMillions(NumberValue) 
    AS 
    (
        SELECT 1 
        FROM Thousands AS Units
        CROSS JOIN Thousands AS Squared 
        CROSS JOIN Thousands AS Cubed
    )
    SELECT TOP(@NumberRequired) 
           ROW_NUMBER() OVER (ORDER BY(SELECT 1)) + @StartValue - 1  AS Number
    FROM ThousandMillions AS Units 
    CROSS JOIN ThousandMillions AS Squared 
    CROSS JOIN ThousandMillions AS Cubed
);
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ExtractTrimmedWords
(
    @InputValue varchar(max)
)
RETURNS @TrimmedWords TABLE
(
    WordNumber int,
    TrimmedWord varchar(max)
)
AS
-- Function:      Extracts words from a string and trims them
-- Parameters:    @InputValue varchar(max) -> the string to extract words from
-- Action:        Returns an ordered table of trimmed words extracted from the string
-- Return:        Rowset with WordNumber and TrimmedWord
-- Refer to this video: https://youtu.be/wkSF0VWZwOs
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.ExtractTrimmedWords('fre john   C10');

*/
BEGIN
    DECLARE @Counter int = 1;
    DECLARE @StartOfWord int = 0;
    DECLARE @InAWord bit = 0;
    DECLARE @Character char(1);
    DECLARE @WordCounter int = 0;
 
    WHILE @Counter <= LEN(@InputValue)
    BEGIN
        SET @Character = SUBSTRING(@InputValue, @Counter, 1);
        IF @Character IN (' ', CHAR(9), CHAR(13), CHAR(10)) -- whitespace
        BEGIN
            IF @InAWord <> 0
            BEGIN -- end of a word
                SET @WordCounter = @WordCounter + 1;
                INSERT @TrimmedWords (WordNumber, TrimmedWord) VALUES (@WordCounter, SUBSTRING(@InputValue, @StartOfWord, @Counter - @StartOfWord));
            END;
            SET @InAWord = 0;
        END ELSE BEGIN
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @StartOfWord = @Counter;
            END ELSE BEGIN
                IF @Counter = LEN(@InputValue) -- last word in string
                BEGIN
                    SET @WordCounter = @WordCounter + 1;
                    INSERT @TrimmedWords (WordNumber, TrimmedWord) VALUES (@WordCounter, SUBSTRING(@InputValue, @StartOfWord, @Counter - @StartOfWord + 1));
                END;
            END;
            SET @InAWord = 1;
        END;      
        SET @Counter += 1;
    END;
   
    RETURN;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ExtractTrigrams
(
    @InputValue varchar(max)
)
RETURNS TABLE
AS
-- Function:      Extracts all trigrams (up to 3 character substrings) from a string
-- Parameters:    @InputValue varchar(max) -> the string to extract the trigrams from
-- Action:        Returns an ordered table of distinct trigrams extracted from the string
-- Return:        Rowset with TrigramNumber and Trigram
-- Refer to this video: https://youtu.be/Bx8tijrm84E
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.ExtractTrigrams('1846 Hudecova Crescent');

*/
RETURN (
            WITH Numbers(Number) AS
            (
              SELECT 1 
              UNION ALL
              SELECT Number + 1
              FROM Numbers
              WHERE Number < (LEN(@InputValue) - 2)
            ),
            DistinctTrigrams AS
            (
                SELECT DISTINCT LTRIM(RTRIM(LOWER(SUBSTRING(@InputValue, Number, 3)))) AS Trigram
                FROM Numbers
            )
            SELECT ROW_NUMBER() OVER (ORDER BY Trigram) AS TrigramNumber, Trigram 
            FROM DistinctTrigrams
       );
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListIncomingForeignKeysInCurrentDatabase
@ReferencedSchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@ReferencedTablesToList nvarchar(max) = N'ALL'    -- N'ALL' for all
AS
BEGIN

-- Function:      ListIncomingForeignKeys
-- Parameters:    @ReferencedSchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @ReferencedTablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List foreign keys with column lists filtered by the target schemas and tables
-- Return:        Rowset of foreign keys
-- Refer to this video: https://youtu.be/NnkAcm_b9ks
--
-- Test examples: 
/*

EXEC SDU_Tools.ListIncomingForeignKeysInCurrentDatabase 
     @ReferencedSchemasToList = N'Application,Sales', 
     @ReferencedTablesToList = N'Cities,Orders'; 

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'WITH DeclaredForeignKeys
AS
(
       SELECT ss.[name] AS SourceSchemaName, st.[name] AS SourceTableName, 
              fk.[name] AS ForeignKeyName,
              LEFT(fkcl.ColumnList, LEN(fkcl.ColumnList) - 1) AS SourceColumnList,
              rs.[name] AS ReferencedSchemaName, rt.[name] AS ReferencedTableName,
              LEFT(rtcl.ColumnList, LEN(rtcl.ColumnList) - 1) AS ReferencedColumnList,
              fk.is_not_trusted AS IsNotTrusted,
             fk.is_disabled AS IsDisabled
       FROM sys.foreign_keys AS fk
       INNER JOIN sys.tables AS st 
       ON st.object_id = fk.parent_object_id
       INNER JOIN sys.schemas AS ss
       ON ss.schema_id = st.schema_id
       INNER JOIN sys.tables AS rt
       ON rt.object_id = fk.referenced_object_id
       INNER JOIN sys.schemas AS rs
       ON rs.schema_id = rt.schema_id 
       CROSS APPLY 
       (
           SELECT c.[name] + N'','' 
           FROM sys.foreign_key_columns AS fkc 
           INNER JOIN sys.columns AS c 
           ON fkc.parent_object_id = c.object_id 
           AND fkc.parent_column_id = c.column_id
           WHERE fkc.constraint_object_id = fk.object_id 
           ORDER BY fkc.constraint_column_id
           FOR XML PATH ('''')
       ) AS fkcl (ColumnList)
       CROSS APPLY 
       (
           SELECT c.[name] + N'','' 
           FROM sys.foreign_key_columns AS fkc 
           INNER JOIN sys.columns AS c 
           ON fkc.referenced_object_id = c.object_id 
           AND fkc.referenced_column_id = c.column_id
           WHERE fkc.constraint_object_id = fk.object_id 
           ORDER BY fkc.constraint_column_id
           FOR XML PATH ('''')
       ) AS rtcl (ColumnList)
       WHERE st.is_ms_shipped = 0
       AND st.[name] <> N''sysdiagrams''
)
SELECT dfk.SourceSchemaName, dfk.SourceTableName, dfk.ForeignKeyName, dfk.SourceColumnList,
       dfk.ReferencedSchemaName, dfk.ReferencedTableName, dfk.ReferencedColumnList,
       dfk.IsNotTrusted, dfk.IsDisabled
FROM DeclaredForeignKeys AS dfk 
WHERE 1 = 1 '
    + CASE WHEN @ReferencedSchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND dfk.ReferencedSchemaName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @ReferencedSchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @ReferencedTablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND dfk.ReferencedTableName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @ReferencedTablesToList + ''', N'','', 1))'
      END + @CRLF + N'
ORDER BY dfk.SourceSchemaName, dfk.SourceTableName, dfk.ForeignKeyName;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ScriptTableInCurrentDatabase
@ExistingSchemaName sysname,
@ExistingTableName sysname,
@OutputSchemaName sysname = @ExistingSchemaName,
@OutputTableName sysname = @ExistingTableName, 
@OutputDataCompressionStyle nvarchar(10) = N'SAME',  -- SAME, NONE, ROW, PAGE
@AreCollationsScripted bit = 0,
@AreUsingBaseTypes bit = 1,
@AreForcingAnsiNulls bit = 1,
@AreForcingAnsiPadding bit = 1,
@ColumnIndentSize int = 4,
@ScriptIndentSize int = 0,
@TableScript nvarchar(max) OUTPUT
AS
BEGIN
/* 

-- Function:      ScriptTable
-- Parameters:    @ExistingSchemaName sysname              -> Schema name for the table to be scripted
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
-- Refer to this video: https://youtu.be/U62ACZQUDk4
--
-- Test examples: 

SET NOCOUNT ON;

DECLARE @Script nvarchar(max);

EXEC SDU_Tools.ScriptTableInCurrentDatabase 
     @ExistingSchemaName = N'Sales'
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

*/

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);
    DECLARE @ReturnValue nvarchar(max) = N'';
    DECLARE @ReturnedData TABLE
    (
        ReturnedData nvarchar(max)
    );

    DECLARE @SQL nvarchar(max);
    DECLARE @OutputColumnIndentSize int = COALESCE(@ColumnIndentSize, 4);
    DECLARE @OutputScriptIndentSize int = COALESCE(@ScriptIndentSize, 0);

    IF @OutputColumnIndentSize < 2 SET @OutputColumnIndentSize = 2;
    IF @OutputScriptIndentSize < 0 SET @OutputScriptIndentSize = 0;
    
    IF @OutputDataCompressionStyle = N'SAME' 
    BEGIN
        SET @SQL = N'SELECT TOP(1) p.data_compression_desc' + @CRLF 
                 + N'FROM sys.partitions AS p' + @CRLF 
                 + N'INNER JOIN sys.tables AS t ON t.object_id = p.object_id' + @CRLF 
                 + N'INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id' + @CRLF 
                 + N'WHERE p.partition_number = 1' + @CRLF 
                 + N'AND p.index_id IN (0, 1)' + @CRLF 
                 + N'AND s.[name] = ''' + @ExistingSchemaName + N'''' + @CRLF  
                 + N'AND t.[name] = ''' + @ExistingTableName + N''';';
        
        INSERT @ReturnedData (ReturnedData)
        EXEC (@SQL);

        SET @OutputDataCompressionStyle = COALESCE((SELECT TOP(1) ReturnedData FROM @ReturnedData), 'NONE');
        DELETE @ReturnedData;
    END;

    IF @OutputDataCompressionStyle NOT IN (N'NONE', N'ROW', N'PAGE')
    BEGIN
        SET @OutputDataCompressionStyle = N'NONE';
    END;

    SET @SQL = N'DECLARE @TableScript nvarchar(max) = N'''';' + @CRLF
             + N'DECLARE @IsFirstColumn bit = 1;' + @CRLF 
             + N'DECLARE @IsFirstKeyColumn bit = 1;' + @CRLF 
             + N'DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);' + @CRLF
             + N'DECLARE @ScriptIndent nvarchar(max) = N''' + REPLICATE(N' ', @OutputScriptIndentSize) + N''';' + @CRLF 
             + N'DECLARE @ColumnLeadIn nvarchar(max) = N''' + REPLICATE(N' ', @OutputColumnIndentSize - 2) + N', ' + N''';' + @CRLF 
             + N'DECLARE @FirstColumnLeadIn nvarchar(max) = N''' + REPLICATE(N' ', @OutputColumnIndentSize - 2) + N'  ' + N''';' + @CRLF
             + N'DECLARE @ColumnName sysname;' + @CRLF 
             + N'DECLARE @DataType nvarchar(max);' + @CRLF 
             + N'DECLARE @ColumnDefinition nvarchar(max);' + @CRLF 
             + N'DECLARE @IsPersisted bit;' + @CRLF 
             + N'DECLARE @IsNullable bit;' + @CRLF 
             + N'DECLARE @CollationName sysname;' + @CRLF
             + N'DECLARE @PrimaryKeyName sysname;' + @CRLF 
             + N'DECLARE @DirectionModifier nvarchar(10);' + @CRLF + @CRLF;
    SET @SQL = @SQL 
             + N'IF EXISTS (SELECT 1 FROM sys.tables AS t' + @CRLF
             + N'                    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id' + @CRLF
             + N'                    WHERE t.[name] = N''' + @ExistingTableName + N'''' + @CRLF
             + N'                    AND s.[name] = N''' + @ExistingSchemaName + N''')' + @CRLF 
             + N'BEGIN' + @CRLF
             + N'    SET @TableScript = ' + CASE WHEN @AreForcingAnsiNulls <> 0 
                                                 THEN N'@ScriptIndent + N''SET ANSI_NULLS ON;'' + @CRLF + @CRLF' + @CRLF + N'                     + '      
                                                 ELSE N'' 
                                            END
                                          + CASE WHEN @AreForcingAnsiPadding <> 0 
                                                 THEN N'@ScriptIndent + N''SET ANSI_PADDING ON;'' + @CRLF + @CRLF' + @CRLF + N'                     + '      
                                                 ELSE N'' 
                                            END
             + N'@ScriptIndent + N''' + + N'CREATE TABLE ' + QUOTENAME(@OutputSchemaName) + N'.' + QUOTENAME(@OutputTableName) + N''' + @CRLF' + @CRLF
             + N'                     + @ScriptIndent + N''('' + @CRLF;' + @CRLF 
             + N'    DECLARE ColumnList CURSOR FAST_FORWARD READ_ONLY' + @CRLF 
             + N'    FOR' + @CRLF;
    SET @SQL = @SQL 
             + N'    SELECT c.[name] AS ColumnName' + @CRLF
             + N'         , typ.[name] + CASE WHEN typ.[name] IN (N''decimal'', N''numeric'')' + @CRLF 
             + N'                             THEN N''('' + CAST(c.precision AS nvarchar(20)) + N'', ''' + @CRLF 
             + N'                                  + CAST(c.scale AS nvarchar(20)) + N'')''' + @CRLF 
             + N'                             WHEN typ.[name] IN (N''varchar'', N''nvarchar'', N''char'', N''nchar'', N''varbinary'', N''binary'')' + @CRLF 
             + N'                             THEN N''('' + CASE WHEN c.max_length < 0' + @CRLF 
             + N'                                                THEN N''max''' + @CRLF
             + N'                                                ELSE CAST(CASE WHEN typ.[name] IN (N''nvarchar'', N''nchar'')' + @CRLF 
             + N'                                                               THEN c.max_length / 2' + @CRLF 
             + N'                                                               ELSE c.max_length' + @CRLF 
             + N'                                                          END AS nvarchar(20))' + @CRLF 
             + N'                                           END + N'')''' + @CRLF 
             + N'                             WHEN typ.[name] IN (N''time'', N''datetime2'', N''datetimeoffset'')' + @CRLF 
             + N'                             THEN N''('' + CAST(c.scale AS nvarchar(20)) + N'')''' + @CRLF 
             + N'                             ELSE N''''' + @CRLF 
             + N'                        END AS DataType' + @CRLF  
             + N'        , c.is_nullable AS IsNullable' + @CRLF 
             + N'        , ' + CASE WHEN @AreCollationsScripted <> 0 THEN N'c.collation_name' ELSE N'NULL' END + N' AS CollationName' + @CRLF
             + N'        , cc.definition AS ColumnDefinition' + @CRLF
             + N'        , cc.is_persisted AS IsPersisted' + @CRLF 
    SET @SQL = @SQL 
             + N'    FROM sys.tables AS t' + @CRLF 
             + N'    INNER JOIN sys.columns AS c ON c.object_id = t.object_id' + @CRLF  
             + N'    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id' + @CRLF 
             + N'    INNER JOIN sys.types AS typ ON c.system_type_id = typ.system_type_id AND c.user_type_id = typ.' 
               + CASE WHEN @AreUsingBaseTypes <> 0 THEN N'system_type_id' ELSE N'user_type_id' END + @CRLF 
             + N'    LEFT OUTER JOIN sys.computed_columns AS cc ON cc.object_id = c.object_id AND cc.column_id = c.column_id' + @CRLF 
             + N'    WHERE s.[name] = N''' + @ExistingSchemaName + N'''' + @CRLF 
             + N'    AND t.[name] = N''' + @ExistingTableName + N'''' + @CRLF 
             + N'    AND t.[type] = N''U''' + @CRLF 
             + N'    ORDER BY c.column_id;' + @CRLF + @CRLF;
    SET @SQL = @SQL 
             + N'    OPEN ColumnList;' + @CRLF + @CRLF 
             + N'    FETCH NEXT FROM ColumnList INTO @ColumnName, @DataType, @IsNullable, @CollationName, @ColumnDefinition, @IsPersisted;' + @CRLF 
             + N'    WHILE @@FETCH_STATUS = 0' + @CRLF 
             + N'    BEGIN' + @CRLF 
             + N'        SET @TableScript = @TableScript + @ScriptIndent + CASE WHEN @IsFirstColumn <> 0 THEN @FirstColumnLeadIn ELSE @ColumnLeadIn END' + @CRLF
             + N'                         + QUOTENAME(@ColumnName) + N'' '' + CASE WHEN @ColumnDefinition IS NOT NULL' + @CRLF 
             + N'                                                                  THEN N''AS '' + @ColumnDefinition' + @CRLF 
             + N'                                                                       + CASE WHEN @IsPersisted <> 0' + @CRLF 
             + N'                                                                              THEN N'' PERSISTED''' + @CRLF 
             + N'                                                                              ELSE N''''' + @CRLF 
             + N'                                                                         END' + @CRLF 
             + N'                                                                  ELSE @DataType' + @CRLF 
             + N'                                                                       + COALESCE(N'' COLLATE '' + @CollationName, N'''')' + @CRLF 
             + N'                                                                       + CASE WHEN @IsNullable <> 0 THEN N'' NULL'' ELSE N'' NOT NULL'' END' + @CRLF 
             + N'                                                             END + @CRLF' + @CRLF 
             + N'        SET @IsFirstColumn = 0;' + @CRLF
             + N'        FETCH NEXT FROM ColumnList INTO @ColumnName, @DataType, @IsNullable, @CollationName, @ColumnDefinition, @IsPersisted;' + @CRLF 
             + N'    END;' + @CRLF + @CRLF 
             + N'    CLOSE ColumnList;' + @CRLF
             + N'    DEALLOCATE ColumnList;' + @CRLF + @CRLF;
    SET @SQL = @SQL 
             + N'    DECLARE KeyColumnList CURSOR FAST_FORWARD READ_ONLY' + @CRLF 
             + N'    FOR' + @CRLF 
             + N'    SELECT kc.[name] AS PrimaryKeyName' + @CRLF 
             + N'         , c.[name] AS ColumnName' + @CRLF 
             + N'         , CASE WHEN ic.is_descending_key <> 0 THEN N'' DESC'' ELSE N'''' END AS DirectionModifier' + @CRLF 
             + N'    FROM sys.key_constraints AS kc' + @CRLF 
             + N'    INNER JOIN sys.indexes AS i ON i.object_id = kc.parent_object_id AND i.is_primary_key <> 0' + @CRLF 
             + N'    INNER JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id' + @CRLF  
             + N'    INNER JOIN sys.tables AS t ON t.object_id = kc.parent_object_id' + @CRLF  
             + N'    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id' + @CRLF 
             + N'    INNER JOIN sys.columns AS c ON c.object_id = t.object_id AND c.column_id = ic.column_id' + @CRLF  
             + N'    WHERE kc.[type] = N''PK''' + @CRLF 
             + N'    AND s.[name] = N''' + @ExistingSchemaName + N'''' + @CRLF  
             + N'    AND t.[name] = N''' + @ExistingTableName + N'''' + @CRLF 
             + N'    ORDER BY ic.index_column_id;' + @CRLF;
    SET @SQL = @SQL 
             + N'    OPEN KeyColumnList;' + @CRLF + @CRLF 
             + N'    FETCH NEXT FROM KeyColumnList INTO @PrimaryKeyName, @ColumnName, @DirectionModifier;' + @CRLF 
             + N'    WHILE @@FETCH_STATUS = 0' + @CRLF 
             + N'    BEGIN' + @CRLF 
             + N'        IF @IsFirstKeyColumn <> 0' + @CRLF 
             + N'        BEGIN' + @CRLF 
             + N'            SET @TableScript = @TableScript + @ScriptIndent + @ColumnLeadIn + N''CONSTRAINT '' + @PrimaryKeyName + N'' PRIMARY KEY'' + @CRLF' + @CRLF 
             + N'                             + @ScriptIndent + @FirstColumnLeadIn + N''('' + @CRLF' + @CRLF 
             + N'                             + @ScriptIndent + @FirstColumnLeadIn + @FirstColumnLeadIn + @ColumnName + @DirectionModifier + @CRLF' + @CRLF 
             + N'        END ELSE BEGIN' + @CRLF 
             + N'            SET @TableScript = @TableScript + @ScriptIndent + @FirstColumnLeadIn + @ColumnLeadIn + @ColumnName + @DirectionModifier + @CRLF' + @CRLF               
             + N'        END' + @CRLF
             + N'        SET @IsFirstKeyColumn = 0;' + @CRLF 
             + N'        FETCH NEXT FROM KeyColumnList INTO @PrimaryKeyName, @ColumnName, @DirectionModifier;' + @CRLF 
             + N'    END;' + @CRLF 
             + N'    CLOSE KeyColumnList;' + @CRLF
             + N'    DEALLOCATE KeyColumnList;' + @CRLF + @CRLF;
    SET @SQL = @SQL 
             + N'    IF @IsFirstKeyColumn = 0' + @CRLF 
             + N'    BEGIN' + @CRLF 
             + N'        SET @TableScript = @TableScript + @ScriptIndent + @FirstColumnLeadIn + N'')'' + @CRLF;' + @CRLF
             + N'    END;' + @CRLF + @CRLF 
             + N'    SET @TableScript = @TableScript + @ScriptIndent + N'')'' + @CRLF' + @CRLF 
             + N'                     + @ScriptIndent + N''WITH (DATA_COMPRESSION = ' + @OutputDataCompressionStyle + N');'' + @CRLF' + @CRLF
             + N'END;' + @CRLF + @CRLF
             + N'SELECT @TableScript;' + @CRLF  

    INSERT @ReturnedData (ReturnedData)
    EXEC (@SQL);

    SET @TableScript = (SELECT TOP(1) ReturnedData FROM @ReturnedData);
END;
GO
 
------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.SetAnsiNullsOnForTableInCurrentDatabase
@ExistingSchemaName sysname,
@ExistingTableName sysname,
@IHaveABackUp bit = 0,
@WorkingTableName sysname = NULL
AS
BEGIN
/* 

-- Function:      SetAnsiNullsOnForTable
-- Parameters:    @ExistingSchemaName sysname              -> Schema name for the table to be scripted
--                @ExistingTableName sysname               -> Table name for the table to be scripted
--                @IHaveABackup bit                        -> Ensure you have a backup before running this command as it could be destructive
--                @workingTableName sysname                -> Temporary working table name that can be used. Default is table name with ANSI_NULLS suffix
-- Action:        Changes the ANSI Nulls setting for a table to ON
-- Return:        No rows returned
-- Refer to this video: https://youtu.be/dQGBjchJYzc
--
-- Test examples: 

SET ANSI_NULLS OFF;

CREATE TABLE dbo.TestTable
(
    TestTableID int IDENTITY(1,1) PRIMARY KEY,
    TestTableDescription varchar(50)
);
GO

SELECT * FROM sys.tables WHERE [name] = N'TestTable';
GO

EXEC SDU_Tools.SetAnsiNullsOnForTableInCurrentDatabase 
       @ExistingSchemaName = 'dbo'
     , @ExistingTableName = 'TestTable'
     , @IHaveABackUp = 1;
GO

SELECT * FROM sys.tables WHERE [name] = N'TestTable';
GO

DROP TABLE dbo.TestTable;
GO

*/

    BEGIN TRY 
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
    
        DECLARE @SQL nvarchar(max);
        DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);
        DECLARE @ReturnValue TABLE
        (
            IsAnsiPaddingOn bit
        );
        DECLARE @IsAnsiPaddingOn bit;
        DECLARE @PrimaryKeyColumns TABLE 
        (
            IndexColumnID int PRIMARY KEY,
            PrimaryKeyName sysname,
            IndexID int,
            ColumnName sysname,
            DirectionModifier nvarchar(20)
        );
        DECLARE @Counter int;
        DECLARE @IndexColumnID int;
        DECLARE @PrimaryKeyName sysname;
        DECLARE @IndexID int;
        DECLARE @ColumnName sysname;
        DECLARE @DirectionModifier nvarchar(20);
        DECLARE @IsFirstColumn bit;

        SET @WorkingTableName = COALESCE(@WorkingTableName, @ExistingTableName + N'_ANSI_NULLS');
    
        BEGIN TRAN;
        
        IF @IHaveABackUp = 0
        BEGIN;
            RAISERROR (N'Do a backup before continuing with this, just in case !', 16, 1);
        END;

        SET @SQL = N'SELECT CASE WHEN EXISTS (SELECT 1 FROM sys.tables AS t INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id' + @CRLF 
                 + N'                                  INNER JOIN sys.columns AS c ON c.object_id = t.object_id' + @CRLF 
                 + N'                                  WHERE s.[name] = N''' + @ExistingSchemaName + N'''' + @CRLF 
                 + N'                                  AND t.[name] = N''' + @ExistingTableName + N'''' + @CRLF                                 
                 + N'                                  AND c.is_ansi_padded <> 0)' + @CRLF 
                 + N'            THEN CAST(1 AS bit)' + @CRLF 
                 + N'            ELSE CAST(0 AS bit)' + @CRLF 
                 + N'       END;';

        INSERT @ReturnValue (IsAnsiPaddingOn)
        EXEC (@SQL);
                 
        SET @IsAnsiPaddingOn = (SELECT TOP(1) IsAnsiPaddingOn FROM @ReturnValue);

        SET @SQL = N'SELECT kc.[name] AS PrimaryKeyName,' + @CRLF
                 + N'       i.index_id AS IndexID,' + @CRLF 
                 + N'       ic.index_column_id AS IndexColumnID,' + @CRLF  
                 + N'       c.[name] AS ColumnName,' + @CRLF 
                 + N'       CASE WHEN ic.is_descending_key <> 0 THEN N'' DESC'' ELSE N'''' END AS DirectionModifier' + @CRLF 
                 + N'FROM sys.key_constraints AS kc' + @CRLF 
                 + N'INNER JOIN sys.indexes AS i ON i.object_id = kc.parent_object_id AND i.is_primary_key <> 0' + @CRLF 
                 + N'INNER JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id' + @CRLF  
                 + N'INNER JOIN sys.tables AS t ON t.object_id = kc.parent_object_id' + @CRLF  
                 + N'INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id' + @CRLF 
                 + N'INNER JOIN sys.columns AS c ON c.object_id = t.object_id AND c.column_id = ic.column_id' + @CRLF  
                 + N'WHERE kc.[type] = N''PK''' + @CRLF 
                 + N'AND s.[name] = N''' + @ExistingSchemaName + N'''' + @CRLF  
                 + N'AND t.[name] = N''' + @ExistingTableName + N'''' + @CRLF 
                 + N'ORDER BY ic.index_column_id;' + @CRLF;        
        
        INSERT @PrimaryKeyColumns (PrimaryKeyName, IndexID, IndexColumnID, ColumnName, DirectionModifier)
        EXEC (@SQL);

        IF EXISTS (SELECT 1 FROM @PrimaryKeyColumns)
        BEGIN
            SET @SQL = N'ALTER TABLE ' + QUOTENAME(@ExistingSchemaName) + N'.' + QUOTENAME(@ExistingTableName)  
                     + N'DROP CONSTRAINT ' + QUOTENAME((SELECT TOP(1) PrimaryKeyName FROM @PrimaryKeyColumns)) + N';'; 
            EXEC(@SQL);
        END;

        DECLARE @TableScript nvarchar(max);
        
        EXEC SDU_Tools.ScriptTableInCurrentDatabase 
             @ExistingSchemaName = @ExistingSchemaName
           , @ExistingTableName = @ExistingTableName
           , @OutputSchemaName = @ExistingSchemaName
           , @OutputTableName = @WorkingTableName
           , @OutputDataCompressionStyle = N'SAME'
           , @AreCollationsScripted = 1
           , @AreUsingBaseTypes = 0
           , @AreForcingAnsiNulls = 1
           , @AreForcingAnsiPadding = 0
           , @ColumnIndentSize = 4
           , @ScriptIndentSize = 0
           , @TableScript = @TableScript OUTPUT;     
        IF COALESCE(@TableScript, N'') = N''
        BEGIN;
            RAISERROR (N'Unable to script existing table. Please check its name and the other parameters.', 16, 1);
        END;
    
        SET @SQL = N'IF EXISTS (SELECT 1 FROM sys.tables AS t INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id' + @CRLF 
                 + N'                    WHERE s.[name] = N''' + @ExistingSchemaName + N'''' + @CRLF 
                 + N'                    AND t.[name] = N''' + @WorkingTableName + N''')' + @CRLF 
                 + N'BEGIN' + @CRLF 
                 + N'    DROP TABLE ' + QUOTENAME(@ExistingSchemaName) + N'.' + QUOTENAME(@WorkingTableName) + N';' + @CRLF 
                 + N'END;' + @CRLF;

        EXEC(@SQL);

        SET @SQL = N'SET ANSI_NULLS ON;' + @CRLF 
                 + CASE WHEN @IsAnsiPaddingOn = 0 
                        THEN N'SET ANSI_PADDING OFF;' 
                        ELSE N'SET ANSI_PADDING ON;' 
                   END + @CRLF + @CRLF 
                 + N'EXEC (''' + REPLACE(@TableScript, N'''', N'''''') + N''');' + @CRLF;
        EXEC(@SQL);

        SET @SQL = N'ALTER TABLE ' + QUOTENAME(@ExistingSchemaName) + N'.' + QUOTENAME(@ExistingTableName) + @CRLF 
                 + N'SWITCH TO ' + QUOTENAME(@ExistingSchemaName) + N'.' + QUOTENAME(@WorkingTableName) + N';' + @CRLF;

        EXEC(@SQL);

        SET @SQL = N'DROP TABLE ' + QUOTENAME(@ExistingSchemaName) + N'.' + QUOTENAME(@ExistingTableName) + N';'; 

        EXEC(@SQL);

        SET @SQL = N'EXEC sp_rename N''' + QUOTENAME(@ExistingSchemaName) + N'.' + QUOTENAME(@WorkingTableName) + N''''
                     + N', N''' + @ExistingTableName + N''', ''OBJECT'';'; 

        EXEC(@SQL);

        IF EXISTS (SELECT 1 FROM @PrimaryKeyColumns)
        BEGIN
            SET @IsFirstColumn = 1;
            SET @Counter = 1;
            WHILE @Counter <= (SELECT MAX(IndexColumnID) FROM @PrimaryKeyColumns)
            BEGIN
                SELECT @IndexColumnID = IndexColumnID,
                       @PrimaryKeyName = PrimaryKeyName,
                       @IndexID = IndexID,
                       @ColumnName = ColumnName,
                       @DirectionModifier = DirectionModifier
                FROM @PrimaryKeyColumns 
                WHERE IndexColumnID = @Counter;

                IF @IsFirstColumn <> 0
                BEGIN
                    SET @SQL = N'ALTER TABLE ' + QUOTENAME(@ExistingSchemaName) + N'.' + QUOTENAME(@ExistingTableName)  
                             + N'ADD CONSTRAINT ' + QUOTENAME(@PrimaryKeyName) + N' PRIMARY KEY '
                             + CASE WHEN @IndexID = 1 THEN N'CLUSTERED' ELSE N'NONCLUSTERED' END
                             + N' (' + @ColumnName + CASE WHEN @DirectionModifier <> N'' THEN N' ' + @DirectionModifier ELSE N'' END; 
                END ELSE BEGIN
                    SET @SQL += N', ' + @ColumnName + N' ' + CASE WHEN @DirectionModifier <> N'' THEN N' ' + @DirectionModifier ELSE N'' END;
                END;
                SET @IsFirstColumn = 0;
                SET @Counter = @Counter + 1;
            END;
            SET @SQL += N');';

            EXEC(@SQL);
        END;
    
        COMMIT ; 
    END TRY 
    BEGIN CATCH 
        IF XACT_STATE() <> 0 
        BEGIN
            ROLLBACK; 
        END;
    
        PRINT 'Unable to change table. Error returned was:';
        PRINT ERROR_MESSAGE(); 
    END CATCH; 
END;
GO

------------------------------------------------------------------------------------

-- CREATE FUNCTION SDU_Tools.IsJobRunning (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------
GO

CREATE FUNCTION SDU_Tools.AlphanumericOnly
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Removes all non-alphanumeric characters in a string
-- Parameters:    @InputString nvarchar(max) - String to be processed (unicode or single byte)
-- Action:        Removes all non-alphanumeric characters in a string
-- Return:        varchar(max)
-- Refer to this video: https://youtu.be/R51509NbAf0
--
-- Test example: 
/*

SELECT SDU_Tools.AlphanumericOnly('Hello20834There  234');

*/

    DECLARE @Counter int = 1;
    DECLARE @ReturnValue nvarchar(max) = '';
    DECLARE @CharacterCode int;
    DECLARE @StringToProcess nvarchar(max) = LTRIM(RTRIM(@InputString)); -- cast all unicode to single byte
    DECLARE @NextCharacter nchar(1);

    WHILE @Counter <= LEN(@StringToProcess)
    BEGIN
        SET @NextCharacter = SUBSTRING(@StringToProcess, @Counter, 1);
        SET @ReturnValue = @ReturnValue
                         + CASE WHEN @NextCharacter BETWEEN N'0' AND N'9'
                                OR @NextCharacter BETWEEN N'A' AND N'Z'
                                OR @NextCharacter BETWEEN N'a' AND N'z'
                                THEN @NextCharacter
                                ELSE N''
                           END;
        SET @Counter = @Counter + 1;
    END;

    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.AlphabeticOnly
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Removes all non-alphabetic characters in a string
-- Parameters:    @InputString nvarchar(max) - String to be processed (unicode or single byte)
-- Action:        Removes all non-alphabetic characters in a string
-- Return:        varchar(max)
-- Refer to this video: https://youtu.be/R51509NbAf0
--
-- Test example: 
/*

SELECT SDU_Tools.AlphabeticOnly('Hello20834There  234');

*/

    DECLARE @Counter int = 1;
    DECLARE @ReturnValue nvarchar(max) = '';
    DECLARE @CharacterCode int;
    DECLARE @StringToProcess nvarchar(max) = LTRIM(RTRIM(@InputString)); -- cast all unicode to single byte
    DECLARE @NextCharacter nchar(1);

    WHILE @Counter <= LEN(@StringToProcess)
    BEGIN
        SET @NextCharacter = SUBSTRING(@StringToProcess, @Counter, 1);
        SET @ReturnValue = @ReturnValue
                         + CASE WHEN @NextCharacter BETWEEN N'A' AND N'Z'
                                OR @NextCharacter BETWEEN N'a' AND N'z'
                                THEN @NextCharacter
                                ELSE N''
                           END;
        SET @Counter = @Counter + 1;
    END;

    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ReseedSequenceBeyondTableValuesInCurrentDatabase
@SchemaName sysname,
@SequenceName sysname
AS
BEGIN

-- Function:      ReseedSequenceBeyondTableValues
-- Parameters:    @SchemaName sysname           -> Schema for the sequence to process
--                @SequenceName sysname         -> Sequence to process
-- Action:        Sets the sequence to a value beyond any column value that uses it as a default
-- Return:        Nil
-- Refer to this video: https://youtu.be/q-Ng3vQRo50
--
-- Test examples: 
/*

EXEC SDU_Tools.ReseedSequenceBeyondTableValuesInCurrentDatabase
     @SchemaName = N'Sequences', 
     @SequenceName = N'CustomerID'; 

*/

    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @SQL nvarchar(max);
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);
    DECLARE @ColumnSchemaName sysname;
    DECLARE @TableName sysname;
    DECLARE @ColumnName sysname;
    DECLARE @ColumnCounter int;
    DECLARE @NewSeedValue bigint = 1;

    DECLARE @ColumnsUsingSequenceDefault TABLE
    (
        ColumnsUsingSequenceDefaultID int IDENTITY(1,1) PRIMARY KEY,
        SchemaName sysname,
        TableName sysname, 
        ColumnName sysname
    );
    DECLARE @ReturnValues TABLE
    (
        ReturnValue bigint
    );

    SET @SQL = N'SELECT s.[name] AS SchemaName, t.[name] AS TableName, c.[name] AS ColumnName' + @CRLF  
             + N'FROM sys.default_constraints AS dc' + @CRLF 
             + N'INNER JOIN sys.columns AS c' + @CRLF 
             + N'ON dc.parent_object_id = c.object_id' + @CRLF 
             + N'AND dc.parent_column_id = c.column_id' + @CRLF 
             + N'INNER JOIN sys.tables AS t' + @CRLF 
             + N'ON t.object_id = c.object_id' + @CRLF 
             + N'INNER JOIN sys.schemas AS s' + @CRLF 
             + N'ON s.schema_id = t.schema_id' + @CRLF 
             + N'WHERE LOWER(dc.definition) LIKE N''%next%value%for%''' + @CRLF 
             + N'AND dc.definition LIKE N''%' + @SchemaName + N'%.%' + @SequenceName + N'%'''
             + N'ORDER BY SchemaName, TableName, ColumnName;';

    INSERT @ColumnsUsingSequenceDefault (SchemaName, TableName, ColumnName)
    EXEC (@SQL);

    IF EXISTS (SELECT 1 FROM @ColumnsUsingSequenceDefault)
    BEGIN
        SET @ColumnCounter = 1;
        
        WHILE @ColumnCounter <= (SELECT MAX(ColumnsUsingSequenceDefaultID) FROM @ColumnsUsingSequenceDefault)
        BEGIN
            SELECT @ColumnSchemaName = cusd.SchemaName,
                   @TableName = cusd.TableName,
                   @ColumnName = cusd.ColumnName 
            FROM @ColumnsUsingSequenceDefault AS cusd
            WHERE cusd.ColumnsUsingSequenceDefaultID = @ColumnCounter;
        
            DELETE @ReturnValues;
        
            SET @SQL = N'SELECT MAX(' + QUOTENAME(@ColumnName) + N') FROM ' + QUOTENAME(@ColumnSchemaName) + N'.' + QUOTENAME(@TableName) + N';';
            INSERT @ReturnValues (ReturnValue)
            EXEC (@SQL);
        
            IF (SELECT ReturnValue FROM @ReturnValues) >= @NewSeedValue
            BEGIN
                SET @NewSeedValue = (SELECT ReturnValue FROM @ReturnValues) + 1;
            END;
        
            SET @ColumnCounter = @ColumnCounter + 1;
        END;
        
        PRINT N'Assigning next value for ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@SequenceName) + N' as ' + CAST(@NewSeedValue AS nvarchar(20));

        SET @SQL = N'ALTER SEQUENCE ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@SequenceName) + N' RESTART WITH ' + CAST(@NewSeedValue AS nvarchar(20)) + N';';
        EXEC (@SQL);

    END;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ReseedSequencesInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',
@SequencesToList nvarchar(max) = N'ALL'
AS
BEGIN

-- Function:      ReseedSequences
-- Parameters:    @SchemasToList nvarchar(max)     -> Schemas to process (comma-delimited list) or ALL
--                @SequencesToList nvarchar(max)   -> Schemas to process (comma-delimited list) or ALL
-- Action:        Sets the sequences to a value beyond any column value that uses them as a default
-- Return:        Nil
-- Refer to this video: https://youtu.be/q-Ng3vQRo50
--
-- Test examples: 
/*

EXEC SDU_Tools.ReseedSequencesInCurrentDatabase;

*/

    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @SQL nvarchar(max);
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);
    DECLARE @SchemaName sysname;
    DECLARE @SequenceName sysname;
    DECLARE @SequenceCounter int;

    DECLARE @SequencesToProcess TABLE
    (
        SequencesToProcessID int IDENTITY(1,1) PRIMARY KEY,
        SchemaName sysname,
        SequenceName sysname 
    );

    SET @SQL = N'SELECT sch.[name] AS SchemaName, s.[name] AS SequenceName' + @CRLF  
             + N'FROM sys.sequences AS s' + @CRLF 
             + N'INNER JOIN sys.schemas AS sch' + @CRLF 
             + N'ON sch.schema_id = s.schema_id' + @CRLF 
             + N'WHERE 1 = 1 ' + @CRLF 
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'AND sch.[name] IN (''' + REPLACE(REPLACE(@SchemasToList, N' ', N''), N',', N''',''') + N''')'
      END + @CRLF 
    + CASE WHEN @SequencesToList = N'ALL' 
           THEN N''
           ELSE N'AND s.[name] IN (''' + REPLACE(REPLACE(@SequencesToList, N' ', N''), N',', N''',''') + N''')'
      END + @CRLF 
    + N'ORDER BY sch.[name], s.[name];';
    
    INSERT @SequencesToProcess (SchemaName, SequenceName)
    EXEC (@SQL);
    
    IF EXISTS (SELECT 1 FROM @SequencesToProcess)
    BEGIN
        SET @SequenceCounter = 1;
        
        WHILE @SequenceCounter <= (SELECT MAX(SequencesToProcessID) FROM @SequencesToProcess)
        BEGIN
            SELECT @SchemaName = stp.SchemaName,
                   @SequenceName = stp.SequenceName
            FROM @SequencesToProcess AS stp
            WHERE stp.SequencesToProcessID = @SequenceCounter;
        
            EXEC SDU_Tools.ReseedSequenceBeyondTableValuesInCurrentDatabase
                 @SchemaName = @SchemaName,
                 @SequenceName = @SequenceName;
        
            SET @SequenceCounter = @SequenceCounter + 1;
        END;
        
    END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DateOfEasterSunday
(
    @Year int
)
RETURNS date
AS
BEGIN

-- Function:      Returns the date of Easter Sunday in a given year
-- Parameters:    @Year int  -> year number
-- Action:        Calculates the date of Easter Sunday (Christian Easter) for
--                a given year, adapted from the wonderful calculation described
--                on this page: http://www.tondering.dk/claus/cal/easter.php#wheneasterlong
--                contained in the highly recommended Calendar FAQ by Claus Tondering
-- Return:        date
-- Refer to this video: https://youtu.be/Cru9RVZqFZU
--
-- Test examples: 
/*

SELECT SDU_Tools.DateOfEasterSunday(2018);
SELECT SDU_Tools.DateOfEasterSunday(1958);

*/
    RETURN CAST(CAST(@Year AS varchar(4))
              + RIGHT('0' + CAST(3 + ((((24 + 19*(@Year % 19)) % 30) - ((24 + 19*(@Year % 19)) % 30)/ 28) - (@Year + @Year/4 + (((24 + 19*(@Year % 19)) % 30) - ((24 + 19*(@Year % 19)) % 30) / 28)- 13) % 7 + 40) / 44 AS varchar(2)), 2)
              + RIGHT('0' + CAST(((((24 + 19 * (@Year % 19)) % 30) - ((24 + 19 * (@Year % 19)) % 30) / 28) - ((@Year + @Year / 4 + (((24 + 19 * (@Year % 19)) % 30) - ((24 + 19 * (@Year % 19)) % 30) / 28) - 13) % 7)) + 28 - 31 * ((3 + ((((24 + 19*(@Year % 19)) % 30) - ((24 + 19*(@Year % 19)) % 30)/ 28) - (@Year + @Year/4 + (((24 + 19*(@Year % 19)) % 30) - ((24 + 19*(@Year % 19)) % 30) / 28)- 13) % 7 + 40) / 44) / 4) AS varchar(2)), 2) AS date);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListPrimaryKeyColumnsInCurrentDatabase
@SchemasToList nvarchar(max),  -- N'ALL' for all
@TablesToList nvarchar(max),   -- N'ALL' for all
@ExcludeEmptyTables bit = 0,   -- 1 for yes
@IsOutputOrderedBySize bit = 0 -- 1 for yes
AS
BEGIN

-- Function:      Lists the columns that are used in primary keys for all tables
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists the columns that are used in primary keys for all tables
-- Return:        Rowset containing SchemaName, TableName, PrimaryKeyName, ColumnList
--                in order of SchemaName, TableName
-- Refer to this video: https://youtu.be/usTlhzOJj9o
--
-- Test examples: 
/*

EXEC SDU_Tools.ListPrimaryKeyColumnsInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = N'
WITH PrimaryKeyColumns
AS
(
       SELECT s.[name] AS SchemaName,
              t.[name] AS TableName,
              i.[name] AS PrimaryKeyName,
              c.[name] AS ColumnName,
              ic.index_column_id AS IndexColumnID
       FROM sys.indexes AS i
       INNER JOIN sys.index_columns AS ic 
       ON ic.object_id = i.object_id
       AND ic.index_id = i.index_id 
       INNER JOIN sys.columns AS c 
       ON c.object_id = i.object_id 
       AND c.column_id = ic.column_id  
       INNER JOIN sys.tables AS t 
       ON t.object_id = i.object_id 
       INNER JOIN sys.schemas AS s 
       ON s.schema_id = t.schema_id 
       WHERE i.is_primary_key <> 0
       AND ic.is_included_column = 0
       AND t.is_ms_shipped = 0
       AND t.[name] NOT LIKE N''sysdiagrams''' + @CRLF
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))' + @CRLF
      END 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))' + @CRLF
      END
+ N'
),
PrimaryKeyColumnLists
AS
(
       SELECT pkc.SchemaName, pkc.TableName, pkc.PrimaryKeyName, pkc.IndexColumnID AS NumberOfColumns, CAST(pkc.ColumnName AS nvarchar(max)) AS ColumnList
       FROM PrimaryKeyColumns AS pkc 
       WHERE pkc.IndexColumnID = 1

       UNION ALL

       SELECT pkc.SchemaName, pkc.TableName, pkc.PrimaryKeyName, pkcl.NumberOfColumns + 1, CAST(CONCAT(pkcl.ColumnList, N'','', pkc.ColumnName) AS nvarchar(max))
       FROM PrimaryKeyColumns AS pkc 
       INNER JOIN PrimaryKeyColumnLists AS pkcl 
       ON pkc.PrimaryKeyName = pkcl.PrimaryKeyName
       AND pkc.IndexColumnID = pkcl.NumberOfColumns + 1
)
SELECT pkcl.SchemaName, pkcl.TableName, pkcl.PrimaryKeyName, pkcl.NumberOfColumns, pkcl.ColumnList
FROM PrimaryKeyColumnLists AS pkcl 
WHERE pkcl.NumberOfColumns = (SELECT MAX(pkcll.NumberOfColumns) FROM PrimaryKeyColumnLists AS pkcll WHERE pkcll.PrimaryKeyName = pkcl.PrimaryKeyName)
ORDER BY SchemaName, TableName;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.ReservedWords
AS
/* 

-- View:          ReservedWords
-- Action:        View returning SQL Server reserved words, and the color they normally appear in SSMS
-- Return:        One row per reserved word.
-- Refer to this video: https://youtu.be/WITnoiWRPsI
--
-- Test examples: 

SELECT * FROM SDU_Tools.ReservedWords;

*/

SELECT ReservedWord, SSMSColor
FROM (VALUES ('ADD', 'blue'),
             ('ALTER', 'blue'),
             ('AS', 'blue'),
             ('ASC', 'blue'),
             ('AUTHORIZATION', 'blue'),
             ('BACKUP', 'blue'),
             ('BEGIN', 'blue'),
             ('BREAK', 'blue'),
             ('BROWSE', 'blue'),
             ('BULK', 'blue'),
             ('BY', 'blue'),
             ('CASCADE', 'blue'),
             ('CASE', 'blue'),
             ('CHECK', 'blue'),
             ('CHECKPOINT', 'blue'),
             ('CLOSE', 'blue'),
             ('CLUSTERED', 'blue'),
             ('COLUMN', 'blue'),
             ('COMMIT', 'blue'),
             ('COMPUTE', 'blue'),
             ('CONSTRAINT', 'blue'),
             ('CONTAINSTABLE', 'blue'),
             ('CONTINUE', 'blue'),
             ('CREATE', 'blue'),
             ('CURRENT', 'blue'),
             ('CURRENT_DATE', 'blue'),
             ('CURSOR', 'blue'),
             ('DATABASE', 'blue'),
             ('DBCC', 'blue'),
             ('DEALLOCATE', 'blue'),
             ('DECLARE', 'blue'),
             ('DEFAULT', 'blue'),
             ('DELETE', 'blue'),
             ('DENY', 'blue'),
             ('DESC', 'blue'),
             ('DISK', 'blue'),
             ('DISTINCT', 'blue'),
             ('DISTRIBUTED', 'blue'),
             ('DOUBLE', 'blue'),
             ('DROP', 'blue'),
             ('DUMP', 'blue'),
             ('ELSE', 'blue'),
             ('END', 'blue'),
             ('ERRLVL', 'blue'),
             ('ESCAPE', 'blue'),
             ('EXCEPT', 'blue'),
             ('EXEC', 'blue'),
             ('EXECUTE', 'blue'),
             ('EXIT', 'blue'),
             ('EXTERNAL', 'blue'),
             ('FETCH', 'blue'),
             ('FILE', 'blue'),
             ('FILLFACTOR', 'blue'),
             ('FOR', 'blue'),
             ('FOREIGN', 'blue'),
             ('FREETEXT', 'blue'),
             ('FREETEXTTABLE', 'blue'),
             ('FROM', 'blue'),
             ('FULL', 'blue'),
             ('FUNCTION', 'blue'),
             ('GOTO', 'blue'),
             ('GRANT', 'blue'),
             ('GREATER', 'purple'),
             ('GROUP', 'blue'),
             ('HAVING', 'blue'),
             ('HOLDLOCK', 'blue'),
             ('IDENTITY', 'blue'),
             ('IDENTITY_INSERT', 'blue'),
             ('IDENTITYCOL', 'blue'),
             ('IF', 'blue'),
             ('INDEX', 'blue'),
             ('INSERT', 'blue'),
             ('INTERSECT', 'blue'),
             ('INTO', 'blue'),
             ('KEY', 'blue'),
             ('KILL', 'blue'),
             ('LEAST', 'purple'),
             ('LINENO', 'blue'),
             ('LOAD', 'blue'),
             ('MERGE', 'blue'),
             ('NATIONAL', 'blue'),
             ('NOCHECK', 'blue'),
             ('NONCLUSTERED', 'blue'),
             ('OF', 'blue'),
             ('OFF', 'blue'),
             ('OFFSETS', 'blue'),
             ('ON', 'blue'),
             ('OPEN', 'blue'),
             ('OPENDATASOURCE', 'blue'),
             ('OPENQUERY', 'blue'),
             ('OPENROWSET', 'blue'),
             ('OPENXML', 'blue'),
             ('OPTION', 'blue'),
             ('ORDER', 'blue'),
             ('OVER', 'blue'),
             ('PERCENT', 'blue'),
             ('PLAN', 'blue'),
             ('PRECISION', 'blue'),
             ('PRIMARY', 'blue'),
             ('PRINT', 'blue'),
             ('PROC', 'blue'),
             ('PROCEDURE', 'blue'),
             ('PUBLIC', 'blue'),
             ('RAISERROR', 'blue'),
             ('READ', 'blue'),
             ('READTEXT', 'blue'),
             ('RECONFIGURE', 'blue'),
             ('REFERENCES', 'blue'),
             ('REPLICATION', 'blue'),
             ('RESTORE', 'blue'),
             ('RESTRICT', 'blue'),
             ('RETURN', 'blue'),
             ('REVERT', 'blue'),
             ('REVOKE', 'blue'),
             ('ROLLBACK', 'blue'),
             ('ROWCOUNT', 'blue'),
             ('ROWGUIDCOL', 'blue'),
             ('RULE', 'blue'),
             ('SAVE', 'blue'),
             ('SCHEMA', 'blue'),
             ('SECURITYAUDIT', 'blue'),
             ('SELECT', 'blue'),
             ('SEMANTICKEYPHRASETABLE', 'blue'),
             ('SEMANTICSIMILARITYDETAILSTABLE', 'blue'),
             ('SEMANTICSIMILARITYTABLE', 'blue'),
             ('SET', 'blue'),
             ('SETUSER', 'blue'),
             ('SHUTDOWN', 'blue'),
             ('STATISTICS', 'blue'),
             ('TABLE', 'blue'),
             ('TABLESAMPLE', 'blue'),
             ('TEXTSIZE', 'blue'),
             ('THEN', 'blue'),
             ('TO', 'blue'),
             ('TOP', 'blue'),
             ('TRAN', 'blue'),
             ('TRANSACTION', 'blue'),
             ('TRIGGER', 'blue'),
             ('TRUNCATE', 'blue'),
             ('UNION', 'blue'),
             ('UNIQUE', 'blue'),
             ('UPDATETEXT', 'blue'),
             ('USE', 'blue'),
             ('USER', 'blue'),
             ('VALUES', 'blue'),
             ('VARYING', 'blue'),
             ('VIEW', 'blue'),
             ('WAITFOR', 'blue'),
             ('WHEN', 'blue'),
             ('WHERE', 'blue'),
             ('WHILE', 'blue'),
             ('WITH', 'blue'),
             ('WITHIN GROUP', 'blue'),
             ('WRITETEXT', 'blue'),
             ('COALESCE', 'purple'),
             ('COLLATE', 'purple'),
             ('CONTAINS', 'purple'),
             ('CONVERT', 'purple'),
             ('CURRENT_TIME', 'purple'),
             ('CURRENT_TIMESTAMP', 'purple'),
             ('CURRENT_USER', 'purple'),
             ('NULLIF', 'purple'),
             ('SESSION_USER', 'purple'),
             ('SYSTEM_USER', 'purple'),
             ('TRY_CONVERT', 'purple'),
             ('TSEQUAL', 'purple'),
             ('UPDATE', 'purple'),
             ('ALL', 'gray'),
             ('AND', 'gray'),
             ('ANY', 'gray'),
             ('BETWEEN', 'gray'),
             ('CROSS', 'gray'),
             ('EXISTS', 'gray'),
             ('IN', 'gray'),
             ('INNER', 'gray'),
             ('IS', 'gray'),
             ('JOIN', 'gray'),
             ('LEFT', 'gray'),
             ('LIKE', 'gray'),
             ('NOT', 'gray'),
             ('NULL', 'gray'),
             ('OR', 'gray'),
             ('OUTER', 'gray'),
             ('PIVOT', 'gray'),
             ('RIGHT', 'gray'),
             ('SOME', 'gray'),
             ('UNPIVOT', 'gray')) AS rw(ReservedWord, SSMSColor);
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.FutureReservedWords
AS
/* 

-- View:          FutureReservedWords
-- Action:        View returning SQL Server declared future reserved words, and the color they normally appear in SSMS
-- Return:        One row per reserved word.
-- Refer to this video: https://youtu.be/WITnoiWRPsI
--
-- Test examples: 

SELECT * FROM SDU_Tools.FutureReservedWords;

*/

SELECT ReservedWord, SSMSColor
FROM (VALUES ('ABSOLUTE', 'blue'),
             ('ACTION', 'blue'),
             ('ADMIN', 'blue'),
             ('AFTER', 'blue'),
             ('AGGREGATE', 'blue'),
             ('ASYMMETRIC', 'blue'),
             ('AT', 'blue'),
             ('ATOMIC', 'blue'),
             ('BEFORE', 'blue'),
             ('BINARY', 'blue'),
             ('BIT', 'blue'),
             ('CALL', 'blue'),
             ('CATALOG', 'blue'),
             ('CHAR', 'blue'),
             ('CHARACTER', 'blue'),
             ('CONNECT', 'blue'),
             ('CUBE', 'blue'),
             ('DATA', 'blue'),
             ('DATE', 'blue'),
             ('DEC', 'blue'),
             ('DECIMAL', 'blue'),
             ('DYNAMIC', 'blue'),
             ('END-EXEC', 'blue'),
             ('FILTER', 'blue'),
             ('FIRST', 'blue'),
             ('FLOAT', 'blue'),
             ('GET', 'blue'),
             ('GLOBAL', 'blue'),
             ('GO', 'blue'),
             ('IMMEDIATE', 'blue'),
             ('INT', 'blue'),
             ('INTEGER', 'blue'),
             ('ISOLATION', 'blue'),
             ('LANGUAGE', 'blue'),
             ('LAST', 'blue'),
             ('LEVEL', 'blue'),
             ('LOCAL', 'blue'),
             ('MATCH', 'blue'),
             ('MODIFY', 'blue'),
             ('NCHAR', 'blue'),
             ('NEXT', 'blue'),
             ('NO', 'blue'),
             ('NONE', 'blue'),
             ('NUMERIC', 'blue'),
             ('OBJECT', 'blue'),
             ('OUT', 'blue'),
             ('OUTPUT', 'blue'),
             ('PARTIAL', 'blue'),
             ('PARTITION', 'blue'),
             ('PATH', 'blue'),
             ('PRIOR', 'blue'),
             ('RANGE', 'blue'),
             ('REAL', 'blue'),
             ('RECURSIVE', 'blue'),
             ('RELATIVE', 'blue'),
             ('RETURNS', 'blue'),
             ('ROLE', 'blue'),
             ('ROLLUP', 'blue'),
             ('ROW', 'blue'),
             ('ROWS', 'blue'),
             ('SCROLL', 'blue'),
             ('SEQUENCE', 'blue'),
             ('SESSION', 'blue'),
             ('SETS', 'blue'),
             ('SMALLINT', 'blue'),
             ('SQL', 'blue'),
             ('START', 'blue'),
             ('STATE', 'blue'),
             ('STATEMENT', 'blue'),
             ('STATIC', 'blue'),
             ('SYMMETRIC', 'blue'),
             ('SYSTEM', 'blue'),
             ('TIME', 'blue'),
             ('TIMESTAMP', 'blue'),
             ('USING', 'blue'),
             ('VALUE', 'blue'),
             ('VARCHAR', 'blue'),
             ('WITHIN', 'blue'),
             ('WITHOUT', 'blue'),
             ('ZONE', 'blue'),
             ('PARAMETERS', 'green'),
             ('CAST', 'purple'),
             ('DAY', 'purple'),
             ('GROUPING', 'purple'),
             ('HOUR', 'purple'),
             ('MINUTE', 'purple'),
             ('MOD', 'purple'),
             ('MONTH', 'purple'),
             ('NORMALIZE', 'purple'),
             ('SECOND', 'purple'),
             ('SPACE', 'purple'),
             ('YEAR', 'purple'),
             ('ALIAS', 'black'),
             ('ALLOCATE', 'black'),
             ('ARE', 'black'),
             ('ARRAY', 'black'),
             ('ASENSITIVE', 'black'),
             ('ASSERTION', 'black'),
             ('BLOB', 'black'),
             ('BOOLEAN', 'black'),
             ('BOTH', 'black'),
             ('BREADTH', 'black'),
             ('CALLED', 'black'),
             ('CARDINALITY', 'black'),
             ('CASCADED', 'black'),
             ('CLASS', 'black'),
             ('CLOB', 'black'),
             ('COLLATION', 'black'),
             ('COLLECT', 'black'),
             ('COMPLETION', 'black'),
             ('CONDITION', 'black'),
             ('CONNECTION', 'black'),
             ('CONSTRAINTS', 'black'),
             ('CONSTRUCTOR', 'black'),
             ('CORR', 'black'),
             ('CORRESPONDING', 'black'),
             ('COVAR_POP', 'black'),
             ('COVAR_SAMP', 'black'),
             ('CUME_DIST', 'black'),
             ('CURRENT_CATALOG', 'black'),
             ('CURRENT_DEFAULT_TRANSFORM_GROUP', 'black'),
             ('CURRENT_PATH', 'black'),
             ('CURRENT_ROLE', 'black'),
             ('CURRENT_SCHEMA', 'black'),
             ('CURRENT_TRANSFORM_GROUP_FOR_TYPE', 'black'),
             ('CYCLE', 'black'),
             ('DEFERRABLE', 'black'),
             ('DEFERRED', 'black'),
             ('DEPTH', 'black'),
             ('DEREF', 'black'),
             ('DESCRIBE', 'black'),
             ('DESCRIPTOR', 'black'),
             ('DESTROY', 'black'),
             ('DESTRUCTOR', 'black'),
             ('DETERMINISTIC', 'black'),
             ('DIAGNOSTICS', 'black'),
             ('DICTIONARY', 'black'),
             ('DISCONNECT', 'black'),
             ('DOMAIN', 'black'),
             ('EACH', 'black'),
             ('ELEMENT', 'black'),
             ('EQUALS', 'black'),
             ('EVERY', 'black'),
             ('EXCEPTION', 'black'),
             ('FOUND', 'black'),
             ('FREE', 'black'),
             ('FULLTEXTTABLE', 'black'),
             ('FUSION', 'black'),
             ('GENERAL', 'black'),
             ('HOLD', 'black'),
             ('HOST', 'black'),
             ('IGNORE', 'black'),
             ('INDICATOR', 'black'),
             ('INITIALIZE', 'black'),
             ('INITIALLY', 'black'),
             ('INOUT', 'black'),
             ('INPUT', 'black'),
             ('INTERSECTION', 'black'),
             ('INTERVAL', 'black'),
             ('ITERATE', 'black'),
             ('LARGE', 'black'),
             ('LATERAL', 'black'),
             ('LEADING', 'black'),
             ('LESS', 'black'),
             ('LIKE_REGEX', 'black'),
             ('LIMIT', 'black'),
             ('LN', 'black'),
             ('LOCALTIME', 'black'),
             ('LOCALTIMESTAMP', 'black'),
             ('LOCATOR', 'black'),
             ('MAP', 'black'),
             ('MEMBER', 'black'),
             ('METHOD', 'black'),
             ('MODIFIES', 'black'),
             ('MODULE', 'black'),
             ('MULTISET', 'black'),
             ('NAMES', 'black'),
             ('NATURAL', 'black'),
             ('NCLOB', 'black'),
             ('NEW', 'black'),
             ('OCCURRENCES_REGEX', 'black'),
             ('OLD', 'black'),
             ('ONLY', 'black'),
             ('OPERATION', 'black'),
             ('ORDINALITY', 'black'),
             ('OVERLAY', 'black'),
             ('PAD', 'black'),
             ('PARAMETER', 'black'),
             ('PERCENT_RANK', 'black'),
             ('PERCENTILE_CONT', 'black'),
             ('PERCENTILE_DISC', 'black'),
             ('POSITION_REGEX', 'black'),
             ('POSTFIX', 'black'),
             ('PREFIX', 'black'),
             ('PREORDER', 'black'),
             ('PREPARE', 'black'),
             ('PRESERVE', 'black'),
             ('PRIVILEGES', 'black'),
             ('READS', 'black'),
             ('REF', 'black'),
             ('REFERENCING', 'black'),
             ('REGR_AVGX', 'black'),
             ('REGR_AVGY', 'black'),
             ('REGR_COUNT', 'black'),
             ('REGR_INTERCEPT', 'black'),
             ('REGR_R2', 'black'),
             ('REGR_SLOPE', 'black'),
             ('REGR_SXX', 'black'),
             ('REGR_SXY', 'black'),
             ('REGR_SYY', 'black'),
             ('RELEASE', 'black'),
             ('RESULT', 'black'),
             ('ROUTINE', 'black'),
             ('SAVEPOINT', 'black'),
             ('SCOPE', 'black'),
             ('SEARCH', 'black'),
             ('SECTION', 'black'),
             ('SENSITIVE', 'black'),
             ('SIMILAR', 'black'),
             ('SIZE', 'black'),
             ('SPECIFIC', 'black'),
             ('SPECIFICTYPE', 'black'),
             ('SQLEXCEPTION', 'black'),
             ('SQLSTATE', 'black'),
             ('SQLWARNING', 'black'),
             ('STDDEV_POP', 'black'),
             ('STDDEV_SAMP', 'black'),
             ('STRUCTURE', 'black'),
             ('SUBMULTISET', 'black'),
             ('SUBSTRING_REGEX', 'black'),
             ('TEMPORARY', 'black'),
             ('TERMINATE', 'black'),
             ('THAN', 'black'),
             ('TIMEZONE_HOUR', 'black'),
             ('TIMEZONE_MINUTE', 'black'),
             ('TRAILING', 'black'),
             ('TRANSLATE_REGEX', 'black'),
             ('TRANSLATION', 'black'),
             ('TREAT', 'black'),
             ('UESCAPE', 'black'),
             ('UNDER', 'black'),
             ('UNKNOWN', 'black'),
             ('UNNEST', 'black'),
             ('USAGE', 'black'),
             ('VAR_POP', 'black'),
             ('VAR_SAMP', 'black'),
             ('VARIABLE', 'black'),
             ('WHENEVER', 'black'),
             ('WIDTH_BUCKET', 'black'),
             ('WINDOW', 'black'),
             ('WORK', 'black'),
             ('WRITE', 'black'),
             ('XMLAGG', 'black'),
             ('XMLATTRIBUTES', 'black'),
             ('XMLBINARY', 'black'),
             ('XMLCAST', 'black'),
             ('XMLCOMMENT', 'black'),
             ('XMLCONCAT', 'black'),
             ('XMLDOCUMENT', 'black'),
             ('XMLELEMENT', 'black'),
             ('XMLEXISTS', 'black'),
             ('XMLFOREST', 'black'),
             ('XMLITERATE', 'black'),
             ('XMLNAMESPACES', 'black'),
             ('XMLPARSE', 'black'),
             ('XMLPI', 'black'),
             ('XMLQUERY', 'black'),
             ('XMLSERIALIZE', 'black'),
             ('XMLTABLE', 'black'),
             ('XMLTEXT', 'black'),
             ('XMLVALIDATE', 'black'),
             ('FALSE', 'black'),
             ('TRUE', 'black')) AS frw(ReservedWord, SSMSColor);
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.ODBCReservedWords
AS
/* 

-- View:          ODBCReservedWords
-- Action:        View returning SQL Server ODBC reserved words, and the color they normally appear in SSMS
-- Return:        One row per reserved word.
-- Refer to this video: https://youtu.be/WITnoiWRPsI
--
-- Test examples: 

SELECT * FROM SDU_Tools.ODBCReservedWords;

*/

SELECT ReservedWord, SSMSColor
FROM (VALUES ('ALLOCATE', 'black'),
             ('ARE', 'black'),
             ('ASSERTION', 'black'),
             ('BOTH', 'black'),
             ('CASCADED', 'black'),
             ('CHAR_LENGTH', 'black'),
             ('CHARACTER_LENGTH', 'black'),
             ('COLLATION', 'black'),
             ('CONNECTION', 'black'),
             ('CONSTRAINTS', 'black'),
             ('CORRESPONDING', 'black'),
             ('DEFERRABLE', 'black'),
             ('DEFERRED', 'black'),
             ('DESCRIBE', 'black'),
             ('DESCRIPTOR', 'black'),
             ('DIAGNOSTICS', 'black'),
             ('DISCONNECT', 'black'),
             ('DOMAIN', 'black'),
             ('EXCEPTION', 'black'),
             ('FORTRAN', 'black'),
             ('FOUND', 'black'),
             ('INDICATOR', 'black'),
             ('INITIALLY', 'black'),
             ('INPUT', 'black'),
             ('INTERVAL', 'black'),
             ('LEADING', 'black'),
             ('MODULE', 'black'),
             ('NAMES', 'black'),
             ('NATURAL', 'black'),
             ('ONLY', 'black'),
             ('OVERLAPS', 'black'),
             ('PAD', 'black'),
             ('PASCAL', 'black'),
             ('POSITION', 'black'),
             ('PREPARE', 'black'),
             ('PRESERVE', 'black'),
             ('PRIVILEGES', 'black'),
             ('SECTION', 'black'),
             ('SIZE', 'black'),
             ('SQLCA', 'black'),
             ('SQLCODE', 'black'),
             ('SQLERROR', 'black'),
             ('SQLSTATE', 'black'),
             ('SQLWARNING', 'black'),
             ('TEMPORARY', 'black'),
             ('TIMEZONE_HOUR', 'black'),
             ('TIMEZONE_MINUTE', 'black'),
             ('TRAILING', 'black'),
             ('TRANSLATE', 'black'),
             ('TRANSLATION', 'black'),
             ('UNKNOWN', 'black'),
             ('USAGE', 'black'),
             ('WHENEVER', 'black'),
             ('WORK', 'black'),
             ('WRITE', 'black'),
             ('FALSE', 'black'),
             ('TRUE', 'black'),
             ('AVG', 'purple'),
             ('BIT_LENGTH', 'purple'),
             ('CAST', 'purple'),
             ('COALESCE', 'purple'),
             ('COLLATE', 'purple'),
             ('CONVERT', 'purple'),
             ('COUNT', 'purple'),
             ('CURRENT_TIME', 'purple'),
             ('CURRENT_TIMESTAMP', 'purple'),
             ('CURRENT_USER', 'purple'),
             ('DAY', 'purple'),
             ('EXTRACT', 'purple'),
             ('HOUR', 'purple'),
             ('LOWER', 'purple'),
             ('MAX', 'purple'),
             ('MIN', 'purple'),
             ('MINUTE', 'purple'),
             ('MONTH', 'purple'),
             ('NULLIF', 'purple'),
             ('OCTET_LENGTH', 'purple'),
             ('SECOND', 'purple'),
             ('SESSION_USER', 'purple'),
             ('SPACE', 'purple'),
             ('SUBSTRING', 'purple'),
             ('SUM', 'purple'),
             ('SYSTEM_USER', 'purple'),
             ('TRIM', 'purple'),
             ('UPDATE', 'purple'),
             ('UPPER', 'purple'),
             ('YEAR', 'purple'),
             ('ALL', 'gray'),
             ('AND', 'gray'),
             ('ANY', 'gray'),
             ('BETWEEN', 'gray'),
             ('CROSS', 'gray'),
             ('EXISTS', 'gray'),
             ('IN', 'gray'),
             ('INNER', 'gray'),
             ('IS', 'gray'),
             ('JOIN', 'gray'),
             ('LEFT', 'gray'),
             ('LIKE', 'gray'),
             ('NOT', 'gray'),
             ('NULL', 'gray'),
             ('OR', 'gray'),
             ('OUTER', 'gray'),
             ('RIGHT', 'gray'),
             ('SOME', 'gray'),
             ('ABSOLUTE', 'blue'),
             ('ACTION', 'blue'),
             ('ADD', 'blue'),
             ('ALTER', 'blue'),
             ('AS', 'blue'),
             ('ASC', 'blue'),
             ('AT', 'blue'),
             ('AUTHORIZATION', 'blue'),
             ('BEGIN', 'blue'),
             ('BIT', 'blue'),
             ('BY', 'blue'),
             ('CASCADE', 'blue'),
             ('CASE', 'blue'),
             ('CATALOG', 'blue'),
             ('CHAR', 'blue'),
             ('CHARACTER', 'blue'),
             ('CHECK', 'blue'),
             ('CLOSE', 'blue'),
             ('COLUMN', 'blue'),
             ('COMMIT', 'blue'),
             ('CONNECT', 'blue'),
             ('CONSTRAINT', 'blue'),
             ('CONTINUE', 'blue'),
             ('CREATE', 'blue'),
             ('CURRENT', 'blue'),
             ('CURRENT_DATE', 'blue'),
             ('CURSOR', 'blue'),
             ('DATE', 'blue'),
             ('DEALLOCATE', 'blue'),
             ('DEC', 'blue'),
             ('DECIMAL', 'blue'),
             ('DECLARE', 'blue'),
             ('DEFAULT', 'blue'),
             ('DELETE', 'blue'),
             ('DESC', 'blue'),
             ('DISTINCT', 'blue'),
             ('DOUBLE', 'blue'),
             ('DROP', 'blue'),
             ('ELSE', 'blue'),
             ('END', 'blue'),
             ('END-EXEC', 'blue'),
             ('ESCAPE', 'blue'),
             ('EXCEPT', 'blue'),
             ('EXEC', 'blue'),
             ('EXECUTE', 'blue'),
             ('EXTERNAL', 'blue'),
             ('FETCH', 'blue'),
             ('FIRST', 'blue'),
             ('FLOAT', 'blue'),
             ('FOR', 'blue'),
             ('FOREIGN', 'blue'),
             ('FROM', 'blue'),
             ('FULL', 'blue'),
             ('GET', 'blue'),
             ('GLOBAL', 'blue'),
             ('GO', 'blue'),
             ('GOTO', 'blue'),
             ('GRANT', 'blue'),
             ('GROUP', 'blue'),
             ('HAVING', 'blue'),
             ('HOUR', 'blue'),
             ('IDENTITY', 'blue'),
             ('IMMEDIATE', 'blue'),
             ('INCLUDE', 'blue'),
             ('INDEX', 'blue'),
             ('INSENSITIVE', 'blue'),
             ('INSERT', 'blue'),
             ('INT', 'blue'),
             ('INTEGER', 'blue'),
             ('INTERSECT', 'blue'),
             ('INTO', 'blue'),
             ('ISOLATION', 'blue'),
             ('KEY', 'blue'),
             ('LANGUAGE', 'blue'),
             ('LAST', 'blue'),
             ('LEVEL', 'blue'),
             ('LOCAL', 'blue'),
             ('MATCH', 'blue'),
             ('NATIONAL', 'blue'),
             ('NCHAR', 'blue'),
             ('NEXT', 'blue'),
             ('NO', 'blue'),
             ('NONE', 'blue'),
             ('NUMERIC', 'blue'),
             ('OF', 'blue'),
             ('ON', 'blue'),
             ('OPEN', 'blue'),
             ('OPTION', 'blue'),
             ('ORDER', 'blue'),
             ('OUTPUT', 'blue'),
             ('PARTIAL', 'blue'),
             ('PRECISION', 'blue'),
             ('PRIMARY', 'blue'),
             ('PRIOR', 'blue'),
             ('PROCEDURE', 'blue'),
             ('PUBLIC', 'blue'),
             ('READ', 'blue'),
             ('REAL', 'blue'),
             ('REFERENCES', 'blue'),
             ('RELATIVE', 'blue'),
             ('RESTRICT', 'blue'),
             ('REVOKE', 'blue'),
             ('ROLLBACK', 'blue'),
             ('ROWS', 'blue'),
             ('SCHEMA', 'blue'),
             ('SCROLL', 'blue'),
             ('SELECT', 'blue'),
             ('SESSION', 'blue'),
             ('SET', 'blue'),
             ('SMALLINT', 'blue'),
             ('SQL', 'blue'),
             ('TABLE', 'blue'),
             ('THEN', 'blue'),
             ('TIME', 'blue'),
             ('TIMESTAMP', 'blue'),
             ('TO', 'blue'),
             ('TRANSACTION', 'blue'),
             ('UNION', 'blue'),
             ('UNIQUE', 'blue'),
             ('USER', 'blue'),
             ('USING', 'blue'),
             ('VALUE', 'blue'),
             ('VALUES', 'blue'),
             ('VARCHAR', 'blue'),
             ('VARYING', 'blue'),
             ('VIEW', 'blue'),
             ('WHEN', 'blue'),
             ('WHERE', 'blue'),
             ('WITH', 'blue'),
             ('ZONE', 'blue')) AS frw(ReservedWord, SSMSColor);
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.SystemDataTypeNames
AS
/* 

-- View:          SystemDataTypeNames
-- Action:        View returning SQL Server system data type names, and the color they normally appear in SSMS
-- Return:        One row per data type name.
-- Refer to this video: https://youtu.be/WITnoiWRPsI
--
-- Test examples: 

SELECT * FROM SDU_Tools.SystemDataTypeNames;

*/

SELECT DataTypeName, SSMSColor
FROM (VALUES ('bigint', 'blue'),
             ('binary', 'blue'),
             ('bit', 'blue'),
             ('char', 'blue'),
             ('date', 'blue'),
             ('datetime', 'blue'),
             ('datetime2', 'blue'),
             ('datetimeoffset', 'blue'),
             ('decimal', 'blue'),
             ('edge', 'blue'),
             ('float', 'blue'),
             ('geography', 'blue'),
             ('geometry', 'blue'),
             ('hierarchyid', 'blue'),
             ('image', 'blue'),
             ('int', 'blue'),
             ('money', 'blue'),
             ('nchar', 'blue'),
             ('node', 'blue'),
             ('ntext', 'blue'),
             ('numeric', 'blue'),
             ('nvarchar', 'blue'),
             ('real', 'blue'),
             ('smalldatetime', 'blue'),
             ('smallint', 'blue'),
             ('smallmoney', 'blue'),
             ('sql_variant', 'blue'),
             ('sysname', 'blue'),
             ('table', 'blue'),
             ('text', 'blue'),
             ('time', 'blue'),
             ('timestamp', 'blue'),
             ('tinyint', 'blue'),
             ('uniqueidentifier', 'blue'),
             ('varbinary', 'blue'),
             ('varchar', 'blue'),
             ('xml', 'blue')) AS dtn(DataTypeName, SSMSColor);
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.SystemWords
AS
/* 

-- View:          SystemWords
-- Action:        View returning SQL Server reserved words, future reserved words, ODBC 
--                reserved words, and system data type names, and the color they normally appear in SSMS
-- Return:        One row per system word with the SystemWord, SSMSColor, IsReservedWord, IsFutureReservedWord,
--                IsODBCReservedWord, IsSystemDataTypeName
-- Refer to this video: https://youtu.be/WITnoiWRPsI
--
-- Test examples: 

SELECT * FROM SDU_Tools.SystemWords ORDER BY SystemWord;

*/

SELECT SystemWord, 
       SSMSColor, 
       CAST(SUM(IsReservedWord) AS bit) AS IsReservedWord, 
       CAST(SUM(IsFutureReservedWord) AS bit) AS IsFutureReservedWord, 
       CAST(SUM(IsODBCReservedWord) AS bit) AS IsODBCReservedWord, 
       CAST(SUM(IsSystemDataTypeName) AS bit) AS IsSystemDataTypeName
FROM (
         SELECT rw.ReservedWord AS SystemWord, 
                rw.SSMSColor, 
                1 AS IsReservedWord, 
                0 AS IsFutureReservedWord, 
                0 AS IsODBCReservedWord, 
                0 AS IsSystemDataTypeName 
         FROM SDU_Tools.ReservedWords AS rw
         UNION ALL 
         SELECT frw.ReservedWord, frw.SSMSColor, 0, 1, 0, 0
         FROM SDU_Tools.FutureReservedWords AS frw
         UNION ALL
         SELECT orw.ReservedWord, orw.SSMSColor, 0, 0, 1, 0
         FROM SDU_Tools.ODBCReservedWords AS orw
         UNION ALL 
         SELECT sdtn.DataTypeName, sdtn.SSMSColor, 0, 0, 0, 1
         FROM SDU_Tools.SystemDataTypeNames AS sdtn 
    ) AS sw
GROUP BY SystemWord, SSMSColor;
GO

------------------------------------------------------------------------------------

-- CREATE PROCEDURE SDU_Tools.CreateLinkedServerToAzureSQLDatabase (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.SystemConfigurationOptionDefaults
AS
/* 

-- View:          SystemConfigurationOptionDefaults
-- Action:        View returning SQL Server Configuration Option Default values
-- Return:        One row per configuration option
-- Refer to this video: https://youtu.be/PZy2zWH0Nzc
--
-- Test examples: 

SELECT * FROM SDU_Tools.SystemConfigurationOptionDefaults;

*/

SELECT CAST(ConfigurationOptionName AS varchar(35)) AS ConfigurationOptionName,
       CAST(MinimumValue AS int) AS MinimumValue,
       CAST(MaximumValue AS int) AS MaximumValue,
       CAST(DefaultValue AS int) AS DefaultValue,
       CAST(IsAdvanced AS bit) AS IsAdvanced,
       CAST(IsRestartRequired AS bit) AS IsRestartRequired,
       CAST(IsRestartPolybaseRequired AS bit) AS IsRestartPolybaseRequired,
       CAST(IsSelfConfiguring AS bit) AS IsSelfConfiguring,
       CAST(IsDeprecated AS bit) AS IsDeprecated,
       CAST(IsObsolete AS bit) AS IsObsolete,
       CAST(DocumentationURL AS nvarchar(max)) AS DocumentationURL
FROM (VALUES 
('access check cache bucket count',0,16384,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/access-check-cache-server-configuration-options'),
('access check cache quota',0,2147483647,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/access-check-cache-server-configuration-options'),
('ad hoc distributed queries',0,1,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/ad-hoc-distributed-queries-server-configuration-option'),
('affinity I/O mask',-2147483648,2147483647,0,1,1,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/affinity-input-output-mask-server-configuration-option'),
('affinity64 I/O mask',-2147483648,2147483647,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/affinity64-input-output-mask-server-configuration-option'),
('affinity mask',-2147483648,2147483647,0,1,0,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/affinity-mask-server-configuration-option'),
('affinity64 mask',-2147483648,2147483647,0,1,1,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/affinity64-mask-server-configuration-option'),
('Agent XPs',0,1,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/agent-xps-server-configuration-option'),
('allow updates',0,1,0,0,0,0,0,1,1,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/allow-updates-server-configuration-option'),
('automatic soft-NUMA disabled',0,1,0,0,0,0,0,0,0,'http://msdn.microsoft.com/library/ms345357.aspx'),
('backup checksum default',0,1,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/backup-checksum-default'),
('backup compression default',0,1,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/view-or-configure-the-backup-compression-default-server-configuration-option'),
('blocked process threshold',0,86400,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/blocked-process-threshold-server-configuration-option'),
('c2 audit mode',0,1,0,1,1,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/c2-audit-mode-server-configuration-option'),
('clr enabled',0,1,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/clr-enabled-server-configuration-option'),
('clr strict security',0,1,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/clr-strict-security'),
('common criteria compliance enabled',0,1,0,1,1,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/common-criteria-compliance-enabled-server-configuration-option'),
('contained database authentication',0,1,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/contained-database-authentication-server-configuration-option'),
('cost threshold for parallelism',0,32767,5,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-cost-threshold-for-parallelism-server-configuration-option'),
('cross db ownership chaining',0,1,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/cross-db-ownership-chaining-server-configuration-option'),
('cursor threshold',-1,2147483647,-1,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-cursor-threshold-server-configuration-option'),
('Database Mail XPs',0,1,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/database-mail-xps-server-configuration-option'),
('default full-text language',0,2147483647,1033,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-default-full-text-language-server-configuration-option'),
('default language',0,9999,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-default-language-server-configuration-option'),
('default trace enabled',0,1,1,1,0,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/default-trace-enabled-server-configuration-option'),
('disallow results from triggers',0,1,0,1,0,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/disallow-results-from-triggers-server-configuration-option'),
('EKM provider enabled',0,1,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/ekm-provider-enabled-server-configuration-option'),
('external scripts enabled',0,1,0,0,1,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/external-scripts-enabled-server-configuration-option'),
('filestream_access_level',0,2,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/filestream-access-level-server-configuration-option'),
('fill factor',0,100,0,1,1,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-fill-factor-server-configuration-option'),
('ft crawl bandwidth (max)',0,32767,100,1,0,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/ft-crawl-bandwidth-server-configuration-option'),
('ft crawl bandwidth (min)',0,32767,0,1,0,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/ft-crawl-bandwidth-server-configuration-option'),
('ft notify bandwidth (max)',0,32767,100,1,0,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/ft-notify-bandwidth-server-configuration-option'),
('ft notify bandwidth (min)',0,32767,0,1,0,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/ft-notify-bandwidth-server-configuration-option'),
('index create memory',704,2147483647,0,1,0,0,1,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-index-create-memory-server-configuration-option'),
('in-doubt xact resolution',0,2,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/in-doubt-xact-resolution-server-configuration-option'),
('lightweight pooling',0,1,0,1,1,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/lightweight-pooling-server-configuration-option'),
('locks',5000,2147483647,0,1,1,0,1,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-locks-server-configuration-option'),
('max degree of parallelism',0,32767,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option'),
('max full-text crawl range',0,256,4,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/max-full-text-crawl-range-server-configuration-option'),
('max server memory',16,2147483647,2147483647,1,0,0,1,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/server-memory-server-configuration-options'),
('max text repl size',0,2147483647,65536,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-text-repl-size-server-configuration-option'),
('max worker threads',128,2048,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-worker-threads-server-configuration-option'),
('media retention',0,365,0,1,1,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-media-retention-server-configuration-option'),
('min memory per query',512,2147483647,1024,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-min-memory-per-query-server-configuration-option'),
('min server memory',0,2147483647,0,1,0,0,1,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/server-memory-server-configuration-options'),
('nested triggers',0,1,1,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-nested-triggers-server-configuration-option'),
('network packet size',512,32767,4096,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-network-packet-size-server-configuration-option'),
('Ole Automation Procedures',0,1,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/ole-automation-procedures-server-configuration-option'),
('open objects',0,2147483647,0,1,1,0,0,0,1,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/open-objects-server-configuration-option'),
('optimize for ad hoc workloads',0,1,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/optimize-for-ad-hoc-workloads-server-configuration-option'),
('PH_timeout',1,3600,60,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/ph-timeout-server-configuration-option'),
('PolyBase Hadoop and Azure blob storage',0,7,0,0,0,1,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/polybase-connectivity-configuration-transact-sql'),
('precompute rank',0,1,0,1,0,0,0,0,1,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/precompute-rank-server-configuration-option'),
('priority boost',0,1,0,1,1,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-priority-boost-server-configuration-option'),
('query governor cost limit',0,2147483647,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-query-governor-cost-limit-server-configuration-option'),
('query wait',-1,2147483647,-1,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-query-wait-server-configuration-option'),
('recovery interval',0,32767,0,1,0,0,1,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-recovery-interval-server-configuration-option'),
('remote access',0,1,1,0,1,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-remote-access-server-configuration-option'),
('remote admin connections',0,1,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/remote-admin-connections-server-configuration-option'),
('remote data archive',0,1,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-remote-data-archive-server-configuration-option'),
('remote login timeout',0,2147483647,10,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-remote-login-timeout-server-configuration-option'),
('remote proc trans',0,1,0,0,0,0,0,1,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-remote-proc-trans-server-configuration-option'),
('remote query timeout',0,2147483647,600,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-remote-query-timeout-server-configuration-option'),
('Replication XPs Option',0,1,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/replication-xps-server-configuration-option'),
('scan for startup procs',0,1,0,1,1,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-scan-for-startup-procs-server-configuration-option'),
('server trigger recursion',0,1,1,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/server-trigger-recursion-server-configuration-option'),
('set working set size',0,1,0,1,1,0,0,0,1,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/set-working-set-size-server-configuration-option'),
('show advanced options',0,1,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/show-advanced-options-server-configuration-option'),
('SMO and DMO XPs',0,1,1,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/smo-and-dmo-xps-server-configuration-option'),
('transform noise words',0,1,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/transform-noise-words-server-configuration-option'),
('two digit year cutoff',1753,9999,2049,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-two-digit-year-cutoff-server-configuration-option'),
('user connections',0,32767,0,1,1,0,1,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-user-connections-server-configuration-option'),
('user options',0,32767,0,0,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-user-options-server-configuration-option'),
('xp_cmdshell',0,1,0,1,0,0,0,0,0,'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/xp-cmdshell-server-configuration-option')
) AS c(ConfigurationOptionName, MinimumValue, MaximumValue, DefaultValue, IsAdvanced, IsRestartRequired, IsRestartPolybaseRequired, IsSelfConfiguring, IsDeprecated, IsObsolete, DocumentationURL);
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.NonDefaultSystemConfigurationOptions
AS
/* 

-- View:          NonDefaultSystemConfigurationOptions
-- Action:        View returning SQL Server Configuration options 
--                that are not at their default values
-- Return:        One row per altered configuration option
-- Refer to this video: https://youtu.be/PZy2zWH0Nzc
--
-- Test examples: 

SELECT * FROM SDU_Tools.NonDefaultSystemConfigurationOptions;

*/

SELECT scod.ConfigurationOptionName, scod.DefaultValue, c.[value] AS ConfiguredValue, c.value_in_use AS CurrentValue
FROM sys.configurations AS c
INNER JOIN SDU_Tools.SystemConfigurationOptionDefaults AS scod 
ON c.[description] = scod.ConfigurationOptionName COLLATE DATABASE_DEFAULT 
WHERE c.[value] <> scod.DefaultValue;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.SQLServerVersionForCompatibilityLevel
(
    @DatabaseCompatibilityLevel tinyint
)
RETURNS varchar(7)
AS
BEGIN

-- Function:      Converts a database compatibility level to a SQL Server version
-- Parameters:    @DatabaseCompatibilityLevel tinyint
-- Action:        Converts a database compatibility level to a SQL Server version
--                and returns NULL if not recognized
-- Return:        nvarchar(4)
-- Refer to this video: https://youtu.be/3i6xB7guzVM
--
-- Test examples: 
/*

SELECT SDU_Tools.SQLServerVersionForCompatibilityLevel(110);
SELECT SDU_Tools.SQLServerVersionForCompatibilityLevel(140);

*/

    RETURN CASE @DatabaseCompatibilityLevel 
                WHEN 80 THEN '2000'
                WHEN 90 THEN '2005'
                WHEN 100 THEN '2008'
                WHEN 110 THEN '2012'
                WHEN 120 THEN '2014'
                WHEN 130 THEN '2016'
                WHEN 140 THEN '2017'
                WHEN 150 THEN '2019'
           END;
END;
GO


------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.JulianDayNumberToDate
(
    @JulianDayNumber int
)
RETURNS date 
AS 
BEGIN

-- Function:      Converts a Julian day number to a date
-- Parameters:    @JulianDayNumber int - value to be converted
-- Action:        Converts the Julian day number to a date
--                The value must be between 1721426 ('00010101') and 5373120 ('99990101')
-- Return:        date
-- Refer to this video: https://youtu.be/eLk2Bgj-aPo
--
-- Test examples: 
/*

SELECT SDU_Tools.JulianDayNumberToDate(2451545);
SELECT SDU_Tools.JulianDayNumberToDate(1721426);


*/
    RETURN CASE WHEN @JulianDayNumber BETWEEN 1721426 AND 5373120
                THEN DATEADD(day, @JulianDayNumber - 1721426, CAST('00010101' AS date))
           END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DateToJulianDayNumber
(
    @DateToConvert date
)
RETURNS int 
AS 
BEGIN

-- Function:      Converts a date to a Julian day number
-- Parameters:    @DateToConvert date - date to be converted
-- Action:        Converts the date to a Julian day number
-- Return:        int
-- Refer to this video: https://youtu.be/eLk2Bgj-aPo
--
-- Test examples: 
/*

SELECT SDU_Tools.DateToJulianDayNumber('20000101');
SELECT SDU_Tools.DateToJulianDayNumber('00010101');

*/
    RETURN 1721426 + DATEDIFF(day, CAST('00010101' AS date), @DateToConvert);
END;
GO

--------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DatesBetween
(
    @StartDate date,
    @EndDate date 
)
RETURNS @Dates TABLE
(
    DateNumber int IDENTITY(1,1) PRIMARY KEY,
    DateValue date
)
AS
-- Function:      Returns a table of dates 
-- Parameters:    @StartDate date => first date to return
--                @EndDate => last date to return
-- Action:        Returns a table of dates between the two dates supplied (inclusive)
-- Return:        Rowset with DateNumber as int and DateValue as a date
-- Refer to this video: https://youtu.be/oxJi41TnE94
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.DatesBetween('20170101', '20170131');
SELECT * FROM SDU_Tools.DatesBetween('20170131', '20170101');

*/
BEGIN
    DECLARE @CurrentValue date = @StartDate;

    WHILE @CurrentValue <= @EndDate 
    BEGIN
        INSERT @Dates (DateValue) VALUES (@CurrentValue);
        SET @CurrentValue = DATEADD(day, 1, @CurrentValue);
    END;

    RETURN;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DateDimensionColumns
(
    @Date date,
    @FiscalYearStartMonth int
)
RETURNS TABLE
AS
-- Function:      Returns a table (single row) of date dimension columns
-- Parameters:    @Date date => date to process
--                @FiscalYearStartMonth int => month number when the financial year starts
-- Action:        Returns a single row table with date dimension columns
-- Return:        Single row rowset with date dimension columns
-- Refer to this video: https://youtu.be/oxJi41TnE94
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.DateDimensionColumns('20170131', 7);

SELECT ddc.* 
FROM SDU_Tools.DatesBetween('20180201', '20180401') AS db
CROSS APPLY SDU_Tools.DateDimensionColumns(db.DateValue, 7) AS ddc
ORDER BY db.DateValue;

*/
RETURN SELECT @Date AS [Date],
              DAY(@Date) AS DayNumber,
              DATENAME(weekday, @Date) AS [DayName],
              LEFT(DATENAME(weekday, @Date), 3) AS ShortDayName,
              CAST(DATENAME(month, @Date) AS nvarchar(10)) AS MonthName,
              CAST(SUBSTRING(DATENAME(month, @Date), 1, 3) AS nvarchar(3)) AS ShortMonthName,
              MONTH(@Date) AS [MonthNumber],
              N'CY' + CAST(YEAR(@Date) AS nvarchar(4)) + N'-' + SUBSTRING(DATENAME(month, @Date), 1, 3) AS MonthLabel,
              (MONTH(@Date) - 1) / 3 + 1 AS QuarterNumber,
              N'CYQ' + CAST((MONTH(@Date) - 1) / 3 + 1 AS nvarchar(10)) AS QuarterLabel,
              YEAR(@Date) AS [Year],
              CAST(N'CY' + CAST(YEAR(@Date) AS nvarchar(4)) AS nvarchar(10)) AS YearLabel,
              DATEPART(dayofyear, @Date) AS DayOfYear,
              CASE WHEN MONTH(@Date) >= @FiscalYearStartMonth
                   THEN MONTH(@Date) - @FiscalYearStartMonth + 1
                   ELSE MONTH(@Date) + 13 - @FiscalYearStartMonth
              END AS FiscalMonthNumber,
              N'FY' + CAST(CASE WHEN MONTH(@Date) >= @FiscalYearStartMonth
                                THEN YEAR(@Date) + 1
                                ELSE YEAR(@Date)
                           END AS nvarchar(4)) + N'-' + SUBSTRING(DATENAME(month, @Date), 1, 3) AS FiscalMonthLabel,
              (CASE WHEN MONTH(@Date) >= @FiscalYearStartMonth
                   THEN MONTH(@Date) - @FiscalYearStartMonth + 1
                   ELSE MONTH(@Date) + 13 - @FiscalYearStartMonth
               END - 1) / 3 + 1 AS FiscalQuarterNumber,
              N'FYQ' + CAST((CASE WHEN MONTH(@Date) >= @FiscalYearStartMonth
                                  THEN MONTH(@Date) - @FiscalYearStartMonth + 1
                                  ELSE MONTH(@Date) + 13 - @FiscalYearStartMonth
                             END - 1) / 3 + 1 AS nvarchar(10)) AS FiscalQuarterLabel,
              CASE WHEN MONTH(@Date) >= @FiscalYearStartMonth
                   THEN YEAR(@Date) + 1
                   ELSE YEAR(@Date)
              END AS FiscalYear,
              N'FY' + CAST(CASE WHEN MONTH(@Date) >= @FiscalYearStartMonth
                                THEN YEAR(@Date) + 1
                                ELSE YEAR(@Date)
                           END AS nvarchar(4)) AS FiscalYearLabel,
              CASE WHEN MONTH(@Date) >= @FiscalYearStartMonth 
                   THEN DATEDIFF(day, 
                                 CAST(CAST(YEAR(@Date) AS nvarchar(4)) 
                                      + RIGHT(N'0' + CAST(@FiscalYearStartMonth AS nvarchar(2)), 2) 
                                      + N'01' AS date),
                                 @Date) + 1
                   ELSE DATEDIFF(day, 
                                 CAST(CAST(YEAR(@Date) - 1 AS nvarchar(4)) 
                                      + RIGHT(N'0' + CAST(@FiscalYearStartMonth AS nvarchar(2)), 2) 
                                      + N'01' AS date),
                                 @Date) + 1
              END AS DayOfFiscalYear,
              DATEPART(ISO_WEEK, @Date) AS ISOWeekNumber,
              YEAR(@Date) * 10000 + MONTH(@Date) * 100 + DAY(@Date) AS DateKey,
              DATEFROMPARTS(YEAR(@Date), MONTH(@Date), 1) AS StartOfMonthDate,
              EOMONTH(@Date) AS EndOfMonthDate;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.TrainCase
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Apply Train Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Train Casing to a string 
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/6IcLkMEQtkY
--
-- Test examples: 
/*

SELECT SDU_Tools.TrainCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.TrainCase(N'janet mcdermott');
SELECT SDU_Tools.TrainCase(N'the case of sherlock holmes and the curly-Haired  company');

*/
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @WordCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    DECLARE @CurrentWord nvarchar(max);
    DECLARE @NumberOfWords int;
    
    DECLARE @Words TABLE
    (
        WordNumber int IDENTITY(1,1),
        Word nvarchar(max)
    );
    
    SET @StringToProcess = LOWER(LTRIM(RTRIM(@InputString)));
    SET @InAWord = 0;
    SET @CurrentWord = N'';
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', N'-', NCHAR(9)) -- whitespace or hyphens
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
                INSERT @Words VALUES (@CurrentWord);
                SET @CurrentWord = N'';
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                SET @CurrentWord = @Character;
            END ELSE BEGIN -- part of a word
                SET @CurrentWord += @Character;
            END;
        END;
    END;
    IF @InAWord <> 0 
    BEGIN
        INSERT @Words VALUES (@CurrentWord);
    END;
    
    UPDATE @Words SET Word = UPPER(SUBSTRING(Word, 1, 1)) + SUBSTRING(Word, 2, LEN(Word) - 1);

    SET @NumberOfWords = (SELECT COUNT(*) FROM @Words);
    SET @WordCounter = 0;
    
    WHILE @WordCounter < @NumberOfWords
    BEGIN
        SET @WordCounter += 1;
        SET @CurrentWord = (SELECT Word FROM @Words WHERE WordNumber = @WordCounter);
        SET @Response += CASE WHEN @WordCounter > 1 THEN N'-' ELSE N'' END + @CurrentWord;
    END;
    
    RETURN @Response;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ScreamingSnakeCase
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Apply Screaming Snake Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Screaming Snake Casing to a string (similar to programming identifiers)
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/6IcLkMEQtkY
--
-- Test examples: 
/*

SELECT SDU_Tools.ScreamingSnakeCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.ScreamingSnakeCase(N'janet mcdermott');
SELECT SDU_Tools.ScreamingSnakeCase(N'the case of sherlock holmes and the curly-Haired  company');

*/
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @WordCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    DECLARE @CurrentWord nvarchar(max);
    DECLARE @NumberOfWords int;
    
    DECLARE @Words TABLE
    (
        WordNumber int IDENTITY(1,1),
        Word nvarchar(max)
    );
    
    SET @StringToProcess = LOWER(LTRIM(RTRIM(@InputString)));
    SET @InAWord = 0;
    SET @CurrentWord = N'';
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', N'-', NCHAR(9)) -- whitespace or hyphens
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
                INSERT @Words VALUES (@CurrentWord);
                SET @CurrentWord = N'';
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                SET @CurrentWord = @Character;
            END ELSE BEGIN -- part of a word
                SET @CurrentWord += @Character;
            END;
        END;
    END;
    IF @InAWord <> 0 
    BEGIN
        INSERT @Words VALUES (@CurrentWord);
    END;
    
    SET @NumberOfWords = (SELECT COUNT(*) FROM @Words);
    SET @WordCounter = 0;
    
    WHILE @WordCounter < @NumberOfWords
    BEGIN
        SET @WordCounter += 1;
        SET @CurrentWord = (SELECT Word FROM @Words WHERE WordNumber = @WordCounter);
        SET @Response += CASE WHEN @WordCounter > 1 THEN N'_' ELSE N'' END + @CurrentWord;
    END;
    
    RETURN UPPER(@Response);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.SpongeBobSnakeCase
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Apply SpongeBob Snake Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply SpongeBob Snake Casing to a string
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/6IcLkMEQtkY
--
-- Test examples: 
/*

SELECT SDU_Tools.SpongeBobSnakeCase(N'SpongeBob SnakeCase');
SELECT SDU_Tools.SpongeBobSnakeCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.SpongeBobSnakeCase(N'janet mcdermott');
SELECT SDU_Tools.SpongeBobSnakeCase(N'the case of sherlock holmes and the curly-Haired  company');

*/
    DECLARE @UnformattedResponse nvarchar(max) = N'';
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @WordCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    DECLARE @CurrentWord nvarchar(max);
    DECLARE @NumberOfWords int;
    DECLARE @IsNextUpper bit = 0;
    
    DECLARE @Words TABLE
    (
        WordNumber int IDENTITY(1,1),
        Word nvarchar(max)
    );
    
    SET @StringToProcess = LOWER(LTRIM(RTRIM(@InputString)));
    SET @InAWord = 0;
    SET @CurrentWord = N'';
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', N'-', NCHAR(9)) -- whitespace or hyphens
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
                INSERT @Words VALUES (@CurrentWord);
                SET @CurrentWord = N'';
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                SET @CurrentWord = @Character;
            END ELSE BEGIN -- part of a word
                SET @CurrentWord += @Character;
            END;
        END;
    END;
    IF @InAWord <> 0 
    BEGIN
        INSERT @Words VALUES (@CurrentWord);
    END;
    
    SET @NumberOfWords = (SELECT COUNT(*) FROM @Words);
    SET @WordCounter = 0;
    
    WHILE @WordCounter < @NumberOfWords
    BEGIN
        SET @WordCounter += 1;
        SET @CurrentWord = (SELECT Word FROM @Words WHERE WordNumber = @WordCounter);
        SET @UnformattedResponse += CASE WHEN @WordCounter > 1 THEN N'_' ELSE N'' END + @CurrentWord;
    END;
    
    SET @CharacterCounter = 0;
    WHILE @CharacterCounter < LEN(@UnformattedResponse)
    BEGIN
        SET @CharacterCounter += 1;
        IF @IsNextUpper = 0
        BEGIN
            SET @Response += SUBSTRING(@UnformattedResponse, @CharacterCounter, 1);
            SET @IsNextUpper = 1;
        END ELSE BEGIN
            SET @Response += UPPER(SUBSTRING(@UnformattedResponse, @CharacterCounter, 1));
            SET @IsNextUpper = 0;
        END;
    END;

    RETURN @Response;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.NumberAsText
(
    @InputNumber bigint
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Converts a number to a text string
-- Parameters:    @InputNumber bigint - the value to be converted
-- Action:        Converts a number to a text string (using English words)
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/_jgU-5jUUA8
--
-- Test examples: 
/*

SELECT SDU_Tools.NumberAsText(2);
SELECT SDU_Tools.NumberAsText(12342);
SELECT SDU_Tools.NumberAsText(322342);
SELECT SDU_Tools.NumberAsText(13);
SELECT SDU_Tools.NumberAsText(34);

SELECT SDU_Tools.NumberAsText(345543234242);

SELECT SDU_Tools.NumberAsText(967) + N' dollars ' + SDU_Tools.NumberAsText(34) + N' cents';
SELECT UPPER(SDU_Tools.NumberAsText(967) + N' dollars ' + SDU_Tools.NumberAsText(34) + N' cents');
SELECT REPLACE(UPPER(SDU_Tools.NumberAsText(967) + N' dollars ' + SDU_Tools.NumberAsText(34) + N' cents'), N'DOLLARS', N'DOLLARS,');

*/
    DECLARE @Billions bigint;
    DECLARE @Millions int;
    DECLARE @Thousands int;
    DECLARE @Units int;
    
    DECLARE @BillionWord nvarchar(20) = N'billion';
    DECLARE @MillionWord nvarchar(20) = N'million';
    DECLARE @ThousandWord nvarchar(20) = N'thousand';
    DECLARE @HundredWord nvarchar(20) = N'hundred';
    DECLARE @AndWord nvarchar(20) = N'and';

    DECLARE @NumbersAsWords TABLE
    (
        NumberValue int,
        NumberAsWord nvarchar(20)
    );
    INSERT @NumbersAsWords (NumberValue, NumberAsWord)
    VALUES (1, N'one'), (2, N'two'), (3, N'three'), (4, N'four'), (5, N'five'),
           (6, N'six'), (7, N'seven'), (8, N'eight'), (9, N'nine'), (10, N'ten'),
           (11, N'eleven'), (12, N'twelve'), (13, N'thirteen'), (14, N'fourteen'), (15, N'fifteen'),
           (16, N'sixteen'), (17, N'seventeen'), (18, N'eighteen'), (19, N'nineteen'), (20, N'twenty'),
           (30, N'thirty'), (40, N'forty'), (50, N'fifty'), (60, N'sixty'), (70, N'seventy'),
           (80, N'eighty'), (90, N'ninety');

    DECLARE @HundredsPart int;
    DECLARE @TensPart int;
    DECLARE @UnitsPart int;
    DECLARE @PartString nvarchar(200);

    DECLARE @ReturnValue nvarchar(max) = N'';

    DECLARE @RemainingValue bigint = @InputNumber;

    SET @Billions = FLOOR(@RemainingValue / 1000000000.0);
    SET @RemainingValue = @RemainingValue - (@Billions * 1000000000);

    IF @Billions > 0
    BEGIN
        IF @Billions > 999 
        BEGIN
            SET @ReturnValue += CAST(@Billions AS nvarchar(20));
        END ELSE BEGIN
            SET @PartString = N'';
            SET @HundredsPart = FLOOR(@Billions / 100.0);
            SET @TensPart = FLOOR((@Billions - (@HundredsPart * 100)) / 10.0);
            SET @UnitsPart = @Billions - (@HundredsPart * 100) - (@TensPart * 10);
            SET @PartString += CASE WHEN @HundredsPart > 0 
                                    THEN (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = @HundredsPart)
                                         + N' ' + @HundredWord
                                    ELSE N'' 
                               END
                             + CASE WHEN @HundredsPart > 0 AND (@TensPart > 0 OR @UnitsPart > 0)
                                    THEN N' ' + @AndWord + N' '
                                    ELSE N'' 
                               END
                             + CASE WHEN @TensPart > 0 OR @UnitsPart > 0
                                    THEN CASE WHEN @TensPart >= 2
                                              THEN (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = (@TensPart * 10))
                                                   + CASE WHEN @UnitsPart = 0 
                                                          THEN N''
                                                          ELSE N'-'
                                                               + (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = @UnitsPart)
                                                     END 
                                              ELSE (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = (@TensPart * 10 + @UnitsPart))
                                         END 
                                    ELSE N''
                               END
                             
        END;
        
        SET @ReturnValue += @PartString + N' ' + @BillionWord;
    END;

    SET @Millions = FLOOR(@RemainingValue / 1000000.0);
    SET @RemainingValue = @RemainingValue - (@Millions * 1000000);
    
    IF @Millions > 0
    BEGIN
        SET @ReturnValue += CASE WHEN @Billions > 0 THEN N' ' ELSE N'' END;
        SET @PartString = N'';
        SET @HundredsPart = FLOOR(@Millions / 100.0);
        SET @TensPart = FLOOR((@Millions - (@HundredsPart * 100)) / 10.0);
        SET @UnitsPart = @Millions - (@HundredsPart * 100) - (@TensPart * 10);
        SET @PartString += CASE WHEN @HundredsPart > 0 
                                THEN (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = @HundredsPart)
                                     + N' ' + @HundredWord
                                ELSE N'' 
                           END
                         + CASE WHEN @HundredsPart > 0 AND (@TensPart > 0 OR @UnitsPart > 0)
                                THEN N' ' + @AndWord + N' '
                                ELSE N'' 
                           END
                         + CASE WHEN @TensPart > 0 OR @UnitsPart > 0
                                THEN CASE WHEN @TensPart >= 2
                                          THEN (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = (@TensPart * 10))
                                               + CASE WHEN @UnitsPart = 0 
                                                      THEN N''
                                                      ELSE N'-'
                                                           + (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = @UnitsPart)
                                                 END 
                                          ELSE (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = (@TensPart * 10 + @UnitsPart))
                                     END 
                                ELSE N''
                           END
                         
        
        
        SET @ReturnValue += @PartString + N' ' + @MillionWord;
    END;

    SET @Thousands = FLOOR(@RemainingValue / 1000.0);

    IF @Thousands > 0
    BEGIN
        SET @ReturnValue += CASE WHEN @Billions > 0 OR @Millions > 0 THEN N' ' ELSE N'' END;
        SET @PartString = N'';
        SET @HundredsPart = FLOOR(@Thousands / 100.0);
        SET @TensPart = FLOOR((@Thousands - (@HundredsPart * 100)) / 10.0);
        SET @UnitsPart = @Thousands - (@HundredsPart * 100) - (@TensPart * 10);
        SET @PartString += CASE WHEN @HundredsPart > 0 
                                THEN (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = @HundredsPart)
                                     + N' ' + @HundredWord
                                ELSE N'' 
                           END
                         + CASE WHEN @HundredsPart > 0 AND (@TensPart > 0 OR @UnitsPart > 0)
                                THEN N' ' + @AndWord + N' '
                                ELSE N'' 
                           END
                         + CASE WHEN @TensPart > 0 OR @UnitsPart > 0
                                THEN CASE WHEN @TensPart >= 2
                                          THEN (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = (@TensPart * 10))
                                               + CASE WHEN @UnitsPart = 0 
                                                      THEN N''
                                                      ELSE N'-'
                                                           + (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = @UnitsPart)
                                                 END 
                                          ELSE (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = (@TensPart * 10 + @UnitsPart))
                                     END 
                                ELSE N''
                           END
                         
        
        
        SET @ReturnValue += @PartString + N' ' + @ThousandWord;
    END;

    SET @Units = @RemainingValue - (@Thousands * 1000);

    IF @Units > 0
    BEGIN
        SET @ReturnValue += CASE WHEN @Billions > 0 OR @Millions > 0 OR @Thousands > 0 THEN N' ' ELSE N'' END;
        SET @PartString = N'';
        SET @HundredsPart = FLOOR(@Units / 100.0);
        SET @TensPart = FLOOR((@Units - (@HundredsPart * 100)) / 10.0);
        SET @UnitsPart = @Units - (@HundredsPart * 100) - (@TensPart * 10);
        SET @PartString += CASE WHEN @HundredsPart > 0 
                                THEN (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = @HundredsPart)
                                     + N' ' + @HundredWord
                                ELSE N'' 
                           END
                         + CASE WHEN @HundredsPart > 0 AND (@TensPart > 0 OR @UnitsPart > 0)
                                THEN N' ' + @AndWord + N' '
                                ELSE N'' 
                           END
                         + CASE WHEN @TensPart > 0 OR @UnitsPart > 0
                                THEN CASE WHEN @TensPart >= 2
                                          THEN (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = (@TensPart * 10))
                                               + CASE WHEN @UnitsPart = 0 
                                                      THEN N''
                                                      ELSE N'-'
                                                           + (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = @UnitsPart)
                                                 END 
                                          ELSE (SELECT NumberAsWord FROM @NumbersAsWords WHERE NumberValue = (@TensPart * 10 + @UnitsPart))
                                     END 
                                ELSE N''
                           END
                         
        
        
        SET @ReturnValue += @PartString;
    END;

    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.TimePeriodDimensionColumns
(
    @TimeOfDay datetime2,
    @MinutesPerPeriod int
)
RETURNS TABLE
AS
-- Function:      Returns a table (single row) of time period dimension columns
-- Parameters:    @TimeOfDay datetime2 => time of day to process as a time period row
--                @MinutesPerPeriod => number of minutes in each time period for the day
-- Action:        Returns a single row table with time period dimension columns
-- Return:        Single row rowset with time period dimension columns
-- Refer to this video: https://youtu.be/14UrzoIgrwA
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.TimePeriodDimensionColumns('10:17 AM', 15);
SELECT * FROM SDU_Tools.TimePeriodDimensionColumns('8:34 PM', 15);

*/
RETURN 
(
    WITH PeriodNumber
    AS
    (
        SELECT FLOOR(DATEDIFF(minute, CAST(@TimeOfDay AS date), @TimeOfDay) / @MinutesPerPeriod) AS TimePeriodKey,
               DATEADD(minute, @MinutesPerPeriod * FLOOR(DATEDIFF(minute, CAST(@TimeOfDay AS date), @TimeOfDay) / @MinutesPerPeriod), '20160101') AS StartOfPeriod
    )
    SELECT pn.TimePeriodKey,
           DATEPART(hour, pn.StartOfPeriod) AS [Hour],
           CASE WHEN DATEPART(hour, pn.StartOfPeriod) = 0 
                THEN CAST('12' AS varchar(2)) 
                ELSE CASE WHEN DATEPART(hour, pn.StartOfPeriod) > 12
                          THEN RIGHT('0' + CAST(DATEPART(hour, pn.StartOfPeriod) - 12 AS varchar(2)), 2)
                          ELSE RIGHT('0' + CAST(DATEPART(hour, pn.StartOfPeriod) AS varchar(2)), 2)
                     END 
           END AS [AM PM Hour Label],
           RIGHT('0' + CAST(DATEPART(hour, pn.StartOfPeriod) AS varchar(2)), 2) AS [24 Hour Label],
           DATEPART(minute, pn.StartOfPeriod) AS [Minute],
           RIGHT('0' + CAST(DATEPART(minute, pn.StartOfPeriod) AS varchar(2)), 2) AS [Minute Label],
           CASE WHEN DATEPART(hour, pn.StartOfPeriod) >= 12 THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END AS [Is AM],
           CASE WHEN DATEPART(hour, pn.StartOfPeriod) >= 12 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS [Is PM],
           CASE WHEN DATEPART(hour, pn.StartOfPeriod) >= 12 THEN CAST('PM' AS varchar(2)) ELSE CAST('AM' AS varchar(2)) END AS [AM PM Label],
           REPLACE(RIGHT('0' + LTRIM(RIGHT(CONVERT(varchar(30), DATEADD(minute, 15 * pn.TimePeriodKey, '20160101'), 109), 14)), 14), ':00:000', ' ') AS [Time Period Label],
           LEFT(CONVERT(varchar(100), pn.StartOfPeriod, 108), 5) AS [Time Period 24 Hour Label],
          pn.TimePeriodKey * @MinutesPerPeriod AS [Time Period Minute of Day]
    FROM PeriodNumber AS pn
);
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.GetDateDimension
@FromDate date,
@ToDate date,
@StartOfFinancialYearMonth int = 7
AS
BEGIN

-- Function:      Outputs date dimension columns for all dates in the supplied range of dates
-- Parameters:    @FromDate date   -> start date for the period
--                @ToDate date     -> end date for the period
--                @StartOfFinancialYearMonth int -> month of the year that the financial year starts
--                                                  (default is 7)
-- Action:        Outputs date dimension columns for all dates in the range provided
-- Return:        Rowset of date dimension columns
-- Refer to video: https://youtu.be/jYKkh52TEqo
--
-- Test examples: 
/*

EXEC SDU_Tools.GetDateDimension 
     @FromDate = '20180701', 
     @ToDate = '20180731', 
     @StartOfFinancialYearMonth = 7;

*/
    
    SELECT ddc.* 
    FROM SDU_Tools.DatesBetween(@FromDate, @ToDate) AS db
    CROSS APPLY SDU_Tools.DateDimensionColumns(db.DateValue, 7) AS ddc
    ORDER BY db.DateValue;
END;   
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.GetTimePeriodDimension
@MinutesPerPeriod int = 15
AS
BEGIN

-- Function:       Outputs time period dimension columns for an entire day
-- Parameters:     @MinutesPerPeriod int -> number of minutes per time period (default 15)
-- Action:         Outputs time period dimension columns for an entire day based on the 
--                 suppliednumber of minutes per period
-- Return:         Rowset of time period dimension columns
-- Refer to video: https://youtu.be/jYKkh52TEqo
--
-- Test examples: 
/*

EXEC SDU_Tools.GetTimePeriodDimension 
     @MinutesPerPeriod = 15;

*/
    
    SELECT tpdc.* 
    FROM SDU_Tools.TableOfNumbers(0, 24 * 60 / @MinutesPerPeriod) AS tn
    CROSS APPLY SDU_Tools.TimePeriodDimensionColumns(DATEADD(minute, 
                                                             @MinutesPerPeriod * tn.Number, 
                                                             CAST(CAST(SYSDATETIME() AS date) AS datetime2)), 
                                                     @MinutesPerPeriod) AS tpdc
    ORDER BY tpdc.TimePeriodKey
    OPTION (MAXRECURSION 0);
END;   
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.StartOfMonth
(
    @InputDate date
)
RETURNS date
AS
BEGIN

-- Function:      Return date of beginnning of the month
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the first date of the month for any given date 
-- Return:        date
-- Refer to this video: https://youtu.be/ZZ9NR8M5lRc
--
-- Test examples: 
/*

SELECT SDU_Tools.StartOfMonth('20180713');
SELECT SDU_Tools.StartOfMonth(SYSDATETIME());
SELECT SDU_Tools.StartOfMonth(GETDATE());

*/
    RETURN DATEADD(day, 
                   1 - DAY(ISNULL(@InputDate, SYSDATETIME())), 
                   ISNULL(@InputDate, SYSDATETIME()));
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.EndOfMonth
(
    @InputDate date
)
RETURNS date
AS
BEGIN

-- Function:      Return date of end of the month
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the last date of the month for any given date 
-- Return:        date
-- Refer to this video: https://youtu.be/ZZ9NR8M5lRc
--
-- Test examples: 
/*

SELECT SDU_Tools.EndOfMonth('20160205');
SELECT SDU_Tools.EndOfMonth(SYSDATETIME());
SELECT SDU_Tools.EndOfMonth(GETDATE());

*/
    RETURN DATEADD(day, 
                   -1, 
                   DATEADD(month, 
                           1, 
                           DATEADD(day, 
                                   1 - DAY(ISNULL(@InputDate, SYSDATETIME())), 
                                   ISNULL(@InputDate, SYSDATETIME()))));
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.CalculateTableLoadingOrderInCurrentDatabase
AS
BEGIN

-- Function:      Traverse the foreign key relationships within a database 
--                and work out which order tables need to be loaded in
-- Parameters:    Nil
-- Action:        Work out dependency between tables and work out loading order
-- Return:        Rowset describing tables
-- Refer to video: https://youtu.be/7p5RXUplO40
--
-- Test examples: 
/*

EXEC SDU_Tools.CalculateTableLoadingOrderInCurrentDatabase;

*/

    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @SQL nvarchar(max);
    DECLARE @LoadingPhase int = 0;
    DECLARE @ForeignKeyCounter int;
    DECLARE @AnyUpdated bit;
    DECLARE @IncludeThisTable bit;
    DECLARE @TableRow int;
    DECLARE @SchemaName sysname;
    DECLARE @TableName sysname;
    DECLARE @SourceSchemaName sysname;
    DECLARE @SourceTableName sysname;
    DECLARE @ReferencedSchemaName sysname;
    DECLARE @ReferencedTableName sysname;
    DECLARE @CurrentLoadingPhase int;
    
    DECLARE @DatabaseVersion varchar(12) = SDU_Tools.SQLServerVersionForCompatibilityLevel((SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID()));
    
    DECLARE @Tables TABLE
    (
        TableRow int IDENTITY(1,1) PRIMARY KEY,
        SchemaName sysname,
        TableName sysname,
        TableObjectID int,
        IsSystemTemporal bit,
        IsTemporalHistory bit,
        TemporalHistorySchemaName sysname NULL,
        TemporalHistoryTableName sysname NULL,
        LoadingPhase int,
        LoadOrder int
    );
    
    DECLARE @Columns TABLE
    (
        ColumnRow int IDENTITY(1,1) PRIMARY KEY,
        SchemaName sysname,
        TableName sysname,
        ColumnName sysname,
        ColumnID int,
        SystemDataTypeName sysname,
        UserDataTypeName sysname,
        MaximumLength int,
        [Precision] int,
        [Scale] int,
        [CollationName] sysname NULL,
        IsNullable bit,
        IsIdentity bit,
        IsComputed bit,
        IsSparse bit,
        IsColumnSet bit,
        IsGeneratedAlways bit,
        IsHidden bit,
        IsMasked bit
    );
    
    DECLARE @ForeignKeyColumns TABLE
    (
        ForeignKeyColumnRow int IDENTITY(1,1) PRIMARY KEY,
        ForeignKeyName sysname,
        IsDisabled bit,
        IsNotTrusted bit,
        IsSystemNamed bit,
        IsLogicalOnly bit,
        SchemaName sysname,
        TableName sysname,
        ColumnID int,
        ColumnName sysname,
        ReferencedSchemaName sysname,
        ReferencedTableName sysname,
        ReferencedColumnName sysname
    );
    
    SET @SQL = N'
    WITH AllTables
    AS
    (
        SELECT t.object_id AS ObjectID,
               s.[name] AS SchemaName,
               t.[name] AS TableName, ' 
        + CASE WHEN @DatabaseVersion >= '2016' THEN 
    N'         CASE WHEN t.temporal_type_desc = N''SYSTEM_VERSIONED_TEMPORAL_TABLE'' THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS IsSystemTemporal,
               CASE WHEN t.temporal_type_desc = N''HISTORY_TABLE'' THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS IsTemporalHistory,
               sh.[name] AS TemporalHistorySchemaName,
               th.[name] AS TemporalHistoryTableName'
               ELSE 
    N'         CAST(0 AS bit) AS IsSystemTemporal,
               CAST(0 AS bit) AS IsTemporalHistory,
               NULL AS TemporalHistorySchemaName,
               NULL AS TemporalHistoryTableName '
          END 
    + N'
        FROM sys.schemas AS s
        INNER JOIN sys.tables AS t
        ON t.schema_id = s.schema_id ' 
        + CASE WHEN @DatabaseVersion >= '2016' THEN 
    N'  LEFT OUTER JOIN sys.tables AS th 
        ON th.object_id = t.history_table_id
        LEFT OUTER JOIN sys.schemas AS sh
        ON sh.schema_id = th.schema_id '
               ELSE N''
          END 
    + N' WHERE t.is_ms_shipped = 0
    )
    SELECT t.SchemaName,
           t.TableName, 
           t.ObjectID,
           t.IsSystemTemporal,
           t.IsTemporalHistory,
           t.TemporalHistorySchemaName,
           t.TemporalHistoryTableName,
           0,
           0
    FROM AllTables AS t;';
    
    INSERT @Tables 
    (
        SchemaName, TableName, TableObjectID, IsSystemTemporal, 
        IsTemporalHistory, TemporalHistorySchemaName, TemporalHistoryTableName, 
        LoadingPhase, LoadOrder
    )
    EXEC (@SQL);
    
    SET @SQL = N'
    WITH AllColumns
    AS
    (
        SELECT s.[name] AS SchemaName, t.[name] AS TableName, c.[name] AS ColumnName, c.column_id AS ColumnID,
               styp.[name] AS SystemDataTypeName, utyp.[name] AS UserDataTypeName, 
               c.max_length AS MaximumLength, c.[precision] AS [Precision], c.[scale] AS [Scale], c.[collation_name] AS [CollationName],
               c.is_nullable AS IsNullable, c.is_identity AS IsIdentity, c.is_computed AS IsComputed, c.is_sparse AS IsSparse,
               c.is_column_set AS IsColumnSet, '
        + CASE WHEN @DatabaseVersion >= '2016' 
               THEN N'CASE WHEN c.generated_always_type > 0 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS IsGeneratedAlways, c.is_hidden AS IsHidden, c.is_masked AS IsMasked ' 
               ELSE N'CAST(0 AS bit) AS IsGeneratedAlways, CAST(0 AS bit) AS IsHidden, CAST(0 AS bit) AS IsMasked ' 
          END 
    + N'FROM sys.schemas AS s
        INNER JOIN sys.tables AS t
        ON t.schema_id = s.schema_id 
        INNER JOIN sys.columns AS c
        ON c.object_id = t.object_id
        INNER JOIN sys.types AS styp
        ON styp.system_type_id = c.system_type_id
        AND styp.user_type_id = c.system_type_id
        INNER JOIN sys.types AS utyp
        ON utyp.system_type_id = c.system_type_id
        AND utyp.user_type_id = c.user_type_id 
        WHERE t.is_ms_shipped = 0
    )
    SELECT SchemaName, TableName, ColumnName, ColumnID, SystemDataTypeName, UserDataTypeName, MaximumLength, [Precision], [Scale], [CollationName],
           IsNullable, IsIdentity, IsComputed, IsSparse, IsColumnSet, IsGeneratedAlways, IsHidden, IsMasked
    FROM AllColumns AS c;';
    
    INSERT @Columns
    (
        SchemaName, TableName, ColumnName, ColumnID, SystemDataTypeName, UserDataTypeName, MaximumLength, [Precision], [Scale], [CollationName],
        IsNullable, IsIdentity, IsComputed, IsSparse, IsColumnSet, IsGeneratedAlways, IsHidden, IsMasked
    )
    EXEC (@SQL);
    
    SET @SQL = N'
    WITH AllForeignKeyColumns
    AS
    (
        SELECT fk.[name] AS ForeignKeyName, fk.is_disabled AS IsDisabled, fk.is_not_trusted AS IsNotTrusted, fk.is_system_named AS IsSystemNamed, CAST(0 AS bit) AS IsLogicalOnly,
               s.[name] AS SchemaName, t.[name] AS TableName,
               fkc.constraint_column_id AS ColumnID, c.[name] AS ColumnName,
               rs.[name] AS ReferencedSchemaName, rt.[name] AS ReferencedTableName,
               rc.[name] AS ReferencedColumnName 
        FROM sys.foreign_keys AS fk
        INNER JOIN sys.tables AS t 
        ON t.object_id = fk.parent_object_id
        INNER JOIN sys.schemas AS s
        ON s.schema_id = t.schema_id 
        INNER JOIN sys.tables AS rt 
        ON rt.object_id = fk.referenced_object_id
        INNER JOIN sys.schemas AS rs
        ON rs.schema_id = rt.schema_id 
        INNER JOIN sys.foreign_key_columns AS fkc 
        ON fkc.constraint_object_id = fk.object_id 
        INNER JOIN sys.columns AS c
        ON c.object_id = t.object_id 
        AND c.column_id = fkc.parent_column_id 
        INNER JOIN sys.columns AS rc
        ON rc.object_id = rt.object_id 
        AND rc.column_id = fkc.referenced_column_id
        WHERE fk.is_ms_shipped = 0
        AND t.is_ms_shipped = 0
        AND rt.is_ms_shipped = 0
    )
    SELECT ForeignKeyName, IsDisabled, IsNotTrusted, IsSystemNamed, IsLogicalOnly,
           SchemaName, TableName, ColumnID, ColumnName,
           ReferencedSchemaName, ReferencedTableName, ReferencedColumnName
    FROM AllForeignKeyColumns;';
    
    INSERT @ForeignKeyColumns 
    (
        ForeignKeyName, IsDisabled, IsNotTrusted, IsSystemNamed, IsLogicalOnly,
        SchemaName, TableName, ColumnID, ColumnName,
        ReferencedSchemaName, ReferencedTableName, ReferencedColumnName
    )
    EXEC (@SQL);
    
    SET @ForeignKeyCounter = 1;
    SET @AnyUpdated = 1;
    SET @IncludeThisTable = 0;
    
    WHILE @AnyUpdated <> 0
    BEGIN
        SET @AnyUpdated = 0;
        SET @LoadingPhase += 1;
    
        SET @TableRow = 1;
    
        WHILE @TableRow <= COALESCE((SELECT MAX(t.TableRow) FROM @Tables AS t), 0)
        BEGIN
            SELECT @SchemaName = t.SchemaName,
                   @TableName = t.TableName,
                   @CurrentLoadingPhase = t.LoadingPhase 
            FROM @Tables AS t 
            WHERE t.TableRow = @TableRow;
    
            IF @CurrentLoadingPhase = 0
            BEGIN -- does this table still need to be processed
                SET @IncludeThisTable = 1;
        
                SET @ForeignKeyCounter = 1;
        
                WHILE @ForeignKeyCounter <= COALESCE((SELECT MAX(fkc.ForeignKeyColumnRow) FROM @ForeignKeyColumns AS fkc), 0)
                BEGIN
                    SELECT @SourceSchemaName = fkc.SchemaName,
                           @SourceTableName = fkc.TableName,
                           @ReferencedSchemaName = fkc.ReferencedSchemaName,
                           @ReferencedTableName = fkc.ReferencedTableName
                    FROM @ForeignKeyColumns AS fkc 
                    WHERE fkc.ForeignKeyColumnRow = @ForeignKeyCounter;
        
                    IF @SchemaName = @SourceSchemaName AND @TableName = @SourceTableName 
                    BEGIN -- reference from this table
                        IF @ReferencedSchemaName <> @SourceSchemaName OR @ReferencedTableName <> @SourceTableName 
                        BEGIN -- not just a reference to itself
                            SET @CurrentLoadingPhase = (SELECT t.LoadingPhase FROM @Tables AS t 
                                                                              WHERE t.SchemaName = @ReferencedSchemaName
                                                                              AND t.TableName = @ReferencedTableName);
                            IF @CurrentLoadingPhase = 0 OR @CurrentLoadingPhase = @LoadingPhase
                            BEGIN -- needs a table not yet loaded or only mentioned in this phase
                                SET @IncludeThisTable = 0;
                            END;
                        END;
                    END;
        
                    SET @ForeignKeyCounter += 1;   
                END;
        
                IF @IncludeThisTable <> 0
                BEGIN
                    UPDATE @Tables 
                        SET LoadingPhase = @LoadingPhase 
                    WHERE TableRow = @TableRow;
                    SET @AnyUpdated = 1;
                END;
            END;
                        
            SET @TableRow += 1;
        END;
    END;
    
    WITH OrderedTables
    AS
    (
        SELECT ROW_NUMBER() OVER(ORDER BY t.LoadingPhase, t.SchemaName, t.TableName) AS LoadOrder,
               t.TableRow,
               t.SchemaName,
               t.TableName 
        FROM @Tables AS t
    )
    UPDATE t
        SET t.LoadOrder = ot.LoadOrder
    FROM @Tables AS t
    INNER JOIN OrderedTables AS ot 
    ON t.TableRow = ot.TableRow;
    
    SELECT LoadOrder,
           LoadingPhase,
           SchemaName,
           TableName,
           TableObjectID,
           IsSystemTemporal,
           IsTemporalHistory,
           TemporalHistorySchemaName,
           TemporalHistoryTableName
    FROM @Tables 
    ORDER BY LoadOrder;
END;
GO
    
------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ProductVersionToMajorVersion 
(
    @ProductVersion varchar(20)
)
RETURNS int
AS
BEGIN

-- Function:      Extracts a product major version from a build number (product version)
-- Parameters:    @ProductVersion varchar(20)
-- Action:        Extracts a product major version from a build number (product version)
--                in the form MM.mm.BBBB.RRR (MM = Major, mm = minor, BBBB = build, RRR = release)
-- Return:        int
-- Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- Test examples: 
/*

SELECT SDU_Tools.ProductVersionToMajorVersion('13.0.4435.0');
SELECT SDU_Tools.ProductVersionToMajorVersion('   13.0.4435.0 ');

*/
    DECLARE @ReturnValue int;
    DECLARE @TrimmedVersion varchar(20) = LTRIM(RTRIM(@ProductVersion));
    DECLARE @IsValidLooking bit = CASE WHEN LEN(REPLACE(@TrimmedVersion, '.', '')) = (LEN(@TrimmedVersion) - 3) 
                                       THEN CAST(1 AS bit)
                                       ELSE CAST(0 AS bit)
                                  END;
    DECLARE @FirstPeriod int;
    DECLARE @ValueString varchar(20);

    IF @IsValidLooking <> 0
    BEGIN
        SET @FirstPeriod = CHARINDEX('.', @TrimmedVersion, 1);
        SET @ValueString = SUBSTRING(@TrimmedVersion, 1, @FirstPeriod - 1);

        SET @ReturnValue = CASE WHEN ISNUMERIC(@ValueString) = 1
                                THEN CAST(@ValueString AS int) 
                           END;
    END;

    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ProductVersionToMinorVersion 
(
    @ProductVersion varchar(20)
)
RETURNS int
AS 
BEGIN

-- Function:      Extracts a product minor version from a build number (product version)
-- Parameters:    @ProductVersion varchar(20)
-- Action:        Extracts a product minor version from a build number (product version)
--                in the form MM.mm.BBBB.RRR (MM = Major, mm = minor, BBBB = build, RRR = release)
-- Return:        int
-- Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- Test examples: 
/*

SELECT SDU_Tools.ProductVersionToMinorVersion('13.0.4435.0');
SELECT SDU_Tools.ProductVersionToMinorVersion('   13.0.4435.0 ');

*/
    DECLARE @ReturnValue int;
    DECLARE @TrimmedVersion varchar(20) = LTRIM(RTRIM(@ProductVersion));
    DECLARE @IsValidLooking bit = CASE WHEN LEN(REPLACE(@TrimmedVersion, '.', '')) = (LEN(@TrimmedVersion) - 3) 
                                       THEN CAST(1 AS bit)
                                       ELSE CAST(0 AS bit)
                                  END;
    DECLARE @FirstPeriod int;
    DECLARE @SecondPeriod int;
    DECLARE @ValueString varchar(20);

    IF @IsValidLooking <> 0
    BEGIN
        SET @FirstPeriod = CHARINDEX('.', @TrimmedVersion, 1);
        SET @SecondPeriod = CHARINDEX('.', @TrimmedVersion, @FirstPeriod + 1);
        SET @ValueString = SUBSTRING(@TrimmedVersion, @FirstPeriod + 1, @SecondPeriod - @FirstPeriod - 1);

        SET @ReturnValue = CASE WHEN ISNUMERIC(@ValueString) = 1
                                THEN CAST(@ValueString AS int) 
                           END;
    END;

    RETURN @ReturnValue;
END;
GO

-------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ProductVersionToBuild 
(
    @ProductVersion varchar(20)
)
RETURNS int
AS 
BEGIN

-- Function:      Extracts a product build from a build number (product version)
-- Parameters:    @ProductVersion varchar(20)
-- Action:        Extracts a product build from a build number (product version)
--                in the form MM.mm.BBBB.RRR (MM = Major, mm = minor, BBBB = build, RRR = release)
-- Return:        int
-- Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- Test examples: 
/*

SELECT SDU_Tools.ProductVersionToBuild('13.0.4435.0');
SELECT SDU_Tools.ProductVersionToBuild('   13.0.4435.0 ');

*/
    DECLARE @ReturnValue int;
    DECLARE @TrimmedVersion varchar(20) = LTRIM(RTRIM(@ProductVersion));
    DECLARE @IsValidLooking bit = CASE WHEN LEN(REPLACE(@TrimmedVersion, '.', '')) = (LEN(@TrimmedVersion) - 3) 
                                       THEN CAST(1 AS bit)
                                       ELSE CAST(0 AS bit)
                                  END;
    DECLARE @FirstPeriod int;
    DECLARE @SecondPeriod int;
    DECLARE @ThirdPeriod int;
    DECLARE @ValueString varchar(20);

    IF @IsValidLooking <> 0
    BEGIN
        SET @FirstPeriod = CHARINDEX('.', @TrimmedVersion, 1);
        SET @SecondPeriod = CHARINDEX('.', @TrimmedVersion, @FirstPeriod + 1);
        SET @ThirdPeriod = CHARINDEX('.', @TrimmedVersion, @SecondPeriod + 1);
        SET @ValueString = SUBSTRING(@TrimmedVersion, @SecondPeriod + 1, @ThirdPeriod - @SecondPeriod - 1);

        SET @ReturnValue = CASE WHEN ISNUMERIC(@ValueString) = 1
                                THEN CAST(@ValueString AS int) 
                           END;
    END;

    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ProductVersionToRelease 
(
    @ProductVersion varchar(20)
)
RETURNS int
AS 
BEGIN

-- Function:      Extracts a product release from a build number (product version)
-- Parameters:    @ProductVersion varchar(20)
-- Action:        Extracts a product release from a build number (product version)
--                in the form MM.mm.BBBB.RRR (MM = Major, mm = minor, BBBB = build, RRR = release)
-- Return:        int
-- Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- Test examples: 
/*

SELECT SDU_Tools.ProductVersionToRelease('13.0.4435.0');
SELECT SDU_Tools.ProductVersionToRelease('   13.0.4435.0 ');

*/
    DECLARE @ReturnValue int;
    DECLARE @TrimmedVersion varchar(20) = LTRIM(RTRIM(@ProductVersion));
    DECLARE @IsValidLooking bit = CASE WHEN LEN(REPLACE(@TrimmedVersion, '.', '')) = (LEN(@TrimmedVersion) - 3) 
                                       THEN CAST(1 AS bit)
                                       ELSE CAST(0 AS bit)
                                  END;
    DECLARE @FirstPeriod int;
    DECLARE @SecondPeriod int;
    DECLARE @ThirdPeriod int;
    DECLARE @ValueString varchar(20);

    IF @IsValidLooking <> 0
    BEGIN
        SET @FirstPeriod = CHARINDEX('.', @TrimmedVersion, 1);
        SET @SecondPeriod = CHARINDEX('.', @TrimmedVersion, @FirstPeriod + 1);
        SET @ThirdPeriod = CHARINDEX('.', @TrimmedVersion, @SecondPeriod + 1);
        SET @ValueString = SUBSTRING(@TrimmedVersion, @ThirdPeriod + 1, LEN(@TrimmedVersion) - @ThirdPeriod);

        SET @ReturnValue = CASE WHEN ISNUMERIC(@ValueString) = 1
                                THEN CAST(@ValueString AS int) 
                           END;
    END;

    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ProductVersionComponents
(
    @ProductVersion varchar(20)
)

-- Function:      Extracts the components of a product version
--                from a build number (product version)
-- Parameters:    @ProductVersion varchar(20)
-- Action:        Extracts the components of a product version from a build number (product version)
--                in the form MM.mm.BBBB.RRR (MM = Major, mm = minor, BBBB = build, RRR = release)
-- Return:        Rowset with product version components
-- Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.ProductVersionComponents('  13.0.4435.0 ');

*/
RETURNS @Components TABLE 
(
    MajorVersion int,
    MinorVersion int,
    Build int,
    Release int
)
AS 
BEGIN
    DECLARE @TrimmedVersion varchar(20) = LTRIM(RTRIM(@ProductVersion));
    DECLARE @IsValidLooking bit = CASE WHEN LEN(REPLACE(@TrimmedVersion, '.', '')) = (LEN(@TrimmedVersion) - 3) 
                                       THEN CAST(1 AS bit)
                                       ELSE CAST(0 AS bit)
                                  END;
    DECLARE @FirstPeriod int;
    DECLARE @SecondPeriod int;
    DECLARE @ThirdPeriod int;
    DECLARE @MajorVersionString varchar(20);
    DECLARE @MinorVersionString varchar(20);
    DECLARE @BuildString varchar(20);
    DECLARE @ReleaseString varchar(20);
    DECLARE @MajorVersion int;
    DECLARE @MinorVersion int;
    DECLARE @Build int;
    DECLARE @Release int;

    IF @IsValidLooking <> 0
    BEGIN
        SET @FirstPeriod = CHARINDEX('.', @TrimmedVersion, 1);
        SET @SecondPeriod = CHARINDEX('.', @TrimmedVersion, @FirstPeriod + 1);
        SET @ThirdPeriod = CHARINDEX('.', @TrimmedVersion, @SecondPeriod + 1);
        SET @MajorVersionString = SUBSTRING(@TrimmedVersion, 1, @FirstPeriod - 1);
        SET @MinorVersionString = SUBSTRING(@TrimmedVersion, @FirstPeriod + 1, @SecondPeriod - @FirstPeriod - 1);
        SET @BuildString = SUBSTRING(@TrimmedVersion, @SecondPeriod + 1, @ThirdPeriod - @SecondPeriod - 1);
        SET @ReleaseString = SUBSTRING(@TrimmedVersion, @ThirdPeriod + 1, LEN(@TrimmedVersion));

        SET @MajorVersion = CASE WHEN ISNUMERIC(@MajorVersionString) = 1
                                 THEN CAST(@MajorVersionString AS int) 
                            END;
        SET @MinorVersion = CASE WHEN ISNUMERIC(@MinorVersionString) = 1
                                 THEN CAST(@MinorVersionString AS int) 
                            END;
        SET @Build = CASE WHEN ISNUMERIC(@BuildString) = 1
                          THEN CAST(@BuildString AS int) 
                     END;
        SET @Release = CASE WHEN ISNUMERIC(@ReleaseString) = 1
                          THEN CAST(@ReleaseString AS int) 
                       END;

        INSERT @Components (MajorVersion, MinorVersion, Build, Release)
        VALUES (@MajorVersion, @MinorVersion, @Build, @Release);
    END;
    RETURN;
END;
GO

------------------------------------------------------------------------------------

CREATE VIEW [SDU_Tools].[OperatingSystemVersions]
AS
/* 

-- View:          OperatingSystemVersions
-- Action:        View returning names of operating systems by versions
-- Return:        One row per operating system version
-- Refer to this video: https://youtu.be/vppwkKyWCwQ
--
-- Test examples: 

SELECT * FROM SDU_Tools.OperatingSystemVersions ORDER BY OS_Family, OS_Version;

*/

SELECT OS_Family, OS_Version, OS_Name 
FROM (VALUES (N'Windows', N'10.0', N'Windows 10/Windows Server 2016'),
             (N'Windows', N'6.3', N'Windows 8.1/Windows Server 2012 R2'),
             (N'Windows', N'6.2', N'Windows 8/Windows Server 2012'), 
             (N'Windows', N'6.1', N'Windows 7/Windows Server 2008 R2'),
             (N'Windows', N'6.0', N'Windows Vista/Windows Server 2008'),
             (N'Windows', N'5.2', N'Windows XP/Windows Server 2003/Windows Server 2003 R2'),
             (N'Windows', N'5.1', N'Windows XP 32 bit'),
             (N'Windows', N'5.0', N'Windows 2000')) AS OS(OS_Family, OS_Version, OS_Name);
GO

------------------------------------------------------------------------------------

CREATE VIEW [SDU_Tools].[OperatingSystemLocales]
AS
/* 

-- View:          OperatingSystemLocales
-- Action:        View returning locales used by operating systems
-- Return:        One row per operating system locale
-- Refer to this video: https://youtu.be/vppwkKyWCwQ
--
-- Test examples: 

SELECT * FROM SDU_Tools.OperatingSystemLocales ORDER BY OS_Family, LocaleID, LanguageName;

*/

SELECT OS_Family, LocaleID, LanguageName 
FROM (VALUES(N'Windows', 1,'Arabic'),
            (N'Windows', 2,'Bulgarian'),
            (N'Windows', 3,'Catalan'),
            (N'Windows', 4,'Chinese (Simplified)'),
            (N'Windows', 5,'Czech'),
            (N'Windows', 6,'Danish'),
            (N'Windows', 7,'German'),
            (N'Windows', 8,'Greek'),
            (N'Windows', 9,'English'),
            (N'Windows', 10,'Spanish'),
            (N'Windows', 11,'Finnish'),
            (N'Windows', 12,'French'),
            (N'Windows', 13,'Hebrew'),
            (N'Windows', 14,'Hungarian'),
            (N'Windows', 15,'Icelandic'),
            (N'Windows', 16,'Italian'),
            (N'Windows', 17,'Japanese'),
            (N'Windows', 18,'Korean'),
            (N'Windows', 19,'Dutch'),
            (N'Windows', 20,'Norwegian (Bokmal)'),
            (N'Windows', 21,'Polish'),
            (N'Windows', 22,'Portuguese'),
            (N'Windows', 23,'Romansh'),
            (N'Windows', 24,'Romanian'),
            (N'Windows', 25,'Russian'),
            (N'Windows', 26,'Croatian'),
            (N'Windows', 27,'Slovak'),
            (N'Windows', 28,'Albanian'),
            (N'Windows', 29,'Swedish'),
            (N'Windows', 30,'Thai'),
            (N'Windows', 31,'Turkish'),
            (N'Windows', 32,'Urdu'),
            (N'Windows', 33,'Indonesian'),
            (N'Windows', 34,'Ukrainian'),
            (N'Windows', 35,'Belarusian'),
            (N'Windows', 36,'Slovenian'),
            (N'Windows', 37,'Estonian'),
            (N'Windows', 38,'Latvian'),
            (N'Windows', 39,'Lithuanian'),
            (N'Windows', 40,'Tajik (Cyrillic)'),
            (N'Windows', 41,'Persian'),
            (N'Windows', 42,'Vietnamese'),
            (N'Windows', 43,'Armenian'),
            (N'Windows', 44,'Azerbaijani (Latin)'),
            (N'Windows', 45,'Basque'),
            (N'Windows', 46,'Upper Sorbian'),
            (N'Windows', 47,'Macedonian'),
            (N'Windows', 48,'Sotho'),
            (N'Windows', 49,'Tsonga'),
            (N'Windows', 50,'Setswana'),
            (N'Windows', 51,'Venda'),
            (N'Windows', 52,'Xhosa'),
            (N'Windows', 53,'Zulu'),
            (N'Windows', 54,'Afrikaans'),
            (N'Windows', 55,'Georgian'),
            (N'Windows', 56,'Faroese'),
            (N'Windows', 57,'Hindi'),
            (N'Windows', 58,'Maltese'),
            (N'Windows', 59,'Sami (Northern)'),
            (N'Windows', 60,'Irish'),
            (N'Windows', 62,'Malay'),
            (N'Windows', 63,'Kazakh'),
            (N'Windows', 64,'Kyrgyz'),
            (N'Windows', 65,'Kiswahili'),
            (N'Windows', 66,'Turkmen'),
            (N'Windows', 67,'Uzbek (Latin)'),
            (N'Windows', 68,'Tatar'),
            (N'Windows', 69,'Bangla'),
            (N'Windows', 70,'Punjabi'),
            (N'Windows', 71,'Gujarati'),
            (N'Windows', 72,'Odia'),
            (N'Windows', 73,'Tamil'),
            (N'Windows', 74,'Telugu'),
            (N'Windows', 75,'Kannada'),
            (N'Windows', 76,'Malayalam'),
            (N'Windows', 77,'Assamese'),
            (N'Windows', 78,'Marathi'),
            (N'Windows', 79,'Sanskrit'),
            (N'Windows', 80,'Mongolian (Cyrillic)'),
            (N'Windows', 81,'Tibetan'),
            (N'Windows', 82,'Welsh'),
            (N'Windows', 83,'Khmer'),
            (N'Windows', 84,'Lao'),
            (N'Windows', 85,'Burmese'),
            (N'Windows', 86,'Galician'),
            (N'Windows', 87,'Konkani'),
            (N'Windows', 89,'Sindhi'),
            (N'Windows', 90,'Syriac'),
            (N'Windows', 91,'Sinhala'),
            (N'Windows', 92,'Cherokee'),
            (N'Windows', 93,'Inuktitut (Latin)'),
            (N'Windows', 94,'Amharic'),
            (N'Windows', 95,'Tamazight (Latin)'),
            (N'Windows', 96,'Kashmiri'),
            (N'Windows', 97,'Nepali'),
            (N'Windows', 98,'Frisian'),
            (N'Windows', 99,'Pashto'),
            (N'Windows', 100,'Filipino'),
            (N'Windows', 101,'Divehi'),
            (N'Windows', 103,'Fulah'),
            (N'Windows', 104,'Hausa (Latin)'),
            (N'Windows', 106,'Yoruba'),
            (N'Windows', 107,'Quechua'),
            (N'Windows', 108,'Sesotho sa Leboa'),
            (N'Windows', 109,'Bashkir'),
            (N'Windows', 110,'Luxembourgish'),
            (N'Windows', 111,'Greenlandic'),
            (N'Windows', 112,'Igbo'),
            (N'Windows', 114,'Oromo'),
            (N'Windows', 115,'Tigrinya'),
            (N'Windows', 116,'Guarani'),
            (N'Windows', 117,'Hawaiian'),
            (N'Windows', 119,'Somali'),
            (N'Windows', 120,'Yi'),
            (N'Windows', 122,'Mapudungun'),
            (N'Windows', 124,'Mohawk'),
            (N'Windows', 126,'Breton'),
            (N'Windows', 128,'Uyghur'),
            (N'Windows', 129,'Maori'),
            (N'Windows', 130,'Occitan'),
            (N'Windows', 131,'Corsican'),
            (N'Windows', 132,'Alsatian'),
            (N'Windows', 133,'Sakha'),
            (N'Windows', 134,'K''iche'),
            (N'Windows', 135,'Kinyarwanda'),
            (N'Windows', 136,'Wolof'),
            (N'Windows', 140,'Dari'),
            (N'Windows', 145,'Scottish Gaelic'),
            (N'Windows', 146,'Central Kurdish'),
            (N'Windows', 1025,'Arabic'),
            (N'Windows', 1026,'Bulgarian'),
            (N'Windows', 1027,'Catalan'),
            (N'Windows', 1028,'Chinese (Traditional)'),
            (N'Windows', 1029,'Czech'),
            (N'Windows', 1030,'Danish'),
            (N'Windows', 1031,'German'),
            (N'Windows', 1032,'Greek'),
            (N'Windows', 1033,'English'),
            (N'Windows', 1034,'Spanish'),
            (N'Windows', 1035,'Finnish'),
            (N'Windows', 1036,'French'),
            (N'Windows', 1037,'Hebrew'),
            (N'Windows', 1038,'Hungarian'),
            (N'Windows', 1039,'Icelandic'),
            (N'Windows', 1040,'Italian'),
            (N'Windows', 1041,'Japanese'),
            (N'Windows', 1042,'Korean'),
            (N'Windows', 1043,'Dutch'),
            (N'Windows', 1044,'Norwegian (Bokmal)'),
            (N'Windows', 1045,'Polish'),
            (N'Windows', 1046,'Portuguese'),
            (N'Windows', 1047,'Romansh'),
            (N'Windows', 1048,'Romanian'),
            (N'Windows', 1049,'Russian'),
            (N'Windows', 1050,'Croatian'),
            (N'Windows', 1051,'Slovak'),
            (N'Windows', 1052,'Albanian'),
            (N'Windows', 1053,'Swedish'),
            (N'Windows', 1054,'Thai'),
            (N'Windows', 1055,'Turkish'),
            (N'Windows', 1056,'Urdu'),
            (N'Windows', 1057,'Indonesian'),
            (N'Windows', 1058,'Ukrainian'),
            (N'Windows', 1059,'Belarusian'),
            (N'Windows', 1060,'Slovenian'),
            (N'Windows', 1061,'Estonian'),
            (N'Windows', 1062,'Latvian'),
            (N'Windows', 1063,'Lithuanian'),
            (N'Windows', 1064,'Tajik (Cyrillic)'),
            (N'Windows', 1065,'Persian'),
            (N'Windows', 1066,'Vietnamese'),
            (N'Windows', 1067,'Armenian'),
            (N'Windows', 1068,'Azerbaijani (Latin)'),
            (N'Windows', 1069,'Basque'),
            (N'Windows', 1070,'Upper Sorbian'),
            (N'Windows', 1071,'Macedonian'),
            (N'Windows', 1072,'Sotho'),
            (N'Windows', 1073,'Tsonga'),
            (N'Windows', 1074,'Setswana'),
            (N'Windows', 1075,'Venda'),
            (N'Windows', 1076,'Xhosa'),
            (N'Windows', 1077,'Zulu'),
            (N'Windows', 1078,'Afrikaans'),
            (N'Windows', 1079,'Georgian'),
            (N'Windows', 1080,'Faroese'),
            (N'Windows', 1081,'Hindi'),
            (N'Windows', 1082,'Maltese'),
            (N'Windows', 1083,'Sami (Northern)'),
            (N'Windows', 1086,'Malay'),
            (N'Windows', 1087,'Kazakh'),
            (N'Windows', 1088,'Kyrgyz'),
            (N'Windows', 1089,'Kiswahili'),
            (N'Windows', 1090,'Turkmen'),
            (N'Windows', 1091,'Uzbek (Latin)'),
            (N'Windows', 1092,'Tatar'),
            (N'Windows', 1093,'Bangla'),
            (N'Windows', 1094,'Punjabi'),
            (N'Windows', 1095,'Gujarati'),
            (N'Windows', 1096,'Odia'),
            (N'Windows', 1097,'Tamil'),
            (N'Windows', 1098,'Telugu'),
            (N'Windows', 1099,'Kannada'),
            (N'Windows', 1100,'Malayalam'),
            (N'Windows', 1101,'Assamese'),
            (N'Windows', 1102,'Marathi'),
            (N'Windows', 1103,'Sanskrit'),
            (N'Windows', 1104,'Mongolian (Cyrillic)'),
            (N'Windows', 1105,'Tibetan'),
            (N'Windows', 1106,'Welsh'),
            (N'Windows', 1107,'Khmer'),
            (N'Windows', 1108,'Lao'),
            (N'Windows', 1109,'Burmese'),
            (N'Windows', 1110,'Galician'),
            (N'Windows', 1111,'Konkani'),
            (N'Windows', 1114,'Syriac'),
            (N'Windows', 1115,'Sinhala'),
            (N'Windows', 1116,'Cherokee'),
            (N'Windows', 1117,'Inuktitut (Syllabics)'),
            (N'Windows', 1118,'Amharic'),
            (N'Windows', 1120,'Kashmiri'),
            (N'Windows', 1121,'Nepali'),
            (N'Windows', 1122,'Frisian'),
            (N'Windows', 1123,'Pashto'),
            (N'Windows', 1124,'Filipino'),
            (N'Windows', 1125,'Divehi'),
            (N'Windows', 1128,'Hausa (Latin)'),
            (N'Windows', 1130,'Yoruba'),
            (N'Windows', 1131,'Quechua'),
            (N'Windows', 1132,'Sesotho sa Leboa'),
            (N'Windows', 1133,'Bashkir'),
            (N'Windows', 1134,'Luxembourgish'),
            (N'Windows', 1135,'Greenlandic'),
            (N'Windows', 1136,'Igbo'),
            (N'Windows', 1138,'Oromo'),
            (N'Windows', 1139,'Tigrinya'),
            (N'Windows', 1140,'Guarani'),
            (N'Windows', 1141,'Hawaiian'),
            (N'Windows', 1143,'Somali'),
            (N'Windows', 1144,'Yi'),
            (N'Windows', 1146,'Mapudungun'),
            (N'Windows', 1148,'Mohawk'),
            (N'Windows', 1150,'Breton'),
            (N'Windows', 1152,'Uyghur'),
            (N'Windows', 1153,'Maori'),
            (N'Windows', 1154,'Occitan'),
            (N'Windows', 1155,'Corsican'),
            (N'Windows', 1156,'Alsatian'),
            (N'Windows', 1157,'Sakha'),
            (N'Windows', 1158,'K''iche'),
            (N'Windows', 1159,'Kinyarwanda'),
            (N'Windows', 1160,'Wolof'),
            (N'Windows', 1164,'Dari'),
            (N'Windows', 1169,'Scottish Gaelic'),
            (N'Windows', 1170,'Central Kurdish'),
            (N'Windows', 1281,'Pseudo Language'),
            (N'Windows', 1534,'Pseudo Language'),
            (N'Windows', 2049,'Arabic'),
            (N'Windows', 2051,'Valencian'),
            (N'Windows', 2052,'Chinese (Simplified)'),
            (N'Windows', 2055,'German'),
            (N'Windows', 2057,'English'),
            (N'Windows', 2058,'Spanish'),
            (N'Windows', 2060,'French'),
            (N'Windows', 2064,'Italian'),
            (N'Windows', 2067,'Dutch'),
            (N'Windows', 2068,'Norwegian (Nynorsk)'),
            (N'Windows', 2070,'Portuguese'),
            (N'Windows', 2072,'Romanian'),
            (N'Windows', 2073,'Russian'),
            (N'Windows', 2074,'Serbian (Latin)'),
            (N'Windows', 2077,'Swedish'),
            (N'Windows', 2080,'Urdu'),
            (N'Windows', 2092,'Azerbaijani (Cyrillic)'),
            (N'Windows', 2094,'Lower Sorbian'),
            (N'Windows', 2098,'Setswana'),
            (N'Windows', 2107,'Sami (Northern)'),
            (N'Windows', 2108,'Irish'),
            (N'Windows', 2110,'Malay'),
            (N'Windows', 2115,'Uzbek (Cyrillic)'),
            (N'Windows', 2117,'Bangla'),
            (N'Windows', 2118,'Punjabi'),
            (N'Windows', 2121,'Tamil'),
            (N'Windows', 2128,'Mongolian (Traditional Mongolian)'),
            (N'Windows', 2137,'Sindhi'),
            (N'Windows', 2141,'Inuktitut (Latin)'),
            (N'Windows', 2143,'Tamazight (Latin)'),
            (N'Windows', 2145,'Nepali'),
            (N'Windows', 2151,'Fulah'),
            (N'Windows', 2155,'Quechua'),
            (N'Windows', 2163,'Tigrinya'),
            (N'Windows', 2559,'Pseudo Language'),
            (N'Windows', 3073,'Arabic'),
            (N'Windows', 3076,'Chinese (Traditional)'),
            (N'Windows', 3079,'German'),
            (N'Windows', 3081,'English'),
            (N'Windows', 3082,'Spanish'),
            (N'Windows', 3084,'French'),
            (N'Windows', 3098,'Serbian (Cyrillic)'),
            (N'Windows', 3131,'Sami (Northern)'),
            (N'Windows', 3152,'Mongolian (Traditional Mongolian)'),
            (N'Windows', 3153,'Dzongkha'),
            (N'Windows', 3179,'Quechua'),
            (N'Windows', 4096,'Afar'),
            (N'Windows', 4097,'Arabic'),
            (N'Windows', 4100,'Chinese (Simplified)'),
            (N'Windows', 4103,'German'),
            (N'Windows', 4105,'English'),
            (N'Windows', 4106,'Spanish'),
            (N'Windows', 4108,'French'),
            (N'Windows', 4122,'Croatian (Latin)'),
            (N'Windows', 4155,'Sami (Lule)'),
            (N'Windows', 5121,'Arabic'),
            (N'Windows', 5124,'Chinese (Traditional)'),
            (N'Windows', 5127,'German'),
            (N'Windows', 5129,'English'),
            (N'Windows', 5130,'Spanish'),
            (N'Windows', 5132,'French'),
            (N'Windows', 5146,'Bosnian (Latin)'),
            (N'Windows', 5179,'Sami (Lule)'),
            (N'Windows', 6145,'Arabic'),
            (N'Windows', 6153,'English'),
            (N'Windows', 6154,'Spanish'),
            (N'Windows', 6156,'French'),
            (N'Windows', 6170,'Serbian (Latin)'),
            (N'Windows', 6203,'Sami (Southern)'),
            (N'Windows', 7169,'Arabic'),
            (N'Windows', 7177,'English'),
            (N'Windows', 7178,'Spanish'),
            (N'Windows', 7194,'Serbian (Cyrillic)'),
            (N'Windows', 7227,'Sami (Southern)'),
            (N'Windows', 8193,'Arabic'),
            (N'Windows', 8201,'English'),
            (N'Windows', 8202,'Spanish'),
            (N'Windows', 8204,'French'),
            (N'Windows', 8218,'Bosnian (Cyrillic)'),
            (N'Windows', 8251,'Sami (Skolt)'),
            (N'Windows', 9217,'Arabic'),
            (N'Windows', 9225,'English'),
            (N'Windows', 9226,'Spanish'),
            (N'Windows', 9228,'French'),
            (N'Windows', 9242,'Serbian (Latin)'),
            (N'Windows', 9275,'Sami (Inari)'),
            (N'Windows', 10241,'Arabic'),
            (N'Windows', 10249,'English'),
            (N'Windows', 10250,'Spanish'),
            (N'Windows', 10252,'French'),
            (N'Windows', 10266,'Serbian (Cyrillic)'),
            (N'Windows', 11265,'Arabic'),
            (N'Windows', 11273,'English'),
            (N'Windows', 11274,'Spanish'),
            (N'Windows', 11276,'French'),
            (N'Windows', 11290,'Serbian (Latin)'),
            (N'Windows', 12289,'Arabic'),
            (N'Windows', 12297,'English'),
            (N'Windows', 12298,'Spanish'),
            (N'Windows', 12300,'French'),
            (N'Windows', 12314,'Serbian (Cyrillic)'),
            (N'Windows', 13313,'Arabic'),
            (N'Windows', 13321,'English'),
            (N'Windows', 13322,'Spanish'),
            (N'Windows', 13324,'French'),
            (N'Windows', 14337,'Arabic'),
            (N'Windows', 14346,'Spanish'),
            (N'Windows', 14348,'French'),
            (N'Windows', 15361,'Arabic'),
            (N'Windows', 15369,'English'),
            (N'Windows', 15370,'Spanish'),
            (N'Windows', 15372,'French'),
            (N'Windows', 16385,'Arabic'),
            (N'Windows', 16393,'English'),
            (N'Windows', 16394,'Spanish'),
            (N'Windows', 17417,'English'),
            (N'Windows', 17418,'Spanish'),
            (N'Windows', 18441,'English'),
            (N'Windows', 18442,'Spanish'),
            (N'Windows', 19466,'Spanish'),
            (N'Windows', 20490,'Spanish'),
            (N'Windows', 21514,'Spanish'),
            (N'Windows', 22538,'Spanish'),
            (N'Windows', 23562,'Spanish'),
            (N'Windows', 25626,'Bosnian (Cyrillic)'),
            (N'Windows', 26650,'Bosnian (Latin)'),
            (N'Windows', 27674,'Serbian (Cyrillic)'),
            (N'Windows', 28698,'Serbian (Latin)'),
            (N'Windows', 28731,'Sami (Inari)'),
            (N'Windows', 29740,'Azerbaijani (Cyrillic)'),
            (N'Windows', 29755,'Sami (Skolt)'),
            (N'Windows', 30724,'Chinese (Simplified)'),
            (N'Windows', 30740,'Norwegian (Nynorsk)'),
            (N'Windows', 30746,'Bosnian (Latin)'),
            (N'Windows', 30764,'Azerbaijani (Latin)'),
            (N'Windows', 30779,'Sami (Southern)'),
            (N'Windows', 30787,'Uzbek (Cyrillic)'),
            (N'Windows', 30800,'Mongolian (Cyrillic)'),
            (N'Windows', 30813,'Inuktitut (Syllabics)'),
            (N'Windows', 31748,'Chinese (Traditional)'),
            (N'Windows', 31764,'Norwegian (Bokmal)'),
            (N'Windows', 31770,'Serbian (Latin)'),
            (N'Windows', 31784,'Tajik (Cyrillic)'),
            (N'Windows', 31790,'Lower Sorbian'),
            (N'Windows', 31803,'Sami (Lule)'),
            (N'Windows', 31811,'Uzbek (Latin)'),
            (N'Windows', 31814,'Punjabi'),
            (N'Windows', 31824,'Mongolian (Traditional Mongolian)'),
            (N'Windows', 31833,'Sindhi'),
            (N'Windows', 31836,'Cherokee'),
            (N'Windows', 31837,'Inuktitut (Latin)'),
            (N'Windows', 31839,'Tamazight (Latin)'),
            (N'Windows', 31847,'Fulah'),
            (N'Windows', 31848,'Hausa (Latin)'),
            (N'Windows', 31890,'Central Kurdish')) AS LCID(OS_Family, LocaleID, LanguageName);

GO

------------------------------------------------------------------------------------

CREATE VIEW [SDU_Tools].[OperatingSystemSKUs]
AS
/* 

-- View:          OperatingSystemSKUs
-- Action:        View returning SKUs used by operating systems
-- Return:        One row per operating system SKU
-- Refer to this video: https://youtu.be/vppwkKyWCwQ
--
-- Test examples: 

SELECT * FROM SDU_Tools.OperatingSystemSKUs ORDER BY OS_Family, SKU, SKU_Name;

*/

SELECT OS_Family, SKU, SKU_Name 
FROM (VALUES (N'Windows', 0,'An unknown product'),
             (N'Windows', 1,'Ultimate'),
             (N'Windows', 2,'Home Basic'),
             (N'Windows', 3,'Home Premium'),
             (N'Windows', 4,'Windows 10 Enterprise'),
             (N'Windows', 5,'Home Basic N'),
             (N'Windows', 6,'Business'),
             (N'Windows', 7,'Server Standard'),
             (N'Windows', 8,'Server Datacenter (full installation)'),
             (N'Windows', 9,'Windows Small Business Server'),
             (N'Windows', 10,'Server Enterprise (full installation)'),
             (N'Windows', 11,'Starter'),
             (N'Windows', 12,'Server Datacenter (core installation)'),
             (N'Windows', 13,'Server Standard (core installation)'),
             (N'Windows', 14,'Server Enterprise (core installation)'),
             (N'Windows', 15,'Server Enterprise for Itanium-based Systems'),
             (N'Windows', 16,'Business N'),
             (N'Windows', 17,'Web Server (full installation)'),
             (N'Windows', 18,'HPC Edition'),
             (N'Windows', 19,'Windows Storage Server 2008 R2 Essentials'),
             (N'Windows', 20,'Storage Server Express'),
             (N'Windows', 21,'Storage Server Standard'),
             (N'Windows', 22,'Storage Server Workgroup'),
             (N'Windows', 23,'Storage Server Enterprise'),
             (N'Windows', 24,'Windows Server 2008 for Windows Essential Server Solutions'),
             (N'Windows', 25,'Small Business Server Premium'),
             (N'Windows', 26,'Home Premium N'),
             (N'Windows', 27,'Windows 10 Enterprise N'),
             (N'Windows', 28,'Ultimate N'),
             (N'Windows', 29,'Web Server (core installation)'),
             (N'Windows', 30,'Windows Essential Business Server Management Server'),
             (N'Windows', 31,'Windows Essential Business Server Security Server'),
             (N'Windows', 32,'Windows Essential Business Server Messaging Server'),
             (N'Windows', 33,'Server Foundation'),
             (N'Windows', 34,'Windows Home Server 2011'),
             (N'Windows', 35,'Windows Server 2008 without Hyper-V for Windows Essential Server Solutions'),
             (N'Windows', 36,'Server Standard without Hyper-V'),
             (N'Windows', 37,'Server Datacenter without Hyper-V (full installation)'),
             (N'Windows', 38,'Server Enterprise without Hyper-V (full installation)'),
             (N'Windows', 39,'Server Datacenter without Hyper-V (core installation)'),
             (N'Windows', 40,'Server Standard without Hyper-V (core installation)'),
             (N'Windows', 41,'Server Enterprise without Hyper-V (core installation)'),
             (N'Windows', 42,'Microsoft Hyper-V Server'),
             (N'Windows', 43,'Storage Server Express (core installation)'),
             (N'Windows', 44,'Storage Server Standard (core installation)'),
             (N'Windows', 45,'Storage Server Workgroup (core installation)'),
             (N'Windows', 46,'Storage Server Enterprise (core installation)'),
             (N'Windows', 47,'Starter N'),
             (N'Windows', 48,'Windows 10 Pro'),
             (N'Windows', 49,'Windows 10 Pro N'),
             (N'Windows', 50,'Windows Small Business Server 2011 Essentials'),
             (N'Windows', 51,'Server For SB Solutions'),
             (N'Windows', 52,'Server Solutions Premium'),
             (N'Windows', 53,'Server Solutions Premium (core installation)'),
             (N'Windows', 54,'Server For SB Solutions EM'),
             (N'Windows', 55,'Server For SB Solutions EM'),
             (N'Windows', 56,'Windows MultiPoint Server'),
             (N'Windows', 59,'Windows Essential Server Solution Management'),
             (N'Windows', 60,'Windows Essential Server Solution Additional'),
             (N'Windows', 61,'Windows Essential Server Solution Management SVC'),
             (N'Windows', 62,'Windows Essential Server Solution Additional SVC'),
             (N'Windows', 63,'Small Business Server Premium (core installation)'),
             (N'Windows', 64,'Server Hyper Core V'),
             (N'Windows', 66,'Not supported'),
             (N'Windows', 67,'Not supported'),
             (N'Windows', 68,'Not supported'),
             (N'Windows', 69,'Not supported'),
             (N'Windows', 70,'Windows 10 Enterprise E'),
             (N'Windows', 71,'Not supported'),
             (N'Windows', 72,'Windows 10 Enterprise Evaluation'),
             (N'Windows', 76,'Windows MultiPoint Server Standard (full installation)'),
             (N'Windows', 77,'Windows MultiPoint Server Premium (full installation)'),
             (N'Windows', 79,'Server Standard (evaluation installation)'),
             (N'Windows', 80,'Server Datacenter (evaluation installation)'),
             (N'Windows', 84,'Windows 10 Enterprise N Evaluation'),
             (N'Windows', 95,'Storage Server Workgroup (evaluation installation)'),
             (N'Windows', 96,'Storage Server Standard (evaluation installation)'),
             (N'Windows', 98,'Windows 10 Home N'),
             (N'Windows', 99,'Windows 10 Home China'),
             (N'Windows', 100,'Windows 10 Home Single Language'),
             (N'Windows', 101,'Windows 10 Home'),
             (N'Windows', 103,'Professional with Media Center'),
             (N'Windows', 104,'Windows 10 Mobile'),
             (N'Windows', 121,'Windows 10 Education'),
             (N'Windows', 122,'Windows 10 Education N'),
             (N'Windows', 123,'Windows 10 IoT Core'),
             (N'Windows', 125,'Windows 10 Enterprise 2015 LTSB'),
             (N'Windows', 126,'Windows 10 Enterprise 2015 LTSB N'),
             (N'Windows', 129,'Windows 10 Enterprise 2015 LTSB Evaluation'),
             (N'Windows', 130,'Windows 10 Enterprise 2015 LTSB N Evaluation'),
             (N'Windows', 131,'Windows 10 IoT Core Commercial'),
             (N'Windows', 133,'Windows 10 Mobile Enterprise'),
             (N'Windows', 161,'Windows 10 Pro for Workstations'),
             (N'Windows', 162,'Windows 10 Pro for Workstations N')) AS SKU(OS_Family, SKU, SKU_Name)
GO

------------------------------------------------------------------------------------

-- CREATE VIEW SDU_Tools.OperatingSystemConfiguration (Not appropriate for Azure SQL DB)

------------------------------------------------------------------------------------
GO

CREATE VIEW [SDU_Tools].[SQLServerProductVersions]
AS
/* 

-- View:          SQLServerProductVersions
-- Action:        View returning Product Versions for SQL Server
-- Return:        One row per SQL Server product version
-- Refer to this video: https://youtu.be/st9RO_Ir1tc
--
-- Test examples: 

SELECT * 
FROM SDU_Tools.SQLServerProductVersions 
ORDER BY MajorVersionNumber, MinorVersionNumber, BuildNumber;

*/

SELECT SQLServerVersion, BaseLevel, PatchLevel, 
       MajorVersionNumber, MinorVersionNumber, BuildNumber,
       CAST(ReleaseDate AS date) AS ReleaseDate,
       CASE WHEN CoreKBArticleNumber IS NOT NULL
            THEN 'KB' + CoreKBArticleNumber
       END AS CoreKBArticleName, 
       CASE WHEN CoreKBArticleNumber IS NOT NULL
            THEN 'https://support.microsoft.com/en-us/help/' + CoreKBArticleNumber
       END AS CoreKBArticleURL,
       AdditionalKBArticles
FROM (VALUES ('SQL Server 2008','RTM',NULL,10,0,1600,'20080806',NULL,NULL),
             ('SQL Server 2008','RTM','Hotfix',10,0,1755,'20080912','957387',NULL),
             ('SQL Server 2008','RTM','CU1',10,0,1763,'20080922','956717',NULL),
             ('SQL Server 2008','RTM','CU1 + Hotfix',10,0,1767,'20081013','958208',NULL),
             ('SQL Server 2008','RTM','CU1 + Hotfix',10,0,1771,'20081027','958611',NULL),
             ('SQL Server 2008','RTM','CU2',10,0,1779,'20081117','958186',NULL),
             ('SQL Server 2008','RTM','CU3',10,0,1787,'20090119','960484',NULL),
             ('SQL Server 2008','RTM','CU3 + Hotfix',10,0,1788,'20090128','965221',NULL),
             ('SQL Server 2008','RTM','CU3 + Hotfix',10,0,1790,'20090204','967178',NULL),
             ('SQL Server 2008','RTM','CU4',10,0,1798,'20090316','963036',NULL),
             ('SQL Server 2008','RTM','CU4 + Hotfix',10,0,1799,'20090331','969453',NULL),
             ('SQL Server 2008','RTM','CU4 + Hotfix',10,0,1801,'20090408','968543',NULL),
             ('SQL Server 2008','RTM','CU5',10,0,1806,'20090518','969531',NULL),
             ('SQL Server 2008','RTM','CU5 + Hotfix',10,0,1807,'20090526','969050',NULL),
             ('SQL Server 2008','RTM','CU5 + Hotfix',10,0,1810,'20090624','968722','971780,971068'),
             ('SQL Server 2008','RTM','CU6',10,0,1812,'20090720','971490',NULL),
             ('SQL Server 2008','RTM','CU6 + Hotfix',10,0,1814,'20090813','972687',NULL),
             ('SQL Server 2008','RTM','CU7',10,0,1818,'20090921','973601',NULL),
             ('SQL Server 2008','RTM','CU8',10,0,1823,'20091116','975976',NULL),
             ('SQL Server 2008','RTM','CU9',10,0,1828,'20100118','977444',NULL),
             ('SQL Server 2008','RTM','CU10',10,0,1835,'20100315','979064',NULL),
             ('SQL Server 2008','SP1',NULL,10,0,2531,'20090407','968369',NULL),
             ('SQL Server 2008','SP1','CU1',10,0,2710,'20090415','969099',NULL),
             ('SQL Server 2008','SP1','CU1 + Hotfix',10,0,2712,'20090519','970507',NULL),
             ('SQL Server 2008','SP1','CU2',10,0,2714,'20090519','970315',NULL),
             ('SQL Server 2008','SP1','CU2 + Hotfix',10,0,2718,'20090612','971049','970349,971068'),
             ('SQL Server 2008','SP1','CU2 + Hotfix',10,0,2721,'20090625','971136','971985'),
             ('SQL Server 2008','SP1','CU3',10,0,2723,'20090720','971491',NULL),
             ('SQL Server 2008','SP1','CU3 + Hotfix',10,0,2727,'20090814','972687','974231'),
             ('SQL Server 2008','SP1','CU3 + Hotfix',10,0,2728,'20090906','974766',NULL),
             ('SQL Server 2008','SP1','CU4',10,0,2734,'20090921','973602',NULL),
             ('SQL Server 2008','SP1','CU4 + Hotfix',10,0,2740,'20091104','976761',NULL),
             ('SQL Server 2008','SP1','CU5',10,0,2746,'20091116','975977',NULL),
             ('SQL Server 2008','SP1','CU5 + Hotfix',10,0,2748,'20091127','975991',NULL),
             ('SQL Server 2008','SP1','CU5 + Hotfix',10,0,2749,'20091208','978070',NULL),
             ('SQL Server 2008','SP1','CU6',10,0,2757,'20100118','977443',NULL),
             ('SQL Server 2008','SP1','CU6 + Hotfix',10,0,2758,'20100204','978791','978947'),
             ('SQL Server 2008','SP1','CU6 + Hotfix',10,0,2760,'20100123','978839',NULL),
             ('SQL Server 2008','SP1','CU6 + Hotfix',10,0,2763,'20100311',NULL,NULL),
             ('SQL Server 2008','SP1','CU7',10,0,2766,'20100315','979065',NULL),
             ('SQL Server 2008','SP1','CU7 + Hotfix',10,0,2769,'20100330',NULL,NULL),
             ('SQL Server 2008','SP1','CU7 + Hotfix',10,0,2770,'20100406',NULL,NULL),
             ('SQL Server 2008','SP1','CU7 + Hotfix',10,0,2773,'20100508',NULL,NULL),
             ('SQL Server 2008','SP1','CU8',10,0,2775,'20100517','981702',NULL),
             ('SQL Server 2008','SP1','CU8 + Hotfix',10,0,2781,'20100610','980832',NULL),
             ('SQL Server 2008','SP1','CU9',10,0,2789,'20100719','2083921',NULL),
             ('SQL Server 2008','SP1','CU10',10,0,2799,'20100921','2279604',NULL),
             ('SQL Server 2008','SP1','CU11',10,0,2804,'20101115','2413738',NULL),
             ('SQL Server 2008','SP1','CU12',10,0,2808,'201117','2467236',NULL),
             ('SQL Server 2008','SP1','CU13',10,0,2816,'20110321','2497673',NULL),
             ('SQL Server 2008','SP1','CU14',10,0,2821,'20110516','2527187',NULL),
             ('SQL Server 2008','SP1','CU15',10,0,2847,'20110718','2555406',NULL),
             ('SQL Server 2008','SP1','CU16',10,0,2850,'20110919','2582282',NULL),
             ('SQL Server 2008','SP2',NULL,10,0,4000,'20100924','2285068',NULL),
             ('SQL Server 2008','SP2','CU1',10,0,4266,'20101115','2289254',NULL),
             ('SQL Server 2008','SP2','CU2',10,0,4272,'20110117','2467239',NULL),
             ('SQL Server 2008','SP2','CU3',10,0,4279,'20110321','2498535',NULL),
             ('SQL Server 2008','SP2','CU4',10,0,4285,'20110516','2527180',NULL),
             ('SQL Server 2008','SP2','CU5',10,0,4316,'20110718','2555408',NULL),
             ('SQL Server 2008','SP2','CU6',10,0,4321,'20110919','2582285',NULL),
             ('SQL Server 2008','SP2','CU7',10,0,4323,'20111121','2617148',NULL),
             ('SQL Server 2008','SP2','CU8',10,0,4326,'20120116','2648096',NULL),
             ('SQL Server 2008','SP2','CU9',10,0,4330,'20120319','2673382',NULL),
             ('SQL Server 2008','SP2','CU10',10,0,4332,'20120521','2696625',NULL),
             ('SQL Server 2008','SP2','CU11',10,0,4333,'20120716','2715951',NULL),
             ('SQL Server 2008','SP3',NULL,10,0,5500,'20111006','2546951',NULL),
             ('SQL Server 2008','SP3','CU1',10,0,5766,'20111017','2617146',NULL),
             ('SQL Server 2008','SP3','CU2',10,0,5768,'20111121','2633143',NULL),
             ('SQL Server 2008','SP3','CU3',10,0,5770,'20120116','2648098',NULL),
             ('SQL Server 2008','SP3','CU4',10,0,5775,'20120319','2673383',NULL),
             ('SQL Server 2008','SP3','CU5',10,0,5785,'20120521','2696626',NULL),
             ('SQL Server 2008','SP3','CU6',10,0,5788,'20120716','2715953',NULL),
             ('SQL Server 2008','SP3','CU7',10,0,5794,'20120917','2738350',NULL),
             ('SQL Server 2008','SP3','CU8',10,0,5828,'20121119','2771833',NULL),
             ('SQL Server 2008','SP3','CU9',10,0,5829,'20130121','2799883',NULL),
             ('SQL Server 2008','SP3','CU10',10,0,5835,'20130318','2814783',NULL),
             ('SQL Server 2008','SP3','CU11',10,0,5840,'20130520','2834048',NULL),
             ('SQL Server 2008','SP3','CU12',10,0,5844,'20130715','2863205',NULL),
             ('SQL Server 2008','SP3','CU13',10,0,5846,'20130916','2880350',NULL),
             ('SQL Server 2008','SP3','CU14',10,0,5848,'20131118','2893410',NULL),
             ('SQL Server 2008','SP3','CU15',10,0,5850,'20140120','2923520',NULL),
             ('SQL Server 2008','SP3','CU16',10,0,5852,'20140317','2936421',NULL),
             ('SQL Server 2008','SP3','CU17',10,0,5861,'20140519','2958696',NULL),
             ('SQL Server 2008','SP3','CU17 + Hotfix',10,0,5867,'20140930','2888996','2877204,2920987'),
             ('SQL Server 2008','SP4',NULL,10,0,6000,'20140930','2979596',NULL),
             ('SQL Server 2008','SP4','Hotfix',10,0,6526,'20150209','3034373',NULL),
             ('SQL Server 2008','SP4','Hotfix',10,0,6241,'20150714','3045311',NULL),
             ('SQL Server 2008','SP4','Hotfix',10,0,6535,'20150714','3045308',NULL),
             ('SQL Server 2008','SP4','Hotfix',10,0,6543,'20160127','3135244',NULL),
             ('SQL Server 2008','SP4','Hotfix',10,0,6547,'20160303','3146034',NULL),
             ('SQL Server 2008','SP4','Hotfix',10,0,6556,'20180106','4057114',NULL),
             ('SQL Server 2008 R2','RTM',NULL,10,50,1600,'20100510',NULL,NULL),
             ('SQL Server 2008 R2','RTM','CU1',10,50,1702,'20100518','981355',NULL),
             ('SQL Server 2008 R2','RTM','CU2',10,50,1720,'20100621','2072493',NULL),
             ('SQL Server 2008 R2','RTM','CU3',10,50,1734,'20100816','2261464',NULL),
             ('SQL Server 2008 R2','RTM','CU4',10,50,1746,'20101018','2345451',NULL),
             ('SQL Server 2008 R2','RTM','CU5',10,50,1753,'20101220','2438347',NULL),
             ('SQL Server 2008 R2','RTM','CU6',10,50,1765,'20110221','2489376',NULL),
             ('SQL Server 2008 R2','RTM','CU7',10,50,1777,'20110418','2507770',NULL),
             ('SQL Server 2008 R2','RTM','CU8',10,50,1797,'20110620','2534352',NULL),
             ('SQL Server 2008 R2','RTM','CU9',10,50,1804,'20110815','2567713',NULL),
             ('SQL Server 2008 R2','RTM','CU10',10,50,1807,'20111017','2591746',NULL),
             ('SQL Server 2008 R2','RTM','CU11',10,50,1809,'20111219','2633145',NULL),
             ('SQL Server 2008 R2','RTM','CU12',10,50,1810,'20120220','2659692',NULL),
             ('SQL Server 2008 R2','RTM','CU13',10,50,1815,'20120416','2679366',NULL),
             ('SQL Server 2008 R2','RTM','CU14',10,50,1817,'20120618','2703280',NULL),
             ('SQL Server 2008 R2','SP1',NULL,10,50,2500,'20131008','2528583',NULL),
             ('SQL Server 2008 R2','SP1','CU1',10,50,2769,'20110718','2544793',NULL),
             ('SQL Server 2008 R2','SP1','CU2',10,50,2772,'20110815','2567714',NULL),
             ('SQL Server 2008 R2','SP1','CU3',10,50,2789,'20111017','2591748',NULL),
             ('SQL Server 2008 R2','SP1','CU4',10,50,2796,'20111219','2633146',NULL),
             ('SQL Server 2008 R2','SP1','CU5',10,50,2806,'20120220','2659694',NULL),
             ('SQL Server 2008 R2','SP1','CU6',10,50,2811,'20120416','2679367',NULL),
             ('SQL Server 2008 R2','SP1','CU7',10,50,2817,'20120618','2703282',NULL),
             ('SQL Server 2008 R2','SP1','CU8',10,50,2822,'20120831','2723743',NULL),
             ('SQL Server 2008 R2','SP1','CU9',10,50,2866,'20121015','2756574',NULL),
             ('SQL Server 2008 R2','SP1','CU10',10,50,2868,'20121217','2783135',NULL),
             ('SQL Server 2008 R2','SP1','CU11',10,50,2869,'20130218','2812683',NULL),
             ('SQL Server 2008 R2','SP1','CU12',10,50,2874,'20130415','2828727',NULL),
             ('SQL Server 2008 R2','SP1','CU13',10,50,2876,'20130617','2855792',NULL),
             ('SQL Server 2008 R2','SP2',NULL,10,50,4000,'20120720','2630458',NULL),
             ('SQL Server 2008 R2','SP2','CU1',10,50,4260,'20120724','2720425',NULL),
             ('SQL Server 2008 R2','SP2','CU2',10,50,4263,'20120831','2740411',NULL),
             ('SQL Server 2008 R2','SP2','CU3',10,50,4266,'20121015','2754552',NULL),
             ('SQL Server 2008 R2','SP2','CU4',10,50,4270,'20121217','2777358',NULL),
             ('SQL Server 2008 R2','SP2','CU5',10,50,4276,'20130218','2797460',NULL),
             ('SQL Server 2008 R2','SP2','CU6',10,50,4279,'20130415','2830140',NULL),
             ('SQL Server 2008 R2','SP2','CU7',10,50,4286,'20130617','2844090',NULL),
             ('SQL Server 2008 R2','SP2','CU8',10,50,4290,'20130822','2871401',NULL),
             ('SQL Server 2008 R2','SP2','CU9',10,50,4295,'20131028','2887606',NULL),
             ('SQL Server 2008 R2','SP2','CU10',10,50,4297,'20131216','2908087',NULL),
             ('SQL Server 2008 R2','SP2','CU11',10,50,4302,'20140217','2926028',NULL),
             ('SQL Server 2008 R2','SP2','CU12',10,50,4305,'20140421','2938478',NULL),
             ('SQL Server 2008 R2','SP2','CU13',10,50,4319,'20140630','2967540',NULL),
             ('SQL Server 2008 R2','SP3',NULL,10,50,6000,'20140926','2979597',NULL),
             ('SQL Server 2008 R2','SP3','Hotfix',10,50,6525,'20150209','3033860',NULL),
             ('SQL Server 2008 R2','SP3','Hotfix',10,50,6520,'20150714','3045316',NULL),
             ('SQL Server 2008 R2','SP3','Hotfix',10,50,6529,'20150714','3045314',NULL),
             ('SQL Server 2008 R2','SP3','Hotfix',10,50,6537,'20160127','3135244',NULL),
             ('SQL Server 2008 R2','SP3','Hotfix',10,50,6542,'20160303','3146034',NULL),
             ('SQL Server 2008 R2','SP3','Hotfix',10,50,6560,'20180106','4057113',NULL),
             ('SQL Server 2012','RTM',NULL,11,0,2100,'20120303',NULL,NULL),
             ('SQL Server 2012','RTM','CU1',11,0,2316,'20120412','2679368',NULL),
             ('SQL Server 2012','RTM','CU2',11,0,2325,'20120618','2703275',NULL),
             ('SQL Server 2012','RTM','CU3',11,0,2332,'20120831','2723749',NULL),
             ('SQL Server 2012','RTM','CU4',11,0,2383,'20121015','2758687',NULL),
             ('SQL Server 2012','RTM','CU5',11,0,2395,'20121217','2777772',NULL),
             ('SQL Server 2012','RTM','CU6',11,0,2401,'20130218','2728897',NULL),
             ('SQL Server 2012','RTM','CU7',11,0,2405,'20130415','2823247',NULL),
             ('SQL Server 2012','RTM','CU8',11,0,2410,'20130617','2844205',NULL),
             ('SQL Server 2012','RTM','CU9',11,0,2419,'20130820','2867319',NULL),
             ('SQL Server 2012','RTM','CU10',11,0,2420,'20131021','2891666',NULL),
             ('SQL Server 2012','RTM','CU11',11,0,2424,'20131216','2908007',NULL),
             ('SQL Server 2012','SP1',NULL,11,0,3000,'20121111','2674319',NULL),
             ('SQL Server 2012','SP1','CU1',11,0,3321,'20121120','2765331',NULL),
             ('SQL Server 2012','SP1','CU2',11,0,3339,'20130121','2790947',NULL),
             ('SQL Server 2012','SP1','CU3',11,0,3349,'20130318','2812412',NULL),
             ('SQL Server 2012','SP1','CU4',11,0,3368,'20130530','2833645',NULL),
             ('SQL Server 2012','SP1','CU5',11,0,3373,'20130715','2861107',NULL),
             ('SQL Server 2012','SP1','CU6',11,0,3381,'20130916','2874879',NULL),
             ('SQL Server 2012','SP1','CU7',11,0,3393,'20131118','2894115',NULL),
             ('SQL Server 2012','SP1','CU8',11,0,3401,'20140120','2917531',NULL),
             ('SQL Server 2012','SP1','CU9',11,0,3412,'20140317','2931078',NULL),
             ('SQL Server 2012','SP1','CU10',11,0,3431,'20140519','2954099',NULL),
             ('SQL Server 2012','SP1','CU11',11,0,3449,'20140721','2975396',NULL),
             ('SQL Server 2012','SP1','CU12',11,0,3470,'20140915','2991533',NULL),
             ('SQL Server 2012','SP1','CU13',11,0,3482,'20141117','3002044',NULL),
             ('SQL Server 2012','SP1','CU14',11,0,3486,'20150119','3023636',NULL),
             ('SQL Server 2012','SP1','CU15',11,0,3487,'20150316','3038001',NULL),
             ('SQL Server 2012','SP1','CU16',11,0,3492,'20150518','3052476',NULL),
             ('SQL Server 2012','SP2',NULL,11,0,5058,'20140610','2958429',NULL),
             ('SQL Server 2012','SP2','CU1',11,0,5532,'20140723','2976982',NULL),
             ('SQL Server 2012','SP2','CU2',11,0,5548,'20140915','2983175',NULL),
             ('SQL Server 2012','SP2','CU3',11,0,5556,'20141117','3002049',NULL),
             ('SQL Server 2012','SP2','CU4',11,0,5569,'20150119','3007556',NULL),
             ('SQL Server 2012','SP2','CU5',11,0,5582,'20150316','3037255',NULL),
             ('SQL Server 2012','SP2','CU6',11,0,5592,'20150518','3052468',NULL),
             ('SQL Server 2012','SP2','CU7',11,0,5623,'20150720','3072100',NULL),
             ('SQL Server 2012','SP2','CU8',11,0,5634,'20150921','3082561',NULL),
             ('SQL Server 2012','SP2','CU9',11,0,5641,'20151116','3098512',NULL),
             ('SQL Server 2012','SP2','CU10',11,0,5644,'20160118','3120313',NULL),
             ('SQL Server 2012','SP2','CU11 ',11,0,5646,'20160321','3137745',NULL),
             ('SQL Server 2012','SP2','CU12 ',11,0,5649,'20160516','3152637',NULL),
             ('SQL Server 2012','SP2','CU13',11,0,5655,'20160718','3165266',NULL),
             ('SQL Server 2012','SP2','CU14',11,0,5657,'20160919','3180914',NULL),
             ('SQL Server 2012','SP2','CU15 ',11,0,5676,'20161117','3205416',NULL),
             ('SQL Server 2012','SP2','CU16 ',11,0,5678,'20170118','3205054',NULL),
             ('SQL Server 2012','SP3',NULL,11,0,6020,'20151120','3072779',NULL),
             ('SQL Server 2012','SP3','CU1',11,0,6518,'20160119','3123299',NULL),
             ('SQL Server 2012','SP3','CU2 ',11,0,6523,'20160321','3137746  ',NULL),
             ('SQL Server 2012','SP3','CU3',11,0,6537,'20160516','3152635',NULL),
             ('SQL Server 2012','SP3','CU4',11,0,6540,'20160718','3165264',NULL),
             ('SQL Server 2012','SP3','CU5',11,0,6544,'20160920','3180915',NULL),
             ('SQL Server 2012','SP3','CU6',11,0,6567,'20161117','3194992',NULL),
             ('SQL Server 2012','SP3','CU7',11,0,6579,'20170118','3205051',NULL),
             ('SQL Server 2012','SP3','CU8',11,0,6594,'20170320','4013104',NULL),
             ('SQL Server 2012','SP3','CU9',11,0,6598,'20170515','4016762',NULL),
             ('SQL Server 2012','SP3','CU10',11,0,6607,'20170808','4025925',NULL),
             ('SQL Server 2012','SP4',NULL,11,0,7001,'20171002','4018073',NULL),
             ('SQL Server 2012','SP4','GDR1',11,0,7493,'20200212','4532098',NULL),
             ('SQL Server 2012','SP4','GDR2',11,0,7507,'20210113','4583465','CVE-2021-1636'),
             ('SQL Server 2014','RTM',NULL,12,0,2000,'20140401',NULL,NULL),
             ('SQL Server 2014','RTM','CU1',12,0,2342,'20140421','2931693',NULL),
             ('SQL Server 2014','RTM','CU2',12,0,2370,'20140627','2967546',NULL),
             ('SQL Server 2014','RTM','CU3',12,0,2402,'20140818','2984923',NULL),
             ('SQL Server 2014','RTM','CU4',12,0,2430,'20141021','2999197',NULL),
             ('SQL Server 2014','RTM','CU5',12,0,2456,'20141217','3011055',NULL),
             ('SQL Server 2014','RTM','CU6',12,0,2480,'20150216','3031047',NULL),
             ('SQL Server 2014','RTM','CU7',12,0,2495,'20150420','3046038',NULL),
             ('SQL Server 2014','RTM','CU8',12,0,2546,'20150619','3067836',NULL),
             ('SQL Server 2014','RTM','CU9',12,0,2553,'20150817','3075949',NULL),
             ('SQL Server 2014','RTM','CU10',12,0,2556,'20151019','3094220',NULL),
             ('SQL Server 2014','RTM','CU11',12,0,2560,'20151221','3106659',NULL),
             ('SQL Server 2014','RTM','CU12',12,0,2564,'20160222','3130923',NULL),
             ('SQL Server 2014','RTM','CU13',12,0,2568,'20160418','3144517',NULL),
             ('SQL Server 2014','RTM','CU14',12,0,2569,'20160620','3158271',NULL),
             ('SQL Server 2014','SP1',NULL,12,0,4100,'20150504','3130923',NULL),
             ('SQL Server 2014','SP1','CU1',12,0,4416,'20150619','3067839',NULL),
             ('SQL Server 2014','SP1','CU2',12,0,4422,'20150817','3075950',NULL),
             ('SQL Server 2014','SP1','CU3',12,0,4427,'20151019','3094221',NULL),
             ('SQL Server 2014','SP1','CU4',12,0,4436,'20151221','3106660',NULL),
             ('SQL Server 2014','SP1','CU5',12,0,4439,'20160222','3130926',NULL),
             ('SQL Server 2014','SP1','CU6 (Replaced)',12,0,4449,'20160418','3144524',NULL),
             ('SQL Server 2014','SP1','CU6',12,0,4457,'20160530','3167392',NULL),
             ('SQL Server 2014','SP1','CU7',12,0,4459,'20160620','3162659',NULL),
             ('SQL Server 2014','SP1','CU8',12,0,4468,'20160815','3174038',NULL),
             ('SQL Server 2014','SP1','CU9',12,0,4474,'20161017','3186964',NULL),
             ('SQL Server 2014','SP1','CU10',12,0,4491,'20161219','3204399',NULL),
             ('SQL Server 2014','SP1','CU11',12,0,4502,'20170221','4010392',NULL),
             ('SQL Server 2014','SP1','CU12',12,0,4511,'20170417','4017793',NULL),
             ('SQL Server 2014','SP1','CU13',12,0,4520,'20170717','4019099',NULL),
             ('SQL Server 2014','SP2',NULL,12,0,5000,'20160711','3171021',NULL),
             ('SQL Server 2014','SP2','CU1',12,0,5511,'20160825','3178925',NULL),
             ('SQL Server 2014','SP2','CU2',12,0,5522,'20161017','3188778',NULL),
             ('SQL Server 2014','SP2','CU3',12,0,5538,'20161219','3204388',NULL),
             ('SQL Server 2014','SP2','CU4',12,0,5540,'20170221','4010394',NULL),
             ('SQL Server 2014','SP2','CU5',12,0,5546,'20170417','4013098',NULL),
             ('SQL Server 2014','SP2','CU6',12,0,5552,'20170717','4019094',NULL),
             ('SQL Server 2014','SP2','CU7',12,0,5556,'20170828','4032541',NULL),
             ('SQL Server 2014','SP2','CU8',12,0,5557,'20171016','4037356',NULL),
             ('SQL Server 2014','SP2','CU9',12,0,5563,'20171218','4055557',NULL),
             ('SQL Server 2014','SP2','CU10',12,0,5571,'20180116','4052725',NULL),
             ('SQL Server 2014','SP2','CU11',12,0,5579,'20180319','4077063',NULL),
             ('SQL Server 2014','SP2','CU12',12,0,5589,'20180618','4130489',NULL),
             ('SQL Server 2014','SP2','CU13',12,0,5590,'20180828','4456287',NULL),
             ('SQL Server 2014','SP2','CU14',12,0,5600,'20181016','4459860','4459981,4460112,4460116,4463742,4459220,4465867,4459981,4460112,4460116,4463742,4459220,4465867'),
             ('SQL Server 2014','SP2','CU15',12,0,5605,'20181213','4469137','4463320, 4469268, 4469722, 4470916, 4471974, 4475322, 4480647'),
             ('SQL Server 2014','SP2','CU16',12,0,5626,'20190220','4482967','4487957,4488809,4489150'),
             ('SQL Server 2014','SP2','CU17',12,0,5632,'20190417','4491540','4338636,4497230,4497701'),
             ('SQL Server 2014','SP2','GDR',12,0,5223,'20190710','4505217',NULL),
             ('SQL Server 2014','SP2','CU17+GDR',12,0,5659,'20190710','4505419',NULL),
             ('SQL Server 2014','SP2','CU18',12,0,5687,'20190730','4500180','4469942,4506023,4510934,4512011'),
             ('SQL Server 2014','SP3',NULL,12,0,6024,'20181030','4022619','3136242,4046870,4338890,3107173,3136496,3170019,3170020,3170115,3170116,3173157,3191296,3201552,4013128,4016867,4016949,4018930,4038113,4038210,4038418,4038419,4041809,4041811,4042415,4042788,4051360,4051361,4052129,4056008,4088193,4099472,4316858'),
             ('SQL Server 2014','SP3','GDR',12,0,6108,'20190710','4505218',NULL),
             ('SQL Server 2014','SP3','GDR1',12,0,6118,'20200212','4532095',NULL),
             ('SQL Server 2014','SP3','GDR2',12,0,6164,'20210113','4583463','CVE-2021-1636'),
             ('SQL Server 2014','SP3','CU1',12,0,6205,'20181213','4470220','4479283,4456883,4459220,4459981,4460112,4460116,4463742,4465867,4469268,4469554,4469722,4480648,4480639'),
             ('SQL Server 2014','SP3','CU2',12,0,6214,'20190220','4482960','4057280,4463320,4471974,4475322,4488809'),
             ('SQL Server 2014','SP3','CU3',12,0,6259,'20190417','4491539','4467058,4492379,4497701,4499231'),
             ('SQL Server 2014','SP3','CU3+GDR',12,0,6293,'20190710','4505422',NULL),
             ('SQL Server 2014','SP3','CU4',12,0,6329,'20190730','4500181','4338636,4469942,4483427,4489150,4490140,4497230,4497701,4500403,4502400,4506023,4510122,4510934,4511608,4511743,4511750,4511771,4511868,4512011,4512016'),
             ('SQL Server 2014','SP3','CU4+GDR',12,0,6372,'20200212','4535288',NULL),
             ('SQL Server 2014','SP3','CU4+GDR2',12,0,6433,'20210113','4583462','CVE-2021-1636'),
             ('SQL Server 2016','RTM',NULL,13,0,1601,'20160601',NULL,NULL),
             ('SQL Server 2016','RTM','CU1',13,0,2149,'20160725','3164674',NULL),
             ('SQL Server 2016','RTM','CU2 ',13,0,2164,'20160922','3182270',NULL),
             ('SQL Server 2016','RTM','CU3',13,0,2186,'20161116','3205413',NULL),
             ('SQL Server 2016','RTM','CU4',13,0,2193,'20170118','3205052',NULL),
             ('SQL Server 2016','RTM','CU5',13,0,2197,'20170320','4013105',NULL),
             ('SQL Server 2016','RTM','CU6',13,0,2204,'20170515','4019914',NULL),
             ('SQL Server 2016','RTM','CU7',13,0,2210,'20170808','4024304',NULL),
             ('SQL Server 2016','RTM','CU8',13,0,2213,'20170918','4040713',NULL),
             ('SQL Server 2016','RTM','CU9',13,0,2216,'20171121','4037357',NULL),
             ('SQL Server 2016','SP1',NULL,13,0,4001,'20161116','3182545  ',NULL),
             ('SQL Server 2016','SP1','CU1',13,0,4411,'20170118','3208177  ',NULL),
             ('SQL Server 2016','SP1','CU2',13,0,4422,'20170320','4013106',NULL),
             ('SQL Server 2016','SP1','CU3',13,0,4435,'20170515','4019916',NULL),
             ('SQL Server 2016','SP1','CU4',13,0,4446,'20170808','4024305',NULL),
             ('SQL Server 2016','SP1','CU5',13,0,4451,'20170918','4040714',NULL),
             ('SQL Server 2016','SP1','CU6',13,0,4457,'20171121','4037354',NULL),
             ('SQL Server 2016','SP1','CU7',13,0,4466,'20180104','4057119',NULL),
             ('SQL Server 2016','SP1','CU8',13,0,4474,'20180319','4077064',NULL),
             ('SQL Server 2016','SP1','CU9',13,0,4502,'20180530','4100997',NULL),
             ('SQL Server 2016','SP1','CU10',13,0,4514,'20180716','4341569',NULL),
             ('SQL Server 2016','SP1','CU11',13,0,4528,'20180918','4459676','4338204,4133191,4457953,4458880,4131251,4459535,4463125,4463328'),
             ('SQL Server 2016','SP1','CU12',13,0,4541,'20181014','4464343','4019799,4294694,4459220,4459981,4460116,4465443,4465745,4465747,4465867,4468103,4469349,4469554,4469600,4469815,4470057,4470546'),
             ('SQL Server 2016','SP1','CU13',13,0,4550,'20190124','4475775','4055674,4090032,4346803,4460112,4465745,4475322,4480709,4486852,4486932'),
             ('SQL Server 2016','SP1','CU14',13,0,4560,'20190320','4488535','4463320,4488809,4490138,4490435,4491696,4493329,4493363'),
             ('SQL Server 2016','SP1','CU15',13,0,4574,'20190517','4495257','4338636,4489150,4492604,4497225,4497230,4497701,4499231'),
             ('SQL Server 2016','SP1','GDR',13,0,4259,'20190710','4505219',NULL),
             ('SQL Server 2016','SP1','CU15+GDR',13,0,4604,'20190710','4505221',NULL),
             ('SQL Server 2016','SP2',NULL,13,0,5026,'20180424','4052908',NULL),
             ('SQL Server 2016','SP2','GDR',13,0,5101,'20190710','4505220',NULL),
             ('SQL Server 2016','SP2','GDR1',13,0,5102,'20200212','4532097',NULL),
             ('SQL Server 2016','SP2','GDR2',13,0,5103,'20210113','4583460','CVE-2021-1636'),
             ('SQL Server 2016','SP2','CU1',13,0,5149,'20180530','4135048',NULL),
             ('SQL Server 2016','SP2','CU2',13,0,5153,'20180716','4340355',NULL),
             ('SQL Server 2016','SP2','CU3',13,0,5216,'20180921','4458871','4456163,4100582,4338204,4456775,4347088,4456962,4133191,4340746,4456883,4458157,4458316,4458438,4294660,4338576,4458593,4131251,4338040,4459220,4459327,4340986,4459522,4459545,4459682,4459709,3216543,4135045,4463517'),
             ('SQL Server 2016','SP2','CU4',13,0,5233,'20181014','4464106','4019799,4052133,4294694,4338761,4458880,4459981,4460116,4462426,4462481,4465236,4465249,4465443,4465476,4465745,4465747,4465867,4466108,4466793,4466831,4466994,4467058,4467119,4468102,4468103,4468322,4468868,4468869,4469292,4469539,4469554,4469815,4469857,4469908,4469942,4470528,4470991'),
             ('SQL Server 2016','SP2','CU5',13,0,5264,'20190124','4475776','4055674,4090032,4099335,4316948,4346803,4457953,4459535,4460112,4461562,4463125,4463328,4465247,4467006,4469268,4470528,4470916,4475322,4479280,4479283,4480635,4480639,4480640,4480641,4480643,4480647,4480648,4480650,4480653,4480654,4480709,4480795,4481148,4483427,4483571,4483593,4486852,4486931,4486935,4486936,4486937,4486939,4486940,4487094'),
             ('SQL Server 2016','SP2','CU6',13,0,5292,'20190320','4488536','4468101,4486932,4488403,4488809,4488817,4488853,4488856,4488949,4488971,4489202,4490138,4490140,4490141,4490435,4490737,4490743,4491333,4492762,4492865,4492880,4492899,4493329,4493363,4493364'),
             ('SQL Server 2016','SP2','CU7',13,0,5337,'20190523','4495256','4338636,4488036,4489150,4490136,4491560,4491696,4492604,4493364,4493765,4494225,4494805,4495547,4497222,4497225,4497230,4497701,4497928,4499231,4500403,4500770,4501052,4501205,4501741,4501797,4502400,4502427,4502428'),
             ('SQL Server 2016','SP2','CU7+GDR',13,0,5366,'20190710','4505222',NULL),
             ('SQL Server 2016','SP2','CU8',13,0,5426,'20190801','4505830','4466107,4469600,4502658,4503385,4503417,4504511,4506023,4506912,4508472,4508621,4510934,4511593,4511715,4511751,4511816,4511834,4511868,4512016,4512130,4512151,4512558,4512567,4512821,4512956,4513097,4513099,4513236,4513238'),
             ('SQL Server 2016','SP2','CU9',13,0,5470,'20191001','4515435','4513096,4515772,4517771,4518364,4519366,4519668,4519679,4519796,4519847,4520109,4520124,4520266,4520739,4521659,4521701,4521739,4521960,4522126,4522127,4522134,4523102'),
             ('SQL Server 2016','SP2','CU10',13,0,5492,'20191009','4524334',NULL), -- just a replacement for faulty CU9
             ('SQL Server 2016','SP2','CU11',13,0,5498,'20191210','4527378','4470057, 4500574, 4521599, 4524542, 4525483, 4525612, 4526315, 4527229, 4527355, 4527716, 4528065, 4528066, 4528067, 4528130, 4528250, 4529876, 4529942, 4530212, 4530251, 4530259, 4530443, 4530475, 4530500, 4530720, 4531010, 4531027'),
             ('SQL Server 2016','SP2','CU11+GDR2',13,0,5622,'20200212','4535706','CVE-2021-1636'),
             ('SQL Server 2016','SP2','CU12',13,0,5698,'20200226','4536648','4480651,4527510,4537350,4538378,4539815,4539880,4539892,4539897,4539947,4540107,4540342,4540346,4540385,4540449,4540731,4540896,4540901,4540903,4541096,4541132,4541288,4541300,4541303,4541309,4541385,4541435,4541520,4541550,4541724,4541762,4541769,4541770,4543027'),
             ('SQL Server 2016','SP2','CU13',13,0,5820,'20200529','4549825','4549825,4556096,4551720,4511771,4563115,4560183,4561305,4563597,4562173'),
             ('SQL Server 2016','SP2','CU14',13,0,5830,'20200807','4564903','4576757,4568447,4571296,4575939,4568653,4569837,4575940,4547890'),
             ('SQL Server 2016','SP2','CU15',13,0,5850,'20200929','4577775','4536005,4580397,4575689,4578008'),
             ('SQL Server 2016','SP2','CU15+GDR2',13,0,5865,'20210113','4583461','CVE-2021-1636'),
             ('SQL Server 2016','SP2','CU16',13,0,5882,'20210212','5000645','5000649,5000651,4092997,4585971,4589350,5000650,5000652,5000715'),
             ('SQL Server 2016','SP2','CU17',13,0,5888,'20210330','5001092','5001260,4486936,5001114'),
             ('SQL Server 2017','RTM',NULL,14,0,1000,'20171002',NULL,NULL),
             ('SQL Server 2017','RTM','GDR1',14,0,2014,'20190514',NULL,'CVE-2019-0819'),
             ('SQL Server 2017','RTM','GDR2',14,0,2037,'20210113','4583456','CVE-2021-1636'),
             ('SQL Server 2017','RTM','CU1',14,0,3006,'20171024','4038634',NULL),
             ('SQL Server 2017','RTM','CU2',14,0,3008,'20171128','4052574 ',NULL),
             ('SQL Server 2017','RTM','CU3',14,0,3015,'20180104','4052987',NULL),
             ('SQL Server 2017','RTM','CU4',14,0,3022,'20180220','4056498',NULL),
             ('SQL Server 2017','RTM','CU5',14,0,3023,'20180320','4092643',NULL),
             ('SQL Server 2017','RTM','CU6',14,0,3025,'20180417','4101464',NULL),
             ('SQL Server 2017','RTM','CU7',14,0,3026,'20180523','4229789',NULL),
             ('SQL Server 2017','RTM','CU8',14,0,3029,'20180621','4338363',NULL), 
             ('SQL Server 2017','RTM','CU9',14,0,3030,'20180719','4341265',NULL), 
             ('SQL Server 2017','RTM','CU10',14,0,3037,'20180828','4342123',NULL), 
             ('SQL Server 2017','RTM','CU11',14,0,3038,'20180921','4462262','4340730,4456962,4458438,4459576,4459575,4458316,4459900,4458593,4460203,4461562,4294694,4462699,4462767,4463314'),
             ('SQL Server 2017','RTM','CU12',14,0,3045,'20181026','4464082','4345524,4462426,4462481,4463757,4465204,4465236,4465248,4465247,4459220,4465745,4465832,4466108,4466962,4467074,4468103,4468102,4468101,4469140'), 
             ('SQL Server 2017','RTM','CU13',14,0,3048,'20181219','4466404','4055674,4089239,4090032,4092997,4340986,4346803,4456775,4457953,4458157,4458880,4459327,4459522,4459535,4459981,4460112,4460116,4463125,4463320,4463328,4465443,4465867,4466491,4466831,4466994,4467058,4467119,4467449,4468102,4469292,4469554,4469722,4470411,4470811,4470821,4470991,4471213,4479280,4479283,4480630,4480631,4480634,4480639,4480643,4480644,4480645,4480648,4480651,4480653,4480709,4481148'), 
             ('SQL Server 2017','RTM','CU14',14,0,3076,'20190326','4484710','4338761,4469268,4475322,4480641,4480647,4480650,4483427,4483571,4483593,4486931,4486932,4486935,4486937,4486940,4487751,4487975,4488026,4488036,4488400,4488809,4488817,4488856,4488949,4488971,4490134,4490135,4490137,4490138,4490140,4490142,4490144,4490145,4490379,4490799'), 
             ('SQL Server 2017','RTM','CU14+GDR',14,0,3103,'20190514','4494352','CVE-2019-0819'), 
             ('SQL Server 2017','RTM','CU15',14,0,3162,'20190524','4498951','4480652,4488853,4489202,4490136,4490141,4490237,4490478,4492604,4492880,4492899,4493329,4493363,4493364,4494650,4495683,4497225,4497230,4497701,4498720,4498924,4499231,4499423,4499614,4500327,4500511,4500574,4500595,4500783,4501670,4501797,4502376,4502380,4502400,4502427,4502442,4502532,4502658,4502659,4502706,4503379,4503385,4503386,4503417,4505726,4505820'), 
             ('SQL Server 2017','RTM','GDR',14,0,2027,'20190710','4505224',NULL), 
             ('SQL Server 2017','RTM','CU15+GDR',14,0,3192,'20190710','4505225',NULL),
             ('SQL Server 2017','RTM','CU16',14,0,3223,'20190803','4508218','4338773,4459709,4489150,4491560,4493364,4494225,4494805,4497222,4497928,4501542,4502400,4502428,4506023,4508065,4508472,4508621,4508623,4509084,4510934,4511593,4511715,4511885,4512016,4512026,4512130,4512150,4512151,4512210,4512603,4512820,4512956,4512979,4513095,4513096,4513097,4513235,4513236,4513237,4514829'), 
             ('SQL Server 2017','RTM','CU17',14,0,3238,'20191009','4515579','4338636,4469600,4495663,4497225,4497701,4500770,4502442,4511751,4511884,4512558,4512567,4513097,4513099,4513238,4515773,4516999,4517404,4518364,4519366,4519668,4519796,4520124,4520148,4520149,4520438,4521659,4521701,4521758,4521960,4522002,4522404,4522405,4522909,4522911'), 
             ('SQL Server 2017','RTM','CU18',14,0,3257,'20191210','4527377','4470057,4506912,4515772,4517771,4519679,4520739,4521739,4524191,4525483,4526315,4526524,4527229,4527510,4527538,4527842,4527916,4528130,4529833,4529927,4529942,4530212,4530251,4530500,4530720,4530955,4531009,4532171,4532751'), 
             ('SQL Server 2017','RTM','CU19',14,0,3281,'20200206','4535007','4523102,4524542,4527355,4527716,4528066,4528067,4528250,4529876,4530212,4530251,4530259,4530443,4530475,4531010,4531386,4531736,4534893,4537350,4537438,4537649,4538174,4538205,4538268,4538275,4538356,4538365,4538377,4538378,4538447,4538497,4538849'), 
             ('SQL Server 2017','RTM','CU20',14,0,3294,'20200410','4541283','4506023,4536005,4541132,4548523,4551720,4548597,4541096,4551220,4532432,4548597,4539023,4540385,4548597,4541300,4541303,4541309,4551221,4541283,4541724,4541762,4539815,4540107,4540342,4540903,4541435,4541520,4541770,4552478,4548597,4548597,4539880,4540346,4543027,4541283,4548597,4540901'), 
             ('SQL Server 2017','RTM','CU21',14,0,3335,'20200702','4557397','3195888,4521599,4540896,4562173,4563597,4564868,4565944,4567166,4567837,4569424,4569425'), 
             ('SQL Server 2017','RTM','CU22',14,0,3356,'20200911','4577467','4336873,4469942,4486936,4511771,4560183,4561305,4563115,4568653,4573172,4575453,4575689,4577932,4577933,4577976,4578008,4578011,4578012,4578110,4578887,4579966'), 
             ('SQL Server 2017','RTM','CU22+GDR2',14,0,3370,'20210113','4583457', 'CVE-2021-1636'), 
             ('SQL Server 2017','RTM','CU23',14,0,3381,'20210225','5000685','4336876,4486936,4547890,4568447,4569837,4571296,4575939,4575940,4580397,4582558,4585971,4588977,4589170,4589350,4589352,4589360,4589362,4589370,4589372,5000649,5001044,5001045'),
             ('SQL Server 2017','RTM','CU24',14,0,3391,'20210511','5001228','5000651,5001260,4023170,4589350,5000715,5001423,5003342'),
             ('SQL Server 2019','RTM',NULL,15,0,2000,'20191105',NULL, NULL), 
             ('SQL Server 2019','RTM','GDR1',15,0,2070,'20191105','4517790', '4527165'), 
             ('SQL Server 2019','RTM','GDR2',15,0,2080,'20210113','4583458', 'CVE-2021-1636'), 
             ('SQL Server 2019','RTM','CU1',15,0,4003,'20200108','4527376', '4515772,4516999,4517771,4518364,4519366,4519668,4519796,4521659,4521702,4521739,4521960,4522002,4522405,4526315,4527538,4528097,4528139,4528168,4528337,4528490,4528491,4528492,4529848,4529893,4529942,4529944,4530054,4530055,4530079,4530080,4530084,4530097,4530251,4530280,4530281,4530283,4530286,4530287,4530302,4530303,4530427,4530468,4530496,4530499,4530500,4530720,4530769,4530814,4530827,4530907,4531025,4531026,4531029,4531049,4531125,4531224,4531225,4531226,4531238,4531349,4533251,4536077'),
             ('SQL Server 2019','RTM','CU2',15,0,4013,'20200214','4536075', '4523102,4524191,4524542,4525483,4527229,4527355,4527510,4527716,4527916,4528066,4528067,4528250,4529833,4529876,4530097,4530212,4530251,4530259,4530443,4530475,4531010,4531232,4531384,4531702,4531736,4533497,4534148,4534249,4536005,4536684,4536841,4537072,4537300,4537347,4537350,4537401,4537452,4537710,4537749,4537751,4537868,4537869,4538017,4538036,4538112,4538159,4538160,4538161,4538162,4538163,4538164,4538174,4538205,4538342,4538344,4538377,4538378,4538382,4538481,4538493,4538495,4538496,4538515,4538573,4538575,4538581,4538595,4538661,4538685,4538688,4538689,4538759,4538858,4538968,4538978,4539000,4539197,4539198,4539199,4539200,4539201,4539203,4539340,4540343,4540371,4540372,4540449'),
             ('SQL Server 2019','RTM','CU3',15,0,4023,'20200313','4538853', '4529927,4538118,4538686,4539172,4540121,4541132,4547890,4548131,4548133,4548523,4550657'), 
             ('SQL Server 2019','RTM','CU4',15,0,4033,'20200401','4548597', '4548597,4538581,4552159,4552205,4538688,4548597,4538268,4541096,4543027,4548597,4548597,4532432,4541313,4541300,4541303,4541309,4541724,4549897,4538365,4539815,4540107,4540121,4540342,4540903,4541435,4541520,4541762,4541770,4548103,4548597,4548597,4548597,4538497,4539880,4540346,4540901'), 
             ('SQL Server 2019','RTM','CU5',15,0,4043,'20200623','4552255', '4538581,4555232,4561915,4556244,4563007,4561725,4539023,4560051,4562173,4556233,4540896,4552478,4562618,4563044,4563195,4563348,4564868,4564876'), 
             ('SQL Server 2019','RTM','CU6',15,0,4053,'20200805','4563110', '4568448,4568653,4538581,4551220,4570355,4538849,4551221,4570571,4547890,4563597,4570433,4571296,4575275'), 
             ('SQL Server 2019','RTM','CU7',15,0,4063,'20200903','4570012', '4034376,4511771,4538581,4560183,4561305,4563115,4567166,4569424,4569425,4574801,4575453,4576778,4577561,4577590,4577591,4577594,4577836,4578011,4578110,4578395'), 
             ('SQL Server 2019','RTM','CU8',15,0,4073,'20201002','4577194', '4034376,4511771,4538581,4538688,4560183,4561305,4563115,4567166,4569424,4569425,4574801,4575453,4576778,4577561,4577590,4577591,4577594,4577836,4578011,4578110,4578267,4578395,4578579,4580397,4580413,4580915,4580949,4581882,4581886,4582558'),
             ('SQL Server 2019','RTM','CU8+GDR2',15,0,4083,'20210113','4583459', 'CVE-2021-1636'),
             ('SQL Server 2019','RTM','CU9',15,0,4083,'20210212','5000642', '4538581,4538688,4547890,4565944,4568447,4569837,4575689,4575939,4575940,4577932,4577933,4577976,4580397,4585971,4588977,4588978,4588979,4588980,4588981,4588982,4588983,4588984,4589170,4589171,4589345,4589350,4594016,5000649,5000655,5000656,5000663,5000669,5000670,5000671,5000672,5000895'),
             ('SQL Server 2019','RTM','CU10',15,0,4123,'20210407','5001090', '4486936,4548523,4589350,5000649,5000650,5000715,5001044,5001159,5001260,5001266,5001517,5001526')
             ) 
             AS SQLServer(SQLServerVersion, BaseLevel, PatchLevel, MajorVersionNumber, MinorVersionNumber, BuildNumber,
                          ReleaseDate, CoreKBArticleNumber, AdditionalKBArticles);
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.SetAnsiNullsQuotedIdentifierForStoredProceduresInCurrentDatabase
@SchemaName sysname,
@ProcedureName sysname,
@NeedsAnsiNulls bit,
@NeedsQuotedIdentifier bit,
@IHaveABackup bit
AS
BEGIN
/* 

-- Function:      SetAnsiNullsQuotedIdentifierForStoredProcedures
-- Parameters:    @SchemaName sysname                      -> Schema name for the procedure to be altered or ALL
--                @ProcedureName sysname                   -> Procedure name for the procedure to be altered or ALL
--                @NeedsAnsiNulls bit                      -> Should ANSI_NULLS be turned on?
--                @NeedsQuotedIdentifier bit               -> Should QUOTED_IDENTIFIER be turned on?
--                @IHaveABackup bit                        -> Don't do this without a backup (just in case)
-- Action:        Changes the ANSI_NULLS and QUOTED_IDENTIFIER settings for selected procedures
-- Return:        No rows returned
-- Refer to this video: https://youtu.be/EoYV_FbvkZQ
--
-- Test examples: 

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

EXEC SDU_Tools.SetAnsiNullsQuotedIdentifierForStoredProceduresInCurrentDatabase
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

*/

    BEGIN TRY 
        SET NOCOUNT ON;
        SET XACT_ABORT ON;
    
        DECLARE @SQL nvarchar(max);
        DECLARE @Schema sysname;
        DECLARE @Procedure sysname;
        DECLARE @Definition nvarchar(max);
        DECLARE @Counter int;
        DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);
    
        BEGIN TRAN;
        
        IF @IHaveABackup = 0
        BEGIN;
            RAISERROR (N'Do a backup before continuing with this, just in case !', 16, 1);
        END;

        DECLARE @Procedures TABLE
        (
            ProcedureNumber int IDENTITY(1,1),
            SchemaName sysname,
            ProcedureName sysname,
            ProcedureDefinition nvarchar(max)
        );

        SET @SQL = N'SELECT s.[name], o.[name], m.[definition]' + @CRLF 
                 + N'FROM sys.sql_modules AS m' + @CRLF 
                 + N'INNER JOIN sys.objects AS o' + @CRLF 
                 + N'ON o.object_id = m.object_id' + @CRLF 
                 + N'INNER JOIN sys.schemas AS s' + @CRLF 
                 + N'ON s.schema_id = o.schema_id' + @CRLF 
                 + N'WHERE o.type_desc = ''SQL_STORED_PROCEDURE''' + @CRLF 
                 + CASE WHEN @SchemaName = N'ALL'
                        THEN N'' 
                        ELSE N'AND s.[name] = N''' + @SchemaName + N'''' + @CRLF 
                   END
                 + CASE WHEN @ProcedureName = N'ALL' 
                        THEN N''
                        ELSE N'AND o.[name] = N''' + @ProcedureName + N'''' + @CRLF
                   END 
                 + N';';

        INSERT @Procedures (SchemaName, ProcedureName, ProcedureDefinition)
        EXEC (@SQL);
        
        SET @Counter = 1;
        WHILE @Counter <= (SELECT MAX(ProcedureNumber) FROM @Procedures)
        BEGIN
            SELECT @Schema = p.SchemaName,
                   @Procedure = p.ProcedureName,
                   @Definition = p.ProcedureDefinition
            FROM @Procedures AS p
            WHERE p.ProcedureNumber = @Counter;

            PRINT N'Processing ' + @Schema + N'.' + @Procedure;

            IF @Definition IS NULL
            BEGIN;
                RAISERROR(N'Cannot find the definition for the procedure !', 16, 1);
            END;          
            
            SET @SQL = N'DROP PROCEDURE ' + QUOTENAME(@Schema) + N'.' + QUOTENAME(@Procedure) + N';';
            EXEC (@SQL);
                  
            SET @SQL = N'SET ANSI_NULLS ' + CASE WHEN @NeedsAnsiNulls <> 0 THEN N'ON;' ELSE N'OFF' END + @CRLF 
                     + N'SET QUOTED_IDENTIFIER ' + CASE WHEN @NeedsQuotedIdentifier <> 0 THEN N'ON' ELSE N'OFF' END + @CRLF + @CRLF 
                     + N'DECLARE @SQL nvarchar(max) = N''' + REPLACE(@Definition, N'''', N'''''') + N''';' + @CRLF 
                     + N'EXEC (@SQL);';
            EXEC(@SQL);
            
            SET @Counter = @Counter + 1;
        END;

        COMMIT;
    END TRY 
    BEGIN CATCH 
        IF XACT_STATE() <> 0 
        BEGIN
            ROLLBACK; 
        END;
    
        PRINT 'Unable to change procedures. Error returned was:';
        PRINT ERROR_MESSAGE(); 
    END CATCH; 
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.IsWeekday
(
    @InputDate date
)
RETURNS bit
AS
BEGIN

-- Function:      Determines if the provided date is a week day (Monday to Friday)
-- Parameters:    @Input date (NULL for today)
-- Action:        Determines if the provided date is a week day (Monday to Friday) 
-- Return:        bit
-- Refer to this video: https://youtu.be/yizREK9tCZA
--
-- Test examples: 
/*

SELECT SDU_Tools.IsWeekday('20180713');
SELECT SDU_Tools.IsWeekday('20180811');
SELECT SDU_Tools.IsWeekday(SYSDATETIME());
SELECT SDU_Tools.IsWeekday(NULL);

*/
    RETURN CASE WHEN DATEDIFF(day, '20000101', ISNULL(@InputDate, SYSDATETIME())) % 7 BETWEEN 2 AND 6
                THEN CAST(1 AS bit)
                ELSE CAST(0 AS bit)
           END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.IsWeekend
(
    @InputDate date
)
RETURNS bit
AS
BEGIN

-- Function:      Determines if the provided date is a weekend day (Saturday or Sunday)
-- Parameters:    @Input date (NULL for today)
-- Action:        Determines if the provided date is a weekend day (Saturday or Sunday) 
-- Return:        bit
-- Refer to this video: https://youtu.be/yizREK9tCZA
--
-- Test examples: 
/*

SELECT SDU_Tools.IsWeekend('20180713');
SELECT SDU_Tools.IsWeekend('20180811');
SELECT SDU_Tools.IsWeekend(SYSDATETIME());
SELECT SDU_Tools.IsWeekend(NULL);

*/
    RETURN CASE WHEN DATEDIFF(day, '20000101', ISNULL(@InputDate, SYSDATETIME())) % 7 BETWEEN 2 AND 6
                THEN CAST(0 AS bit)
                ELSE CAST(1 AS bit)
           END;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListDisabledIndexesInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL'    -- N'ALL' for all
AS
BEGIN

-- Function:      ListDisabledIndexes
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        List indexes that are disabled with both key and included column lists
-- Return:        Rowset of indexes
-- Refer to this video: https://youtu.be/oLfp8y7XRdE
--
-- Test examples: 
/*

EXEC SDU_Tools.ListDisabledIndexesInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = 
'WITH IndexKeys
AS
(
       SELECT s.[name] AS SchemaName, t.[name] AS TableName, i.[name] AS IndexName,
              LEFT(icl.KeyColumnList, LEN(icl.KeyColumnList) - 1) AS KeyColumnList,
              LEFT(inccl.IncludedColumnList, LEN(inccl.IncludedColumnList) - 1) AS IncludedColumnList
       FROM sys.indexes AS i
       INNER JOIN sys.tables AS t 
       ON t.object_id = i.object_id
       INNER JOIN sys.schemas AS s
       ON s.schema_id = t.schema_id
       CROSS APPLY 
       (
           SELECT c.[name] + N'','' 
           FROM sys.index_columns AS ic 
           INNER JOIN sys.columns AS c 
           ON c.object_id = ic.object_id 
           AND c.column_id = ic.column_id
           WHERE ic.object_id = i.object_id 
           AND ic.index_id = i.index_id 
           AND ic.is_included_column = 0
           ORDER BY ic.index_column_id
           FOR XML PATH ('''')
       ) AS icl (KeyColumnList)
       CROSS APPLY 
       (
           SELECT c.[name] + N'','' 
           FROM sys.index_columns AS ic 
           INNER JOIN sys.columns AS c 
           ON c.object_id = ic.object_id 
           AND c.column_id = ic.column_id
           WHERE ic.object_id = i.object_id 
           AND ic.index_id = i.index_id 
           AND ic.is_included_column = 1
           ORDER BY ic.index_column_id
           FOR XML PATH ('''')
       ) AS inccl (IncludedColumnList)       
       WHERE t.is_ms_shipped = 0
       AND t.[name] <> N''sysdiagrams''
       AND i.is_hypothetical = 0
       AND i.is_disabled <> 0
)
SELECT ik.SchemaName, ik.TableName, ik.IndexName, ik.KeyColumnList, ik.IncludedColumnList
FROM IndexKeys AS ik
WHERE 1 = 1 '
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND ik.SchemaName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND ik.TableName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))'
      END + @CRLF + N'
ORDER BY ik.SchemaName, ik.TableName, ik.IndexName;';
    EXEC (@SQL);
END;
GO
   

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListUserHeapTablesInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL'    -- N'ALL' for all
AS
BEGIN

-- Function:      Lists the user tables that do not have a clustered index declared
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists the user tables that do not have a clustered index declared
-- Return:        Rowset containing SchemaName, TableName
-- Refer to this video: https://youtu.be/hhrLzkSY3pQ
--
-- Test examples: 
/*

EXEC SDU_Tools.ListUserHeapTablesInCurrentDatabase 
    @SchemasToList = N'ALL', 
    @TablesToList = N'ALL';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = N'
SELECT s.[name] AS SchemaName,
       t.[name] AS TableName
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.[schema_id] = t.[schema_id] 
WHERE t.is_ms_shipped = 0
AND t.[name] NOT LIKE ''dt%'' 
AND NOT EXISTS (SELECT 1 FROM sys.indexes AS i
                         WHERE i.[object_id] = t.[object_id]
                         AND i.index_id = 1)
AND t.[name] <> ''sysdiagrams''' + @CRLF
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))' + @CRLF
      END 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))' + @CRLF
      END
    + N'ORDER BY SchemaName, TableName;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListUserTablesWithNoPrimaryKeyInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL'    -- N'ALL' for all
AS
BEGIN

-- Function:      Lists the user tables that do not have a primary key declared
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists the user tables that do not have a primary key declared
-- Return:        Rowset containing SchemaName, TableName
-- Refer to this video: https://youtu.be/HVMEBhJS-GQ
--
-- Test examples: 
/*

EXEC SDU_Tools.ListUserTablesWithNoPrimaryKeyInCurrentDatabase 
    @SchemasToList = N'ALL', 
    @TablesToList = N'ALL';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = N'
SELECT s.[name] AS SchemaName,
       t.[name] AS TableName
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.[schema_id] = t.[schema_id] 
WHERE t.is_ms_shipped = 0
AND t.[name] NOT LIKE ''dt%'' 
AND NOT EXISTS (SELECT 1 FROM sys.indexes AS i
                         WHERE i.[object_id] = t.[object_id]
                         AND i.is_primary_key <> 0)
AND t.[name] <> ''sysdiagrams''' + @CRLF
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))' + @CRLF
      END 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))' + @CRLF
      END
    + N'ORDER BY SchemaName, TableName;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.NumberToRomanNumerals
(
    @InputNumber bigint
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Converts a number to a text string containing Roman Numerals
-- Parameters:    @InputNumber bigint - the value to be converted
-- Action:        Converts a number to a text string containing Roman Numerals
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/msCDdOdYwAo
--
-- Test examples: 
/*

SELECT SDU_Tools.NumberToRomanNumerals(9);
SELECT SDU_Tools.NumberToRomanNumerals(27);
SELECT SDU_Tools.NumberToRomanNumerals(2018);
SELECT SDU_Tools.NumberToRomanNumerals(12342);
SELECT SDU_Tools.NumberToRomanNumerals(657);
SELECT SDU_Tools.NumberToRomanNumerals(342);
SELECT SDU_Tools.NumberToRomanNumerals(53342);

*/
    DECLARE @Thousands bigint;
    DECLARE @Hundreds int;
    DECLARE @Tens int;
    DECLARE @Ones int;

    DECLARE @ReturnValue nvarchar(max) = N'';
    DECLARE @RemainingValue bigint = @InputNumber;

    SET @Thousands = FLOOR(@RemainingValue / 1000.0);
    SET @RemainingValue = @RemainingValue - (@Thousands * 1000);
    SET @ReturnValue = @ReturnValue + REPLICATE(N'M', @Thousands);

    SET @Hundreds = FLOOR(@RemainingValue / 100.0);
    SET @RemainingValue = @RemainingValue - (@Hundreds * 100);
    SET @ReturnValue = @ReturnValue 
                     + CASE @Hundreds WHEN 1 THEN N'C'
                                      WHEN 2 THEN N'CC'
                                      WHEN 3 THEN N'CCC'
                                      WHEN 4 THEN N'CD'
                                      WHEN 5 THEN N'D'
                                      WHEN 6 THEN N'DC'
                                      WHEN 7 THEN N'DCC'
                                      WHEN 8 THEN N'DCCC'
                                      WHEN 9 THEN N'CM'
                                      ELSE N'' 
                       END;

    SET @Tens = FLOOR(@RemainingValue / 10.0);
    SET @RemainingValue = @RemainingValue - (@Tens * 10);
    SET @ReturnValue = @ReturnValue 
                     + CASE @Tens WHEN 1 THEN N'X'
                                  WHEN 2 THEN N'XX'
                                  WHEN 3 THEN N'XXX'
                                  WHEN 4 THEN N'XL'
                                  WHEN 5 THEN N'L'
                                  WHEN 6 THEN N'LX'
                                  WHEN 7 THEN N'DLXX'
                                  WHEN 8 THEN N'LXXX'
                                  WHEN 9 THEN N'XC'
                                  ELSE N'' 
                       END;
    SET @Ones = @RemainingValue;
    SET @ReturnValue = @ReturnValue 
                     + CASE @Ones WHEN 1 THEN N'I'
                                  WHEN 2 THEN N'II'
                                  WHEN 3 THEN N'III'
                                  WHEN 4 THEN N'IV'
                                  WHEN 5 THEN N'V'
                                  WHEN 6 THEN N'VI'
                                  WHEN 7 THEN N'VII'
                                  WHEN 8 THEN N'VIII'
                                  WHEN 9 THEN N'IX'
                                  ELSE N'' 
                       END;
                     
    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ScriptTableAsUnpivotInCurrentDatabase
@SourceTableSchemaName sysname,
@SourceTableName sysname,
@OutputViewSchemaName sysname = @SourceTableSchemaName,
@OutputViewName sysname = @SourceTableName, 
@IsViewScript bit = 0,
@IncludeNullColumns bit = 0,
@IncludeWHEREClause bit = 0,
@ColumnIndentSize int = 4,
@ScriptIndentSize int = 0,
@QueryScript nvarchar(max) OUTPUT
AS
BEGIN
/* 

-- Function:      ScriptTableAsUnpivot
-- Parameters:    @SourceTableSchemaName sysname           -> Schema name for the table to be scripted
--                @SourceTableName sysname                 -> Table name for the table to be scripted
--                @OutputViewSchemaName sysname            -> Schema name for the output script (defaults to same as existing schema)
--                @OutputViewName sysname                  -> View name for the output script (defaults to same as existing table
--                                                            with _Unpivoted appended)
--                @IsViewScript bit                        -> Is a view being created? If not, a query is created. (defaults to query)
--                @IncludeNullColumns bit                  -> Should columns whose values are NULL be output? (defaults to no)
--                @IncludeWHEREClause bit                  -> Should a WHERE clause be included? (does not apply to views) (defaults to no)
--                @ColumnIndentSize                        -> How far should columns be indented from the table definition (defaults to 4)
--                @ScriptIndentSize                        -> How far indented should the script be? (defaults to 0)
--                @QueryScript nvarchar(max) OUTPUT        -> The output script
-- Action:        Create a script for a table that unpivots its results. The script can be a view or a query.
-- Return:        No rows returned. Output parameter holds the generated script.
-- Refer to this video: https://youtu.be/03f6NDB19ms
--
-- Test examples: 

SET NOCOUNT ON;

DECLARE @Script nvarchar(max);

EXEC SDU_Tools.ScriptTableAsUnpivotInCurrentDatabase 
    @SourceTableSchemaName  = N'Reference'
  , @SourceTableName = N'Currencies'
  , @OutputViewSchemaName = N'Reference'
  , @OutputViewName = N'Currencies_Unpivoted'
  , @IsViewScript = 0
  , @IncludeNullColumns = 0
  , @IncludeWHEREClause = 0
  , @ColumnIndentSize = 4
  , @ScriptIndentSize = 0
  , @QueryScript = @Script OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @Script, 1, 0, 0, 0, 'GO';

*/

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SQL nvarchar(max);
    DECLARE @Counter int;
    DECLARE @ColumnName sysname;
    DECLARE @DataTypeName sysname;
    DECLARE @TableAlias nvarchar(1);
    DECLARE @COLUMN_INDENT nvarchar(max) = REPLICATE(N' ', @ColumnIndentSize);
    DECLARE @SCRIPT_INDENT nvarchar(max) = REPLICATE(N' ', @ScriptIndentSize);
    DECLARE @CRLF nvarchar(2) = NCHAR(13) + NCHAR(10);
    
    DECLARE @PrimaryKeyColumns TABLE
    (
        PrimaryKeyColumnID int IDENTITY(1,1),
        ColumnName sysname,
        DataTypeName sysname
    );
    DECLARE @NonPrimaryKeyColumns TABLE
    (
        ColumnID int IDENTITY(1,1),
        ColumnName sysname,
        DataTypeName sysname
    );
    
    SET @TableAlias = LOWER(LEFT(@SourceTableName, 1));

    IF @TableAlias < N'a' OR @TableAlias > N'z' 
    BEGIN
        SET @TableAlias = N's';
    END;
    
    IF @OutputViewName = @SourceTableName SET @OutputViewName = @SourceTableName + N'_Unpivoted';

    IF @ColumnIndentSize < 2 SET @ColumnIndentSize = 2;
    IF @ScriptIndentSize < 0 SET @ScriptIndentSize = 0;
    
    SET @SQL = N'
           SELECT c.[name] AS ColumnName,
                  typ.[name] AS DataTypeName
           FROM sys.indexes AS i
           INNER JOIN sys.index_columns AS ic 
           ON ic.object_id = i.object_id
           AND ic.index_id = i.index_id 
           INNER JOIN sys.columns AS c 
           ON c.object_id = i.object_id 
           AND c.column_id = ic.column_id  
           INNER JOIN sys.tables AS t 
           ON t.object_id = i.object_id 
           INNER JOIN sys.schemas AS s 
           ON s.schema_id = t.schema_id 
           INNER JOIN sys.types AS typ
           ON c.system_type_id = typ.system_type_id 
           AND c.user_type_id = typ.user_type_id 
           WHERE i.is_primary_key <> 0
           AND ic.is_included_column = 0
           AND t.is_ms_shipped = 0
           AND s.[name] = N''' + @SourceTableSchemaName + N''' 
           AND t.[name] = N''' + @SourceTableName + N'''
           ORDER BY ic.index_column_id;';
    
    INSERT @PrimaryKeyColumns (ColumnName, DataTypeName)
    EXEC (@SQL);
    
    SET @SQL = N'
           SELECT c.[name] AS ColumnName,
                  typ.[name] AS DataTypeName
           FROM sys.columns AS c 
           INNER JOIN sys.tables AS t 
           ON t.object_id = c.object_id 
           INNER JOIN sys.schemas AS s 
           ON s.schema_id = t.schema_id 
           INNER JOIN sys.types AS typ
           ON c.system_type_id = typ.system_type_id 
           AND c.user_type_id = typ.user_type_id 
           WHERE t.is_ms_shipped = 0
           AND s.[name] = N''' + @SourceTableSchemaName + N''' 
           AND t.[name] = N''' + @SourceTableName + N'''
          AND NOT EXISTS (SELECT 1 
                           FROM sys.indexes AS i
                           INNER JOIN sys.index_columns AS ic 
                           ON ic.object_id = i.object_id
                           AND ic.index_id = i.index_id 
                           AND i.object_id = t.object_id 
                           AND i.is_primary_key <> 0
                           AND ic.column_id = c.column_id)
           ORDER BY c.column_id;';
    
    INSERT @NonPrimaryKeyColumns (ColumnName, DataTypeName)
    EXEC (@SQL);

    IF NOT EXISTS (SELECT 1 FROM @PrimaryKeyColumns)
        OR NOT EXISTS (SELECT 1 FROM @NonPrimaryKeyColumns)
    BEGIN
        RAISERROR(N'Sorry. Unable to script tables without primary keys or other columns.', 16, 1);
        RETURN;
    END;
    
    SET @QueryScript = N'';
    
    IF @IsViewScript <> 0
    BEGIN
        SET @QueryScript += @SCRIPT_INDENT + N'CREATE OR ALTER VIEW ' 
                          + QUOTENAME(@OutputViewSchemaName) + N'.' + QUOTENAME(@OutputViewName) + @CRLF 
                          + @SCRIPT_INDENT + N'AS' + @CRLF;
    END;
    
    SET @QueryScript += @SCRIPT_INDENT + N'SELECT' + @CRLF;
    
    SET @Counter = 1;
    WHILE @Counter <= (SELECT MAX(PrimaryKeyColumnID) FROM @PrimaryKeyColumns)
    BEGIN
        SELECT @ColumnName = ColumnName FROM @PrimaryKeyColumns WHERE PrimaryKeyColumnID = @Counter;
        SET @QueryScript += @SCRIPT_INDENT + @COLUMN_INDENT 
                          + N'att.' + QUOTENAME(@ColumnName) 
                          + N' AS AttributeID' 
                          + CASE WHEN @Counter > 1 THEN CAST(@Counter AS nvarchar(20)) ELSE N'' END
                          + N',' + @CRLF;
        SET @Counter += 1;
    END;
    
    SET @QueryScript += @SCRIPT_INDENT + @COLUMN_INDENT + N'att.AttributeName,' + @CRLF 
                      + @SCRIPT_INDENT + @COLUMN_INDENT
                      + CASE WHEN @IncludeNullColumns <> 0 
                             THEN N'CASE WHEN att.AttributeValue = N''COLUMN VALUE IS NULL'' '
                                  + N'THEN NULL ELSE att.AttributeValue END AS AttributeValue'
                             ELSE N'att.AttributeValue' 
                        END
                      + @CRLF 
                      + @SCRIPT_INDENT + N'FROM' + @CRLF 
                      + @SCRIPT_INDENT + + N'(' + @CRLF 
                      + @SCRIPT_INDENT + @COLUMN_INDENT + N'SELECT' + @CRLF;
                      
    SET @Counter = 1;
    WHILE @Counter <= (SELECT MAX(PrimaryKeyColumnID) FROM @PrimaryKeyColumns)
    BEGIN
        SELECT @ColumnName = ColumnName FROM @PrimaryKeyColumns WHERE PrimaryKeyColumnID = @Counter;
        SET @QueryScript += @SCRIPT_INDENT + @COLUMN_INDENT + @COLUMN_INDENT 
                          + @TableAlias + N'.' + QUOTENAME(@ColumnName) + N', ' + @CRLF 
        SET @Counter += 1;
    END;
                       
    SET @Counter = 1;
    WHILE @Counter <= (SELECT MAX(ColumnID) FROM @NonPrimaryKeyColumns)
    BEGIN
        SELECT @ColumnName = ColumnName,
               @DataTypeName = DataTypeName 
        FROM @NonPrimaryKeyColumns WHERE ColumnID = @Counter;
        SET @QueryScript += @SCRIPT_INDENT + @COLUMN_INDENT + @COLUMN_INDENT 
                         + CASE WHEN @IncludeNullColumns <> 0 THEN N'ISNULL(' ELSE N'' END 
                         + N'CONVERT(nvarchar(max), '
                         + @TableAlias + N'.'
                         + QUOTENAME(@ColumnName) 
                         + CASE WHEN @DataTypeName = N'date' THEN N', 112)'
                                WHEN @DataTypeName IN (N'datetime', N'datetime2', N'datetimeoffset') THEN N', 127)'
                                WHEN @DataTypeName = N'time' THEN N', 114)'
                                ELSE N')'
                           END
                         + CASE WHEN @IncludeNullColumns <> 0 THEN N', N''COLUMN VALUE IS NULL'')' ELSE N'' END
                         + N' AS '
                         + QUOTENAME(@ColumnName)
                         + CASE WHEN @Counter <> (SELECT MAX(ColumnID) FROM @NonPrimaryKeyColumns) THEN N',' ELSE N'' END 
                         + @CRLF;
        SET @Counter += 1;
    END;
    
    SET @QueryScript += @SCRIPT_INDENT + @COLUMN_INDENT 
                      + N'FROM ' + QUOTENAME(@SourceTableSchemaName) + N'.' + QUOTENAME(@SourceTableName) 
                      + N' AS ' + @TableAlias + @CRLF; 
    
    SET @QueryScript += @SCRIPT_INDENT + N') AS s' + @CRLF 
                      + @SCRIPT_INDENT + N'UNPIVOT' + @CRLF 
                      + @SCRIPT_INDENT + N'(' + @CRLF
                      + @SCRIPT_INDENT + @COLUMN_INDENT + N'AttributeValue FOR AttributeName IN' + @CRLF
                      + @SCRIPT_INDENT + @COLUMN_INDENT + N'(' + @CRLF;
    
    SET @Counter = 1;
    WHILE @Counter <= (SELECT MAX(ColumnID) FROM @NonPrimaryKeyColumns)
    BEGIN
        SELECT @ColumnName = ColumnName 
        FROM @NonPrimaryKeyColumns WHERE ColumnID = @Counter;
        SET @QueryScript += @SCRIPT_INDENT + @COLUMN_INDENT + @COLUMN_INDENT 
                         + QUOTENAME(@ColumnName) 
                         + CASE WHEN @Counter <> (SELECT MAX(ColumnID) FROM @NonPrimaryKeyColumns) THEN N',' ELSE N'' END 
                         + @CRLF;
        SET @Counter += 1;
    END;
    
    SET @ColumnName = (SELECT ColumnName FROM @PrimaryKeyColumns WHERE PrimaryKeyColumnID = 1);
    
    SET @QueryScript += @SCRIPT_INDENT + @COLUMN_INDENT + N')' + @CRLF
                      + @SCRIPT_INDENT + N') AS att' 
                      + CASE WHEN @IsViewScript <> 0 OR @IncludeWHEREClause = 0 THEN N';' ELSE N'' END 
                      + @CRLF;
    
    IF @IsViewScript = 0 AND @IncludeWHEREClause <> 0
    BEGIN
         SET @QueryScript += @SCRIPT_INDENT + N'WHERE att.' 
                          + QUOTENAME(@ColumnName) 
                          + N' = @' + @ColumnName 
                          + CASE WHEN (SELECT MAX(PrimaryKeyColumnID) FROM @PrimaryKeyColumns) = 1 THEN N';' ELSE N'' END
                          + @CRLF;
                          
        SET @Counter = 2;
        WHILE @Counter <= (SELECT MAX(PrimaryKeyColumnID) FROM @PrimaryKeyColumns)
        BEGIN
            SELECT @ColumnName = ColumnName FROM @PrimaryKeyColumns WHERE PrimaryKeyColumnID = @Counter;
            SET @QueryScript += @SCRIPT_INDENT 
                              + N'AND att.'
                              + QUOTENAME(@ColumnName) 
                              + N' = @' + @ColumnName 
                              + CASE WHEN @Counter = (SELECT MAX(PrimaryKeyColumnID) FROM @PrimaryKeyColumns) THEN N';' ELSE N'' END
                              + @CRLF;
            SET @Counter += 1;
        END;                   
    END
END;
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.LoginTypes
AS
-- Function:      Maps login types to names and descriptions
-- Parameters:    N/A
-- Action:        Maps login types to names and descriptions
-- Return:        Rowset 
-- Refer to this video: https://youtu.be/DFo9Yl2M3P0
--
-- Test examples: 
/*

SELECT * 
FROM SDU_Tools.LoginTypes 
ORDER BY LoginTypeID;

*/

SELECT LoginTypeID, LoginTypeName, [Description]
FROM (VALUES (0, N'WindowsUser', N'Individual Windows logon'),
             (1, N'WindowsGroup', N'Windows group logon'),
             (2, N'SqlLogin', N'SQL Server authenticated logon'),
             (3, N'Certificate', N'Logon mapped to a certificate'),
             (4, N'AsymmetricKey', N'Logon mapped to an asymmetric key'),
             (5, N'ExternalUser', N'Individual external user logon'),
             (6, N'ExternalGroup', N'External group logon')) 
     AS lt(LoginTypeID, LoginTypeName, [Description]);
GO


------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.UserTypes
AS
-- Function:      Maps user types to names and descriptions
-- Parameters:    N/A
-- Action:        Maps user types to names and descriptions
-- Return:        Rowset 
-- Refer to this video: https://youtu.be/DFo9Yl2M3P0
--
-- Test examples: 
/*

SELECT * 
FROM SDU_Tools.UserTypes 
ORDER BY UserTypeID;

*/

SELECT UserTypeID, UserTypeName, [Description]
FROM (VALUES (0, N'SqlLogin', N'SQL Server authenticated logon'),
             (1, N'Certificate', N'Certificate'),
             (2, N'AsymmetricKey', N'Asymmetric Key'),
             (3, N'NoLogin', N'User unable to log in to SQL Server'),
             (4, N'External', N'External user')) 
     AS ut(UserTypeID, UserTypeName, [Description]);
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.RSCatalogTypes
AS
-- Function:      Maps reporting services catalog types to names
-- Parameters:    N/A
-- Action:        Maps reporting services catalog types to names
-- Return:        Rowset 
-- Refer to this video: https://youtu.be/1eSKt2E0rbY
--
-- Test examples: 
/*

SELECT * 
FROM SDU_Tools.RSCatalogTypes 
ORDER BY CatalogTypeID;

*/

SELECT CatalogTypeID, CatalogTypeName
FROM (VALUES (1, N'Folder'),
             (2, N'Report'),
             (3, N'Resource'),
             (4, N'Linked Report'),
             (5, N'Data Source'),
             (6, N'Report Model'),
             (8, N'Shared DataSet'),
             (9, N'Report Part'),
             (11, N'KPI'),
             (12, N'Mobile Report'),
             (13, N'Power BI Report'))
     AS ct(CatalogTypeID, CatalogTypeName);
GO

------------------------------------------------------------------------------------
-- CREATE PROCEDURE SDU_Tools.RSListUserAccessToContent (Not appropriate for Azure SQL DB)
------------------------------------------------------------------------------------
-- CREATE PROCEDURE SDU_Tools.RSListContentItems (Not appropriate for Azure SQL DB)
------------------------------------------------------------------------------------
-- CREATE PROCEDURE SDU_Tools.RSListUserAccess (Not appropriate for Azure SQL DB)
------------------------------------------------------------------------------------
GO

CREATE VIEW SDU_Tools.ChineseYears
AS
-- Function:      Maps Years to Chinese Years
-- Parameters:    N/A
-- Action:        Maps Years to Chinese Years
-- Return:        Rowset 
-- Refer to this video: https://youtu.be/FM-SPBzXCYM
--
-- Test examples: 
/*

SELECT * 
FROM SDU_Tools.ChineseYears
ORDER BY [Year];

SELECT ChineseNewYearDate 
FROM SDU_Tools.ChineseYears 
WHERE [Year] = 2019;

*/

SELECT CAST(LEFT(ChineseNewYearDate, 4) AS int) AS [Year],
       ChineseNewYearDate, AnimalName, 
       SimplifiedCharacter, PinYin, TraditionalCharacter 
FROM (VALUES (N'19000131', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'19010219', N'Ox', N'牛', N'Niú', N'牛'),
             (N'19020208', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'19030129', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'19040216', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'19050204', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'19060125', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'19070213', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'19080202', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'19090122', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'19100210', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'19110130', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'19120218', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'19130206', N'Ox', N'牛', N'Niú', N'牛'),
             (N'19140126', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'19150214', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'19160203', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'19170123', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'19180211', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'19190201', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'19200220', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'19210208', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'19220128', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'19230216', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'19240205', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'19250124', N'Ox', N'牛', N'Niú', N'牛'),
             (N'19260213', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'19270202', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'19280123', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'19290210', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'19300130', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'19310217', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'19320206', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'19330126', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'19340214', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'19350204', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'19360124', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'19370211', N'Ox', N'牛', N'Niú', N'牛'),
             (N'19380131', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'19390219', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'19400208', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'19410127', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'19420215', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'19430205', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'19440125', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'19450213', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'19460202', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'19470122', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'19480210', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'19490129', N'Ox', N'牛', N'Niú', N'牛'),
             (N'19500217', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'19510206', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'19520127', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'19530214', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'19540203', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'19550124', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'19560212', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'19570131', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'19580218', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'19590208', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'19600128', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'19610215', N'Ox', N'牛', N'Niú', N'牛'),
             (N'19620205', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'19630125', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'19640213', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'19650202', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'19660121', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'19670209', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'19680130', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'19690217', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'19700206', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'19710127', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'19720215', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'19730203', N'Ox', N'牛', N'Niú', N'牛'),
             (N'19740123', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'19750211', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'19760131', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'19770218', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'19780207', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'19790128', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'19800216', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'19810205', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'19820125', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'19830213', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'19840202', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'19850220', N'Ox', N'牛', N'Niú', N'牛'),
             (N'19860209', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'19870129', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'19880217', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'19890206', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'19900127', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'19910215', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'19920204', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'19930123', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'19940210', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'19950131', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'19960219', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'19970207', N'Ox', N'牛', N'Niú', N'牛'),
             (N'19980128', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'19990216', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'20000205', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'20010124', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'20020212', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'20030201', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'20040122', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'20050209', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'20060129', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'20070218', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'20080207', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'20090126', N'Ox', N'牛', N'Niú', N'牛'),
             (N'20100214', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'20110203', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'20120123', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'20130210', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'20140131', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'20150219', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'20160208', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'20170128', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'20180216', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'20190205', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'20200125', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'20210212', N'Ox', N'牛', N'Niú', N'牛'),
             (N'20220201', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'20230122', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'20240210', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'20250129', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'20260217', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'20270206', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'20280126', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'20290213', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'20300203', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'20310123', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'20320211', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'20330131', N'Ox', N'牛', N'Niú', N'牛'),
             (N'20340219', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'20350208', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'20360128', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'20370215', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'20380204', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'20390124', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'20400212', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'20410201', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'20420122', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'20430210', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'20440130', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'20450217', N'Ox', N'牛', N'Niú', N'牛'),
             (N'20460206', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'20470126', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'20480214', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'20490202', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'20500123', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'20510211', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'20520201', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'20530219', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'20540208', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'20550128', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'20560215', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'20570204', N'Ox', N'牛', N'Niú', N'牛'),
             (N'20580124', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'20590212', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'20600202', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'20610121', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'20620209', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'20630129', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'20640217', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'20650205', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'20660126', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'20670214', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'20680203', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'20690123', N'Ox', N'牛', N'Niú', N'牛'),
             (N'20700211', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'20710131', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'20720219', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'20730207', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'20740127', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'20750215', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'20760205', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'20770124', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'20780212', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'20790202', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'20800122', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'20810209', N'Ox', N'牛', N'Niú', N'牛'),
             (N'20820129', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'20830217', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'20840206', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'20850126', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'20860214', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'20870203', N'Goat', N'羊', N'Yáng', N'羊'),
             (N'20880124', N'Monkey', N'猴', N'Hóu', N'猴'),
             (N'20890210', N'Rooster', N'鸡', N'Jī', N'雞'),
             (N'20900130', N'Dog', N'狗', N'Gǒu', N'狗'),
             (N'20910218', N'Pig', N'猪', N'Zhū', N'豬'),
             (N'20920207', N'Rat', N'鼠', N'Shǔ', N'鼠'),
             (N'20930127', N'Ox', N'牛', N'Niú', N'牛'),
             (N'20940215', N'Tiger', N'虎', N'Hǔ', N'虎'),
             (N'20950205', N'Rabbit', N'兔', N'Tù', N'兔'),
             (N'20960125', N'Dragon', N'龙', N'Lóng', N'龍'),
             (N'20970212', N'Snake', N'蛇', N'Shé', N'蛇'),
             (N'20980201', N'Horse', N'马', N'Mǎ', N'馬'),
             (N'20990121', N'Goat', N'羊', N'Yáng', N'羊'))
     AS lcy(ChineseNewYearDate, AnimalName, SimplifiedCharacter, PinYin, TraditionalCharacter);
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DateOfChineseNewYear
(
    @Year int
)
RETURNS date
AS
BEGIN

-- Function:      Returns the date of Chinese New Year in a given year
-- Parameters:    @Year int  -> year number  (must be between 1900 and 2099)
-- Action:        Calculates the date of Chinese New Year for a given year
-- Return:        date
-- Refer to this video: https://youtu.be/FM-SPBzXCYM
--
-- Test examples: 
/*

SELECT SDU_Tools.DateOfChineseNewYear(2019);
SELECT SDU_Tools.DateOfChineseNewYear(1958);

*/

    RETURN (SELECT ChineseNewYearDate
            FROM (VALUES (N'19000131'), (N'19010219'), (N'19020208'), (N'19030129'), (N'19040216'), (N'19050204'), 
                         (N'19060125'), (N'19070213'), (N'19080202'), (N'19090122'), (N'19100210'), (N'19110130'), 
                         (N'19120218'), (N'19130206'), (N'19140126'), (N'19150214'), (N'19160203'), (N'19170123'), 
                         (N'19180211'), (N'19190201'), (N'19200220'), (N'19210208'), (N'19220128'), (N'19230216'), 
                         (N'19240205'), (N'19250124'), (N'19260213'), (N'19270202'), (N'19280123'), (N'19290210'), 
                         (N'19300130'), (N'19310217'), (N'19320206'), (N'19330126'), (N'19340214'), (N'19350204'), 
                         (N'19360124'), (N'19370211'), (N'19380131'), (N'19390219'), (N'19400208'), (N'19410127'), 
                         (N'19420215'), (N'19430205'), (N'19440125'), (N'19450213'), (N'19460202'), (N'19470122'), 
                         (N'19480210'), (N'19490129'), (N'19500217'), (N'19510206'), (N'19520127'), (N'19530214'), 
                         (N'19540203'), (N'19550124'), (N'19560212'), (N'19570131'), (N'19580218'), (N'19590208'), 
                         (N'19600128'), (N'19610215'), (N'19620205'), (N'19630125'), (N'19640213'), (N'19650202'), 
                         (N'19660121'), (N'19670209'), (N'19680130'), (N'19690217'), (N'19700206'), (N'19710127'), 
                         (N'19720215'), (N'19730203'), (N'19740123'), (N'19750211'), (N'19760131'), (N'19770218'), 
                         (N'19780207'), (N'19790128'), (N'19800216'), (N'19810205'), (N'19820125'), (N'19830213'), 
                         (N'19840202'), (N'19850220'), (N'19860209'), (N'19870129'), (N'19880217'), (N'19890206'), 
                         (N'19900127'), (N'19910215'), (N'19920204'), (N'19930123'), (N'19940210'), (N'19950131'), 
                         (N'19960219'), (N'19970207'), (N'19980128'), (N'19990216'), 
                         (N'20000205'), (N'20010124'), (N'20020212'), (N'20030201'), (N'20040122'), (N'20050209'), 
                         (N'20060129'), (N'20070218'), (N'20080207'), (N'20090126'), (N'20100214'), (N'20110203'), 
                         (N'20120123'), (N'20130210'), (N'20140131'), (N'20150219'), (N'20160208'), (N'20170128'), 
                         (N'20180216'), (N'20190205'), (N'20200125'), (N'20210212'), (N'20220201'), (N'20230122'), 
                         (N'20240210'), (N'20250129'), (N'20260217'), (N'20270206'), (N'20280126'), (N'20290213'), 
                         (N'20300203'), (N'20310123'), (N'20320211'), (N'20330131'), (N'20340219'), (N'20350208'), 
                         (N'20360128'), (N'20370215'), (N'20380204'), (N'20390124'), (N'20400212'), (N'20410201'), 
                         (N'20420122'), (N'20430210'), (N'20440130'), (N'20450217'), (N'20460206'), (N'20470126'), 
                         (N'20480214'), (N'20490202'), (N'20500123'), (N'20510211'), (N'20520201'), (N'20530219'), 
                         (N'20540208'), (N'20550128'), (N'20560215'), (N'20570204'), (N'20580124'), (N'20590212'), 
                         (N'20600202'), (N'20610121'), (N'20620209'), (N'20630129'), (N'20640217'), (N'20650205'), 
                         (N'20660126'), (N'20670214'), (N'20680203'), (N'20690123'), (N'20700211'), (N'20710131'), 
                         (N'20720219'), (N'20730207'), (N'20740127'), (N'20750215'), (N'20760205'), (N'20770124'), 
                         (N'20780212'), (N'20790202'), (N'20800122'), (N'20810209'), (N'20820129'), (N'20830217'), 
                         (N'20840206'), (N'20850126'), (N'20860214'), (N'20870203'), (N'20880124'), (N'20890210'), 
                         (N'20900130'), (N'20910218'), (N'20920207'), (N'20930127'), (N'20940215'), (N'20950205'), 
                         (N'20960125'), (N'20970212'), (N'20980201'), (N'20990121')) AS cy(ChineseNewYearDate)
            WHERE LEFT(ChineseNewYearDate, 4) = CAST(@Year AS nvarchar(4)));
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ChineseNewYearAnimalName
(
    @Year int
)
RETURNS nvarchar(8)
AS
BEGIN

-- Function:      Returns the zodiac animal name for Chinese New Year in a given year
-- Parameters:    @Year int  -> year number  (must be between 1900 and 2099)
-- Action:        Returns the zodiac animal name for Chinese New Year in a given year
-- Return:        nvarchar(8)
-- Refer to this video: https://youtu.be/FM-SPBzXCYM
--
-- Test examples: 
/*

SELECT SDU_Tools.ChineseNewYearAnimalName(2019);
SELECT SDU_Tools.ChineseNewYearAnimalName(1958);

*/

    RETURN (SELECT TOP(1) a.AnimalName 
            FROM (VALUES (0, N'Rat'), (1, N'Ox'), (2, N'Tiger'), (3, N'Rabbit'), (4, N'Dragon'), (5, N'Snake'),
                     (6, N'Horse'), (7, N'Goat'), (8, N'Monkey'), (9, N'Rooster'), (10, N'Dog'), (11, N'Pig')
             ) AS a(YearOffset, AnimalName)
            WHERE a.YearOffset = (@Year - 1900) % 12);
END;
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.LatestSQLServerBuilds
AS
/* 

-- View:          LatestSQLServerBuilds
-- Action:        View returning latest release and patch level for all supported
--                SQL Server versions
-- Return:        One or two rows per version; two rows is a patch level exists
-- Refer to this video: https://youtu.be/iukl9tItxJ0
--
-- Test examples: 

SELECT * 
FROM SDU_Tools.LatestSQLServerBuilds 
ORDER BY SQLServerVersion DESC, Build;

*/

SELECT pv.SQLServerVersion, 
       pv.BaseLevel,
       ISNULL(CAST(pv.MajorVersionNumber AS varchar(10)) + '.' 
              + CAST(pv.MinorVersionNumber AS varchar(10)) + '.'
              + CAST(pv.BuildNumber AS varchar(10)), '') AS Build, 
       ISNULL(pv.PatchLevel, N'') AS PatchLevel,
       ISNULL(pv.CoreKBArticleURL, N'N/A') AS KBArticleURL
FROM SDU_Tools.SQLServerProductVersions AS pv
WHERE pv.PatchLevel IS NULL
AND NOT EXISTS (SELECT 1 FROM SDU_Tools.SQLServerProductVersions AS pvp
                         WHERE pvp.SQLServerVersion = pv.SQLServerVersion
                         AND pvp.PatchLevel IS NULL 
                         AND pvp.BuildNumber > pv.BuildNumber)
UNION 
SELECT pv.SQLServerVersion, 
       pv.BaseLevel, 
       ISNULL(CAST(pv.MajorVersionNumber AS varchar(10)) + '.' 
              + CAST(pv.MinorVersionNumber AS varchar(10)) + '.'
              + CAST(pv.BuildNumber AS varchar(10)), '') AS Build,        ISNULL(pv.PatchLevel, N'') AS PatchLevel,
       ISNULL(pv.CoreKBArticleURL, N'N/A') AS KBArticleURL
FROM SDU_Tools.SQLServerProductVersions AS pv
WHERE NOT EXISTS (SELECT 1 FROM SDU_Tools.SQLServerProductVersions AS pvp
                           WHERE pvp.SQLServerVersion = pv.SQLServerVersion
                           AND pvp.BuildNumber > pv.BuildNumber);
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.AddWeekdays
(
    @StartDate date,
    @NumberOfWeekdays int
)
RETURNS date
AS
BEGIN

-- Function:      Adds a number of weekdays (non-weekend-days) to a start date
-- Parameters:    @StartDate date -> date to start calculating from
--                @NumberOfWeekdays int -> number of weekdays to add
-- Action:        Adds a number of weekdays (non-weekend-days) to a start date
-- Return:        date - calculated date
-- Refer to this video: https://youtu.be/P7-nGcDOVyI
--
-- Test examples: 
/*

SELECT SDU_Tools.AddWeekdays('20190201', 5);
SELECT SDU_Tools.AddWeekdays('20190201', 32);
SELECT SDU_Tools.AddWeekdays('20190228', 47);

*/
    DECLARE @FullWeeks int = @NumberOfWeekdays / 5;
    DECLARE @ExtraDays int = @NumberOfWeekdays - (@FullWeeks * 5);
    DECLARE @DateToReturn date = DATEADD(week, @FullWeeks, @StartDate);
    DECLARE @Counter int = 1;

    WHILE @ExtraDays > 0
    BEGIN
        SET @DateToReturn = DATEADD(day, 1, @DateToReturn);
        IF DATEPART(weekday, @DateToReturn) NOT IN (DATEPART(weekday, '19000107'), DATEPART(weekday, '19000106'))
        BEGIN
			SET @ExtraDays = @ExtraDays - 1;
		END;
    END;

	RETURN @DateToReturn;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.TruncateTrailingZeroes
(
    @ValueToTruncate decimal(18, 6)
)
RETURNS nvarchar(40)
AS
BEGIN

-- Function:      Returns the value converted to a string with trailing zeroes truncated
-- Parameters:    @ValueToTruncate decimal(18, 6) -> the value to be truncated
-- Action:        Returns the value converted to a string with trailing zeroes truncated
-- Return:        nvarchar(40)
-- Refer to this video: https://youtu.be/DGnUdJVIxmU
--
-- Test examples: 
/*

SELECT SDU_Tools.TruncateTrailingZeroes(123.11);
SELECT SDU_Tools.TruncateTrailingZeroes(123.00);
SELECT SDU_Tools.TruncateTrailingZeroes(123.010);

*/

    RETURN (SELECT CASE WHEN @ValueToTruncate = FLOOR(@ValueToTruncate) 
                        THEN CAST(FLOOR(@ValueToTruncate) AS varchar(40))
                        ELSE SUBSTRING(CAST(@ValueToTruncate AS varchar(40)), 
                                       1, 
                                       LEN(CAST(@ValueToTruncate AS varchar(40))) 
                                       + 1 
                                       - PATINDEX('%[^0]%', REVERSE(CAST(@ValueToTruncate AS varchar(40)))))
       END);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.RetrustForeignKeysInCurrentDatabase
@SchemasToInclude nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToInclude nvarchar(max) = N'ALL'    -- N'ALL' for all
AS
BEGIN

-- Function:      RetrustForeignKeys
-- Parameters:    @SchemasToInclude nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToInclude nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Tries to retrust untrusted foreign keys. Ignores disabled foreign keys.
-- Return:        Nil
-- Refer to this video: https://youtu.be/UM1NFlu4z28
--
-- Test examples: 
/*

EXEC SDU_Tools.RetrustForeignKeysInCurrentDatabase 
     @SchemasToInclude = N'ALL', 
     @TablesToInclude = N'ALL'; 
GO

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @UntrustedForeignKeys TABLE
    (
        UntrustedForeignKeyID int IDENTITY(1,1) PRIMARY KEY,
        SchemaName sysname,
        TableName sysname,
        ForeignKeyName sysname
    );
    DECLARE @Counter int;
    DECLARE @SchemaName sysname;
    DECLARE @TableName sysname;
    DECLARE @ForeignKeyName sysname;

    DECLARE @SQL nvarchar(max) = 
'WITH UntrustedForeignKeys
AS
(
       SELECT ss.[name] AS SourceSchemaName, 
              st.[name] AS SourceTableName, 
              fk.[name] AS ForeignKeyName
       FROM sys.foreign_keys AS fk
       INNER JOIN sys.tables AS st 
       ON st.object_id = fk.parent_object_id
       INNER JOIN sys.schemas AS ss
       ON ss.schema_id = st.schema_id
       WHERE st.is_ms_shipped = 0
       AND st.[name] <> N''sysdiagrams''
       AND fk.is_not_trusted <> 0 
       AND fk.is_disabled = 0
)
SELECT ufk.SourceSchemaName, ufk.SourceTableName, ufk.ForeignKeyName
FROM UntrustedForeignKeys AS ufk 
WHERE 1 = 1 '
    + CASE WHEN @SchemasToInclude = N'ALL' 
           THEN N''
           ELSE N'    AND ufk.SourceSchemaName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToInclude + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToInclude = N'ALL' 
           THEN N''
           ELSE N'    AND ufk.SourceTableName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToInclude + ''', N'','', 1))'
      END + @CRLF + N'
ORDER BY ufk.SourceSchemaName, ufk.SourceTableName, ufk.ForeignKeyName;';
    INSERT @UntrustedForeignKeys (SchemaName, TableName, ForeignKeyName)
    EXEC (@SQL);

    SET @Counter = 1;
    WHILE @Counter <= (SELECT MAX(UntrustedForeignKeyID) FROM @UntrustedForeignKeys)
    BEGIN
        SELECT @SchemaName = SchemaName,
               @TableName = TableName,
               @ForeignKeyName = ForeignKeyName 
        FROM @UntrustedForeignKeys
        WHERE UntrustedForeignKeyID = @Counter;

        PRINT N'Attempting to trust ' + @SchemaName + N'.' + @TableName + N'.' + @ForeignKeyName;

        SET @SQL = N'ALTER TABLE ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) 
                 + N' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(@ForeignKeyName) + N';';
        EXEC(@SQL);

        SET @Counter = @Counter + 1;
    END;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.RetrustCheckConstraintsInCurrentDatabase
@SchemasToInclude nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToInclude nvarchar(max) = N'ALL'    -- N'ALL' for all
AS
BEGIN

-- Function:      RetrustCheckConstraints
-- Parameters:    @SchemasToInclude nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToInclude nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Tries to retrust untrusted check constraints. Ignores disabled constraints.
-- Return:        Nil
-- Refer to this video: https://youtu.be/UM1NFlu4z28
--
-- Test examples: 
/*

EXEC SDU_Tools.RetrustCheckConstraintsInCurrentDatabase
     @SchemasToInclude = N'ALL', 
     @TablesToInclude = N'ALL'; 
GO

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @UntrustedCheckConstraints TABLE
    (
        UntrustedCheckConstraintID int IDENTITY(1,1) PRIMARY KEY,
        SchemaName sysname,
        TableName sysname,
        CheckConstraintName sysname
    );
    DECLARE @Counter int;
    DECLARE @SchemaName sysname;
    DECLARE @TableName sysname;
    DECLARE @CheckConstraintName sysname;

    DECLARE @SQL nvarchar(max) = 
'WITH UntrustedCheckConstraints
AS
(
       SELECT ss.[name] AS SourceSchemaName, 
              st.[name] AS SourceTableName, 
              cc.[name] AS CheckConstraintName
       FROM sys.check_constraints AS cc
       INNER JOIN sys.tables AS st 
       ON st.object_id = cc.parent_object_id
       INNER JOIN sys.schemas AS ss
       ON ss.schema_id = st.schema_id
       WHERE st.is_ms_shipped = 0
       AND st.[name] <> N''sysdiagrams''
       AND cc.is_not_trusted <> 0 
       AND cc.is_disabled = 0
)
SELECT ucc.SourceSchemaName, ucc.SourceTableName, ucc.CheckConstraintName
FROM UntrustedCheckConstraints AS ucc 
WHERE 1 = 1 '
    + CASE WHEN @SchemasToInclude = N'ALL' 
           THEN N''
           ELSE N'    AND ucc.SourceSchemaName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToInclude + ''', N'','', 1))'
      END + @CRLF 
    + CASE WHEN @TablesToInclude = N'ALL' 
           THEN N''
           ELSE N'    AND ucc.SourceTableName IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToInclude + ''', N'','', 1))'
      END + @CRLF + N'
ORDER BY ucc.SourceSchemaName, ucc.SourceTableName, ucc.CheckConstraintName;';
    INSERT @UntrustedCheckConstraints (SchemaName, TableName, CheckConstraintName)
    EXEC (@SQL);

    SET @Counter = 1;
    WHILE @Counter <= (SELECT MAX(UntrustedCheckConstraintID) FROM @UntrustedCheckConstraints)
    BEGIN
        SELECT @SchemaName = SchemaName,
               @TableName = TableName,
               @CheckConstraintName = CheckConstraintName 
        FROM @UntrustedCheckConstraints
        WHERE UntrustedCheckConstraintID = @Counter;

        PRINT N'Attempting to trust ' + @SchemaName + N'.' + @TableName + N'.' + @CheckConstraintName;

        SET @SQL = N'ALTER TABLE ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) 
                 + N' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(@CheckConstraintName) + N';';
        EXEC(@SQL);

        SET @Counter = @Counter + 1;
    END;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ScriptDatabaseObjectPermissionsInCurrentDatabase
(
    @ScriptOutput nvarchar(max) OUTPUT
)
AS
BEGIN

-- Function:      Scripts all database object permissions
-- Parameters:    Nil
-- Action:        Scripts all database object premissions
-- Return:        Single column called ScriptOutput nvarchar(max)
-- Refer to this video: https://youtu.be/Yz_869V-hRw
-- Test examples: 
/*

SET NOCOUNT ON;
DECLARE @SQL nvarchar(max);

EXEC SDU_Tools.ScriptDatabaseObjectPermissionsInCurrentDatabase @SQL OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @SQL;

*/
    DECLARE @DatabaseObjectPermissions TABLE
    (
        DatabaseObjectPermissionID int IDENTITY(1,1) PRIMARY KEY,
        PermissionState nvarchar(20),
        PermissionName sysname,
        SchemaName sysname,
        ObjectName sysname,
        PrincipalName sysname
    );
    
    DECLARE @SQL nvarchar(max) = N'
SELECT dp.state_desc,
       dp.permission_name,
       s.[name],
       o.[name],
       pr.[name]
FROM sys.database_permissions AS dp
INNER JOIN sys.objects AS o 
ON o.object_id = dp.major_id
INNER JOIN sys.schemas AS s 
ON s.schema_id = o.schema_id
INNER JOIN sys.database_principals AS pr 
ON pr.principal_id = dp.grantee_principal_id
WHERE pr.[name] NOT IN (N''public'', N''guest'')
ORDER BY s.[name], o.[name], pr.[name];';

    INSERT @DatabaseObjectPermissions 
    (
        PermissionState, PermissionName, SchemaName, 
        ObjectName, PrincipalName
    )
    EXECUTE (@SQL);

    DECLARE @Counter int = 1;
    SET @SQL = N'';
    DECLARE @CRLF nvarchar(2) = NCHAR(13) + NCHAR(10);
    DECLARE @PermissionState nvarchar(20);
    DECLARE @PermissionName sysname;
    DECLARE @SchemaName sysname;
    DECLARE @ObjectName sysname;
    DECLARe @PrincipalName sysname;
       
    
    WHILE @Counter <= (SELECT MAX(DatabaseObjectPermissionID) FROM @DatabaseObjectPermissions)
    BEGIN
        SELECT @PermissionState = dop.PermissionState,
               @PermissionName = dop.PermissionName,
               @SchemaName = dop.SchemaName,
               @ObjectName = dop.ObjectName,
               @PrincipalName = dop.PrincipalName 
        FROM @DatabaseObjectPermissions AS dop 
        WHERE dop.DatabaseObjectPermissionID = @Counter;

        SET @SQL += @PermissionState + N' ' + @PermissionName 
                  + N' ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@ObjectName) 
                  + N' TO ' + QUOTENAME(@PrincipalName) + N';'
                  + @CRLF;

        SET @Counter += 1;
    END;

    SET @ScriptOutput = @SQL;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.NumberOfTokens
(
    @StringToTokenize nvarchar(max),
    @Delimiter nvarchar(10)
)
RETURNS int
AS
BEGIN

-- Function:      Counts the number of tokens in a delimited string (usually either a CSV or TSV)
-- Parameters:    @StringToTokenize nvarchar(max)    -> string that will be tokenized
--                @Delimiter nvarchar(10)            -> delimited used (usually either N',' or NCHAR(9) for tab)
-- Action:        Tokenizes a delimited string and counts the number of tokens
--                Delimiter can be specified
-- Return:        Count of the number of tokens
-- Refer to this video: https://youtu.be/vT8GpbwaKzU
-- Test examples: 
/*

SELECT SDU_Tools.NumberOfTokens(N'hello, there, greg', N',');
SELECT SDU_Tools.NumberOfTokens(N'hello' + NCHAR(9) + N'there' + NCHAR(9) + N'greg', NCHAR(9));
SELECT SDU_Tools.NumberOfTokens(N'Now works, with embedded ,% signs', N',');

*/
    DECLARE @StringTable TABLE 
    (
        RowNumber int IDENTITY(1,1),
        StringValue nvarchar(max)
    );

    DECLARE @RemainingString nvarchar(max) = @StringToTokenize;
    DECLARE @NextDelimiterLocation int = CHARINDEX(@Delimiter, @RemainingString);
    WHILE @NextDelimiterLocation > 0
    BEGIN
        INSERT @StringTable VALUES (SUBSTRING(@RemainingString, 1, @NextDelimiterLocation - 1));
        SET @RemainingString = SUBSTRING(@RemainingString, @NextDelimiterLocation + 1, LEN(@RemainingString));
        SET @NextDelimiterLocation = CHARINDEX(@Delimiter, @RemainingString);
    END;

    IF LEN(@RemainingString) > 0
    BEGIN
        INSERT @StringTable VALUES (@RemainingString);
    END;

    RETURN (SELECT COUNT(1) FROM @StringTable);
END;
GO
   
------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ExtractToken
(
    @StringToTokenize nvarchar(max),
    @Delimiter nvarchar(10),
    @TokenNumber int,
    @TrimOutput bit
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Extracts a specific token from a delimited string (usually either a CSV or TSV)
-- Parameters:    @StringToTokenize nvarchar(max)    -> string that will be tokenized
--                @Delimiter nvarchar(10)            -> delimited used (usually either N',' or NCHAR(9) for tab)
--                @TokenNumber int                   -> token that is required - starting at 1
--                @TrimOutput bit                    -> should the output be trimmed?
-- Action:        Extracts a specific token from a delimited string
--                Delimiter can be specified
--                Optionally trims the token
-- Return:        Extracts a specific token as nvarchar(max)
-- Refer to this video: https://youtu.be/vT8GpbwaKzU
-- Test examples: 
/*

SELECT SDU_Tools.ExtractToken(N'hello, there, greg', N',', 1, 1);
SELECT SDU_Tools.ExtractToken(N'hello' + NCHAR(9) + N'there' + NCHAR(9) + N'greg', NCHAR(9), 2, 0);
SELECT SDU_Tools.ExtractToken(N'Now works, with embedded ,% signs', N',', 3, 1);

*/
    DECLARE @StringTable TABLE 
    (
        RowNumber int IDENTITY(1,1),
        StringValue nvarchar(max)
    );

    DECLARE @RemainingString nvarchar(max) = @StringToTokenize;
    DECLARE @NextDelimiterLocation int = CHARINDEX(@Delimiter, @RemainingString);
    WHILE @NextDelimiterLocation > 0
    BEGIN
        INSERT @StringTable VALUES (SUBSTRING(@RemainingString, 1, @NextDelimiterLocation - 1));
        SET @RemainingString = SUBSTRING(@RemainingString, @NextDelimiterLocation + 1, LEN(@RemainingString));
        SET @NextDelimiterLocation = CHARINDEX(@Delimiter, @RemainingString);
    END;

    IF LEN(@RemainingString) > 0
    BEGIN
        INSERT @StringTable VALUES (@RemainingString);
    END;

    RETURN (SELECT CASE WHEN @TrimOutput <> 0
                        THEN LTRIM(RTRIM(StringValue)) 
                        ELSE StringValue 
                   END 
            FROM @StringTable
            WHERE RowNumber = @TokenNumber);
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ListEmptyUserTablesInCurrentDatabase
@SchemasToList nvarchar(max) = N'ALL',  -- N'ALL' for all
@TablesToList nvarchar(max) = N'ALL'   -- N'ALL' for all
AS
BEGIN

-- Function:      Lists empty user tables
-- Parameters:    @SchemasToList nvarchar(max)  -> 'ALL' or comma-delimited list of schemas to list
--                @TablesToList nvarchar(max)   -> 'ALL' or comma-delimited list of tables to list
-- Action:        Lists the schema and table names for all empty tables
-- Return:        Rowset containing SchemaName, TableName in alphabetical order 
-- Refer to this video: https://youtu.be/31uOTcyljWY
--
-- Test examples: 
/*

EXEC SDU_Tools.ListEmptyUserTablesInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL';

*/
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);

    DECLARE @SQL nvarchar(max) = N'
SELECT s.[name] AS SchemaName,
       t.[name] AS TableName
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.[schema_id] = t.[schema_id] 
INNER JOIN sys.indexes AS i 
    ON t.[object_id] = i.[object_id]
INNER JOIN sys.partitions AS p 
    ON i.[object_id] = p.[object_id] AND i.index_id = p.index_id
INNER JOIN sys.allocation_units AS au 
    ON au.container_id = p.partition_id
WHERE t.is_ms_shipped = 0
AND t.[name] NOT LIKE ''dt%'' 
AND t.[name] <> ''sysdiagrams''' + @CRLF
    + CASE WHEN @SchemasToList = N'ALL' 
           THEN N''
           ELSE N'    AND s.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @SchemasToList + ''', N'','', 1))' + @CRLF
      END 
    + CASE WHEN @TablesToList = N'ALL' 
           THEN N''
           ELSE N'    AND t.[name] IN (SELECT StringValue COLLATE DATABASE_DEFAULT FROM SDU_Tools.SplitDelimitedString('''
                + @TablesToList + ''', N'','', 1))' + @CRLF
      END
    + N'GROUP BY s.[name], t.[name], p.rows' + @CRLF
    + N'HAVING p.rows = 0' + @CRLF 
    + N'ORDER BY SchemaName, TableName;';
    EXEC (@SQL);
END;
GO

------------------------------------------------------------------------------------
--CREATE PROCEDURE SDU_Tools.ExecuteCommandInEachDB (Not appropriate for Azure SQL DB)
------------------------------------------------------------------------------------
--CREATE PROCEDURE SDU_Tools.CreateSQLLoginWithSIDFromDB (Not appropriate for Azure SQL DB)
------------------------------------------------------------------------------------
GO

CREATE FUNCTION SDU_Tools.SingleSpaceWords
( 
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Returns a string with all words single-spaced
-- Parameters:    @InputString nvarchar(max)
-- Action:        Removes any whitespace characters and returns words single-spaced
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/h5SGwS-uHzI
--
-- Test examples: 
/*

SELECT '-->' + SDU_Tools.SingleSpaceWords('Test String') + '<--';
SELECT '-->' + SDU_Tools.SingleSpaceWords('  Test String     ') + '<--';
SELECT '-->' + SDU_Tools.SingleSpaceWords('  Test     String     Ending') + '<--';

*/

    DECLARE @WhitespaceCharacterPattern nvarchar(27) 
      = N'['
      + NCHAR(9) + NCHAR(10) + NCHAR(11) + NCHAR(12) + NCHAR(13) 
      + NCHAR(32) + NCHAR(133) + NCHAR(160) + NCHAR(5760) + NCHAR(8192) 
      + NCHAR(8193) + NCHAR(8194) + NCHAR(8195) + NCHAR(8196) 
      + NCHAR(8197) + NCHAR(8198) + NCHAR(8199) + NCHAR(8200) 
      + NCHAR(8201) + NCHAR(8202) + NCHAR(8232) + NCHAR(8233) 
      + NCHAR(8239) + NCHAR(8287) + NCHAR(12288)
      + N']';

    DECLARE @OutputString nvarchar(max) = '';
    DECLARE @CharacterCounter int = 1;
    DECLARE @IsInAWord bit = 0;
    DECLARE @IsWhitespace bit = 0;
    DECLARE @Character nchar(1);

    WHILE @CharacterCounter <= LEN(@InputString)
    BEGIN
        SET @Character = SUBSTRING(@InputString, @CharacterCounter, 1);
        SET @IsWhitespace = CASE WHEN @Character LIKE @WhitespaceCharacterPattern THEN 1 ELSE 0 END;
        IF @IsInAWord = 0
        BEGIN
            IF @IsWhitespace = 0 
            BEGIN -- start of a new word
                SET @OutputString = @OutputString + @Character;
                SET @IsInAWord = 1;
            END;
        END ELSE BEGIN
            IF @IsWhitespace = 0
            BEGIN -- still in a word
                SET @OutputString = @OutputString + @Character;
            END ELSE BEGIN -- end of a word
                SET @OutputString = @OutputString + N' ';
                SET @IsInAWord = 0;
            END;
        END;
        SET @CharacterCounter = @CharacterCounter + 1;
    END;
    RETURN RTRIM(@OutputString);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.IsIPv4Address
( 
    @InputString varchar(max)
)
RETURNS bit
AS
BEGIN

-- Function:      Determines if an input string is a valid IP v2 address
-- Parameters:    @InputString varchar(max)
-- Action:        Determines if an input string is a valid IP v2 address
-- Return:        bit with 0 for no, and 1 for yes
-- Refer to this video: https://youtu.be/lTyVkgjL7wo
--
-- Test examples: 
/*

SELECT SDU_Tools.IsIPv4Address('alsk.sdfsf..s.dfsdf.s.df');
SELECT SDU_Tools.IsIPv4Address('192.168.170.1');
SELECT SDU_Tools.IsIPv4Address('292.168.170.1050');
SELECT SDU_Tools.IsIPv4Address('a.b.c.d');

*/

    DECLARE @Period1Location int = CHARINDEX('.', @InputString, 1);
    DECLARE @Period2Location int = CHARINDEX('.', @InputString, @Period1Location + 1);
    DECLARE @Period3Location int = CHARINDEX('.', @InputString, @Period2Location + 1);
    DECLARE @FirstOctetString varchar(3);
    DECLARE @SecondOctetString varchar(3);
    DECLARE @ThirdOctetString varchar(3);
    DECLARE @FourthOctetString varchar(3);
    DECLARE @FirstOctetValue int;
    DECLARE @SecondOctetValue int;
    DECLARE @ThirdOctetValue int;
    DECLARE @FourthOctetValue int;
    DECLARE @ReturnValue bit = 0;

    IF @Period1Location > 0 AND @Period2Location > @Period1Location AND @Period3Location > @Period2Location 
    BEGIN
        SET @FirstOctetString = SUBSTRING(@InputString, 1, @Period1Location - 1);
        SET @SecondOctetString = SUBSTRING(@InputString, @Period1Location + 1, @Period2Location - @Period1Location - 1);
        SET @ThirdOctetString = SUBSTRING(@InputString, @Period2Location + 1, @Period3Location - @Period2Location - 1);
        SET @FourthOctetString = SUBSTRING(@InputString, @Period3Location + 1, LEN(@InputString));

        IF ISNUMERIC(@FirstOctetString) <> 0 AND ISNUMERIC(@SecondOctetString) <> 0
            AND ISNUMERIC(@ThirdOctetString) <> 0 AND ISNUMERIC(@FourthOctetString) <> 0
        BEGIN
            SET @FirstOctetValue = CONVERT(int, @FirstOctetString);
            SET @SecondOctetValue = CONVERT(int, @SecondOctetString);
            SET @ThirdOctetValue = CONVERT(int, @ThirdOctetString);
            SET @FourthOctetValue = CONVERT(int, @FourthOctetString); 

            IF @FirstOctetValue BETWEEN 0 AND 255
                AND @SecondOctetValue BETWEEN 0 AND 255
                AND @ThirdOctetValue BETWEEN 0 AND 255
                AND @FourthOctetValue BETWEEN 0 AND 255
            BEGIN
                SET @ReturnValue = 1;
            END;
        END;
    END;
    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.ROT13
( 
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Performs ROT-13 encoding or decoding of a string
-- Parameters:    @InputString nvarchar(max)
-- Action:        Performs ROT-13 encoding or decoding of a string
-- Return:        nvarchar(max) - ROT-13 encoded/decoded string
-- Refer to this video: https://youtu.be/xZt__QIPEzA
--
-- Test examples: 
/*

SELECT SDU_Tools.ROT13('This is a fairly standard sentence');
SELECT SDU_Tools.ROT13(N'NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm');
SELECT SDU_Tools.ROT13('This is a test string with 14 values');
SELECT SDU_Tools.ROT13('Guvf vf n snveyl fgnaqneq fragrapr');

*/

    DECLARE @OutputString nvarchar(max) = N'';
    DECLARE @Counter int = 1;
    DECLARE @Character nchar(1);
    DECLARE @CharacterCategory int = 0;

    WHILE @Counter <= LEN(@InputString)
    BEGIN
        SET @Character = SUBSTRING(@InputString, @Counter, 1);
        SET @OutputString = @OutputString
                          + CASE WHEN ASCII(@Character) BETWEEN ASCII(N'A') AND ASCII(N'M') 
                                 THEN NCHAR(ASCII(@Character) + 13)
                                      WHEN ASCII(@Character) BETWEEN ASCII(N'a') AND ASCII(N'm') 
                                      THEN NCHAR(ASCII(@Character) + 13)
                                      WHEN ASCII(@Character) BETWEEN ASCII(N'N') AND ASCII(N'Z') 
                                      THEN NCHAR(ASCII(@Character) - 13)
                                      WHEN ASCII(@Character) BETWEEN ASCII(N'n') AND ASCII(N'z') 
                                      THEN NCHAR(ASCII(@Character) - 13)
                                 ELSE @Character 
                            END;    
        SET @Counter = @Counter + 1;
    END;

     RETURN @OutputString;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DaysInMonth
( 
    @Date date
)
RETURNS int
AS
BEGIN

-- Function:      Returns the total number of days in the month for a given date
-- Parameters:    @Date date
-- Action:        Returns the total number of days in the month for a given date
-- Return:        int - Number of days
-- Refer to this video: https://youtu.be/BWl2jdNzjJU
--
-- Test examples: 
/*

SELECT SDU_Tools.DaysInMonth(SYSDATETIME());
SELECT SDU_Tools.DaysInMonth('20190204');
SELECT SDU_Tools.DaysInMonth('20160204');

*/
 
  RETURN DATEDIFF(day, 
                  CAST(RIGHT('0000' + CAST(YEAR(@Date) AS varchar(4)), 4)
                       + RIGHT('00' + CAST (MONTH(@Date) AS varchar(2)), 2)
                       + '01' AS date),
                  DATEADD(month, 1, CAST(RIGHT('0000' + CAST(YEAR(@Date) AS varchar(4)), 4)
                                         + RIGHT('00' + CAST (MONTH(@Date) AS varchar(2)), 2)
                                         + '01' AS date)));
END;
GO
 
------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.StringLength
(
    @InputString nvarchar(max)
)
RETURNS int
AS
BEGIN

-- Function:      Returns the length of a string
-- Parameters:    @InputString nvarchar(max) - the string whose length to determine
-- Action:        Determines the length of a string 
--                Unlike LEN(), does not ignore trailing blanks
-- Return:        int
-- Refer to this video: https://youtu.be/ztzQ7SLQWlE
--
-- Test examples: 
/*

SELECT LEN('Hello  '), LEN('Hello');
SELECT SDU_Tools.StringLength('Hello   ');

*/
    RETURN LEN(@InputString + N'.') - 1;
END;
GO
 
------------------------------------------------------------------------------------
-- CREATE PROCEDURE SDU_Tools.CheckInstantFileInitializationState (Not appropriate for Azure SQL DB)
------------------------------------------------------------------------------------
GO

CREATE FUNCTION SDU_Tools.SQLServerVersion()
RETURNS nvarchar(20)
AS
BEGIN
/* 

-- Function:      SQLServerVersion
-- Parameters:    Nil
-- Action:        Returns the version of SQL Server (e.g. 2012, 2014, 2008R2)
-- Return:        SQL Server version as nvarchar(20)
-- Refer to this video: https://youtu.be/_5DzK4ywxOU
--
-- Test examples: 

SELECT SDU_Tools.SQLServerVersion();

*/

    DECLARE @TrimmedVersion varchar(20) = LTRIM(RTRIM(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(20))));
    DECLARE @IsValidLooking bit = CASE WHEN LEN(REPLACE(@TrimmedVersion, '.', '')) = (LEN(@TrimmedVersion) - 3) 
                                       THEN CAST(1 AS bit)
                                       ELSE CAST(0 AS bit)
                                  END;
    DECLARE @FirstPeriod int;
    DECLARE @SecondPeriod int;
    DECLARE @MajorVersionString varchar(20);
    DECLARE @MinorVersionString varchar(20);
    DECLARE @MajorVersion int;
    DECLARE @MinorVersion int;

    DECLARE @SQLServerVersion nvarchar(20) = N'Unknown';

    IF @IsValidLooking <> 0
    BEGIN
        SET @FirstPeriod = CHARINDEX('.', @TrimmedVersion, 1);
        SET @SecondPeriod = CHARINDEX('.', @TrimmedVersion, @FirstPeriod + 1);
        SET @MajorVersionString = SUBSTRING(@TrimmedVersion, 1, @FirstPeriod - 1);
        SET @MinorVersionString = SUBSTRING(@TrimmedVersion, @FirstPeriod + 1, @SecondPeriod - @FirstPeriod - 1);

        SET @MajorVersion = CASE WHEN ISNUMERIC(@MajorVersionString) = 1
                                 THEN CAST(@MajorVersionString AS int) 
                            END;
        SET @MinorVersion = CASE WHEN ISNUMERIC(@MinorVersionString) = 1
                                 THEN CAST(@MinorVersionString AS int) 
                            END;

        SET @SQLServerVersion = CASE WHEN @MajorVersion = 10 AND @MinorVersion = 50 THEN N'2008R2'
                                     WHEN @MajorVersion = 10 THEN N'2008'
                                     WHEN @MajorVersion = 11 THEN N'2012'
                                     WHEN @MajorVersion = 12 THEN N'2014'
                                     WHEN @MajorVersion = 13 THEN N'2016'
                                     WHEN @MajorVersion = 14 THEN N'2017'
                                     WHEN @MajorVersion = 15 THEN N'2019'
                                     ELSE N'Unknown'
                                END;
    END;

    RETURN @SQLServerVersion;
END;
GO

------------------------------------------------------------------------------------
-- CREATE FUNCTION SDU_Tools.ScriptUserDefinedServerRoles() (Not appropriate for Azure SQL DB)
------------------------------------------------------------------------------------
-- CREATE FUNCTION SDU_Tools.ScriptUserDefinedServerRolePermissions() (Not appropriate for Azure SQL DB)
------------------------------------------------------------------------------------
GO

CREATE PROCEDURE SDU_Tools.ScriptUserDefinedDatabaseRolesInCurrentDatabase
(
    @ScriptOutput nvarchar(max) OUTPUT
)
AS
BEGIN

-- Function:      Scripts all user-defined database roles
-- Parameters:    Nil
-- Action:        Scripts all user-defined database roles, including disabled state where applicable
-- Return:        Single column called ScriptOutput nvarchar(max)
-- Refer to this video: https://youtu.be/EHMbDKFOS-E
--
-- Test examples: 
/*

CREATE ROLE ProcedureWriters;
GO

GRANT CREATE PROCEDURE TO ProcedureWriters;
GRANT VIEW DEFINITION TO ProcedureWriters;
GO

SET NOCOUNT ON;
DECLARE @SQL nvarchar(max);

EXEC SDU_Tools.ScriptUserDefinedDatabaseRolesInCurrentDatabase @SQL OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @SQL;
GO

DROP ROLE ProcedureWriters;
GO

*/
    DECLARE @Roles TABLE
    (
        RoleID int IDENTITY(1,1) PRIMARY KEY,
        RoleName sysname,
        OwnerName sysname
    );

    DECLARE @SQLCommand nvarchar(max) = 
    N'SELECT p.[name], op.[name]
    FROM sys.database_principals AS p
    INNER JOIN sys.database_principals AS op
    ON op.principal_id = p.owning_principal_id
    WHERE p.type_desc = N''DATABASE_ROLE'' COLLATE DATABASE_DEFAULT
    AND p.is_fixed_role = 0
    AND p.[name] <> N''public'' COLLATE DATABASE_DEFAULT
    ORDER BY p.[name];';

    INSERT @Roles (RoleName, OwnerName)
    EXEC (@SQLCommand);

    DECLARE @Counter int = 1;
    DECLARE @SQL nvarchar(max) = N'';
    DECLARE @CRLF nvarchar(2) = NCHAR(13) + NCHAR(10);
    DECLARE @RoleName sysname;
    DECLARE @OwnerName sysname;

    WHILE @Counter <= (SELECT MAX(RoleID) FROM @Roles)
    BEGIN
        SELECT @RoleName = r.RoleName,
               @OwnerName = r.OwnerName
        FROM @Roles AS r 
        WHERE r.RoleID = @Counter;

        SET @SQL += N'CREATE ROLE ' + QUOTENAME(@RoleName) + N' AUTHORIZATION ' + QUOTENAME(@OwnerName)
                  + N';' 
                  + @CRLF;
        SET @Counter += 1;
    END;

    SET @ScriptOutput = @SQL;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ScriptUserDefinedDatabaseRolePermissionsInCurrentDatabase
(
    @ScriptOutput nvarchar(max) OUTPUT
)
AS
BEGIN

-- Function:      Scripts all permissions for user-defined database roles
-- Parameters:    Nil
-- Action:        Scripts all permissions for user-defined database roles
-- Return:        Single column called ScriptOutput nvarchar(max)
-- Refer to this video: https://youtu.be/EHMbDKFOS-E
--
-- Test examples: 
/*

CREATE ROLE ProcedureWriters;
GO

GRANT CREATE PROCEDURE TO ProcedureWriters;
GRANT VIEW DEFINITION TO ProcedureWriters;
GO

SET NOCOUNT ON;
DECLARE @SQL nvarchar(max);

EXEC SDU_Tools.ScriptUserDefinedDatabaseRolePermissionsInCurrentDatabase @SQL OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @SQL;
GO

DROP ROLE ProcedureWriters;
GO

*/
    DECLARE @RolePermissions TABLE
    (
        RolePermissionID int IDENTITY(1,1) PRIMARY KEY,
        RoleName sysname,
        PermissionName sysname
    );

    DECLARE @SQLCommand nvarchar(max) = 
    N'SELECT r.[name], p.[permission_name]
    FROM sys.database_principals AS r
    INNER JOIN sys.database_permissions AS p
        ON r.principal_id = p.grantee_principal_id
    AND r.type_desc = N''DATABASE_ROLE'' COLLATE DATABASE_DEFAULT
    AND r.is_fixed_role = 0
    AND r.[name] <> N''public'' COLLATE DATABASE_DEFAULT 
    ORDER BY p.permission_name, r.[name];';

    INSERT @RolePermissions (RoleName, PermissionName)
    EXEC (@SQLCommand);
    
    DECLARE @Counter int = 1;
    DECLARE @SQL nvarchar(max) = N'';
    DECLARE @CRLF nvarchar(2) = NCHAR(13) + NCHAR(10);
    DECLARE @RoleName sysname;
    DECLARE @PermissionName sysname;

    WHILE @Counter <= (SELECT MAX(RolePermissionID) FROM @RolePermissions)
    BEGIN
        SELECT @RoleName = rp.RoleName,
               @PermissionName = rp.PermissionName 
        FROM @RolePermissions AS rp 
        WHERE rp.RolePermissionID = @Counter;

        SET @SQL += N'GRANT ' + @PermissionName
                  + N' TO ' + QUOTENAME(@RoleName)
                  + N';' 
                  + @CRLF;

        SET @Counter += 1;
    END;

    SET @ScriptOutput = @SQL;
END;
GO

--------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.TimePeriodsBetween
(
    @StartTime time(0),
    @EndTime time(0),
    @MinutesPerPeriod int 
)
RETURNS @TimePeriods TABLE
(
    TimePeriodKey int PRIMARY KEY,
    TimeValue time
)
AS
-- Function:      Returns a table of time periods (start of each time period)
-- Parameters:    @StartTime time => first time to return
--                @EndTime => last time that can be returned
--                @MinutesPerPeriod => number of minutes in each time period for the day
-- Action:        Returns a table of times starting at the first time provided, increasing
--                by the number of minutes per period, and ending at or before the last time
--                Calculations are done to the seconds level, starting at midnight
-- Return:        Rowset with TimePeriodKey as int and TimeValue as a time
-- Refer to this video: https://youtu.be/YAHLiGHjtfw
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.TimePeriodsBetween('00:00:00', '23:59:59', 15);
SELECT * FROM SDU_Tools.TimePeriodsBetween('01:00:00', '22:00:00', 15);

*/
BEGIN
    DECLARE @CurrentTimePeriodKey int = 1;
    DECLARE @NumberOfTimePeriods int = 24 * 60 / @MinutesPerPeriod;
    DECLARE @CurrentTime time(0);

    WHILE (@CurrentTimePeriodKey <= @NumberOfTimePeriods)
    BEGIN
        SET @CurrentTime = DATEADD(minute, (@CurrentTimePeriodKey - 1) * @MinutesPerPeriod, '00:00:00');    
        IF @CurrentTime BETWEEN @StartTime AND @EndTime 
        BEGIN
            INSERT @TimePeriods (TimePeriodKey, TimeValue) VALUES (@CurrentTimePeriodKey, @CurrentTime);
        END;
        SET @CurrentTimePeriodKey = @CurrentTimePeriodKey + 1;
    END;

    RETURN;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.EmptySchemaInCurrentDatabase
@SchemaName sysname
AS
BEGIN

-- Note: adapted from standard EmptySchema tool to work only in the current database
--       which makes it useful in Azure SQL DB where you can't use USE

-- Function:      Removes objects in the specified schema in the specified database
-- Parameters:    @SchemaName -> schema to empty (cannot be dbo, sys, or SDU_Tools)
-- Action:        Removes objects in the specified schema in the current database
-- Return:        Nil
-- Refer to this video: Refer to this video: https://youtu.be/A0y2Ltemz3g
--
-- Test examples: 
/*

CREATE SCHEMA XYZABC AUTHORIZATION dbo;
GO

CREATE TABLE XYZABC.TABLE1 (ID int);
GO

EXEC SDU_Tools.EmptySchemaInCurrentDatabase @SchemaName = N'XYZABC';
GO

DROP SCHEMA XYZABC;
GO

*/


    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IsVersionWithExternalTables bit 
      = CASE WHEN CAST(REPLACE(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS varchar(20)), 1, 2), '.', '') AS int) >= 13
             THEN 1
             ELSE 0
        END;
    
    DECLARE @SQL nvarchar(max) = 
N'  DECLARE @SchemaName sysname = N''' + @SchemaName + N''';
    DECLARE @SQL nvarchar(max);
    DECLARE @ReturnValue int = 0;
    DECLARE @SchemaID int = SCHEMA_ID(@SchemaName);
    
    IF @SchemaID IS NULL OR @SchemaName IN (N''sys'', N''dbo'', N''SDU_Tools'')
    BEGIN
        RAISERROR (''Selected schema is not present in the current database'', 16, 1);
        SET @ReturnValue = -1;
    END
    ELSE 
    BEGIN -- drop all existing objects in the schema
        DECLARE @ObjectCounter as int = 1;
        DECLARE @ObjectName sysname;
        DECLARE @TableName sysname;
        DECLARE @ObjectTypeCode varchar(10);
        DECLARE @IsExternalTable bit;

        DECLARE @ObjectsToRemove TABLE
        ( 
            ObjectRemovalOrder int IDENTITY(1,1) NOT NULL,
            ObjectTypeCode varchar(10) NOT NULL,
            ObjectName sysname NOT NULL,
            TableName sysname NULL,
            IsExternalTable bit 
        );
        
        INSERT @ObjectsToRemove (ObjectTypeCode, ObjectName, TableName, IsExternalTable)
        SELECT o.[type], COALESCE(tt.[name], o.[name]), t.[name]'
        + CASE WHEN @IsVersionWithExternalTables <> 0 
               THEN N', COALESCE(tab.is_external, 0) '
               ELSE N', 0 '
          END + N'
        FROM sys.objects AS o 
        LEFT OUTER JOIN sys.objects AS t
            ON o.parent_object_id = t.[object_id]
        LEFT OUTER JOIN sys.table_types AS tt
            ON tt.type_table_object_id = o.object_id
        LEFT OUTER JOIN sys.tables AS tab
            ON tab.object_id = o.object_id
        WHERE COALESCE(tt.[schema_id], o.[schema_id]) = @SchemaID
        AND NOT (o.[type] IN (''PK'', ''UQ'', ''C'', ''F'') AND t.[type] <> ''U'')
        ORDER BY CASE o.[type] WHEN ''V'' THEN 1    -- view
                               WHEN ''P'' THEN 2    -- stored procedure
                               WHEN ''PC'' THEN 3   -- clr stored procedure
                               WHEN ''FN'' THEN 4   -- scalar function
                               WHEN ''FS'' THEN 5   -- clr scalar function
                               WHEN ''AF'' THEN 6   -- clr aggregate
                               WHEN ''FT'' THEN 7   -- clr table-valued function
                               WHEN ''TF'' THEN 8   -- table-valued function
                               WHEN ''IF'' THEN 9   -- inline table-valued function
                               WHEN ''TR'' THEN 10  -- trigger
                               WHEN ''TA'' THEN 11  -- clr trigger
                               WHEN ''D'' THEN 12   -- default
                               WHEN ''F'' THEN 13   -- foreign key constraint
                               WHEN ''C'' THEN 14   -- check constraint
                               WHEN ''UQ'' THEN 15  -- unique constraint
                               WHEN ''PK'' THEN 16  -- primary key constraint
                               WHEN ''U'' THEN 17   -- table
                               WHEN ''TT'' THEN 18  -- table type
                               WHEN ''SO'' THEN 19  -- sequence
                               WHEN ''SN'' THEN 20  -- synonym
                 END;

        WHILE @ObjectCounter <= (SELECT MAX(ObjectRemovalOrder) FROM @ObjectsToRemove)
        BEGIN
            SELECT @ObjectTypeCode = otr.ObjectTypeCode,
                   @ObjectName = otr.ObjectName,
                   @TableName = otr.TableName,
                   @IsExternalTable = otr.IsExternalTable
            FROM @ObjectsToRemove AS otr 
            WHERE otr.ObjectRemovalOrder = @ObjectCounter;
    
            SET @SQL = CASE WHEN @ObjectTypeCode = ''V'' 
                            THEN N''DROP VIEW '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@ObjectName) + N'';''
                            WHEN @ObjectTypeCode IN (''P'' , ''PC'')
                            THEN N''DROP PROCEDURE '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@ObjectName) + N'';''
                            WHEN @ObjectTypeCode IN (''FN'', ''FS'', ''FT'', ''TF'', ''IF'')
                            THEN N''DROP FUNCTION '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@ObjectName) + N'';''
                            WHEN @ObjectTypeCode IN (''TR'', ''TA'')
                            THEN N''DROP TRIGGER '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@ObjectName) + N'';''
                            WHEN @ObjectTypeCode IN (''C'', ''D'', ''F'', ''PK'', ''UQ'')
                            THEN N''ALTER TABLE '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@TableName) 
                                 + N'' DROP CONSTRAINT '' + QUOTENAME(@ObjectName) + N'';''
                            WHEN @ObjectTypeCode = ''U'' AND @IsExternalTable = 0
                            THEN N''DROP TABLE '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@ObjectName) + N'';''
                            WHEN @ObjectTypeCode = ''U'' AND @IsExternalTable <> 0
                            THEN N''DROP EXTERNAL TABLE '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@ObjectName) + N'';''
                            WHEN @ObjectTypeCode = ''AF''
                            THEN N''DROP AGGREGATE '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@ObjectName) + N'';''
                            WHEN @ObjectTypeCode = ''TT''
                            THEN N''DROP TYPE '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@ObjectName) + N'';''
                            WHEN @ObjectTypeCode = ''SO''
                            THEN N''DROP SEQUENCE '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@ObjectName) + N'';''
                            WHEN @ObjectTypeCode = ''SN''
                            THEN N''DROP SYNONYM '' + QUOTENAME(@SchemaName) + N''.'' + QUOTENAME(@ObjectName) + N'';''
                       END;
    
                IF @SQL IS NOT NULL
                BEGIN
                    EXECUTE(@SQL);
                END;
    
            SET @ObjectCounter += 1;
        END;
    END;';
    EXECUTE (@SQL);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.NullIfBlank
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Returns NULL if the string contains no characters, else trims the string
-- Parameters:    @InputString nvarchar(max) - the string to process
-- Action:        Returns a NULL string if the string contains no characters, else trims the string
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/u1fCB08407s
--
-- Test examples: 
/*

SELECT N'->' + SDU_Tools.NullIfBlank('xx ') + N'<-';
SELECT N'->' + SDU_Tools.NullIfBlank('  xx ') + N'<-';
SELECT N'->' + SDU_Tools.NullIfBlank('   ') + N'<-';

*/
    RETURN CASE WHEN LEN(LTRIM(RTRIM(@InputString))) > 0
                THEN LTRIM(RTRIM(@InputString))
            END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.NullIfZero
(
    @InputValue decimal(18,2)
)
RETURNS decimal(18,2)
AS
BEGIN

-- Function:      Returns NULL if the value is zero
-- Parameters:    @InputValue decimal(18,2) - the value to process
-- Action:        Returns a NULL decimal if the value is zero
-- Return:        decimal(18,2)
-- Refer to this video: https://youtu.be/u1fCB08407s
--
-- Test examples: 
/*

SELECT SDU_Tools.NullIfZero(18.2);
SELECT SDU_Tools.NullIfZero(5);
SELECT SDU_Tools.NullIfZero(0);

*/
    RETURN CASE WHEN @InputValue <> 0
                THEN @InputValue
            END;
END;
GO

--------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DatesInPeriod
(
    @StartDate date,
    @NumberOfIntervals int,
    @IntervalCode varchar(10)
)
RETURNS @Dates TABLE
(
    DateNumber int IDENTITY(1,1) PRIMARY KEY,
    DateValue date
)
AS
-- Function:      Returns a table of dates 
-- Parameters:    @StartDate date => first date to return
--                @NumberOfIntervals int => number of intervals to add to first date
--                @IntervalCode varchar(10) => code for the interval YEAR, QUARTER, MONTH, WEEK, DAY
-- Action:        Returns a table of dates 
-- Return:        Rowset with DateNumber as int and DateValue as a date
-- Refer to this video: https://youtu.be/D_abxiKmOHY
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 1, 'YEAR');
SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 3, 'QUARTER');
SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 1, 'MONTH');
SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 3, 'WEEK');
SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 1, 'DAY');
SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 3, 'INVALID');

*/
BEGIN
    DECLARE @CurrentValue date = @StartDate;
    DECLARE @EndDate date = CASE @IntervalCode 
                                 WHEN 'YEAR'
                                 THEN DATEADD(YEAR, @NumberOfIntervals, @StartDate)
                                 WHEN 'QUARTER'
                                 THEN DATEADD(QUARTER, @NumberOfIntervals, @StartDate)
                                 WHEN 'MONTH'
                                 THEN DATEADD(MONTH, @NumberOfIntervals, @StartDate)
                                 WHEN 'WEEK'
                                 THEN DATEADD(WEEK, @NumberOfIntervals, @StartDate)
                                 WHEN 'DAY'
                                 THEN DATEADD(DAY, @NumberOfIntervals, @StartDate)
                                 ELSE NULL
                            END;

    WHILE @CurrentValue < @EndDate 
    BEGIN
        INSERT @Dates (DateValue) VALUES (@CurrentValue);
        SET @CurrentValue = DATEADD(day, 1, @CurrentValue);
    END;

    RETURN;
END;
GO

------------------------------------------------------------------------------------
-- CREATE FUNCTION SDU_Tools.ServerMaximumDBCompatibilityLevel() (Not appropriate for Azure SQL DB)
------------------------------------------------------------------------------------
-- CREATE PROCEDURE SDU_Tools.SetDatabaseCompabilityForAllDatabasesToMaximum (Not appropriate for Azure SQL DB)
------------------------------------------------------------------------------------
GO

CREATE FUNCTION SDU_Tools.WeekdayOfMonth
(
     @Year int,
     @Month int,
     @WeekdayNumber int
)
RETURNS date
AS
BEGIN

-- Function:      Returns the nth weekday of the month
-- Parameters:    @Year int - the year
--                @Month int - the month
--                @WeekdayNumber int - positive counting from start of month
--                                   - negative counting back from end of month
-- Action:        Returns the nth weekday of the month
-- Return:        date
-- Refer to this video: https://youtu.be/VFNJLTiqBnY
--
-- Test examples: 
/*

SELECT SDU_Tools.WeekdayOfMonth(2020, 2, 1); -- first weekday of Feb 2020
SELECT SDU_Tools.WeekdayOfMonth(2020, 2, -1); -- last weekday of Feb 2020
SELECT SDU_Tools.WeekdayOfMonth(2020, 2, 7); -- seventh weekday of Feb 2020

*/
    DECLARE @Weekdays TABLE
    (
        WeekdayNumber int IDENTITY(1,1) PRIMARY KEY,
        [Date] date
    );

    DECLARE @DateCounter date = RIGHT('0000' + CAST(@Year AS varchar(4)), 4)
                              + RIGHT('00' + CAST(@Month AS varchar(2)), 2)
                              + '01';
    DECLARE @EndDate date = DATEADD(day, -1, DATEADD(month, 1, @DateCounter)); -- EOMONTH not supported on 2008

    WHILE @DateCounter <= @EndDate 
    BEGIN
        IF DATEPART(weekday, @DateCounter) NOT IN (DATEPART(weekday, '19000107'), DATEPART(weekday, '19000106'))
        BEGIN
            INSERT @Weekdays ([Date]) VALUES (@DateCounter);
        END;
        SET @DateCounter = DATEADD(day, 1, @DateCounter);
    END;
    RETURN CASE WHEN @WeekdayNumber < 0
                THEN (SELECT [Date] 
                      FROM @Weekdays 
                      WHERE WeekdayNumber = (SELECT MAX(WeekdayNumber) FROM @Weekdays) + 1 + @WeekdayNumber)
                WHEN @WeekdayNumber > 0
                THEN (SELECT [Date] 
                      FROM @Weekdays 
                      WHERE WeekdayNumber = (SELECT MIN(WeekdayNumber) FROM @Weekdays) - 1 + @WeekdayNumber)
           END;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DayNumberOfMonth
(
     @Year int,
     @Month int,
     @DayOfWeek int,
     @DayNumber int
)
RETURNS date
AS
BEGIN

-- Function:      Returns the nth nominated day of the month
-- Parameters:    @Year int - the year
--                @Month int - the month
--                @DayOfWeek int - Sunday = 1, Monday = 2, etc.
--                @DayNumber int - day number (i.e. 3 for 3rd Monday)
-- Action:        Returns the nth nominated day of the month
-- Return:        date
-- Refer to this video: https://youtu.be/BeVXs-J4soo
--
-- Test examples: 
/*

SELECT SDU_Tools.DayNumberOfMonth(2020, 2, 1, 1); -- first Sunday of Feb 2020
SELECT SDU_Tools.DayNumberOfMonth(2020, 2, 1, 2); -- second Sunday of Feb 2020
SELECT SDU_Tools.DayNumberOfMonth(2020, 2, 3, 2); -- second Tuesday of Feb 2020
SELECT SDU_Tools.DayNumberOfMonth(2020, 2, 4, 3); -- third Wednesday of Feb 2020

*/
    DECLARE @Days TABLE
    (
        DayNumber int IDENTITY(1,1) PRIMARY KEY,
        [Date] date
    );

    DECLARE @DateCounter date = RIGHT('0000' + CAST(@Year AS varchar(4)), 4)
                              + RIGHT('00' + CAST(@Month AS varchar(2)), 2)
                              + '01';
    DECLARE @EndDate date = DATEADD(day, -1, DATEADD(month, 1, @DateCounter)); -- EOMONTH not supported on 2008

    WHILE @DateCounter <= @EndDate 
    BEGIN
        IF (DATEDIFF(day, '19000107', @DateCounter) % 7 + 1) = @DayOfWeek 
        BEGIN
            INSERT @Days ([Date]) VALUES (@DateCounter);
        END;
        SET @DateCounter = DATEADD(day, 1, @DateCounter);
    END;
    RETURN (SELECT [Date] FROM @Days WHERE DayNumber = @DayNumber);
END;
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.Currencies
AS
-- Function:      Table of common world currencies
-- Parameters:    N/A
-- Action:        Table of common world currencies
-- Return:        Rowset 
-- Refer to this video: https://youtu.be/VuKJEtZ44WY
--
-- Test examples: 
/*

SELECT * 
FROM SDU_Tools.Currencies
ORDER BY CurrencyCode;

*/

SELECT CurrencyCode, CurrencyName, CurrencySymbol, MinorUnit, MinorUnitsToFullUnit
FROM (VALUES (N'AED', N'United Arab Emirates dirham', N'د.إ', N'Fils', 100),
             (N'AFN', N'Afghan afghani', N'؋', N'Pul', 100),
             (N'ALL', N'Albanian lek', N'L', N'Qindarkë', 100),
             (N'AMD', N'Armenian dram', N'֏', N'Luma', 100),
             (N'ANG', N'Netherlands Antillean guilder', N'ƒ', N'Cent', 100),
             (N'AOA', N'Angolan kwanza', N'Kz', N'Cêntimo', 100),
             (N'ARS', N'Argentine peso', N'$', N'Centavo', 100),
             (N'AUD', N'Australian dollar', N'$', N'Cent', 100),
             (N'AWG', N'Aruban florin', N'ƒ', N'Cent', 100),
             (N'AZN', N'Azerbaijani manat', N'₼', N'Qəpik', 100),
             (N'BAM', N'Bosnia and Herzegovina convertible mark', N'KM', N'Fening', 100),
             (N'BBD', N'Barbadian dollar', N'$', N'Cent', 100),
             (N'BDT', N'Bangladeshi taka', N'৳', N'Poisha', 100),
             (N'BGN', N'Bulgarian lev', N'лв.', N'Stotinka', 100),
             (N'BHD', N'Bahraini dinar', N'.د.ب', N'Fils', 1000),
             (N'BIF', N'Burundian franc', N'Fr', N'Centime', 100),
             (N'BMD', N'Bermudian dollar', N'$', N'Cent', 100),
             (N'BND', N'Brunei dollar', N'$', N'Sen', 100),
             (N'BOB', N'Bolivian boliviano', N'Bs.', N'Centavo', 100),
             (N'BRL', N'Brazilian real', N'R$', N'Centavo', 100),
             (N'BSD', N'Bahamian dollar', N'$', N'Cent', 100),
             (N'BTN', N'Bhutanese ngultrum', N'Nu.', N'Chetrum', 100),
             (N'BWP', N'Botswana pula', N'P', N'Thebe', 100),
             (N'BYN', N'Belarusian ruble', N'Br', N'Kapyeyka', 100),
             (N'BZD', N'Belize dollar', N'$', N'Cent', 100),
             (N'CAD', N'Canadian dollar', N'$', N'Cent', 100),
             (N'CDF', N'Congolese franc', N'Fr', N'Centime', 100),
             (N'CHF', N'Swiss franc', N'Fr.', N'Rappen', 100),
             (N'CKD', N'Cook Islands dollar', N'$', N'Cent', 100),
             (N'CLP', N'Chilean peso', N'$', N'Centavo', 100),
             (N'CNY', N'Chinese yuan', N'¥', N'Fen', 100),
             (N'COP', N'Colombian peso', N'$', N'Centavo', 100),
             (N'CRC', N'Costa Rican colón', N'₡', N'Céntimo', 100),
             (N'CUC', N'Cuban convertible peso', N'$', N'Centavo', 100),
             (N'CUP', N'Cuban peso', N'$', N'Centavo', 100),
             (N'CVE', N'Cape Verdean escudo', N'$', N'Centavo', 100),
             (N'CZK', N'Czech koruna', N'Kč', N'Haléř', 100),
             (N'DJF', N'Djiboutian franc', N'Fr', N'Centime', 100),
             (N'DKK', N'Danish krone', N'kr', N'Øre', 100),
             (N'DOP', N'Dominican peso', N'$', N'Centavo', 100),
             (N'DZD', N'Algerian dinar', N'د.ج', N'Santeem', 100),
             (N'EGP', N'Egyptian pound', N'ج.م', N'Piastre', 100),
             (N'ERN', N'Eritrean nakfa', N'Nfk', N'Cent', 100),
             (N'ETB', N'Ethiopian birr', N'Br', N'Santim', 100),
             (N'EUR', N'Euro', N'€', N'Cent', 100),
             (N'FJD', N'Fijian dollar', N'$', N'Cent', 100),
             (N'FKP', N'Falkland Islands pound', N'£', N'Penny', 100),
             (N'FOK', N'Faroese króna', N'kr', N'Oyra', 100),
             (N'GBP', N'British pound', N'£', N'Penny', 100),
             (N'GEL', N'Georgian lari', N'₾', N'Tetri', 100),
             (N'GGP', N'Guernsey pound', N'£', N'Penny', 100),
             (N'GHS', N'Ghanaian cedi', N'₵', N'Pesewa', 100),
             (N'GIP', N'Gibraltar pound', N'£', N'Penny', 100),
             (N'GMD', N'Gambian dalasi', N'D', N'Butut', 100),
             (N'GNF', N'Guinean franc', N'Fr', N'Centime', 100),
             (N'GTQ', N'Guatemalan quetzal', N'Q', N'Centavo', 100),
             (N'GYD', N'Guyanese dollar', N'$', N'Cent', 100),
             (N'HKD', N'Hong Kong dollar', N'$', N'Cent', 100),
             (N'HNL', N'Honduran lempira', N'L', N'Centavo', 100),
             (N'HRK', N'Croatian kuna', N'kn', N'Lipa', 100),
             (N'HTG', N'Haitian gourde', N'G', N'Centime', 100),
             (N'HUF', N'Hungarian forint', N'Ft', N'Fillér', 100),
             (N'IDR', N'Indonesian rupiah', N'Rp', N'Sen', 100),
             (N'ILS', N'Israeli new shekel', N'₪', N'Agora', 100),
             (N'IMP', N'Manx pound', N'£', N'Penny', 100),
             (N'INR', N'Indian rupee', N'₹', N'Paisa', 100),
             (N'IQD', N'Iraqi dinar', N'ع.د', N'Fils', 1000),
             (N'IRR', N'Iranian rial', N'﷼', N'Dinar', 100),
             (N'ISK', N'Icelandic króna', N'kr', N'Eyrir', 100),
             (N'JEP', N'Jersey pound', N'£', N'Penny', 100),
             (N'JMD', N'Jamaican dollar', N'$', N'Cent', 100),
             (N'JOD', N'Jordanian dinar', N'د.ا', N'Piastre', 100),
             (N'JPY', N'Japanese yen', N'¥', N'Sen', 100),
             (N'KES', N'Kenyan shilling', N'Sh', N'Cent', 100),
             (N'KGS', N'Kyrgyzstani som', N'с', N'Tyiyn', 100),
             (N'KHR', N'Cambodian riel', N'៛', N'Sen', 100),
             (N'KID', N'Kiribati dollar', N'$', N'Cent', 100),
             (N'KMF', N'Comorian franc', N'Fr', N'Centime', 100),
             (N'KPW', N'North Korean won', N'₩', N'Chon', 100),
             (N'KRW', N'South Korean won', N'₩', N'Jeon', 100),
             (N'KWD', N'Kuwaiti dinar', N'د.ك', N'Fils', 1000),
             (N'KYD', N'Cayman Islands dollar', N'$', N'Cent', 100),
             (N'KZT', N'Kazakhstani tenge', N'₸', N'Tıyn', 100),
             (N'LAK', N'Lao kip', N'₭', N'Att', 100),
             (N'LBP', N'Lebanese pound', N'ل.ل', N'Piastre', 100),
             (N'LKR', N'Sri Lankan rupee', N'ரூ', N'Cent', 100),
             (N'LRD', N'Liberian dollar', N'$', N'Cent', 100),
             (N'LSL', N'Lesotho loti', N'L', N'Sente', 100),
             (N'LYD', N'Libyan dinar', N'ل.د', N'Dirham', 1000),
             (N'MAD', N'Moroccan dirham', N'د.م.', N'Centime', 100),
             (N'MDL', N'Moldovan leu', N'L', N'Ban', 100),
             (N'MGA', N'Malagasy ariary', N'Ar', N'Iraimbilanja', 5),
             (N'MKD', N'Macedonian denar', N'ден', N'Deni', 100),
             (N'MMK', N'Burmese kyat', N'Ks', N'Pya', 100),
             (N'MNT', N'Mongolian tögrög', N'₮', N'Möngö', 100),
             (N'MOP', N'Macanese pataca', N'P', N'Avo', 100),
             (N'MRU', N'Mauritanian ouguiya', N'UM', N'Khoums', 5),
             (N'MUR', N'Mauritian rupee', N'₨', N'Cent', 100),
             (N'MVR', N'Maldivian rufiyaa', N'.ރ', N'Laari', 100),
             (N'MWK', N'Malawian kwacha', N'MK', N'Tambala', 100),
             (N'MXN', N'Mexican peso', N'$', N'Centavo', 100),
             (N'MYR', N'Malaysian ringgit', N'RM', N'Sen', 100),
             (N'MZN', N'Mozambican metical', N'MT', N'Centavo', 100),
             (N'NAD', N'Namibian dollar', N'$', N'Cent', 100),
             (N'NGN', N'Nigerian naira', N'₦', N'Kobo', 100),
             (N'NIO', N'Nicaraguan córdoba', N'C$', N'Centavo', 100),
             (N'NOK', N'Norwegian krone', N'kr', N'Øre', 100),
             (N'NPR', N'Nepalese rupee', N'रू', N'Paisa', 100),
             (N'NZD', N'New Zealand dollar', N'$', N'Cent', 100),
             (N'OMR', N'Omani rial', N'ر.ع.', N'Baisa', 1000),
             (N'PAB', N'Panamanian balboa', N'B/.', N'Centésimo', 100),
             (N'PEN', N'Peruvian sol', N'S/.', N'Céntimo', 100),
             (N'PGK', N'Papua New Guinean kina', N'K', N'Toea', 100),
             (N'PHP', N'Philippine peso', N'₱', N'Sentimo', 100),
             (N'PKR', N'Pakistani rupee', N'₨', N'Paisa', 100),
             (N'PLN', N'Polish złoty', N'zł', N'Grosz', 100),
             (N'PND', N'Pitcairn Islands dollar', N'$', N'Cent', 100),
             (N'PRB', N'Transnistrian ruble', N'р.', N'Kopek', 100),
             (N'PYG', N'Paraguayan guaraní', N'₲', N'Céntimo', 100),
             (N'QAR', N'Qatari riyal', N'ر.ق', N'Dirham', 100),
             (N'RON', N'Romanian leu', N'lei', N'Ban', 100),
             (N'RSD', N'Serbian dinar', N'дин', N'Para', 100),
             (N'RUB', N'Russian ruble', N'₽', N'Kopek', 100),
             (N'RWF', N'Rwandan franc', N'Fr', N'Centime', 100),
             (N'SAR', N'Saudi riyal', N'ر.س', N'Halala', 100),
             (N'SBD', N'Solomon Islands dollar', N'$', N'Cent', 100),
             (N'SCR', N'Seychellois rupee', N'₨', N'Cent', 100),
             (N'SDG', N'Sudanese pound', N'ج.س.', N'Piastre', 100),
             (N'SEK', N'Swedish krona', N'kr', N'Öre', 100),
             (N'SGD', N'Singapore dollar', N'$', N'Cent', 100),
             (N'SHP', N'Saint Helena pound', N'£', N'Penny', 100),
             (N'SLL', N'Sierra Leonean leone', N'Le', N'Cent', 100),
             (N'SLS', N'Somaliland shilling', N'Sl', N'Cent', 100),
             (N'SOS', N'Somali shilling', N'Sh', N'Cent', 100),
             (N'SRD', N'Surinamese dollar', N'$', N'Cent', 100),
             (N'SSP', N'South Sudanese pound', N'£', N'Piaster', 100),
             (N'STN', N'São Tomé and Príncipe dobra', N'Db', N'Cêntimo', 100),
             (N'SYP', N'Syrian pound', N'ل.س', N'Piastre', 100),
             (N'SZL', N'Swazi lilangeni', N'L', N'Cent', 100),
             (N'THB', N'Thai baht', N'฿', N'Satang', 100),
             (N'TJS', N'Tajikistani somoni', N'ЅМ', N'Diram', 100),
             (N'TMT', N'Turkmenistan manat', N'm', N'Tennesi', 100),
             (N'TND', N'Tunisian dinar', N'د.ت', N'Millime', 1000),
             (N'TOP', N'Tongan paʻanga', N'T$', N'Seniti', 100),
             (N'TRY', N'Turkish lira', N'₺', N'Kuruş', 100),
             (N'TTD', N'Trinidad and Tobago dollar', N'$', N'Cent', 100),
             (N'TVD', N'Tuvaluan dollar', N'$', N'Cent', 100),
             (N'TWD', N'New Taiwan dollar', N'$', N'Cent', 100),
             (N'TZS', N'Tanzanian shilling', N'Sh', N'Cent', 100),
             (N'UAH', N'Ukrainian hryvnia', N'₴', N'Kopiyka', 100),
             (N'UGX', N'Ugandan shilling', N'Sh', N'Cent', 100),
             (N'USD', N'United States dollar', N'$', N'Cent', 100),
             (N'UYU', N'Uruguayan peso', N'$', N'Centésimo', 100),
             (N'UZS', N'Uzbekistani soʻm', N'soʻm', N'Tiyin', 100),
             (N'VES', N'Venezuelan bolívar soberano', N'Bs', N'Céntimo', 100),
             (N'VND', N'Vietnamese đồng', N'₫', N'Hào',10),
             (N'VUV', N'Vanuatu vatu', N'Vt', NULL, NULL),
             (N'WST', N'Samoan tālā', N'T', N'Sene', 100),
             (N'XAF', N'Central African CFA franc', N'Fr', N'Centime', 100),
             (N'XCD', N'Eastern Caribbean dollar', N'$', N'Cent', 100),
             (N'XOF', N'West African CFA franc', N'Fr', N'Centime', 100),
             (N'XPF', N'CFP franc', N'₣', N'Centime', 100),
             (N'YER', N'Yemeni rial', N'﷼', N'Fils', 100),
             (N'ZAR', N'South African rand', N'R', N'Cent', 100),
             (N'ZMW', N'Zambian kwacha', N'ZK', N'Ngwee', 100)
        ) AS c(CurrencyCode, CurrencyName, CurrencySymbol, MinorUnit, MinorUnitsToFullUnit);
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.Countries
AS
-- Function:      Table of countries
-- Parameters:    N/A
-- Action:        Table of countries
-- Return:        Rowset 
-- Refer to this video: https://youtu.be/5HnBk323Lis
--
-- Test examples: 
/*

SELECT * 
FROM SDU_Tools.Countries
ORDER BY CountryCode;

*/

SELECT CountryCode, CountryNumber, CountryName, ContinentName
FROM (VALUES (N'AFG', 4, N'Afghanistan', N'Asia'),
             (N'ALB', 8, N'Albania', N'Europe'),
             (N'DZA', 12, N'Algeria', N'Africa'),
             (N'AND', 20, N'Andorra', N'Europe'),
             (N'AGO', 24, N'Angola', N'Africa'),
             (N'ATG', 28, N'Antigua and Barbuda', N'North America'),
             (N'ARG', 32, N'Argentina', N'South America'),
             (N'ARM', 51, N'Armenia', N'Asia'),
             (N'AUS', 36, N'Australia', N'Oceania'),
             (N'AUT', 40, N'Austria', N'Europe'),
             (N'AZE', 31, N'Azerbaijan', N'Asia'),
             (N'BHS', 44, N'Bahamas', N'North America'),
             (N'BHR', 48, N'Bahrain', N'Asia'),
             (N'BGD', 50, N'Bangladesh', N'Asia'),
             (N'BRB', 52, N'Barbados', N'North America'),
             (N'BLR', 112, N'Belarus', N'Europe'),
             (N'BEL', 56, N'Belgium', N'Europe'),
             (N'BLZ', 84, N'Belize', N'North America'),
             (N'BEN', 204, N'Benin', N'Africa'),
             (N'BTN', 64, N'Bhutan', N'Asia'),
             (N'BOL', 68, N'Bolivia', N'South America'),
             (N'BIH', 70, N'Bosnia and Herzegovina', N'Europe'),
             (N'BWA', 72, N'Botswana', N'Africa'),
             (N'BRA', 76, N'Brazil', N'South America'),
             (N'BRN', 96, N'Brunei', N'Asia'),
             (N'BGR', 100, N'Bulgaria', N'Europe'),
             (N'BFA', 854, N'Burkina Faso', N'Africa'),
             (N'BDI', 108, N'Burundi', N'Africa'),
             (N'KHM', 116, N'Cambodia', N'Asia'),
             (N'CMR', 120, N'Cameroon', N'Africa'),
             (N'CAN', 124, N'Canada', N'North America'),
             (N'CPV', 132, N'Cape Verde', N'Oceania'),
             (N'CAF', 140, N'Central African Republic', N'Africa'),
             (N'TCD', 148, N'Chad', N'Africa'),
             (N'CHL', 152, N'Chile', N'South America'),
             (N'CHN', 156, N'China', N'Asia'),
             (N'COL', 170, N'Colombia', N'South America'),
             (N'COM', 174, N'Comoros', N'Africa'),
             (N'COG', 178, N'Republic of the Congo', N'Africa'),
             (N'CRI', 188, N'Costa Rica', N'North America'),
             (N'CIV', 384, N'Côte d''Ivoire', N'Africa'),
             (N'HRV', 191, N'Croatia', N'Europe'),
             (N'CUB', 192, N'Cuba', N'North America'),
             (N'CYP', 196, N'Cyprus', N'Asia'),
             (N'CZE', 203, N'Czech Republic', N'Europe'),
             (N'COD', 180, N'Democratic Republic of the Congo', N'Africa'),
             (N'PRK', 408, N'Democratic People''s Republic of Korea', N'Asia'),
             (N'DNK', 208, N'Denmark', N'Europe'),
             (N'DJI', 262, N'Djibouti', N'Africa'),
             (N'DMA', 212, N'Dominica', N'North America'),
             (N'DOM', 214, N'Dominican Republic', N'North America'),
             (N'ECU', 218, N'Ecuador', N'South America'),
             (N'EGY', 818, N'Egypt', N'Africa'),
             (N'SLV', 222, N'El Salvador', N'North America'),
             (N'GNQ', 226, N'Equatorial Guinea', N'Africa'),
             (N'ERI', 232, N'Eritrea', N'Africa'),
             (N'EST', 233, N'Estonia', N'Europe'),
             (N'ETH', 231, N'Ethiopia', N'Africa'),
             (N'FJI', 242, N'Fiji', N'Oceania'),
             (N'FIN', 246, N'Finland', N'Europe'),
             (N'FRA', 250, N'France', N'Europe'),
             (N'GAB', 266, N'Gabon', N'Africa'),
             (N'GMB', 270, N'Gambia', N'Africa'),
             (N'GEO', 268, N'Georgia', N'Asia'),
             (N'DEU', 276, N'Germany', N'Europe'),
             (N'GHA', 288, N'Ghana', N'Africa'),
             (N'GRC', 300, N'Greece', N'Europe'),
             (N'GRD', 308, N'Grenada', N'North America'),
             (N'GTM', 320, N'Guatemala', N'North America'),
             (N'GIN', 324, N'Guinea', N'Africa'),
             (N'GNB', 624, N'Guinea-Bissau', N'Africa'),
             (N'GUY', 328, N'Guyana', N'South America'),
             (N'HTI', 332, N'Haiti', N'North America'),
             (N'HND', 340, N'Honduras', N'North America'),
             (N'HUN', 348, N'Hungary', N'Europe'),
             (N'ISL', 352, N'Iceland', N'Europe'),
             (N'IND', 356, N'India', N'Asia'),
             (N'IDN', 360, N'Indonesia', N'Asia'),
             (N'IRN', 364, N'Iran', N'Asia'),
             (N'IRQ', 368, N'Iraq', N'Asia'),
             (N'IRL', 372, N'Ireland', N'Europe'),
             (N'ISR', 376, N'Israel', N'Asia'),
             (N'ITA', 380, N'Italy', N'Europe'),
             (N'JAM', 388, N'Jamaica', N'North America'),
             (N'JPN', 392, N'Japan', N'Asia'),
             (N'JOR', 400, N'Jordan', N'Asia'),
             (N'KAZ', 398, N'Kazakhstan', N'Asia'),
             (N'KEN', 404, N'Kenya', N'Africa'),
             (N'KIR', 296, N'Kiribati', N'Oceania'),
             (N'KOR', 410, N'South Korea', N'Asia'),
             (N'KWT', 414, N'Kuwait', N'Asia'),
             (N'KGZ', 417, N'Kyrgyzstan', N'Asia'),
             (N'LAO', 418, N'Lao People''s Democratic Republic', N'Asia'),
             (N'LVA', 428, N'Latvia', N'Europe'),
             (N'LBN', 422, N'Lebanon', N'Asia'),
             (N'LSO', 426, N'Lesotho', N'Africa'),
             (N'LBR', 430, N'Liberia', N'Africa'),
             (N'LBY', 434, N'Libya', N'Africa'),
             (N'LIE', 438, N'Liechtenstein', N'Europe'),
             (N'LTU', 440, N'Lithuania', N'Europe'),
             (N'LUX', 442, N'Luxembourg', N'Europe'),
             (N'MKD', 807, N'Republic of North Macedonia', N'Europe'),
             (N'MDG', 450, N'Madagascar', N'Africa'),
             (N'MWI', 454, N'Malawi', N'Africa'),
             (N'MYS', 458, N'Malaysia', N'Asia'),
             (N'MDV', 462, N'Maldives', N'Seven seas (open ocean)'),
             (N'MLI', 466, N'Mali', N'Africa'),
             (N'MLT', 470, N'Malta', N'Europe'),
             (N'MHL', 584, N'Marshall Islands', N'Oceania'),
             (N'MRT', 478, N'Mauritania', N'Africa'),
             (N'MUS', 480, N'Mauritius', N'Africa'),
             (N'MEX', 484, N'Mexico', N'North America'),
             (N'FSM', 583, N'Micronesia', N'Oceania'),
             (N'MDA', 498, N'Moldova', N'Europe'),
             (N'MCO', 492, N'Monaco', N'Europe'),
             (N'MNG', 496, N'Mongolia', N'Asia'),
             (N'MNE', 499, N'Montenegro', N'Europe'),
             (N'MAR', 504, N'Morocco', N'Africa'),
             (N'MOZ', 508, N'Mozambique', N'Africa'),
             (N'MMR', 104, N'Myanmar', N'Asia'),
             (N'NAM', 516, N'Namibia', N'Africa'),
             (N'NRU', 520, N'Nauru', N'Oceania'),
             (N'NPL', 524, N'Nepal', N'Asia'),
             (N'NLD', 528, N'Netherlands', N'Europe'),
             (N'NZL', 554, N'New Zealand', N'Oceania'),
             (N'NIC', 558, N'Nicaragua', N'North America'),
             (N'NIU', 570, N'Niue', N'Oceania'),
             (N'NER', 562, N'Niger', N'Africa'),
             (N'NGA', 566, N'Nigeria', N'Africa'),
             (N'NOR', 578, N'Norway', N'Europe'),
             (N'OMN', 512, N'Oman', N'Asia'),
             (N'PAK', 586, N'Pakistan', N'Asia'),
             (N'PLW', 585, N'Palau', N'Oceania'),
             (N'PAN', 591, N'Panama', N'North America'),
             (N'PNG', 598, N'Papua New Guinea', N'Oceania'),
             (N'PRY', 600, N'Paraguay', N'South America'),
             (N'PER', 604, N'Peru', N'South America'),
             (N'PHL', 608, N'Philippines', N'Asia'),
             (N'POL', 616, N'Poland', N'Europe'),
             (N'PRT', 620, N'Portugal', N'Europe'),
             (N'QAT', 634, N'Qatar', N'Asia'),
             (N'ROU', 642, N'Romania', N'Europe'),
             (N'RUS', 643, N'Russia', N'Europe'),
             (N'RWA', 646, N'Rwanda', N'Africa'),
             (N'LCA', 662, N'Saint Lucia', N'North America'),
             (N'WSM', 882, N'Samoa', N'Oceania'),
             (N'SMR', 674, N'San Marino', N'Europe'),
             (N'STP', 678, N'São Tomé and Príncipe', N'Africa'),
             (N'SAU', 682, N'Saudi Arabia', N'Asia'),
             (N'SEN', 686, N'Senegal', N'Africa'),
             (N'SRB', 688, N'Serbia', N'Europe'),
             (N'SYC', 690, N'Seychelles', N'Africa'),
             (N'SLE', 694, N'Sierra Leone', N'Africa'),
             (N'SGP', 702, N'Singapore', N'Asia'),
             (N'SVK', 703, N'Slovakia', N'Europe'),
             (N'SVN', 705, N'Slovenia', N'Europe'),
             (N'SLB', 90, N'Solomon Is.', N'Oceania'),
             (N'SOM', 706, N'Somalia', N'Africa'),
             (N'ZAF', 710, N'South Africa', N'Africa'),
             (N'ESP', 724, N'Spain', N'Europe'),
             (N'LKA', 144, N'Sri Lanka', N'Asia'),
             (N'KNA', 659, N'Saint Kitts and Nevis', N'North America'),
             (N'VCT', 670, N'Saint Vincent and the Grenadines', N'North America'),
             (N'SDN', 729, N'Sudan', N'Africa'),
             (N'SSD', 728, N'South Sudan', N'Africa'),
             (N'SUR', 740, N'Suriname', N'South America'),
             (N'SWZ', 748, N'Eswatini', N'Africa'),
             (N'SWE', 752, N'Sweden', N'Europe'),
             (N'CHE', 756, N'Switzerland', N'Europe'),
             (N'SYR', 760, N'Syria', N'Asia'),
             (N'TWN', 158, N'Taiwan', N'Asia'),
             (N'TJK', 762, N'Tajikistan', N'Asia'),
             (N'TZA', 834, N'Tanzania', N'Africa'),
             (N'THA', 764, N'Thailand', N'Asia'),
             (N'TLS', 626, N'Timor-Leste', N'Asia'),
             (N'TGO', 768, N'Togo', N'Africa'),
             (N'TON', 776, N'Tonga', N'Oceania'),
             (N'TTO', 780, N'Trinidad and Tobago', N'North America'),
             (N'TUN', 788, N'Tunisia', N'Africa'),
             (N'TUR', 792, N'Turkey', N'Asia'),
             (N'TKM', 795, N'Turkmenistan', N'Asia'),
             (N'TUV', 798, N'Tuvalu', N'Oceania'),
             (N'UGA', 800, N'Uganda', N'Africa'),
             (N'UKR', 804, N'Ukraine', N'Europe'),
             (N'ARE', 784, N'United Arab Emirates', N'Asia'),
             (N'GBR', 826, N'United Kingdom', N'Europe'),
             (N'USA', 840, N'United States', N'North America'),
             (N'URY', 858, N'Uruguay', N'South America'),
             (N'UZB', 860, N'Uzbekistan', N'Asia'),
             (N'VUT', 548, N'Vanuatu', N'Oceania'),
             (N'VAT', 336, N'Vatican City', N'Europe'),
             (N'VEN', 862, N'Venezuela', N'South America'),
             (N'VNM', 704, N'Vietnam', N'Asia'),
             (N'YEM', 887, N'Yemen', N'Asia'),
             (N'ZMB', 894, N'Zambia', N'Africa'),
             (N'ZWE', 716, N'Zimbabwe', N'Africa')) 
             AS c(CountryCode, CountryNumber, CountryName, ContinentName);
GO

------------------------------------------------------------------------------------

CREATE VIEW SDU_Tools.CurrenciesByCountry
AS
-- Function:      Table of countries and the currencies they use
-- Parameters:    N/A
-- Action:        Table of countries and the currencies they use
--                Note that some countries have multiple currencies
--                and will return multiple rows
-- Return:        Rowset 
-- Refer to this video: https://youtu.be/VuKJEtZ44WY
--
-- Test examples: 
/*

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

*/

    SELECT CountryCode, CurrencyCode 
    FROM (VALUES (N'AFN', N'AFG'),
                 (N'ALL', N'ALB'),
                 (N'DZD', N'DZA'),
                 (N'EUR', N'AND'),
                 (N'AOA', N'AGO'),
                 (N'XCD', N'ATG'),
                 (N'ARS', N'ARG'),
                 (N'AMD', N'ARM'),
                 (N'AUD', N'AUS'),
                 (N'EUR', N'AUT'),
                 (N'AZN', N'AZE'),
                 (N'BSD', N'BHS'),
                 (N'BHD', N'BHR'),
                 (N'BDT', N'BGD'),
                 (N'BBD', N'BRB'),
                 (N'BYN', N'BLR'),
                 (N'EUR', N'BEL'),
                 (N'BZD', N'BLZ'),
                 (N'XOF', N'BEN'),
                 (N'BTN', N'BTN'),
                 (N'INR', N'BTN'),
                 (N'BOB', N'BOL'),
                 (N'BAM', N'BIH'),
                 (N'BWP', N'BWA'),
                 (N'BRL', N'BRA'),
                 (N'BND', N'BRN'),
                 (N'SGD', N'BRN'),
                 (N'BGN', N'BGR'),
                 (N'XOF', N'BFA'),
                 (N'BIF', N'BDI'),
                 (N'KHR', N'KHM'),
                 (N'XAF', N'CMR'),
                 (N'CAD', N'CAN'),
                 (N'CVE', N'CPV'),
                 (N'XAF', N'CAF'),
                 (N'XAF', N'TCD'),
                 (N'CLP', N'CHL'),
                 (N'CNY', N'CHN'),
                 (N'COP', N'COL'),
                 (N'KMF', N'COM'),
                 (N'CDF', N'COD'),
                 (N'XAF', N'COG'),
                 (N'CRC', N'CRI'),
                 (N'XOF', N'CIV'),
                 (N'HRK', N'HRV'),
                 (N'CUP', N'CUB'),
                 (N'CUC', N'CUB'),
                 (N'EUR', N'CYP'),
                 (N'CZK', N'CZE'),
                 (N'DKK', N'DNK'),
                 (N'DJF', N'DJI'),
                 (N'XCD', N'DMA'),
                 (N'DOP', N'DOM'),
                 (N'USD', N'TLS'),
                 (N'USD', N'ECU'),
                 (N'EGP', N'EGY'),
                 (N'USD', N'SLV'),
                 (N'XAF', N'GNQ'),
                 (N'ERN', N'ERI'),
                 (N'EUR', N'EST'),
                 (N'SZL', N'SWZ'),
                 (N'ZAR', N'SWZ'),
                 (N'ETB', N'ETH'),
                 (N'FJD', N'FJI'),
                 (N'EUR', N'FIN'),
                 (N'EUR', N'FRA'),
                 (N'XAF', N'GAB'),
                 (N'GMD', N'GMB'),
                 (N'GEL', N'GEO'),
                 (N'EUR', N'DEU'),
                 (N'GHS', N'GHA'),
                 (N'EUR', N'GRC'),
                 (N'XCD', N'GRD'),
                 (N'GTQ', N'GTM'),
                 (N'GNF', N'GIN'),
                 (N'XOF', N'GNB'),
                 (N'GYD', N'GUY'),
                 (N'HTG', N'HTI'),
                 (N'HNL', N'HND'),
                 (N'HKD', N'CHN'),
                 (N'HUF', N'HUN'),
                 (N'ISK', N'ISL'),
                 (N'INR', N'IND'),
                 (N'IDR', N'IDN'),
                 (N'IRR', N'IRN'),
                 (N'IQD', N'IRQ'),
                 (N'EUR', N'IRL'),
                 (N'EUR', N'ITA'),
                 (N'JMD', N'JAM'),
                 (N'JPY', N'JPN'),
                 (N'JOD', N'JOR'),
                 (N'KZT', N'KAZ'),
                 (N'KES', N'KEN'),
                 (N'KID', N'KIR'),
                 (N'AUD', N'KIR'),
                 (N'KPW', N'PRK'),
                 (N'KRW', N'KOR'),
                 (N'KWD', N'KWT'),
                 (N'KGS', N'KGZ'),
                 (N'LAK', N'LAO'),
                 (N'EUR', N'LVA'),
                 (N'LBP', N'LBN'),
                 (N'LSL', N'LSO'),
                 (N'ZAR', N'LSO'),
                 (N'LRD', N'LBR'),
                 (N'LYD', N'LBY'),
                 (N'CHF', N'LIE'),
                 (N'EUR', N'LTU'),
                 (N'EUR', N'LUX'),
                 (N'MOP', N'CHN'),
                 (N'MGA', N'MDG'),
                 (N'MWK', N'MWI'),
                 (N'MYR', N'MYS'),
                 (N'MVR', N'MDV'),
                 (N'XOF', N'MLI'),
                 (N'EUR', N'MLT'),
                 (N'USD', N'MHL'),
                 (N'MRU', N'MRT'),
                 (N'MUR', N'MUS'),
                 (N'MXN', N'MEX'),
                 (N'USD', N'FSM'),
                 (N'MDL', N'MDA'),
                 (N'EUR', N'MCO'),
                 (N'MNT', N'MNG'),
                 (N'EUR', N'MNE'),
                 (N'MAD', N'MAR'),
                 (N'MZN', N'MOZ'),
                 (N'MMK', N'MMR'),
                 (N'NAD', N'NAM'),
                 (N'ZAR', N'NAM'),
                 (N'AUD', N'NRU'),
                 (N'NPR', N'NPL'),
                 (N'EUR', N'NLD'),
                 (N'NZD', N'NZL'),
                 (N'NIO', N'NIC'),
                 (N'XOF', N'NER'),
                 (N'NGN', N'NGA'),
                 (N'NZD', N'NIU'),
                 (N'MKD', N'MKD'),
                 (N'NOK', N'NOR'),
                 (N'OMR', N'OMN'),
                 (N'PKR', N'PAK'),
                 (N'USD', N'PLW'),
                 (N'ILS', N'ISR'),
                 (N'JOD', N'ISR'),
                 (N'PAB', N'PAN'),
                 (N'USD', N'PAN'),
                 (N'PGK', N'PNG'),
                 (N'PYG', N'PRY'),
                 (N'PEN', N'PER'),
                 (N'PHP', N'PHL'),
                 (N'PLN', N'POL'),
                 (N'EUR', N'PRT'),
                 (N'QAR', N'QAT'),
                 (N'RON', N'ROU'),
                 (N'RUB', N'RUS'),
                 (N'RWF', N'RWA'),
                 (N'XCD', N'KNA'),
                 (N'XCD', N'LCA'),
                 (N'XCD', N'VCT'),
                 (N'WST', N'WSM'),
                 (N'EUR', N'SMR'),
                 (N'STN', N'STP'),
                 (N'SAR', N'SAU'),
                 (N'XOF', N'SEN'),
                 (N'RSD', N'SRB'),
                 (N'SCR', N'SYC'),
                 (N'SLL', N'SLE'),
                 (N'SGD', N'SGP'),
                 (N'BND', N'SGP'),
                 (N'EUR', N'SVK'),
                 (N'EUR', N'SVN'),
                 (N'SOS', N'SOM'),
                 (N'SLS', N'SOM'),
                 (N'ZAR', N'ZAF'),
                 (N'EUR', N'ESP'),
                 (N'SSP', N'SSD'),
                 (N'LKR', N'LKA'),
                 (N'SDG', N'SDN'),
                 (N'SRD', N'SUR'),
                 (N'SEK', N'SWE'),
                 (N'CHF', N'CHE'),
                 (N'SYP', N'SYR'),
                 (N'TWD', N'TWN'),
                 (N'TJS', N'TJK'),
                 (N'TZS', N'TZA'),
                 (N'THB', N'THA'),
                 (N'XOF', N'TGO'),
                 (N'TOP', N'TON'),
                 (N'TTD', N'TTO'),
                 (N'TND', N'TUN'),
                 (N'TRY', N'TUR'),
                 (N'TMT', N'TKM'),
                 (N'TVD', N'TUV'),
                 (N'AUD', N'TUV'),
                 (N'UGX', N'UGA'),
                 (N'UAH', N'UKR'),
                 (N'RUB', N'UKR'),
                 (N'AED', N'ARE'),
                 (N'GBP', N'GBR'),
                 (N'USD', N'USA'),
                 (N'UYU', N'URY'),
                 (N'UZS', N'UZB'),
                 (N'VUV', N'VUT'),
                 (N'EUR', N'VAT'),
                 (N'VES', N'VEN'),
                 (N'VND', N'VNM'),
                 (N'YER', N'YEM'),
                 (N'ZMW', N'ZMB')) AS cbc(CurrencyCode, CountryCode);
GO

--------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DatesBetweenNoWeekends
(
    @StartDate date,
    @EndDate date 
)
RETURNS @Dates TABLE
(
    DateNumber int IDENTITY(1,1) PRIMARY KEY,
    DateValue date
)
AS
-- Function:      Returns a table of dates excluding weekends
-- Parameters:    @StartDate date => first date to return
--                @EndDate => last date to return
-- Action:        Returns a table of dates between the two dates supplied (inclusive)
--                but excluding Saturday and Sunday
-- Return:        Rowset with DateNumber as int and DateValue as a date
-- Refer to this video: https://youtu.be/m5GtvUHXOFQ
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.DatesBetweenNoWeekends('20200101', '20200131') ORDER BY DateValue;
SELECT * FROM SDU_Tools.DatesBetweenNoWeekends('20200131', '20200101') ORDER BY DateValue;

*/
BEGIN
    DECLARE @CurrentValue date = @StartDate;

    WHILE @CurrentValue <= @EndDate 
    BEGIN
        IF DATEPART(weekday, @CurrentValue) NOT IN (DATEPART(weekday, '19000107'), DATEPART(weekday, '19000106'))
        BEGIN
            INSERT @Dates (DateValue) VALUES (@CurrentValue);
        END;
        SET @CurrentValue = DATEADD(day, 1, @CurrentValue);
    END;

    RETURN;
END;
GO

--------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.InitialsFromName
(
    @Name nvarchar(max),
    @Separator nvarchar(max)
)
RETURNS nvarchar(max)
AS
-- Function:      Returns the initials from a name
-- Parameters:    @Name nvarchar(max) - the string to process
--                @Separator nvarchar(max) - the separator between initials
-- Action:        Returns the initials from a name, separated by a separator
-- Return:        Single string
-- Refer to this video: https://youtu.be/bWPsidPGrCQ
--
-- Test examples: 
/*

SELECT SDU_Tools.InitialsFromName(N'Mary Johanssen', N'');
SELECT SDU_Tools.InitialsFromName(N'Mary Johanssen', N' ');
SELECT SDU_Tools.InitialsFromName(N'Thomas', N' ');
SELECT SDU_Tools.InitialsFromName(N'Test Test', NULL);

*/
BEGIN
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    
    SET @StringToProcess = UPPER(LTRIM(RTRIM(@Name)));
    SET @InAWord = 0;
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', NCHAR(9))
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                IF DATALENGTH(@Response) > 0
                BEGIN
                    SET @Response += @Separator;
                END;
                SET @Response += @Character;
            END;
        END;
    END;
    
    RETURN @Response;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DateDimensionPeriodColumns
(
    @Date date,
    @FiscalYearStartMonth int,
    @Today date
)
RETURNS TABLE
AS
-- Function:      Returns a table (single row) of date dimension period columns
-- Parameters:    @Date date => date to process
--                @FiscalYearStartMonth int => month number when the financial year starts
--                @Today date => the current day (or the target day)
-- Action:        Returns a single row table with date dimension period columns
-- Return:        Single row rowset with date dimension period columns
-- Refer to this video: https://youtu.be/pcoaHYK70nU
--
-- Test examples: 
/*

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

*/
RETURN 

WITH FiscalYearDates
AS
(
    SELECT CASE WHEN MONTH(@Today) >= @FiscalYearStartMonth
                THEN CAST(CAST(YEAR(@Today) AS varchar(4)) 
                               + RIGHT('00' + CAST(@FiscalYearStartMonth AS varchar(2)), 2)
                               + '01' AS date)
                ELSE CAST(CAST(YEAR(@Today) - 1AS varchar(4)) 
                               + RIGHT('00' + CAST(@FiscalYearStartMonth AS varchar(2)), 2)
                               + '01' AS date)
           END AS StartOfFiscalYear,
           DATEADD(day, -1, 
                   DATEADD(year, 1, 
                           CASE WHEN MONTH(@Today) >= @FiscalYearStartMonth
                                THEN CAST(CAST(YEAR(@Today) AS varchar(4)) 
                                          + RIGHT('00' + CAST(@FiscalYearStartMonth AS varchar(2)), 2)
                                          + '01' AS date)
                                ELSE CAST(CAST(YEAR(@Today) - 1AS varchar(4)) 
                                          + RIGHT('00' + CAST(@FiscalYearStartMonth AS varchar(2)), 2)
                                          + '01' AS date)
           END)) AS EndOfFiscalYear
)
SELECT CASE WHEN @Date = @Today 
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsToday,
       CASE WHEN @Date = DATEADD(day, -1, @Today)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsYesterday,
       CASE WHEN @Date = DATEADD(day, 1, @Today)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsTomorrow,
       CASE WHEN @Date > @Today 
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsFuture,
       CASE WHEN DATEPART(weekday, @Date) 
                 NOT IN (DATEPART(weekday, '19000106'), -- Saturday
                         DATEPART(weekday, '19000107')) -- Sunday
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsWorkingDay,
       CASE WHEN @Date = CASE WHEN DATEPART(weekday, @Today) = DATEPART(weekday, '19000108') -- Monday
                              THEN DATEADD(day, -3, @Today)
                              ELSE DATEADD(day, -1, @Today)
                         END 
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsLastWorkingDay,
       CASE WHEN @Date = CASE WHEN DATEPART(weekday, @Today) = DATEPART(weekday, '19000105') -- Friday
                              THEN DATEADD(day, 3, @Today)
                              ELSE DATEADD(day, 1, @Today)
                         END 
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsNextWorkingDay,
       CASE WHEN DATEPART(weekday, @Date) 
                 IN (DATEPART(weekday, '19000106'), -- Saturday
                     DATEPART(weekday, '19000107')) -- Sunday
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsWeekend,
       CASE WHEN MONTH(@Date) = MONTH(@Today) AND YEAR(@Date) = YEAR(@Today)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsSameMonth,
       CASE WHEN MONTH(@Date) = MONTH(@Today) AND YEAR(@Date) = YEAR(@Today)
                                              AND DAY(@Date) BETWEEN 1 AND DAY(@Today)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsMonthToDate,
       CASE WHEN MONTH(@Date) = MONTH(@Today) AND YEAR(@Date) = (YEAR(@Today) - 1)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsSameMonthLastYear,
       CASE WHEN MONTH(@Date) = MONTH(@Today) AND YEAR(@Date) = (YEAR(@Today) - 1)
                                              AND DAY(@Date) BETWEEN 1 AND DAY(@Today)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsMonthToDateLastYear,
       CASE WHEN YEAR(@Date) = YEAR(@Today)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsSameCalendarYear,
       CASE WHEN @Date BETWEEN CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)
                       AND @Today 
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsCalendarYearToDate,
       CASE WHEN YEAR(@Date) = (YEAR(@Today) - 1)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsLastCalendarYear,
       CASE WHEN @Date BETWEEN CAST(CAST(YEAR(@Today) - 1 AS varchar(4)) + '0101' AS date)
                       AND DATEADD(year, -1, @Today) 
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsLastCalendarYearToDate,
       CASE WHEN @Date BETWEEN fyd.StartOfFiscalYear AND fyd.EndOfFiscalYear 
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsSameFiscalYear,
       CASE WHEN @Date BETWEEN fyd.StartOfFiscalYear AND @Date  
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsSameFiscalYearToDate,
       CASE WHEN @Date BETWEEN DATEADD(year, -1, fyd.StartOfFiscalYear) 
                       AND DATEADD(year, -1, fyd.EndOfFiscalYear)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsLastFiscalYear,
       CASE WHEN @Date BETWEEN DATEADD(year, -1, fyd.StartOfFiscalYear) 
                       AND DATEADD(year, -1, @Date)  
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsLastFiscalYearToDate,
       CASE WHEN @Date = DATEADD(day, 1 - DAY(@Today), @Today)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfMonth,
       CASE WHEN @Date = DATEADD(day, -1, DATEADD(month, 1, DATEADD(day, 1 - DAY(@Today), @Today)))
            THEN CAST(1 AS bit)       -- Change to use of EOMONTH when 2012 is minimum
            ELSE CAST(0 AS bit)
       END AS IsEndOfMonth,
       CASE WHEN @Date BETWEEN CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)
                           AND DATEADD(day, -1, DATEADD(month, 3, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END IsCalendarQuarter1,
       CASE WHEN @Date = CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfCalendarQuarter1,
       CASE WHEN @Date = DATEADD(day, -1, DATEADD(month, 3, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsEndOfCalendarQuarter1,
       CASE WHEN @Date BETWEEN DATEADD(month, 3, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date))
                           AND DATEADD(day, -1, DATEADD(month, 6, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END IsCalendarQuarter2,
       CASE WHEN @Date = DATEADD(month, 3, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfCalendarQuarter2,
       CASE WHEN @Date = DATEADD(day, -1, DATEADD(month, 6, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsEndOfCalendarQuarter2,
       CASE WHEN @Date BETWEEN DATEADD(month, 6, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date))
                           AND DATEADD(day, -1, DATEADD(month, 9, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END IsCalendarQuarter3,
       CASE WHEN @Date = DATEADD(month, 6, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfCalendarQuarter3,
       CASE WHEN @Date = DATEADD(day, -1, DATEADD(month, 9, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsEndOfCalendarQuarter3,
       CASE WHEN @Date BETWEEN DATEADD(month, 9, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date))
                           AND DATEADD(day, -1, DATEADD(month, 12, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END IsCalendarQuarter4,
       CASE WHEN @Date = DATEADD(month, 9, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfCalendarQuarter4,
       CASE WHEN @Date = DATEADD(day, -1, DATEADD(month, 12, CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsEndOfCalendarQuarter4,
       CASE WHEN @Date = CAST(CAST(YEAR(@Today) AS varchar(4)) + '0101' AS date)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfCalendarYear,
       CASE WHEN @Date = DATEADD(day, -1, CAST(CAST(YEAR(@Today) + 1 AS varchar(4)) + '0101' AS date))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsEndOfCalendarYear,
       CASE WHEN @Date BETWEEN fyd.StartOfFiscalYear
                           AND DATEADD(day, -1, DATEADD(month, 3, fyd.StartOfFiscalYear))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsFiscalQuarter1,
       CASE WHEN @Date = fyd.StartOfFiscalYear
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfFiscalQuarter1,
       CASE WHEN @Date = DATEADD(day, -1, DATEADD(month, 3, fyd.StartOfFiscalYear))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsEndOfFiscalQuarter1,
       CASE WHEN @Date BETWEEN DATEADD(month, 3, fyd.StartOfFiscalYear)
                           AND DATEADD(day, -1, DATEADD(month, 6, fyd.StartOfFiscalYear))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsFiscalQuarter2,
       CASE WHEN @Date = DATEADD(month, 3, fyd.StartOfFiscalYear)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfFiscalQuarter2,
       CASE WHEN @Date = DATEADD(day, -1, DATEADD(month, 6, fyd.StartOfFiscalYear))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsEndOfFiscalQuarter2,
       CASE WHEN @Date BETWEEN DATEADD(month, 6, fyd.StartOfFiscalYear)
                           AND DATEADD(day, -1, DATEADD(month, 9, fyd.StartOfFiscalYear))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsFiscalQuarter3,
       CASE WHEN @Date = DATEADD(month, 6, fyd.StartOfFiscalYear)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfFiscalQuarter3,
       CASE WHEN @Date = DATEADD(day, -1, DATEADD(month, 9, fyd.StartOfFiscalYear))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsEndOfFiscalQuarter3,
       CASE WHEN @Date BETWEEN DATEADD(month, 9, fyd.StartOfFiscalYear)
                           AND DATEADD(day, -1, DATEADD(month, 12, fyd.StartOfFiscalYear))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsFiscalQuarter4,
       CASE WHEN @Date = DATEADD(month, 9, fyd.StartOfFiscalYear)
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfFiscalQuarter4,
       CASE WHEN @Date = DATEADD(day, -1, DATEADD(month, 12, fyd.StartOfFiscalYear))
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsEndOfFiscalQuarter4,
       CASE WHEN @Date = fyd.StartOfFiscalYear 
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsStartOfFiscalYear,
       CASE WHEN @Date = fyd.EndOfFiscalYear 
            THEN CAST(1 AS bit)
            ELSE CAST(0 AS bit)
       END AS IsEndOfFiscalYear
FROM FiscalYearDates AS fyd;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.TimezoneOffsetToHours
(
    @TimezoneOffset nvarchar(20)
)
RETURNS decimal(18,2) 
AS
BEGIN
-- Function:      Calculates a number of hours from a timezone offset
-- Parameters:    @TimezoneOffset nvarchar(20) => as returned by sys.time_zone_info
-- Action:        Calculates a number of hours from a timezone offset
-- Return:        decimal(18,2)
-- Refer to this video: https://youtu.be/2JRKZeNEIrE
--
-- Test examples: 
/*

SELECT SDU_Tools.TimezoneOffsetToHours(N'-11:00');

*/
    RETURN CASE WHEN LEFT(@TimezoneOffset, 1) = N'+' THEN 1 ELSE -1 END -- sign
           * (
                 CAST(SUBSTRING(@TimezoneOffset, 2, CHARINDEX(N':', @TimezoneOffset) - 2) AS decimal(18,2)) -- hours
                 + CAST(SUBSTRING(@TimezoneOffset, CHARINDEX(N':', @TimezoneOffset) + 1, 20) AS decimal(18,2)) / 60.0 -- minutes
             ); 
END;
GO


------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.StartOfYear
(
    @InputDate date
)
RETURNS date
AS
BEGIN

-- Function:      Return date of the start of the year
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the first date of the year for any given date 
-- Return:        date
-- Refer to this video: https://youtu.be/8ITn30E8240
--
-- Test examples: 
/*

SELECT SDU_Tools.StartOfYear('20180713');
SELECT SDU_Tools.StartOfYear(SYSDATETIME());
SELECT SDU_Tools.StartOfYear(GETDATE());

*/
    RETURN CAST(CAST(YEAR(@InputDate) AS varchar(4)) + '0101' AS date);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.EndOfYear
(
    @InputDate date
)
RETURNS date
AS
BEGIN

-- Function:      Return date of the end of the year
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the last date of the year for any given date 
-- Return:        date
-- Refer to this video: https://youtu.be/8ITn30E8240
--
-- Test examples: 
/*

SELECT SDU_Tools.EndOfYear('20180713');
SELECT SDU_Tools.EndOfYear(SYSDATETIME());
SELECT SDU_Tools.EndOfYear(GETDATE());

*/
    RETURN CAST(CAST(YEAR(@InputDate) AS varchar(4)) + '1231' AS date);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.StartOfWeek
(
    @InputDate date
)
RETURNS date
AS
BEGIN

-- Function:      Return date of the start of the week
--                Note: assumption is a Sunday start (easy to modify if needed)
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the first date of the week for any given date 
-- Return:        date
-- Refer to this video: https://youtu.be/8ITn30E8240
--
-- Test examples: 
/*

SELECT SDU_Tools.StartOfWeek('20200713');
SELECT SDU_Tools.StartOfWeek(SYSDATETIME());
SELECT SDU_Tools.StartOfWeek(GETDATE());

*/
    RETURN DATEADD(day, 
                   DATEPART(weekday, '19000107') - DATEPART(weekday, @InputDate), 
                   @InputDate);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.EndOfWeek
(
    @InputDate date
)
RETURNS date
AS
BEGIN

-- Function:      Return date of the end of the week
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the last date of the week for any given date 
-- Return:        date
-- Refer to this video: https://youtu.be/8ITn30E8240
--
-- Test examples: 
/*

SELECT SDU_Tools.EndOfWeek('20200713');
SELECT SDU_Tools.EndOfWeek(SYSDATETIME());
SELECT SDU_Tools.EndOfWeek(GETDATE());

*/
    RETURN DATEADD(day, 
                   6, 
                   DATEADD(day, 
                           DATEPART(weekday, '19000107') - DATEPART(weekday, @InputDate), 
                           @InputDate));
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.StartOfWorkingWeek
(
    @InputDate date
)
RETURNS date
AS
BEGIN

-- Function:      Return date of the start of the working week
--                Note: assumption is working week is Monday to Friday (easy to modify if needed)
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the first date of the working week for any given date 
-- Return:        date
-- Refer to this video: https://youtu.be/8ITn30E8240
--
-- Test examples: 
/*

SELECT SDU_Tools.StartOfWorkingWeek('20200713');
SELECT SDU_Tools.StartOfWorkingWeek(SYSDATETIME());
SELECT SDU_Tools.StartOfWorkingWeek(GETDATE());

*/
    RETURN DATEADD(day,
                   1,
                   DATEADD(day, 
                           DATEPART(weekday, '19000107') - DATEPART(weekday, @InputDate), 
                           @InputDate));
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.EndOfWorkingWeek
(
    @InputDate date
)
RETURNS date
AS
BEGIN

-- Function:      Return date of the end of the working week
--                Note: assumption is working week is Monday to Friday (easy to modify if needed)
-- Parameters:    @Input date (use GETDATE() or SYSDATETIME() for today)
-- Action:        Calculates the last date of the working week for any given date 
-- Return:        date
-- Refer to this video: https://youtu.be/8ITn30E8240
--
-- Test examples: 
/*

SELECT SDU_Tools.EndOfWorkingWeek('20200713');
SELECT SDU_Tools.EndOfWorkingWeek(SYSDATETIME());
SELECT SDU_Tools.EndOfWorkingWeek(GETDATE());

*/
    RETURN DATEADD(day, 
                   5, 
                   DATEADD(day, 
                           DATEPART(weekday, '19000107') - DATEPART(weekday, @InputDate), 
                           @InputDate));
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.CurrentSessionDecimalSeparator()
RETURNS varchar(1)
AS
BEGIN

-- Function:      Returns the decimal separator for the current session
-- Parameters:    None
-- Action:        Works out what the decimal separator is for the current session
-- Return:        varchar(1)
-- Refer to this video: https://youtu.be/Jy_qVDOjUzI
--
-- Test examples: 
/*

SELECT CAST(FORMAT(123456.789, 'N', 'de-de') AS varchar(20));
SELECT SDU_Tools.CurrentSessionDecimalSeparator();

*/
    RETURN SUBSTRING(CAST(CAST(0 AS decimal(18,2)) AS varchar(20)), 2, 1);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.CurrentSessionThousandsSeparator()
RETURNS varchar(1)
AS
BEGIN

-- Function:      Returns the thousands separator for the current session
-- Parameters:    None
-- Action:        Works out what the thousands separator is for the current session
-- Return:        varchar(1)
-- Refer to this video: https://youtu.be/Jy_qVDOjUzI
--
-- Test examples: 
/*

SELECT CAST(FORMAT(123456.789, 'N', 'de-de') AS varchar(20));
SELECT SDU_Tools.CurrentSessionThousandsSeparator();

*/
    RETURN SUBSTRING(CONVERT(varchar(20), CAST(1000 AS money), 1), 2, 1);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.StripDiacritics
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Strips diacritics (accents, graves, etc.) from a string
-- Parameters:    @InputString nvarchar(max) - string to strip
-- Action:        Strips diacritics (accents, graves, etc.) from a string
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/Aqiqa9OXNqQ
--
-- Test examples: 
/*

SELECT SDU_Tools.StripDiacritics(N'śŚßťŤÄÅàá');

*/

    DECLARE @CharactersToReplace nvarchar(max) 
        = N'ÁÀÂÃÄÅàáâãäåĀāąĄæÆÇçćĆčČ¢©đĐďĎÈÉÊËèéêëěĚĒēęĘÌÍÎÏìíîïĪīłŁ£'
        + N'ÑñňŇńŃÒÓÔÕÕÖØòóôõöøŌōřŘ®ŠšśŚßťŤÙÚÛÜùúûüůŮŪūµ×¥ŸÿýÝŽžżŻźŹ';
    DECLARE @ReplacementCharacters nvarchar(max)
        = N'aaaaaaaaaaaaaaaaaaccccccccddddeeeeeeeeeeeeeeiiiiiiiiiilll'
        + N'nnnnnooooooooooooooooorrsssssttuuuuuuuuuuuuuxyyyyyzzzzzz';
    
    DECLARE @Counter int = 1;
    DECLARE @ReturnValue nvarchar(max) = @InputString;
    
    -- Replace loop with TRANSLATE when lowest supported version = 2016
    WHILE @Counter <= LEN(@CharactersToReplace)
    BEGIN
        SET @ReturnValue = REPLACE(@ReturnValue, 
                                   SUBSTRING(@CharactersToReplace, @Counter, 1),
                                   SUBSTRING(@replacementCharacters, @Counter, 1));
        SET @Counter = @Counter + 1;
    END;
    
    RETURN @ReturnValue;
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DateTime2ToUnixTime
(
    @ValueToConvert datetime2(0)
)
RETURNS bigint
AS
BEGIN

-- Function:      Converts a datetime2 value to Unix time
-- Parameters:    @ValueToConvert datetime2(0) -> the value to convert
-- Action:        Converts a datetime2 value to Unix time
-- Return:        bigint
-- Refer to this video: https://youtu.be/tGplVv-G3E4
--
-- Test examples: 
/*

SELECT SDU_Tools.DateTime2ToUnixTime('20450101');

*/

    RETURN DATEDIFF_BIG(second, '19700101', @ValueToConvert);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.UnixTimeToDateTime2
(
    @ValueToConvert bigint
)
RETURNS datetime2(0)
AS
BEGIN

-- Function:      Converts a Unix time to a datetime2 value
-- Parameters:    @ValueToConvert bigint -> the value to convert
-- Action:        Converts a Unix time to a datetime2 value
-- Return:        datetime2(0)
-- Refer to this video: https://youtu.be/tGplVv-G3E4
--
-- Test examples: 
/*

SELECT SDU_Tools.UnixTimeToDateTime2(2366841600);

*/

    RETURN DATEADD(day, @ValueToConvert / 86400, DATEADD(second, @ValueToConvert % 86400, '19700101'));
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.CobolCase
(
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN

-- Function:      Apply Cobol Casing to a string
-- Parameters:    @InputString varchar(max)
-- Action:        Apply Cobol Casing to a string (similar to programming identifiers)
-- Return:        nvarchar(max)
-- Refer to this video: https://youtu.be/i1rnVlOR760
--
-- Test examples: 
/*

SELECT SDU_Tools.CobolCase(N'the  quick   brown fox consumed a macrib at mcdonalds');
SELECT SDU_Tools.CobolCase(N'janet mcdermott');
SELECT SDU_Tools.CobolCase(N'the case of sherlock holmes and the curly-Haired  company');

*/
    DECLARE @Response nvarchar(max) = N'';
    DECLARE @StringToProcess nvarchar(max);
    DECLARE @CharacterCounter int = 0;
    DECLARE @WordCounter int = 0;
    DECLARE @Character nchar(1);
    DECLARE @InAWord bit;
    DECLARE @CurrentWord nvarchar(max);
    DECLARE @NumberOfWords int;
    
    DECLARE @Words TABLE
    (
        WordNumber int IDENTITY(1,1),
        Word nvarchar(max)
    );
    
    SET @StringToProcess = LOWER(LTRIM(RTRIM(@InputString)));
    SET @InAWord = 0;
    SET @CurrentWord = N'';
    
    WHILE @CharacterCounter < LEN(@StringToProcess)
    BEGIN
        SET @CharacterCounter += 1;
        SET @Character = SUBSTRING(@StringToProcess, @CharacterCounter, 1);
        IF @Character IN (N' ', N'-', NCHAR(9)) -- whitespace or hyphens
        BEGIN
            IF @InAWord <> 0
            BEGIN
                SET @InAWord = 0;
                INSERT @Words VALUES (@CurrentWord);
                SET @CurrentWord = N'';
            END;
        END ELSE BEGIN -- not whitespace
            IF @InAWord = 0 -- start of a word
            BEGIN
                SET @InAWord = 1;
                SET @CurrentWord = @Character;
            END ELSE BEGIN -- part of a word
                SET @CurrentWord += @Character;
            END;
        END;
    END;
    IF @InAWord <> 0 
    BEGIN
        INSERT @Words VALUES (@CurrentWord);
    END;
    
    SET @NumberOfWords = (SELECT COUNT(*) FROM @Words);
    SET @WordCounter = 0;
    
    WHILE @WordCounter < @NumberOfWords
    BEGIN
        SET @WordCounter += 1;
        SET @CurrentWord = (SELECT Word FROM @Words WHERE WordNumber = @WordCounter);
        SET @Response += CASE WHEN @WordCounter > 1 THEN N'-' ELSE N'' END + @CurrentWord;
    END;
    
    RETURN UPPER(@Response);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.DateOfOrthodoxEaster
(
    @Year int
)
RETURNS date
AS
BEGIN

-- Function:      Returns the date of Orthodox Easter in a given year
-- Parameters:    @Year int  -> year number
-- Action:        Calculates the date of Orthodox Easter for
--                a given year, adapted from a code example 
--                courtesy of Antonios Chatzipavlis
-- Return:        date
-- Refer to this video: https://youtu.be/QbYx4k0ey8k
--
-- Test examples: 
/*

SELECT SDU_Tools.DateOfOrthodoxEaster(2020);
SELECT SDU_Tools.DateOfOrthodoxEaster(1958);

*/
    RETURN DATEADD(DAY, 13, CAST(CAST(@Year AS varchar(4))
                            + RIGHT('0' + CAST(((((19 * (@Year % 19) + 15) % 30) 
                                                + ((2 * (@Year % 4) + 4 * (@Year % 7) 
                                                - ((19 * (@Year % 19) + 15) % 30) +34) % 7) 
                                                + 114) / 31) AS varchar(2)), 2)
                            + RIGHT('0' + CAST((((((19 * (@Year % 19) + 15) % 30) 
                                                + ((2 * (@Year % 4) + 4 * (@Year % 7) 
                                                - ((19 * (@Year % 19) + 15) % 30) +34) % 7) 
                                                + 114) % 31) + 1) AS varchar(2)), 2) AS date));
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.WeekdayOfSameWeek
(
     @DayInTargetWeek date,
     @DayOfWeek int
)
RETURNS date
AS
BEGIN

-- Function:      Returns the nominated day of the target week
-- Parameters:    @DayInTargetWeek date - any day in the target week
--                @DayOfWeek int - Sunday = 1, Monday = 2, etc.
-- Action:        Returns the nominated day in the same week as the target date
-- Return:        date
-- Refer to this video: https://youtu.be/XHMrwNvqwdQ
--
-- Test examples: 
/*

SELECT SDU_Tools.WeekdayOfSameWeek('20201022', 1); -- Sunday in week of 22nd Oct 2020
SELECT SDU_Tools.WeekdayOfSameWeek('20201022', 5); -- Thursday in week of 22nd Oct 2020

*/
    RETURN DATEADD(day, 
                   DATEPART(weekday, '19000107') - DATEPART(weekday, @DayInTargetWeek) + @DayOfWeek - 1, 
                   @DayInTargetWeek);
END;
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.NearestWeekday
(
     @TargetDate date,
     @DayOfWeek int
)
RETURNS date
AS
BEGIN

-- Function:      Returns the nearest nominated day to the target date
-- Parameters:    @TargetDate date - the date that we're aiming for
--                @DayOfWeek int - Sunday = 1, Monday = 2, etc.
-- Action:        Returns the nominated day closest to the date supplied
-- Return:        date
-- Refer to this video: https://youtu.be/YSkWiD5Sfeg
--
-- Test examples: 
/*

SELECT SDU_Tools.NearestWeekday('20201022', 1); -- Sunday closest to 22nd Oct 2020
SELECT SDU_Tools.NearestWeekday('20201022', 3); -- Tuesday closest to 22nd Oct 2020
SELECT SDU_Tools.NearestWeekday('20201022', 5); -- Thursday closest to 22nd Oct 2020

*/
    DECLARE @CorrectDayInSameWeek date 
        = DATEADD(day, 
                  DATEPART(weekday, '19000107') - DATEPART(weekday, @TargetDate) + @DayOfWeek - 1, 
                  @TargetDate);
    DECLARE @DaysDifferent int = DATEDIFF(day, @TargetDate, @CorrectDayInSameWeek);

    RETURN CASE WHEN ABS(@DaysDifferent) <= 3
                THEN @CorrectDayInSameWeek 
                ELSE CASE WHEN @DaysDifferent < 0
                          THEN DATEADD(day, 7, @CorrectDayInSameWeek)
                          ELSE DATEADD(day, -7, @CorrectDayInSameWeek)
                     END
           END;
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE SDU_Tools.ScriptAnalyticsViewInCurrentDatabase
(
    @TableSchemaName sysname,
    @TableName sysname,
    @ViewSchemaName sysname,
    @ViewName sysname,
    @ScriptOutput nvarchar(max) OUTPUT
)
AS
BEGIN

-- Function:      Scripts a data model table as an analytics view
-- Parameters:    @TableSchemaName - schema of table to base view upon
--                @TableName - table to base view upon
--                @ViewSchemaName - schema of scripted view
--                @ViewName - name of the scripted view
-- Action:        Scripts a data model table as an analytics view
-- Return:        Single column called ScriptOutput nvarchar(max)
-- Refer to this video: https://youtu.be/lodq1ZvS51s
-- Test examples: 
/*

SET NOCOUNT ON;
DECLARE @SQL nvarchar(max);

EXEC SDU_Tools.ScriptAnalyticsViewInCurrentDatabase N'DataModel', N'Customers', N'Analytics', N'Customer', @SQL OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @SQL;

*/
    SET NOCOUNT ON;
    
    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10);
    DECLARE @Columns TABLE
    (
        ColumnID int IDENTITY(1,1) PRIMARY KEY,
        ColumnName sysname NOT NULL
    );
    DECLARE @ColumnCounter int;
    DECLARE @ColumnName sysname;
    
    INSERT @Columns (ColumnName)
    SELECT c.name
    FROM sys.columns AS c
    INNER JOIN sys.tables AS t
    ON t.object_id = c.object_id 
    INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id 
    WHERE s.name = @TableSchemaName 
    AND t.name = @TableName 
    ORDER BY c.column_id;
    
    DECLARE @SQL nvarchar(max) = N'CREATE OR ALTER VIEW ' 
                               + CASE WHEN CHARINDEX(N' ', @ViewSchemaName) > 0 THEN QUOTENAME(@ViewSchemaName)
                                      ELSE @ViewSchemaName 
                                 END 
                               + N'.' 
                               + CASE WHEN CHARINDEX(N' ', SDU_Tools.SeparateByCase(@ViewName, N' ')) > 0 THEN QUOTENAME(SDU_Tools.SeparateByCase(@ViewName, N' '))
                                      ELSE @ViewName 
                                 END + @CRLF
                               + N'AS' + @CRLF
                               + N'SELECT ';
    
    SET @ColumnCounter = 1;
    WHILE @ColumnCounter <= (SELECT MAX(ColumnID) FROM @Columns)
    BEGIN
        SET @ColumnName = (SELECT ColumnName FROM @Columns WHERE ColumnID = @ColumnCounter);
        IF @ColumnCounter <> 1
        BEGIN
            SET @SQL += N'       ';
        END;
        IF CHARINDEX(N' ', SDU_Tools.SeparateByCase(@ColumnName, N' ')) < 1 OR @ColumnName LIKE N'%Key'
        BEGIN
            SET @SQL += @ColumnName;
        END ELSE BEGIN
            SET @SQL += @ColumnName + N' AS ' 
                     + QUOTENAME(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SDU_Tools.SeparateByCase(@ColumnName, N' '), N' I D', N' ID'), N' U R L', N' URL'), N' In ', N' in '), N' At ', N' at '), N' On ', N' on '), N' To ', N' to '));
        END;
        IF @ColumnCounter < (SELECT MAX(ColumnID) FROM @Columns)
        BEGIN
            SET @SQL += N',';
        END;
        SET @SQL += @CRLF;
        SET @ColumnCounter += 1;
    END;
    
    SET @SQL += N'FROM ' 
              + CASE WHEN CHARINDEX(N' ', @TableSchemaName) > 0 THEN QUOTENAME(@TableSchemaName)
                     ELSE @TableSchemaName 
                END 
              + N'.' 
              + CASE WHEN CHARINDEX(N' ', @TableName) > 0 THEN QUOTENAME(@TableName)
                     ELSE @TableName 
                END
              + N';' + @CRLF     
              + N'GO' + @CRLF;

    SET @ScriptOutput = @SQL;
END;
GO 

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.WeekdayAcrossYears
(
    @DayNumber int,
    @MonthNumber int,
    @FromYear int,
    @ToYear int
)
RETURNS TABLE
AS
-- Function:      Returns a table of days of the week for a given day over a set of years
-- Parameters:    @StartValue int => first value to return
--                @NumberRequired int => number of numbers to return
-- Action:        For a particular day and month, returns the day of the week for a range of years
-- Return:        Rowset with YearNumber as an integer, and WeekDay as a string
-- Refer to this video: https://youtu.be/k4wY1isY1G0
--
-- Test examples: 
/*

SELECT * FROM SDU_Tools.WeekdayAcrossYears(20, 11, 2021, 2030);

*/
RETURN 
(
    WITH Years
    AS
    (
        SELECT TOP(@ToYear - @FromYear + 1) 
               ROW_NUMBER() OVER(ORDER BY (SELECT 1)) + @FromYear - 1 AS YearNumber 
        FROM sys.all_columns AS ac1
        CROSS JOIN sys.all_columns AS ac2
    )   
    SELECT YearNumber,
           DATENAME
           (
               weekday, 
               DATEFROMPARTS(YearNumber, @MonthNumber, @DayNumber)
           ) AS [WeekDay]
    FROM Years
);
GO

------------------------------------------------------------------------------------

CREATE FUNCTION SDU_Tools.SQLServerType()
RETURNS nvarchar(40)
AS
BEGIN

-- Function:      Returns the type of SQL Server for the current session
-- Parameters:    Nil
-- Action:        Returns the type of SQL Server for the current session
-- Return:        nvarchar(40)
-- Refer to this video: https://youtu.be/tASWb2eN-8w
--
-- Test examples: 
/*

SELECT SDU_Tools.SQLServerType();

*/
    RETURN CASE SERVERPROPERTY('EngineEdition')
                WHEN 1 THEN N'Desktop'
                WHEN 2 THEN N'Standard'
                WHEN 3 THEN N'Enterprise'
                WHEN 4 THEN N'Express'
                WHEN 5 THEN N'Azure SQL Database'
                WHEN 6 THEN N'Azure Synapse Analytics'
                WHEN 8 THEN N'Azure SQL Managed Instance'
                WHEN 9 THEN N'Azure SQL Edge'
                WHEN 11 THEN N'Azure Synapse Serverless Pool'
                ELSE N'Unknown'
           END;
END;
GO

