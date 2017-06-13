Declare @TableName VarChar(100), @SQL VarChar(1000)
Declare Cur_Tables Cursor For 
Select Name From sys.objects
Where ObjectProperty(Object_ID, 'IsUserTable') = 1
And ObjectProperty(Object_ID, 'IsView') = 0
And ObjectProperty(Object_ID, 'TableHasIndex') = 1
And Name != 'dtproperties'
Order By Name Asc
Open Cur_Tables
Fetch Next From Cur_Tables 
InTo @TableName
While @@Fetch_Status = 0
Begin
	Set @SQL = 'Alter Index All On ' + @TableName + ' Rebuild With (MAXDOP = 1)'
	Exec(@SQL)
   	FETCH NEXT FROM Cur_Tables 
   	INTO @TableName
END
CLOSE Cur_Tables
DEALLOCATE Cur_Tables
GO