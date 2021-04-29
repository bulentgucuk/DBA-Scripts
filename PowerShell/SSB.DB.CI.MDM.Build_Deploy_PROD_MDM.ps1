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

    $servername = "l2oqghb8m9.database.windows.net"
    $dbname = "SSBRPProduction"
    #$DeploymentLocationScript = "$WorkspaceLocation\ssb-devops\SQL\Deployment Locations\SSB_Active_Databases_Test_Core_Client.sql"
    #$DeploymentLocations = Invoke-Sqlcmd -ServerInstance $servername -Database $dbname -InputFile $DeploymentLocationScript -Username "ssb_bgucuk" -Password 'AllahB1rd1r'
    $DeploymentLocationQuery = "SELECT  s.ServerName
	, s.FQDN
	, ds.DBName
	, ds.Username
	, ds.EncryptedPassword
FROM    dbo.TenantDataSource ds
    INNER JOIN dbo.Server s ON ds.ServerID = s.ServerID
    INNER JOIN dbo.Tenant t ON ds.TenantID = t.TenantID
    INNER JOIN dbo.DBType d ON ds.DBTypeID = d.DBTypeID
WHERE   t.Active = 1       
        AND ds.DBTypeID = 'CD7F61DD-ACB8-4EF1-96D1-019E185310CF' -- SSB CI DW - MDM Common (Admin Only)
ORDER BY s.FQDN;"

    $DeploymentLocations = Invoke-Sqlcmd -ServerInstance $servername -Database $dbname -Query $DeploymentLocationQuery -Username "ssb_bgucuk" -Password 'AllahB1rd1r'
    
    ForEach ($DeploymentLocation in $DeploymentLocations)
    {
        
        $ServerName = $DeploymentLocation.FQDN
        $DBname = $DeploymentLocation.DBName

        Write-Host 'Deployment Location ==> Server Name :'$ServerName  ' --> Database name  :'$DBname
        IF ($ServerName -like "*.windows.net")
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
            
        ELSE
            {
            Deploy-SQLChangeAutomationProject `
                -DatabaseServer $ServerName `
                -DatabaseName $DBname `
                -ProjectReleaseFolder "$WorkspaceLocation\ci-db-common\SSB.DB.CI.MDM\bin\Release" `
                -ProjectDeploymentFile 'SSB.DB.CI.MDM_Package.sql' `
                -UseWindowsAuth $true `
                -DatabaseUserName '' `
                -DatabasePassword '' `
                -UseAADCredential $false ;
            }


    }
}
