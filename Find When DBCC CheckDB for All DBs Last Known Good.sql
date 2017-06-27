CREATE TABLE #temp (
       Id INT IDENTITY(1,1), 
       ParentObject VARCHAR(255),
       [Object] VARCHAR(255),
       Field VARCHAR(255),
       [Value] VARCHAR(255)
)

CREATE TABLE #DBCCRes (
       Id INT IDENTITY(1,1)PRIMARY KEY CLUSTERED, 
       DBName sysname ,
       dbccLastKnownGood DATETIME,
       RowNum	INT
)

DECLARE
	@DBName SYSNAME,
	@SQL    varchar(512);

DECLARE dbccpage CURSOR
	LOCAL STATIC FORWARD_ONLY READ_ONLY
	FOR Select name
		from sys.databases
		where name not in ('tempdb');

Open dbccpage;
Fetch Next From dbccpage into @DBName;
While @@Fetch_Status = 0
Begin
Set @SQL = 'Use [' + @DBName +'];' +char(10)+char(13)
Set @SQL = @SQL + 'DBCC Page ( ['+ @DBName +'],1,9,3) WITH TABLERESULTS;' +char(10)+char(13)

INSERT INTO #temp
	Execute (@SQL);
Set @SQL = ''

INSERT INTO #DBCCRes
        ( DBName, dbccLastKnownGood,RowNum )
	SELECT @DBName, VALUE
			, ROW_NUMBER() OVER (PARTITION BY Field ORDER BY Value) AS Rownum
		FROM #temp
		WHERE field = 'dbi_dbccLastKnownGood';

TRUNCATE TABLE #temp;

Fetch Next From dbccpage into @DBName;
End
Close dbccpage;
Deallocate dbccpage;

SELECT DBName,dbccLastKnownGood
FROM #DBCCRes
WHERE RowNum = 1;

DROP TABLE #temp
DROP TABLE #DBCCRes