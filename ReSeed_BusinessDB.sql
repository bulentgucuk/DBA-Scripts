Set NoCount On
Declare @IdentityTables Table (TableID Int Identity (1, 1) Not Null, ColumnName VarChar (255), TableName VarChar(255))
Insert Into @IdentityTables (ColumnName, TableName)
Select C.[name] 'ColumnName', O.[name] 'TableName' From syscolumns C 
Inner Join sysobjects O On C.id = O.id
Where C.status = 0x80 And O.[name] <> 'dtproperties' Order By O.[name]

Declare @Count1 Int, @Counter1 Int, @Tablename1 VarChar(255), @ColumnName1 VarChar(255), @SQL1 VarChar(2000)
Set @Count1 = (Select Max(TableID) From @IdentityTables)
Set @Counter1 = (Select Min(TableID) From @IdentityTables)
If Object_ID('tempdb.dbo.#IdentityValues') Is Not Null Drop Table #IdentityValues
Create Table #IdentityValues (ValueID Int Identity (1, 1) Not Null, ColumnName VarChar (255), TableName VarChar(255), 
CurrentValue Int, NewValue Int)
While @Counter1 <= @Count1
Begin
Set @Tablename1 = (Select TableName From @IdentityTables Where TableID = @Counter1)
Set @ColumnName1 = (Select ColumnName From @IdentityTables Where TableID = @Counter1)
Set @SQL1 = 'Select ''' + @ColumnName1 + ''' As ColumnName, ''' + @Tablename1 + ''' As TableName, Max(' + 
@ColumnName1 + ') As CurrentValue, Convert(Int, (Convert(Numeric (20, 7), Max(' + @ColumnName1 + ')) * 1.1)) As NewValue From ' + @Tablename1
Insert Into #IdentityValues (ColumnName, TableName, CurrentValue, NewValue)
Exec(@SQL1)
Set @Counter1 = @Counter1 + 1
End

Declare @Count2 Int, @Counter2 Int, @CurrentValue Int, @NewValue Int, 
@Tablename2 VarChar(255), @ColumnName2 VarChar(255)
Declare @Changes Table (ChangeID Int Identity (1, 1) Not Null, ColumnName VarChar (255), TableName VarChar(255), 
CurrentValue Int, NewValue Int)
Insert Into @Changes (ColumnName, TableName, CurrentValue, NewValue)
Select ColumnName, TableName, CurrentValue, NewValue From #IdentityValues Where CurrentValue > 1500
Set @Count2 = (Select Max(ChangeID) From @Changes)
Set @Counter2 = (Select Min(ChangeID) From @Changes)
While @Counter2 <= @Count2
Begin
Set @Tablename2 = (Select TableName From @Changes Where ChangeID = @Counter2)
Set @ColumnName2 = (Select ColumnName From @Changes Where ChangeID = @Counter2)
Set @CurrentValue = (Select CurrentValue From @Changes Where ChangeID = @Counter2)
Set @NewValue = (Select NewValue From @Changes Where ChangeID = @Counter2)
Print 'Table: ' + @Tablename2 + ', Column: ' + @ColumnName2 + '. Changed from ' + 
Convert(VarChar(50), @CurrentValue) + ' to ' + Convert(VarChar(50), @NewValue)
DBCC CheckIdent (@Tablename2, ReSeed, @NewValue)
Set @Counter2 = @Counter2 + 1
End

Drop Table #IdentityValues
Set NoCount On

