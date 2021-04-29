#https://github.com/ssbcode/ci-db-common/pull/629
<#############################################################################################
 Created By:   Bulent Gucuk
 Create Date:  2020.02.21
 Creation:     Script to build the SSB.DB.CI.MDM project.
               Using a couple custom functions right now to build & deploy the project.               
               Use these snippets of code for more information on the functions 

        Get-Help -Name "Build-SQLChangeAutomationProject" -Full
        Get-Help -Name "Deploy-SQLChangeAutomationProject" -Full
        Get-Help -Name "Invoke-MsBuild" -Full
##############################################################################################>
Clear-Host;
$ServerName = 'VM-DB-DEV-01.ssbinfo.com';
$DBname = 'MDM';
$workstation = $env:COMPUTERNAME

if ($workstation -eq 'VM-DEVOPS-01')
{
    Write-Host ("Building & Deploying from $workstation...");
    . "E:\Workspaces\bgucuk\Deploy-SQLChangeAutomationProject.ps1"
    . "E:\Workspaces\bgucuk\ssb-devops\PowerShell\SQL Deployment Scripts\Build-SQLChangeAutomationProject.ps1"
     $WorkspaceLocation = "E:\Workspaces\bgucuk"
     $MSBuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"
}
ELSEif ($workstation -eq 'SSB008541382357')
{
    Write-Host ("Building & Deploying from $workstation...");
    . "C:\SourceControl\Deploy-SQLChangeAutomationProject_G.ps1"
    . "C:\SourceControl\Build-SQLChangeAutomationProject.ps1"
    $WorkspaceLocation = "C:\SourceControl"
    $MSBuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\SQL\MSBuild\15.0\Bin\MSBuild.exe"
    #$MSBuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
}
else
{
    throw "Working from an unknown computer...."
}

$result = Build-SQLChangeAutomationProject `
                -WorkspaceLocation "$WorkspaceLocation\ci-db-common" `
                -ProjectFolder 'SSB.DB.CI.MDM'`
                -ProjectName 'SSB.DB.CI.MDM.sln'`
                -DeployOnBuild $false `
                -TargetServer 'VM-DB-DEV-01.ssbinfo.com'`
                -TargetDatabase 'MDM'`
                -MsBuildFilePath $MSBuildPath `
                -BuildLogPath 'C:\temp\'  

#$result

if ($result -eq $true)
{

   Deploy-SQLChangeAutomationProject `
        -DatabaseServer $ServerName `
        -DatabaseName $DBname `
        -ProjectReleaseFolder "$WorkspaceLocation\ci-db-common\SSB.DB.CI.MDM\bin\Release" `
        -ProjectDeploymentFile 'SSB.DB.CI.MDM_Package.sql' `
        -UseWindowsAuth $false `
        -DatabaseUserName 'ssb_bgucuk' `
        -DatabasePassword 'AllahB1rd1r' `
        -UseAADCredential $false ;

}