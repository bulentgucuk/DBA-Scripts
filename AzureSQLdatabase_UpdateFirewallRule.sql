/****
-- In the master database l2oqghb8m9.database.windows.net
SELECT * 
FROM	sys.firewall_rules 
WHERE	name like '%Ginger%'
ORDER BY start_ip_address, name;
***/


-- In the master database l2oqghb8m9.database.windows.net
exec sp_set_firewall_rule N'Ginger - home office', '71.206.124.94', '71.206.124.94'; 

