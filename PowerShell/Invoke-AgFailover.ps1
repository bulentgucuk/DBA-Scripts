<#
Author: Frank Gill
Date: 2017-11-17
#>
function Invoke-AgFailover {
<#
.SYNOPSIS
Checks specified instance for healthy, synchronous Availability Groups running as secondary and
fails them over
.DESCRIPTION
Checks the instance passed in for healthy, synchronous Availability Groups running as secondary and
fails them over.  If the instance is not hosting secondary replicas, a message will be output.
If there are AGs running as secondary, a message will output for each, including AG name, destination,
and failover duration.
.EXAMPLE
Invoke-AgFailover -Instance YourSecondaryInstance -NoExec 0;
Any Availability Groups running as secondary on YourSecondaryInstance will be failed over.
.EXAMPLE
Invoke-AgFailover -Instance YourSecondaryInstance -NoExec 1;
If Availability Groups are running as secondary on YourSecondaryInstance, T-SQL commands for each AG failover
will be generated and written to C:\AGFailover\failover_YourAgName_YYYYMMDD_HHMMSS.sql.
.PARAMETER Instance
The instance to check for secondary replicas.
.PARAMETER NoExec
Set to 1 to generate T-SQL script for failover.
#>
[CmdletBinding()]
param
(
[Parameter(Mandatory=$True,
Position = 1,
ValueFromPipeline=$True,
ValueFromPipelineByPropertyName=$True,
HelpMessage='Which instance do you want to check for secondary replicas?')]
[Alias('secondaryinstance')]
[string[]]$instance,
 
[Parameter(Mandatory=$True,
Position = 2,
ValueFromPipeline=$True,
ValueFromPipelineByPropertyName=$True,
HelpMessage='Set to 1 if you want to execute the database restore.  Otherwise ')]
[Alias('dontrun')]
[string]$noexec
)
process
{
<# If the $noexec is set to 1, create file path to hold out files #>
if($noexec -eq 1)
{
$rundate = Get-Date -Format yyyyMMdd_HHmmss;
$outpath = "C:\AgFailover";
if((Test-Path -Path $outpath) -eq $true)
{
Remove-Item -Path "$outpath\*" -Recurse;
}
else
{
New-Item -Path $outpath -ItemType Directory;
}
}
 
<# Create query to check for failover-eligible AGs #>
$query = "SELECT g.[name], ar.replica_server_name
FROM sys.dm_hadr_availability_replica_states r
INNER JOIN sys.availability_replicas ar
ON ar.group_id = r.group_id
AND ar.replica_id = r.replica_id
INNER JOIN sys.availability_groups g
ON g.group_id = ar.group_id
WHERE r.role_desc = N'SECONDARY'
AND r.recovery_health_desc = N'ONLINE'
AND r.synchronization_health_desc = N'HEALTHY'
AND ar.availability_mode_desc = N'SYNCHRONOUS_COMMIT';"
 
<# Execute failover-eligible query #>
$secondaries = Invoke-Sqlcmd -ServerInstance "$instance" -Database master -Query $query;
 
<# Output message if there are no failover-eligible AGs #>
if($secondaries.Count -eq 0)
{
Write-Output "There are no Availability Group replicas available to fail over to $instance."
}
 
<# If eligible AGs exist, loop through them #>
foreach($secondary in $secondaries)
{
$secreplica = $secondary.replica_server_name;
$ag = $secondary.name;
 
$query = "ALTER AVAILABILITY GROUP $ag FAILOVER;"
 
<# If $noexec is set to 0, execute the AG failover
and output a message when complete #>
if($noexec -eq 0)
{
$starttime = Get-Date;
Invoke-Sqlcmd -ServerInstance "$instance" -Database master -Query $query;
$endtime = Get-Date;
$duration = (New-TimeSpan -Start $starttime -End $endtime).Seconds;
Write-Output "Failed Availability Group $ag to replica $instance in $duration seconds";
}
<# If $noexec is not set to 0, write a file out to the path built above for each AG #>
else
{
$comment = "/* Run against instance $instance */" ;
$comment | Out-File -FilePath "$outpath\failover_$ag`_$rundate.sql" -Append;
$use = "USE master;";
$use | Out-File -FilePath "$outpath\failover_$ag`_$rundate.sql" -Append;
$query | Out-File -FilePath "$outpath\failover_$ag`_$rundate.sql" -Append;
}
}
}
}