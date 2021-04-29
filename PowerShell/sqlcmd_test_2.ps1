param
(
[System.Management.Automation.CredentialAttribute()]
$Credential
)
#sqlcmd -S "ssb-ssb-server.database.windows.net"  -d SSBRPTest -G -U bgucuk@ssbinfo.com -Q "print ('abc')"
invoke-sqlcmd -ServerInstance "ssb-ssb-server.database.windows.net" -Database SSBRPTest -Credential $Credential -Query "Select Getdate() as [GetDate];" | out-file -Filepath "E:\Workspaces\z_output.txt"


<#
#From PS ISE execute as following
Clear-Host;
$cred = Get-Credential
E:\Workspaces\bgucuk\sqlcmd_test_2.ps1 -Credential $cred;

#>