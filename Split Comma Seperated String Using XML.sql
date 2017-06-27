DECLARE
	  @S VARCHAR(512)
	, @Split CHAR(1)
	, @X XML;

SELECT
	  @S = '1,2,3,4,5'
	, @Split = ',' ;

SELECT	@X = CONVERT(XML,' <root> <s>' + REPLACE(@S,@Split,'</s> <s>') + '</s>   </root> ')

SELECT	[Value] = T.c.value('.','varchar(20)')
FROM	@X.nodes('/root/s') T(c);
