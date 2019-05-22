-- This is for the Azure SQL Server (logical server)
-- Execute the script in the master database
SELECT	*
FROM	sys.firewall_rules
WHERE	NAME LIKE '%gucuk%'
ORDER BY name;

/***
DECLARE	@name NVARCHAR (128) = 'bgucuk_ssbinfo.com_home_office';
DECLARE @start_ip_address VARCHAR(50) = '71.33.218.156';
DECLARE	@end_ip_address VARCHAR(50);

EXEC sp_set_firewall_rule 
	@name = @name,
	@start_ip_address = @start_ip_address,
	@end_ip_address = @start_ip_address;


EXEC sp_delete_firewall_rule
	@name = N'';
	
***/
