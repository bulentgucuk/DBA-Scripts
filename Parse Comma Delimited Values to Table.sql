-- Parse comma delimited text into table
DECLARE @str VARCHAR(4000)
= '\\nq.corp\shared\Installs\DBAS,\\nq.corp\shared\Devcuts,\\nq.corp\shared\Installs\Licensed Software,\\nq.corp\shared\Installs\DBAS\IDERA 7.4\Client Install'
--= '6,7,7,8,10,12,13,14,16,44,46,47,394,396,417,488,714'


Declare	@x XML 

SELECT	@x = cast('<A>'+ REPLACE(@str,',','</A><A>')+ '</A>' AS XML)


SELECT	t.value('.', 'VARCHAR(512)') AS BackupToPath
--SELECT t.value('.', 'int') as inVal 

FROM	@x.nodes('/A') AS x(t)


