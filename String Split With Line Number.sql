CREATE FUNCTION dbo.SplitWithLineNumber (@sep char(1), @s varchar(max))
RETURNS table
AS
RETURN (
 WITH splitter_cte AS (
 SELECT CHARINDEX(@sep, @s) as pos,
        cast(0 as bigint) as lastPos,
        0 as LineNumber
 UNION ALL
 SELECT CHARINDEX(@sep, @s, pos + 1),
        cast(pos as bigint),
        LineNumber + 1 as LineNumber
 FROM splitter_cte
 WHERE pos &amp;amp;amp;gt; 0
 )
 SELECT LineNumber,
        SUBSTRING(@s,
                 lastPos + 1,
                 case when pos = 0 then 2147483647
                      else pos - lastPos -1 end) as chunk
 FROM splitter_cte
 );
 GO
 
 --Samples
 
 SELECT *
 FROM dbo.SplitWithLineNumber (' ',
          'the quick brown dog jumped over the lazy fox')
OPTION(MAXRECURSION 0);

SELECT *
 FROM dbo.SplitWithLineNumber (',',
          'this,is,my,comma,separated,list,it,has,several,items,split,up,by,commas')
OPTION(MAXRECURSION 0);