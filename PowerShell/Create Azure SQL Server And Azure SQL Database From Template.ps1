#Import-Module Az
#Connect-AzAccount
#Get-AzSubscription
#Select-AzSubscription -Subscription e7516aa0-af29-4378-a495-aff8aac8ced2 #SSB Client Data Warehouses

# The SubscriptionId in which to create these objects
$SubscriptionId = 'e7516aa0-af29-4378-a495-aff8aac8ced2'

# Set the resource group name and location for your server
$resourceGroupName = "rg-ssbclientdatawarehouse"
$location = "westus"

# Set an admin login and password for your server
$adminSqlLogin = "ssbadmin"
$password = "L(fs[c7s5A=@Kk>"

# Set server name - the logical server name has to be unique in the system and lowercase
$serverName = "ssb-premierlacrosseleague-db-01"

# The database name must be lowercase and service objective (azure tier)
$databaseName = "ssb-premierlacrosseleague"
$serviceObjectiveName = "S1"

# Source Database Server and Source template database
$sourceServerName = "ssb-ssb-server"
$sourceDatabaseName = "ssb-dw-template"

#Storage for blob auditing
$BlobAuditingStorageAccountName = "saclientdwwest"

# The ip address range that you want to allow to access your server
# All Azure IP Addresses
$FirewallRuleNameAZips = "AllowAllWindowsAzureIps"
$startIPAZ = "0.0.0.0"
$endIPAZ = "0.0.0.0"
# SSB Denver Office
$FirewallRuleNameSSBDenverOffice = "SSB Denver Office"
$startIpSSBDenver = "63.239.148.82"
$endIpSSBDenver = "63.239.148.82"
# SSB Nashville Office
$FirewallRuleNameSSBNashvilleOffice = "SSB Nashville Office"
$startIpSSBNashvilleOffice = "96.82.234.65"
$endIpSSBNashvilleOffice = "96.82.234.65"

# Set context to subscription 
Set-AzContext -SubscriptionId $subscriptionId


# Create a resource group uncomment below if resource group does not exist
# $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a server with a system wide unique server name
New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

#Set Azure SQL Server Active Direcotry Admin to DBAdmins domain group
Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $resourceGroupName -ServerName $serverName -DisplayName "DBAdmins"

#Set Azure SQL Server blob storage auditing
Set-AzSqlServerAuditing -State Enabled -ResourceGroupName $resourceGroupName -ServerName $serverName -StorageAccountName $BlobAuditingStorageAccountName


# Create a server firewall rule that allows access from the specified IP range
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $serverName -FirewallRuleName $FirewallRuleNameAZips -StartIpAddress $startIPAZ -EndIpAddress $endIPAZ
$serverFirewallRule

$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $serverName -FirewallRuleName $FirewallRuleNameSSBDenverOffice -StartIpAddress $startIpSSBDenver -EndIpAddress $endIpSSBDenver
$serverFirewallRule

$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $serverName -FirewallRuleName $FirewallRuleNameSSBNashvilleOffice -StartIpAddress $startIpSSBNashvilleOffice -EndIpAddress $endIpSSBNashvilleOffice
$serverFirewallRule


New-AzSqlDatabaseCopy -ResourceGroupName $resourceGroupName -ServerName $sourceServerName -DatabaseName $sourceDatabaseName -CopyResourceGroupName $resourceGroupName -CopyServerName $serverName -CopyDatabaseName $databaseName -ServiceObjectiveName $serviceObjectiveName

