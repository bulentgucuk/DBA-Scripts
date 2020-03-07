-- returns each rows datalenght for the table
-- where clause can be added before the order by to limit the number of records analyzed for datalenght calculation
DECLARE	@table nvarchar(128)
DECLARE	@idcol nvarchar(128)
DECLARE	@sql nvarchar(2000)

SELECT	@table = 'audit.AuditLogHistory'
SELECT	@idcol = 'AuditId, StartDateTime'
SELECT	@sql =	'select ' + @idcol +' , (0'

SELECT	@sql = @sql + ' + isnull(datalength(' + name + '), 1)'
FROM	syscolumns
WHERE	id = object_id(@table)

SELECT	@sql = @sql + ') as rowsize from ' + @table + ' order by rowsize desc'

PRINT @sql

--EXEC sp_executesql @stmt = @sql;
