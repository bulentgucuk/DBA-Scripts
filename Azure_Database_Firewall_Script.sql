-- this is for the Azure SQL Database
-- execute in the specific database you need to allow traffic to
SELECT	* FROM	sys.database_firewall_rules

GO

/****
EXEC sp_set_database_firewall_rule 
	  @name = N'jrooks_ssbinfo.com_ home office_2018-05-29'
	, @start_ip_address = '73.229.224.123'
	, @end_ip_address = '73.229.224.123';

****/
