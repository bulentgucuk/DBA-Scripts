@echo =========  SQL Server Ports  ===================
@echo Enabling SQLServer default instance port 1433
netsh firewall set portopening TCP 1433 "SQLServer" 
@echo Enabling Dedicated Admin Connection port 1434
netsh firewall set portopening TCP 1434 "SQL Admin Connection" 
@echo Enabling conventional SQL Server Service Broker port 4022  
netsh firewall set portopening TCP 4022 "SQL Service Broker" 
@echo Enabling Transact-SQL Debugger/RPC port 135 
netsh firewall set portopening TCP 135 "SQL Debugger/RPC" 
@echo =========  Analysis Services Ports  ==============
@echo Enabling SSAS Default Instance port 2383
netsh firewall set portopening TCP 2383 "Analysis Services" 
@echo Enabling SQL Server Browser Service port 2382
netsh firewall set portopening TCP 2382 "SQL Browser" 
@echo =========  Misc Applications  ==============
@echo Enabling HTTP port 80 
netsh firewall set portopening TCP 80 "HTTP" 
@echo Enabling SSL port 443
netsh firewall set portopening TCP 443 "SSL" 
@echo Enabling port for SQL Server Browser Service's 'Browse' Button
netsh firewall set portopening UDP 1434 "SQL Browser" 
@echo Allowing multicast broadcast response on UDP (Browser Service Enumerations OK)
netsh firewall set multicastbroadcastresponse ENABLE 