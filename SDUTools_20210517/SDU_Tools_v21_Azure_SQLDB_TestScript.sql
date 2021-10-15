SELECT SDU_Tools.SDUToolsVersion() AS [SDU Tools Version];

SELECT SDU_Tools.CamelCase(N'the  quick   brown fox consumed a macrib at mcdonalds');

SELECT SDU_Tools.KebabCase(N'the  quick   brown fox consumed a macrib at mcdonalds');

SELECT SDU_Tools.CamelCase(N'the  quick   brown fox consumed a macrib at mcdonalds');

SELECT SDU_Tools.PercentEncode('this should be a URL but it contains {}234');

SELECT SDU_Tools.XMLEncodeString(N'Hello there John & Mary. This is <X> only a token');

SELECT SDU_Tools.XMLDecodeString(N'Hello there John &amp; Mary. This is &lt;X&gt; only a token');

SELECT SDU_Tools.PreviousNonWhitespaceCharacter(N'Hello there ' + CHAR(9) + ' fred ' + CHAR(13) + CHAR(10) + 'again',11); -- should be r

SELECT SDU_Tools.ProperCase(N'the  quick   brown fox consumed a macrib at mcdonalds');

SELECT SDU_Tools.SnakeCase(N'the  quick   brown fox consumed a macrib at mcdonalds');

SELECT N'his name' AS Him, SDU_Tools.QuoteString(N'his name') AS QuotedHim
     , N'they''re here' AS Them, SDU_Tools.QuoteString(N'they''re here') AS QuotedThem;

SELECT * FROM SDU_Tools.SplitDelimitedString(N'hello, there, greg', N',', 0);

SELECT * FROM SDU_Tools.SplitDelimitedStringIntoColumns(N'210.4,John Doe,327.32,2234242,Current,1', N',', 1);

SELECT SDU_Tools.DigitsOnly('Hello20834There  234', 1);

SELECT SDU_Tools.TitleCase(N'the  quick   brown fox consumed a macrib at mcdonalds');

SELECT '-->' + SDU_Tools.TrimWhitespace('Test String') + '<--';

SELECT SDU_Tools.LeftPad(N'Hello', 14, N'o');

SELECT SDU_Tools.RightPad(N'Hello', 14, N'o');

SELECT SDU_Tools.SeparateByCase(N'APascalCasedSentence', N' ');

SELECT SDU_Tools.AsciiOnly('Hello° There', '', 0);

SELECT SDU_Tools.Base64ToVarbinary('qrvM3e7/');

SELECT SDU_Tools.CharToHexadecimal('A');
GO

DECLARE @Value SQL_variant = 'hello';
SELECT * FROM SDU_Tools.SQLVariantInfo(@Value);
GO

SELECT SDU_Tools.VarbinaryToBase64(0xAABBCCDDEEFF);

SELECT SDU_Tools.SecondsToDuration(910); 

SELECT SDU_Tools.HexCharStringToInt(N'32');

SELECT SDU_Tools.HexCharStringToChar(N'41');

SELECT SDU_Tools.FormatDataTypeName(N'decimal', 18, 2, NULL);

EXEC SDU_Tools.ExecuteOrPrint @StringToExecuteOrPrint = N'SELECT ''Hello Greg'';',
                              @IncludeGO = 1,
                              @NumberOfCrLfAfterGO = 1;

SELECT SDU_Tools.DeExecuteSQLString('exec sp_executeSQL N''some query goes here''', 0, 1);

SELECT SDU_Tools.ExtractSQLTemplate('select * from customers where customerid = 12 and customername = ''fred'' order by customerid;', 4000);

DECLARE @TestString nvarchar(max) 
    = 'exec sp_executeSQL N''SELECT something FROM somewhere
                             WHERE somethingelse = @range
                                AND somedate = @date 
                             AND someteam = @team'''
                             + ',N''@range nvarchar(5),@date datetime,@team nvarchar(27)'''
                             + ',@range=N''month'',@date=''2014-10-01 00:00:00'',@team=N''Test team''';

