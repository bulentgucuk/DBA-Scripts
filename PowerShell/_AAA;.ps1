Clear-Host;
choco list --local-only; 
choco outdated;
<#
choco uninstall dbatools --all-versions -y
choco install dbatools -y

choco upgrade azcopy10 -y
choco upgrade chocolatey -y
choco upgrade dbatools -y
choco upgrade git -Y
choco upgrade roundhouse -y
choco upgrade sysinternals -y

choco search dbaclone --remote
choco --help
choco source

#>

$now = Get-Date 
$now.AddDays(-1)
Get-Uptime -Since

rh --help


