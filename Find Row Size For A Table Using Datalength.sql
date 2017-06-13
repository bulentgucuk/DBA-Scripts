-- returns each rows datalenght for the table
-- where clause can be added before the order by to limit the number of records analyzed for datalenght calculation
DECLARE	@table varchar(20)
DECLARE	@idcol varchar(10)
DECLARE	@sql varchar(1000)

SELECT	@table = 'asset.inventoryscan'
SELECT	@idcol = 'scandata'
SELECT	@sql =	'select ' + @idcol +' , (0'

SELECT	@sql = @sql + ' + isnull(datalength(' + name + '), 1)'
FROM	syscolumns
WHERE	id = object_id(@table)

SELECT	@sql = @sql + ') as rowsize from ' + @table + ' order by rowsize desc'

PRINT @sql

--EXEC (@sql)