SELECT SDU_Tools.LastParameterStartPosition(N'exec sp_executeSQL N''SELECT something FROM somewhere
                             WHERE somethingelse = @range
                                AND somedate = @date 
                             AND someteam = @team'''
                             + ',N''@range nvarchar(5),@date datetime,@team nvarchar(27)'''
                             + ',@range=N''month'',@date=''2014-10-01 00:00:00'',@team=N''Test team''');

EXEC SDU_Tools.GetTableSchemaComparisonInCurrentDatabase N'dbo', N'TABLE1', N'dbo', N'TABLE2', 1, 1;

EXEC SDU_Tools.AnalyzeTableColumnsInCurrentDatabase N'Warehouse', N'StockItems', 1, 1, 100; 

EXEC SDU_Tools.DropTemporaryTableIfExists N'#Accounts';

EXEC SDU_Tools.FindStringWithinTheCurrentDatabase N'Kayla', 1; 

EXEC SDU_Tools.ListSubsetIndexesInCurrentDatabase;

EXEC SDU_Tools.PrintMessage N'Hello';

EXEC SDU_Tools.ListAllDataTypesInUseInCurrentDatabase
    @SchemasToList = N'ALL', 
    @TablesToList = N'ALL', 
    @ColumnsToList = N'ALL';

EXEC SDU_Tools.ListColumnsAndDataTypesInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ColumnsToList = N'ALL';

EXEC SDU_Tools.ListMismatchedDataTypesInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'InvoiceLines,StockItemTransactions', 
     @ColumnsToList = N'ALL';

EXEC SDU_Tools.ListForeignKeysInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 

EXEC SDU_Tools.ListForeignKeyColumnsInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 

EXEC SDU_Tools.ListIndexesInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 

EXEC SDU_Tools.ListNonIndexedForeignKeysInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 

EXEC SDU_Tools.ListPotentialDateColumnsInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ColumnsToList = N'ALL';

EXEC SDU_Tools.ListPotentialDateColumnsByValueInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ColumnsToList = N'ALL';

EXEC SDU_Tools.ListUnusedIndexesInCurrentDatabase;

EXEC SDU_Tools.ListUserTableSizesInCurrentDatabase 
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ExcludeEmptyTables = 0,
     @IsOutputOrderedBySize = 1;

EXEC SDU_Tools.ListUserTableAndIndexSizesInCurrentDatabase 
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ExcludeEmptyIndexes = 0,
	 @ExcludeTableStructure = 0,
     @IsOutputOrderedBySize = 0;

EXEC SDU_Tools.ListUseOfDeprecatedDataTypesInCurrentDatabase 
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ColumnsToList = N'ALL';

SET XACT_ABORT OFF;
SELECT SDU_Tools.IsXActAbortON();
SET XACT_ABORT ON;
SELECT SDU_Tools.IsXActAbortON();
SET XACT_ABORT OFF;

SELECT SDU_Tools.StartOfFinancialYear(SYSDATETIME(), 7);

SELECT SDU_Tools.EndOfFinancialYear(SYSDATETIME(), 7);

SELECT SDU_Tools.CalculateAge('1968-11-20', SYSDATETIME());

SELECT SDU_Tools.IsLeapYear(1901);

SELECT SDU_Tools.PGObjectName(N'CustomerTradingName');

EXEC SDU_Tools.UpdateStatisticsInCurrentDatabase 
     @SchemasToUpdate = N'ALL', 
     @TablesToUpdate = N'Cities,People', 
     @SamplePercentage = 30;

SELECT SDU_Tools.CountWords('Hello  there');

EXEC SDU_Tools.Sleep 1;

SELECT SDU_Tools.Translate(N'[08] 7777,9876', N'[],', N'()-');

SELECT SDU_Tools.DateDiffNoWeekends('20170101', '20170131');

