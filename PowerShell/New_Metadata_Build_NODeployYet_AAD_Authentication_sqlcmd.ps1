# THIS IS THE NEW SSBMETADATA BUILD PROJECT
<#############################################################################################
 Created By:   Bulent Gucuk
 Create Date:  2020.01.31
 Creation:     Script to build SSB.DB.SSBMetadata project.
               Using a couple custom functions right now to build & deploy the project.               
               Use these snippets of code for more information on the functions 

               Get-Help -Name "Build-SQLChangeAutomationProject" -Full
               Get-Help -Name "Deploy-SQLChangeAutomationProject" -Full
               Get-Help -Name "Invoke-MsBuild" -Full
##############################################################################################>
Clear-Host;
$ServerName = "VM-DEVOPS-01.ssbinfo.com";
$DBName = "SSBRPProduction_Deploy";

$workstation = $env:COMPUTERNAME

if ($workstation -eq 'VM-DEVOPS-01')
{
    Write-Host ("Building & Deploying from $workstation...");
    . "E:\Workspaces\bgucuk\Deploy-SQLChangeAutomationProject.ps1"
    . "E:\Workspaces\bgucuk\ssb-devops\PowerShell\SQL Deployment Scripts\Build-SQLChangeAutomationProject.ps1"
     $WorkspaceLocation = "E:\Workspaces\bgucuk"
     $MSBuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"
}
elseif ($workstation -eq 'SSB008541382357')
{
    Write-Host ("Building & Deploying from $workstation...");
    . "C:\SourceControl\Deploy-SQLChangeAutomationProject_G.ps1"
    . "C:\SourceControl\Build-SQLChangeAutomationProject.ps1"
     $WorkspaceLocation = "C:\Temp\New"
     #$MSBuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\SQL\MSBuild\15.0\Bin\MSBuild.exe"
     $MSBuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
}
else
{
    throw "Working from an unknown computer...."
}
$result = Build-SQLChangeAutomationProject `
                -WorkspaceLocation "$WorkspaceLocation\ci-db-common" `
                -ProjectFolder "SSB.DB.Metadata" `
                -ProjectName "SSB.DB.Metadata.sln" `
                -DeployOnBuild $false `
                -TargetServer $ServerName `
                -TargetDatabase $DBName `
                -MsBuildFilePath $MSBuildPath `
                -BuildLogPath "C:\temp"

#$result