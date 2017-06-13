
DECLARE @xmlSnippet XML
DECLARE @id SMALLINT
DECLARE @value VARCHAR(20) 
SET @xmlSnippet =
'<ninjaElement id="1">SQL Server Ninja</ninjaElement>
<ninjaElement id="2">Oracle Ninja</ninjaElement>
<ninjaElement id="3">MySQL Ninja</ninjaElement>
' 
-- this is what we will look for
SET @id    = 2
SET @value ='SQL Server Ninja' 
-- note exist() will return only either :-- 1 (true) or 0 (false) 

-- check if a node called ninjaElement exists-- at any level in the XML snippet
SELECT @xmlSnippet.exist('//ninjaElement') 

-- check if a node called bar exists
SELECT @xmlSnippet.exist('//bar') 

-- check if attribute id exists anywhere
SELECT @xmlSnippet.exist('//@id') 

-- check if attribute id exists within a ninjaElement tag
SELECT @xmlSnippet.exist('//ninjaElement[@id]') 

-- check if the id attribute equals to what we saved-- in the @id variable
SELECT @xmlSnippet.exist('/ninjaElement[@id=sql:variable("@id")]') 

-- check if the node text equals to what-- we saved in the @value variable
SELECT @xmlSnippet.exist('/ninjaElement1')