SELECT SDU_Tools.InvertString('Hello There');

SELECT * FROM SDU_Tools.TableOfNumbers(12, 90);

SELECT * FROM SDU_Tools.ExtractTrimmedWords('fre john   C10');

SELECT * FROM SDU_Tools.ExtractTrigrams('1846 Hudecova Crescent');

EXEC SDU_Tools.ListIncomingForeignKeysInCurrentDatabase 
     @ReferencedSchemasToList = N'Application,Sales', 
     @ReferencedTablesToList = N'Cities,Orders'; 
GO

SET NOCOUNT ON;

DECLARE @Script nvarchar(max);

EXEC SDU_Tools.ScriptTableInCurrentDatabase 
     @ExistingSchemaName = N'Reference'
   , @ExistingTableName = N'Currencies'
   , @OutputSchemaName = N'Reference'
   , @OutputTableName = N'Currencies'
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

SELECT SDU_Tools.AlphanumericOnly('Hello20834There  234');

SELECT SDU_Tools.AlphabeticOnly('Hello20834There  234');

EXEC SDU_Tools.ReseedSequenceBeyondTableValuesInCurrentDatabase
     @SchemaName = N'Sequences', 
     @SequenceName = N'CustomerID'; 

EXEC SDU_Tools.ReseedSequencesInCurrentDatabase;

SELECT SDU_Tools.DateOfEasterSunday(2018);

EXEC SDU_Tools.ListPrimaryKeyColumnsInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL';

SELECT * FROM SDU_Tools.ReservedWords;

SELECT * FROM SDU_Tools.FutureReservedWords;

SELECT * FROM SDU_Tools.ODBCReservedWords;

SELECT * FROM SDU_Tools.SystemDataTypeNames;

SELECT * FROM SDU_Tools.SystemWords ORDER BY SystemWord;

SELECT * FROM SDU_Tools.SystemConfigurationOptionDefaults;

SELECT * FROM SDU_Tools.NonDefaultSystemConfigurationOptions;

SELECT SDU_Tools.SQLServerVersionForCompatibilityLevel(110);

SELECT SDU_Tools.JulianDayNumberToDate(2451545);

SELECT SDU_Tools.DateToJulianDayNumber('20000101');

SELECT * FROM SDU_Tools.DatesBetween('20170101', '20170131');

SELECT * FROM SDU_Tools.DateDimensionColumns('20170131', 7);

SELECT SDU_Tools.TrainCase(N'the  quick   brown fox consumed a macrib at mcdonalds');

SELECT SDU_Tools.ScreamingSnakeCase(N'the  quick   brown fox consumed a macrib at mcdonalds');

SELECT SDU_Tools.SpongeBobSnakeCase(N'SpongeBob SnakeCase');

SELECT SDU_Tools.NumberAsText(322342);

SELECT * FROM SDU_Tools.TimePeriodDimensionColumns('10:17 AM', 15);

EXEC SDU_Tools.GetDateDimension 
     @FromDate = '20180701', 
     @ToDate = '20180731', 
     @StartOfFinancialYearMonth = 7;

EXEC SDU_Tools.GetTimePeriodDimension 
     @MinutesPerPeriod = 15;

SELECT SDU_Tools.StartOfMonth('20180713');

SELECT SDU_Tools.EndOfMonth('20160205');

EXEC SDU_Tools.CalculateTableLoadingOrderInCurrentDatabase;

SELECT SDU_Tools.ProductVersionToMajorVersion('13.0.4435.0');

SELECT SDU_Tools.ProductVersionToMinorVersion('13.0.4435.0');

SELECT SDU_Tools.ProductVersionToBuild('13.0.4435.0');

SELECT SDU_Tools.ProductVersionToRelease('13.0.4435.0');

SELECT * FROM SDU_Tools.ProductVersionComponents('  13.0.4435.0 ');

SELECT * FROM SDU_Tools.OperatingSystemVersions ORDER BY OS_Family, OS_Version;

