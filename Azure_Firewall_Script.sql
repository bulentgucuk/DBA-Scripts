-- this is for the Azure SQL Server (logical server)
-- execute in the master database
SELECT	*
FROM	sys.firewall_rules
WHERE	NAME LIKE '%gucuk%'
ORDER BY name;


/***
exec sp_set_firewall_rule 
	@name = N'bgucuk_ssbinfo.com_home_office',
	@start_ip_address = '71.211.249.39',
	@end_ip_address = '71.211.249.39'
	
exec sp_delete_firewall_rule
	@name = N'SSB_bgucuk@ssbinfo.com_HomeOffice_2018-3-27_10-26-34';
	
***/
