###################################################################
# Copyright 2020 Brandon Leach
#
###################################################################

[CmdletBinding(supportsshouldprocess=$true)]
    param(
        [Parameter(mandatory=$true)]
        [string]$AGListener
    )


Import-Module dbatools
cls

######################################
#Build exclusion list
$ExclusionList = @( "sa", "sqlserver-1\sqlservernerd", "sqlserver-0\sqlservernerd", "contoso\sqlservernerd", "NT Service\winmgmt", "NT Service\SQLWriter", "NT Service\SQLTELEMETRY", "NT SERVICE\SQLSERVERAGENT", "NT Service\SQLIaaSExtensionQuery", "NT Service\SQLIaaSExtension", "NT Service\MSSQLSERVER", "NT AUTHORITY\SYSTEM", "contoso\sqlservice", "##MS_PolicyTsqlExecutionLogin##", "##MS_PolicyEventProcessingLogin##" )


######################################
#Get Primary and secondary replicas 
$Replicas = Get-DbaAgReplica -SqlInstance $AGListener

$PrimaryReplica = $Replicas | where-object { $_.Role -eq "Primary" }
$SecondaryReplicas = $Replicas | where-object { $_.Role -eq "Secondary" }

######################################
#Get array of login names
[string[]]$primaryLogins = Get-DbaLogin -SqlInstance $PrimaryReplica.Name -ExcludeLogin $ExclusionList | ForEach-Object { "$($_.Name)" }

######################################
#Iterate over secondaries and copy missing logins to them
$SecondaryReplicas | foreach-object { 

    ######################################
    #Get Logins from secondary
    [string[]]$SecondaryLogins = get-dbalogin -SqlInstance $_.Name  | ForEach-Object { "$($_.Name)" }

    ######################################
    #Find missing logins
    [string[]]$MissingLogins = $primaryLogins | where-object { $SecondaryLogins -Notcontains $_ }

    ######################################
    #Copy missing logins to replica
    Copy-DbaLogin -Source $PrimaryReplica.Name -Destination $_.Name -Login $MissingLogins -ExcludeSystemLogins

}