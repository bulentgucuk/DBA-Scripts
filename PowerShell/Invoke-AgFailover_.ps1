<#
Author: Bulent Gucuk
Date  : 2021-01-20
#>
<#
.SYNOPSIS
Checks specified AG listener for healthy, synchronous Availability Groups running as secondary and
fails them over
.DESCRIPTION
Checks the AG Listener passed in for healthy, synchronous Availability Groups running as secondary and
fails them over.  If there is no secondary replicas in health state, a message will be output.
If the fail over is initiated for the AG on the secondary, a message will output for each, including AG name, destination,
and failover duration.
.EXAMPLE
Below will not be executed since the -NoExec is set to 1
Invoke-AgFailover -AGListenerName FIIMSODPSQAG01 -AGName AG01 -Print 1 -NoExec 1;
.EXAMPLE
Below will be executed since -NoExec is 0 and AG running on the primary will be failed over to healty secondary.
Invoke-AgFailover -AGListenerName FIIMSODPSQAG01 -AGName AG01 -Print 1 -NoExec 0;
.PARAMETER AGListenerName
The AGListenerName to check for secondary replicas on the primary hosting the AG
.PARAMETER AGName
Name of the Availability Group to fail over to health secondary replica
.PARAMETER Print
Set to 1 to print the TSQL commands to the host
.PARAMETER NoExec
Set to 0 to execute the failover and set to 1 for what if
#>
[CmdletBinding(supportsshouldprocess=$true)]
    param(
        [Parameter(mandatory=$true)]
        [string]$AGListenerName,
        [Parameter(mandatory=$true)]
        [string]$AGName,
        [Parameter(mandatory=$true)]
        [bool]$Print,
        [Parameter(mandatory=$true)]
        [bool]$NoExec
    )


#Replica query to list all the nodes and health state
$Replicas = "SELECT	cn.group_name
	, cn.node_name
    , rs.role_desc
	, gs.synchronization_health_desc
FROM	sys.dm_hadr_availability_replica_cluster_nodes AS cn
	INNER JOIN sys.dm_hadr_availability_replica_cluster_states AS cs ON cs.replica_server_name = cn.replica_server_name
	INNER JOIN sys.dm_hadr_availability_group_states AS gs ON cs.group_id = gs.group_id
	INNER JOIN sys.dm_hadr_availability_replica_states AS rs ON cs.group_id = rs.group_id AND rs.replica_id = cs.replica_id
WHERE cn.group_name = '$AGName'
ORDER BY rs.role_desc;";

#Query and write the replicas query result
$Output = (Invoke-Sqlcmd -ServerInstance $AGListenerName -Query $Replicas | Format-Table)
If ($Print -eq 1)
    {
    Write-Host '********************************************************************************************'
    Write-Host "The replicas joined to the $AGName, here are the roles and health states for online servers."
    $Output;
    Write-Host '********************************************************************************************'
    }

#Add where filter to find out the secondary nodes in the AG
$Secondaries = (Invoke-Sqlcmd -ServerInstance $AGListenerName -Query $Replicas) | Where-Object {$_.role_desc -eq 'SECONDARY' -AND $_.synchronization_health_desc -eq 'HEALTHY'};

#this is for returning more than one record to test further down.
#$Secondaries = (Invoke-Sqlcmd -ServerInstance $AGListenerName -Query $Replicas) | Where-Object {$_.synchronization_health_desc -eq 'HEALTHY'};

#If no secondary replica is available break and write hos an error message
If($Secondaries.node_name.Length -eq 0)
    {
    Write-Host "There is NO secondary replica for the Availability Group $AGName to fail over!!!." -ForegroundColor Red -BackgroundColor Yellow
    Break
    }

#$Secondaries | Measure-Object -Line;

#If more than one secondary replica is available ask for preferred secondary node name to be passed in


#if one secondary node is available and in healthy state then proceed with fail over
$SecondaryNodeNameToFailOver = $Secondaries.node_name;

$FailoverTSQL = "ALTER AVAILABILITY GROUP $AGName FAILOVER;";

If ($Print -eq 1)
    {
    Write-Host '********************************************************************************************'
    Write-Host "Below failover statement will be executed on secondary node $SecondaryNodeNameToFailOver."
    $FailoverTSQL;
    Write-Host '********************************************************************************************'
    }

If ($NoExec -eq 0)
    {

    $StartTime = Get-Date;
    
    Invoke-Sqlcmd -ServerInstance $SecondaryNodeNameToFailOver -Database master -Query $FailoverTSQL;
    
    $EndTime = Get-Date;
    $Duration = (New-TimeSpan -Start $StartTime -End $EndTime).Seconds;
    Write-Host '********************************************************************************************';
    Write-Output "Failed Availability Group $AGName to replica $SecondaryNodeNameToFailOver in $Duration seconds";
    Write-Host '********************************************************************************************';
    }
