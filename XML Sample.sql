declare @x xml
set  @x = (select top 1 Content from dbo.dupes)

select @X RAW_XML
--SQL 2000 CODE

-- Initialize XML handle
DECLARE @hdoc INT    
EXEC sp_xml_preparedocument @hdoc OUTPUT, @x
 
--SQL 2005 CODE

SELECT 
  x.header.value('@VisitorSessionID[1]', 'varchar(50)') AS PARSED_XML
--,  x.header.value('Typex[1]', 'varchar(20)') AS Typex2
 FROM @x.nodes('//QuoteRequest') AS x(header)



