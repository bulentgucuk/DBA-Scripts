IF OBJECT_ID(N'tempdb..#Results') IS NOT NULL
 DROP TABLE #Results
GO
DECLARE @SQL NVARCHAR(4000);
DECLARE @Schema SYSNAME;
DECLARE @Table SYSNAME;
DECLARE @PartitionNumber INT;
CREATE TABLE #Results (
 [Table] SYSNAME,
 [Schema] SYSNAME,
 IndexID INT,
 PartitionNumber INT,
 [CurrentSize(kb)] INT,
 [CompressedSize(kb)] INT,
 [SampleCurrentSize(kb)] INT,
 [SampleCompressedSize(kb)] INT)

DECLARE TableCursor CURSOR FOR
 select s.name, o.name
 FROM sys.objects o
 JOIN sys.schemas s
 ON s.schema_id = o.schema_id
 WHERE o.[type] = 'U'
 ORDER BY 1,2

SET NOCOUNT ON;

OPEN TableCursor;
FETCH NEXT FROM TableCursor INTO @Schema,@Table
WHILE @@FETCH_STATUS = 0 
 BEGIN
 SET @SQL = '
 INSERT INTO #Results 
 ([Table],[Schema],IndexID,PartitionNumber,[CurrentSize(kb)],[CompressedSize(kb)],[SampleCurrentSize(kb)],[SampleCompressedSize(kb)]) 
 EXEC sp_estimate_data_compression_savings ''' + @Schema + ''',''' + @Table + ''',NULL,NULL,''ROW'';';
 --PRINT @SQL;
 EXEC sp_executeSQL @SQL; 
 FETCH NEXT FROM TableCursor INTO @Schema,@Table;
 END;
CLOSE TableCursor;
DEALLOCATE TableCursor;

--SELECT [Schema], [Table], IndexID, PartitionNumber, [CurrentSize(kb)],CONVERT(NUMERIC(12,2), ROUND(CASE WHEN [CurrentSize(kb)] = 0 THEN 100 ELSE [CompressedSize(kb)] * 100. / [CurrentSize(kb)] END,2)) AS [Compression], [CompressedSize(kb)] 
DECLARE CompressionCursor CURSOR FOR
 SELECT [Schema], [Table], MAX(PartitionNumber) PartitionNumber
 FROM #Results r
 WHERE (IndexID = 0
 OR IndexID = 1 AND NOT EXISTS (Select 'x' FROM #Results r2 where r.[Schema] = r2.[Schema] and r.[Table] = r2.[Table] and r2.IndexID = 0))
 AND (ROUND(CASE WHEN [CurrentSize(kb)] = 0 THEN 100 ELSE [CompressedSize(kb)] * 100. / [CurrentSize(kb)] END,2) BETWEEN 0.01 AND 80.00)
 AND [CurrentSize(kb)] > 64
 GROUP BY [Schema], [Table]
 ORDER BY 1,2;

OPEN CompressionCursor;

FETCH NEXT FROM CompressionCursor INTO @Schema, @Table, @PartitionNumber;
WHILE @@FETCH_STATUS = 0 
 BEGIN
 SET @SQL = CASE WHEN EXISTS (SELECT * FROM #Results WHERE [Schema] = @Schema AND [Table] = @Table AND PartitionNumber > 1) THEN 'ALTER TABLE ' + @Schema + '.' + @Table + ' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = ROW,ONLINE = ON);'
 ELSE 'ALTER TABLE ' + @Schema + '.' + @Table + ' REBUILD WITH (DATA_COMPRESSION = ROW,ONLINE = ON);' END;
 PRINT @SQL;
-- EXEC sp_executeSQL @SQL; 
 FETCH NEXT FROM CompressionCursor INTO @Schema,@Table,@PartitionNumber;
 END;
CLOSE CompressionCursor;
DEALLOCATE CompressionCursor;
GO


select * from #Results