SELECT * FROM SDU_Tools.OperatingSystemLocales ORDER BY OS_Family, LocaleID, LanguageName;

SELECT * FROM SDU_Tools.OperatingSystemSKUs ORDER BY OS_Family, SKU, SKU_Name;

SELECT * 
FROM SDU_Tools.SQLServerProductVersions 
ORDER BY MajorVersionNumber, MinorVersionNumber, BuildNumber;
GO

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

SELECT SDU_Tools.IsWeekday('20180713');

SELECT SDU_Tools.IsWeekend('20180713');

EXEC SDU_Tools.ListDisabledIndexesInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL'; 

EXEC SDU_Tools.ListUserHeapTablesInCurrentDatabase 
    @SchemasToList = N'ALL', 
    @TablesToList = N'ALL';

EXEC SDU_Tools.ListUserTablesWithNoPrimaryKeyInCurrentDatabase 
    @SchemasToList = N'ALL', 
    @TablesToList = N'ALL';

SELECT SDU_Tools.NumberToRomanNumerals(2018);
GO

DROP TABLE IF EXISTS dbo.SDCurrencies;
GO

CREATE TABLE dbo.SDCurrencies
(
    SDCurrencyID int IDENTITY(1,1) PRIMARY KEY,
    SDCurrencyName nvarchar(20) NOT NULL,
    SDCurrencyCode nvarchar(3) NOT NULL
);
GO

SET NOCOUNT ON;

DECLARE @Script nvarchar(max);

EXEC SDU_Tools.ScriptTableAsUnpivotInCurrentDatabase 
    @SourceTableSchemaName  = N'dbo'
  , @SourceTableName = N'SDCurrencies'
  , @OutputViewSchemaName = N'dbo'
  , @OutputViewName = N'SDCurrencies_Unpivoted'
  , @IsViewScript = 0
  , @IncludeNullColumns = 0
  , @IncludeWHEREClause = 0
  , @ColumnIndentSize = 4
  , @ScriptIndentSize = 0
  , @QueryScript = @Script OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @Script, 1, 0, 0, 0, 'GO';
GO

DROP TABLE IF EXISTS dbo.SDCurrencies;
GO

SELECT * 
FROM SDU_Tools.LoginTypes 
ORDER BY LoginTypeID;

SELECT * 
FROM SDU_Tools.UserTypes 
ORDER BY UserTypeID;

SELECT * 
FROM SDU_Tools.RSCatalogTypes 
ORDER BY CatalogTypeID;

SELECT ChineseNewYearDate 
FROM SDU_Tools.ChineseYears 
WHERE [Year] = 2019;

SELECT SDU_Tools.DateOfChineseNewYear(2019);

SELECT SDU_Tools.ChineseNewYearAnimalName(2019);

SELECT * 
FROM SDU_Tools.LatestSQLServerBuilds 
ORDER BY SQLServerVersion DESC, Build;

SELECT SDU_Tools.AddWeekdays('20190201', 5);

SELECT SDU_Tools.TruncateTrailingZeroes(123.11);

EXEC SDU_Tools.RetrustForeignKeysInCurrentDatabase 
     @SchemasToInclude = N'ALL', 
     @TablesToInclude = N'ALL'; 

EXEC SDU_Tools.RetrustCheckConstraintsInCurrentDatabase
     @SchemasToInclude = N'ALL', 
     @TablesToInclude = N'ALL'; 
GO

SET NOCOUNT ON;
DECLARE @SQL nvarchar(max);

EXEC SDU_Tools.ScriptDatabaseObjectPermissionsInCurrentDatabase @SQL OUTPUT;

EXEC SDU_Tools.ExecuteOrPrint @SQL;
GO

SELECT SDU_Tools.NumberOfTokens(N'hello, there, greg', N',');

SELECT SDU_Tools.ExtractToken(N'hello, there, greg', N',', 1, 1);

