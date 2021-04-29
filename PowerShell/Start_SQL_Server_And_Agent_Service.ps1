<#
This script starts the SQL Server and SQL Server Agent service if one or both are
not in a running status.
#>
Clear-Host
#SQL Server Service status
$SQLServerService = Get-Service | Where {$_.name -like 'MSSQL*' -and $_.StartType -eq "Automatic" -and $_.DisplayName -like "SQL Server*" } | Select-Object NAME, STATUS, StartType
#$SQLServerService.Name

# Start the server if it's not in a running status
if ($SQLServerService.Status -ne "Running")
    {
    Write-Output $SQLServerService.Name
    #Start-Service -Name $SQLServerService.Name
    }

#SQL Server Agent Service status
$SQLServerAgentService = Get-Service | Where {$_.name -like 'SQLAgent*' -and $_.StartType -eq "Automatic" -and $_.DisplayName -like "SQL Server Agent*" } | Select-Object NAME, STATUS, StartType
#$SQLServerAgentService.Name

# Start the SQL Server Agent if it's not in a running status
if ($SQLServerAgentService.Status -ne "Running")
    {
    Write-Output $SQLServerAgentService.Name
    #Start-Service -Name $SQLServerAgentService.Name
    }