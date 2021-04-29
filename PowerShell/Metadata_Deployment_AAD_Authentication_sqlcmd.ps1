<#############################################################################################
 Created By:   Bulent Gucuk
 Create Date:  2019.12.16
 Creation:     Script to build SSB.DB.Metadata project.
               Using a couple custom functions right now to build & deploy the project.               
               Use these snippets of code for more information on the functions 

                 Get-Help -Name "Build-SQLChangeAutomationProject" -Full
                 Get-Help -Name "Deploy-SQLChangeAutomationProject" -Full
                 Get-Help -Name "Invoke-MsBuild" -Full
##############################################################################################>
Clear-Host;

$workstation = $env:COMPUTERNAME

if ($workstation -eq 'VM-DEVOPS-01')
{
    Write-Host "Building & Deploying from VM-DEVOPS-01...";
    . "E:\Workspaces\bgucuk\Deploy-SQLChangeAutomationProject.ps1"
    . "E:\Workspaces\bgucuk\ssb-devops\PowerShell\SQL Deployment Scripts\Build-SQLChangeAutomationProject.ps1"
     $WorkspaceLocation = "E:\Workspaces\bgucuk"
     $MSBuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"
}
ELSEif ($workstation -eq 'SSB008541382357')
{
    Write-Host "Building & Deploying from LAPTOP...";
    . "C:\SourceControl\Deploy-SQLChangeAutomationProject_G.ps1"
    . "C:\SourceControl\Build-SQLChangeAutomationProject.ps1"
     $WorkspaceLocation = "C:\SourceControl"
     $MSBuildPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\SQL\MSBuild\15.0\Bin\MSBuild.exe"
}
else
{
    throw "Working from an unknown computer...."
}

$result = Build-SQLChangeAutomationProject `
                -WorkspaceLocation "$WorkspaceLocation\ci-db-common" `
                -ProjectFolder 'SSB.DB.Metadata'`
                -ProjectName 'SSB.DB.Metadata.sln'`
                -DeployOnBuild $false `
                -TargetServer 'ssb-dev-databases.database.windows.net'`
                -TargetDatabase 'SSBRPDevelopment'`
                -MsBuildFilePath $MSBuildPath `
                -BuildLogPath 'C:\temp'  

$result

if ($result -eq $true)
{

   Deploy-SQLChangeAutomationProject `
        -DatabaseServer 'ssb-dev-databases.database.windows.net' `
        -DatabaseName 'SSBRPTest' `
        -ProjectReleaseFolder "$WorkspaceLocation\ci-db-common\SSB.DB.Metadata\bin\Release" `
        -ProjectDeploymentFile 'SSB.DB.Metadata_Package.sql' `
        -UseWindowsAuth $false `
        -DatabaseUserName 'bgucuk@ssbinfo.com' `
        -DatabasePassword '3N%3pvwB' `
        -UseAADCredential $true

<#
   Deploy-SQLChangeAutomationProject `
        -DatabaseServer 'ssb-dev-databases.database.windows.net' `
        -DatabaseName 'SSBRPTest' `
        -ProjectReleaseFolder "$WorkspaceLocation\ci-db-common\SSB.DB.Metadata\bin\Release" `
        -ProjectDeploymentFile 'SSB.DB.Metadata_Package.sql' `
        -UseWindowsAuth $false `
        -DatabaseUserName 'ssb_bgucuk' `
        -DatabasePassword 'AllahB1rd1r' `
        -UseAADCredential $false
#>

}