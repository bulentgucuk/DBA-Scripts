Clear-Host;
Import-Module AZ;

#Get the list of DNS alias for the server
Get-AzSqlServerDNSAlias `
    -ServerName "srv-asusfmc-01" `
    -ResourceGroupName "rg-ssbclientdatawarehouse";

#Remove the DNS alias to fix the issue
<#
Remove-AzSqlServerDnsAlias `
    -name "srv-asu-ssb-01" `
    -ServerName "srv-asusfmc-01" `
    -ResourceGroupName "rg-ssbclientdatawarehouse";
#>

#Create new DNS alias
<#
New-AzSqlServerDNSAlias `
    –ResourceGroupName  "rg-ssbclientdatawarehouse" `
    -ServerName         "srv-asusfmc-01" `
    -name "srv-asu-ssb-01";
#>
