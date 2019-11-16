<#############################################################################################
 Created By:   Bulent Gucuk
 Create Date:  2019.06.04
 Creation:     Script to deploy new Azure SQL Database to existing Azure SQL server
               using the ssb-dw-template as the source.
               The script basically copies the source database with a new name.
			   Make sure you have AZ powershell module installed and logged in before.
			   Update the target server name and database name and service objective which 
			   is service tier.
##############################################################################################>
Clear-Host
#Import-Module az
#Login-AzAccount

# The SubscriptionId in which to create these objects
$SubscriptionId = 'e7516aa0-af29-4378-a495-aff8aac8ced2'

# Set the resource group name
$resourceGroupName = "rg-ssbclientdatawarehouse"

# Set server name - the logical server name has to be unique in the system and lowercase
$targetserverName = "ssb-pegula-db-01"

# The database name must be lowercase and service objective (azure tier)
$targetdatabaseName = "ssb-pegula-enterprise"
$serviceObjectiveName = "S1"

# Source Database Server and Source template database
$sourceServerName = "ssb-ssb-server"
$sourceDatabaseName = "ssb-dw-template"

# Set context to subscription 
Set-AzContext -SubscriptionId $subscriptionId

# New database copy using template database with the new database name to the existing server
New-AzSqlDatabaseCopy `
    -ResourceGroupName $resourceGroupName `
    -ServerName $sourceServerName `
    -DatabaseName $sourceDatabaseName `
    -CopyResourceGroupName $resourceGroupName `
    -CopyServerName $targetserverName `
    -CopyDatabaseName $targetdatabaseName `
    -ServiceObjectiveName $serviceObjectiveName


