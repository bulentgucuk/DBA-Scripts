select	d.name,
		s.name,
		d.sid,
		s.sid
from	netquotewebsite.sys.database_principals as d
	inner join master.sys.server_principals as s 
		on d.name = s.name
where	s.name = 'iusr_sql_web_prod'


select	*
from	NetQuoteWebSite.sys.database_principals
where	name = 'iusr_sql_web_prod'

select	*
from	master.sys.server_principals
where	name = 'iusr_sql_bus_prod'



--if exists (
--		select	1
--		from	master.sys.server_principals
--		where	name = 'iusr_sql_web_prod'
--		)
--	begin
--		drop login iusr_sql_web_prod
--	end
--
--create login IUSR_SQL_WEB_PROD
--	with password = 'T5yqz7SP',
--	sid = 0x81341CD7A514D746A59712F660F31DE2,
--	default_database = netquotewebsite,
--	default_language = English,
--	check_expiration = OFF,
--	check_policy = ON

