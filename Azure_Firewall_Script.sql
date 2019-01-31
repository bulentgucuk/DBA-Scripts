-- this is for the Azure SQL Server (logical server)
-- execute in the master database
SELECT * FROM sys.firewall_rules
WHERE NAME LIKE '%bgucuk%'
ORDER BY start_ip_address, name;

/****
EXECUTE sp_set_firewall_rule
	  @name = N'bgucuk_ssbinfo.com:Home:2018-02-01 00:00:00'
	, @start_ip_address = '71.33.200.167'
	, @end_ip_address = '71.33.200.167'

****/

/***
EXECUTE sp_set_firewall_rule
	  @name = N'bgucuk_ssbinfo.com:Home:2019-01-17'
	, @start_ip_address = '71.33.172.178'
	, @end_ip_address = '71.33.172.178';
***/
GO
SELECT	*
FROM	sys.firewall_rules;
GO