EXEC SDU_Tools.ListEmptyUserTablesInCurrentDatabase
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL';

SELECT '-->' + SDU_Tools.SingleSpaceWords('Test String') + '<--';

SELECT SDU_Tools.IsIPv4Address('alsk.sdfsf..s.dfsdf.s.df');

SELECT SDU_Tools.ROT13('This is a fairly standard sentence');

SELECT SDU_Tools.DaysInMonth(SYSDATETIME());

SELECT LEN('Hello  '), LEN('Hello');

SELECT SDU_Tools.SQLServerVersion();

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

SELECT * FROM SDU_Tools.TimePeriodsBetween('00:00:00', '23:59:59', 15);
GO

CREATE SCHEMA XYZABC AUTHORIZATION dbo;
GO

CREATE TABLE XYZABC.TABLE1 (ID int);
GO

EXEC SDU_Tools.EmptySchemaInCurrentDatabase @SchemaName = N'XYZABC';
GO

DROP SCHEMA XYZABC;
GO

SELECT N'->' + SDU_Tools.NullIfBlank('xx ') + N'<-';

SELECT SDU_Tools.NullIfZero(18.2);

SELECT * FROM SDU_Tools.DatesInPeriod('20170101', 1, 'YEAR');

SELECT SDU_Tools.WeekdayOfMonth(2020, 2, 1); -- first weekday of Feb 2020

SELECT SDU_Tools.DayNumberOfMonth(2020, 2, 1, 1); -- first Sunday of Feb 2020

SELECT * 
FROM SDU_Tools.Currencies
ORDER BY CurrencyCode;

SELECT * 
FROM SDU_Tools.Countries
ORDER BY CountryCode;

SELECT * 
FROM SDU_Tools.CurrenciesByCountry
ORDER BY CountryCode, CurrencyCode;

SELECT * 
FROM SDU_Tools.DatesBetweenNoWeekends('20200101', '20200131')
ORDER BY DateValue;

SELECT SDU_Tools.InitialsFromName(N'Mary Johanssen', N'');
SELECT SDU_Tools.InitialsFromName(N'Mary Johanssen', N' ');
SELECT SDU_Tools.InitialsFromName(N'Thomas', N' ');
SELECT SDU_Tools.InitialsFromName(N'Test Test', NULL);

SELECT * FROM SDU_Tools.DateDimensionPeriodColumns('20200131', 7, SYSDATETIME());

SELECT SDU_Tools.StartOfYear('20180713');
SELECT SDU_Tools.EndOfYear('20180713');
SELECT SDU_Tools.StartOfWeek('20200713');
SELECT SDU_Tools.EndOfWeek('20200713');
SELECT SDU_Tools.StartOfWorkingWeek('20200713');
SELECT SDU_Tools.EndOfWorkingWeek('20200713');

SELECT SDU_Tools.CurrentSessionDecimalSeparator();
SELECT SDU_Tools.CurrentSessionThousandsSeparator();
SELECT SDU_Tools.StripDiacritics(N'śŚßťŤÄÅàá');

SELECT SDU_Tools.DateTime2ToUnixTime(SYSDATETIME());
SELECT SDU_Tools.UnixTimeToDateTime2(1586689900);

SELECT SDU_Tools.CobolCase(N'the  quick   brown fox consumed a macrib at mcdonalds');

SELECT SDU_Tools.DateOfOrthodoxEaster(2020);

SELECT SDU_Tools.WeekdayOfSameWeek('20201022', 1); 
SELECT SDU_Tools.NearestWeekday('20201022', 3);

SELECT * FROM SDU_Tools.WeekdayAcrossYears(20, 11, 2021, 2030);

EXEC SDU_Tools.ListUseOfDeprecatedDataTypesInCurrentDatabase 
     @SchemasToList = N'ALL', 
     @TablesToList = N'ALL', 
     @ColumnsToList = N'ALL';

SELECT SDU_Tools.SQLServerType();

