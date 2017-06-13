create procedure dbo.sp_calc_median
 (@tablename varchar(50),
  @columnname varchar(50),
  @result sql_variant OUTPUT)
as
begin
  declare @sqlstmt varchar(200)
  declare @midCount int
  set nocount on
  set @sqlstmt = 'insert #tempmedian select ' + @columnname +
      ' from ' + @tablename + ' order by 1 asc '
  create table #tempmedian (col sql_variant)
  exec (@sqlstmt)
  declare c_med cursor scroll for select * from #tempmedian
  select @midCount = round ( count(*) * 0.5,0 ) from #tempmedian
  open c_med
        fetch absolute @midCount from c_med into @result
  close c_med
  deallocate c_med
  drop table #tempmedian
end
go

--sample table
CREATE TABLE [dbo].[TestTable](
 [id] [int] IDENTITY(1,1) NOT NULL,
 [testID] [int] NULL,
 [testName] [varchar](50) NULL,
 [testDate] [date] NULL,
 CONSTRAINT [PK_TestTable] PRIMARY KEY CLUSTERED 
([id] ASC) )
-- sample data
INSERT INTO TestTable (testID, testName, testDate)
SELECT 1, 'Dave', '2000-11-01' UNION
SELECT 2, 'Mike', '1995-01-11' UNION
SELECT 3, 'Sue' , '1965-07-14' UNION
SELECT 4, 'Jill', '2001-03-07' UNION
SELECT 5, 'Abe' , '2005-09-13'
-- sample run
DECLARE @result sql_variant 
EXEC dbo.sp_calc_median 'dbo.TestTable', 'testID', @result OUTPUT
SELECT @result
EXEC dbo.sp_calc_median 'dbo.TestTable', 'testName', @result OUTPUT
SELECT @result
EXEC dbo.sp_calc_median 'dbo.TestTable', 'testDate', @result OUTPUT
SELECT @result
-- output from above run
3
Jill
2000-11-01

DECLARE @res sql_variant -- declaring a sql_variant column
EXEC sp_calc_median 'northwind..products','productname',@res OUTPUT 
PRINT convert(nvarchar,@res) 
EXEC sp_calc_median 'northwind..products','UnitPrice',@res OUTPUT
PRINT convert(real,@res) 
-- output from above run  
Maxilaku
19.5