
CREATE FUNCTION [dbo].[fnParseStringTSQL] (@string NVARCHAR(MAX),@separator NCHAR(1))
RETURNS @parsedString TABLE (string NVARCHAR(MAX))
AS 
BEGIN
   DECLARE @position int
   SET @position = 1
   SET @string = @string + @separator
   WHILE charindex(@separator,@string,@position) <> 0
      BEGIN
         INSERT into @parsedString
         SELECT substring(@string, @position, charindex(@separator,@string,@position) - @position)
         SET @position = charindex(@separator,@string,@position) + 1
      END
     RETURN
END
go

SELECT * FROM dbo.fnParseStringTSQL('SQL Server 2000|SQL Server 2005|SQL Server 2008|SQL Server 7.0','|')
GO
SELECT * FROM dbo.fnParseStringTSQL('Apple,Banana,Pear',',')

