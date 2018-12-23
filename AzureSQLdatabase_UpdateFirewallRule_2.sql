-- In the Azure SQL Master database.
SELECT * FROM sys.firewall_rules ORDER BY start_ip_address, name;

/**
EXEC sp_set_firewall_rule 
	 N'Carli.Friss_ucdenver.edu_IP'
	, '132.194.175.154'
	, '132.194.175.154'
****/

