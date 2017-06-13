IF OBJECT_ID (N'tempdb.dbo.#GetDupIdx') IS NOT NULL

DROP TABLE #GetDupIdx

CREATE TABLE #GetDupIdx

(

[Database Name] varchar(500),

[Table Name] varchar(1000),

[Index Name] varchar(1000),

[Indexed Column Names] varchar(1000),

[Index Type] varchar(50),

[Unique] char(1),

[Primary Key] char(1),

[Page Count] int,

[Size (MB)] int,

[Fragment %] int

)

Declare @db_name sysname

DECLARE c_db_names CURSOR FOR

SELECT name

FROM sys.databases

WHERE name NOT IN('tempdb') --can exclude other databases

OPEN c_db_names

FETCH c_db_names INTO @db_name

WHILE @@Fetch_Status = 0

BEGIN

EXEC('Use ' + @db_name + ';

WITH FindDupIdx AS

(

SELECT DISTINCT sys.objects.name AS [Table Name],

sys.indexes.name AS [Index Name],

sys.indexes.type_desc AS [Index Type],

Case sys.indexes.is_unique

When 1 then ''Y''

When 0 then ''N'' End AS [Unique],

Case sys.indexes.is_primary_key

When 1 then ''Y''

When 0 then ''N'' End AS [Primary Key],

SUBSTRING((SELECT '', '' + sys.columns.Name as [text()]

FROM sys.columns

INNER JOIN sys.index_columns

ON sys.index_columns.column_id = sys.columns.column_id

AND sys.index_columns.object_id = sys.columns.object_id

WHERE sys.index_columns.index_id = sys.indexes.index_id

AND sys.index_columns.object_id = sys.indexes.object_id

AND sys.index_columns.is_included_column = 0

ORDER BY sys.columns.name

FOR XML Path('''')), 2, 10000) AS [Indexed Column Names],

ISNULL(SUBSTRING((SELECT '', '' + sys.columns.Name as [text()]

FROM sys.columns

INNER JOIN sys.index_columns

ON sys.index_columns.column_id = sys.columns.column_id

AND sys.index_columns.object_id = sys.columns.object_id

WHERE sys.index_columns.index_id = sys.indexes.index_id

AND sys.index_columns.object_id = sys.indexes.object_id

AND sys.index_columns.is_included_column = 1

ORDER BY sys.columns.name

FOR XML Path('''')), 2, 10000), '''') AS [Included Column Names],

sys.indexes.index_id, sys.indexes.object_id

FROM sys.indexes

INNER JOIN SYS.index_columns

ON sys.indexes.index_id = SYS.index_columns.index_id

AND sys.indexes.object_id = sys.index_columns.object_id

INNER JOIN sys.objects

ON sys.OBJECTS.object_id = SYS.indexes.object_id

WHERE sys.objects.type = ''U''

)

INSERT INTO #GetDupIdx (

[Database Name],[Table Name],[Index Name],[Indexed Column Names],

[Index Type],[Unique], [Primary Key],

[Page Count],[Size (MB)],[Fragment %]

)

SELECT DB_NAME(),FindDupIdx.[Table Name],

FindDupIdx.[Index Name],

FindDupIdx.[Indexed Column Names],

FindDupIdx.[Index Type],

FindDupIdx.[Unique],

FindDupIdx.[Primary Key],

PhysicalStats.page_count as [Page Count],

CONVERT(decimal(18,2), PhysicalStats.page_count * 8 / 1024.0) AS [Size (MB)],

CONVERT(decimal(18,2), PhysicalStats.avg_fragmentation_in_percent) AS [Fragment %]

FROM FindDupIdx

INNER JOIN sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL)

AS PhysicalStats

ON PhysicalStats.index_id = FindDupIdx.index_id

AND PhysicalStats.object_id = FindDupIdx.object_id

WHERE (SELECT COUNT(*) as Computed

FROM FindDupIdx Summary2

WHERE Summary2.[Table Name] = FindDupIdx.[Table Name]

AND Summary2.[Indexed Column Names] = FindDupIdx.[Indexed Column Names]) > 1

AND FindDupIdx.[Index Type] <> ''XML''

ORDER BY [Table Name], [Index Name], [Indexed Column Names], [Included Column Names]

')

FETCH c_db_names INTO @db_name

END

CLOSE c_db_names

DEALLOCATE c_db_names

SELECT * FROM #GetDupIdx 