<#
    .Synopsis
    This function builds a SQL Change Automation Project.      

    .Description
    This function builds a SQL Change Automation Project using MSBUILD. 
    The process requires that SQL Change Automation is installed and configured & integrated properly with Visual Studio

    .PARAMETER WorkspaceLocation
    Specifies the location on disk of the project or solution to build. This should be a folder path.

    .PARAMETER ProjectFolder
    Specifies the name of the folder containing the project.

    .PARAMETER ProjectName
    Specifies the name of the project or solution to build.

    .PARAMETER DeployOnBuild
    Boolean parameter that determines whether the project should deploy on build or not.

    .PARAMETER TargetServer
    Name of the database server to compile the project against. 
    Also, used to deploy the project if -DeployOnBuild $true.

    .PARAMETER TargetDatabase
    Name of the database to compile the project against. 
    Also, used to deploy the project if -DeployOnBuild $true.

    .PARAMETER MsBuildFilePath
    Full path on disk to the MSBUILD executable

    .PARAMETER BuildLogPath
    Folder on disk to store the output from the MSBUILD process.

    .Example


    .Example


#>


Function Build-SQLChangeAutomationProject
{
Param(
    [Parameter(Mandatory = $true)]         #Specifies the location on disk of the project or solution to build. This should be a folder path.
    [string]$WorkspaceLocation       
    ,[Parameter(Mandatory = $true)]        #Specifies the name of the folder containing the project.
    [string]$ProjectFolder
    ,[Parameter(Mandatory = $true)]        #Specifies the name of the project or solution to build.
    [string]$ProjectName             
    ,[Parameter(Mandatory = $true)]        #Boolean parameter that determines whether the project should deploy on build or not.
    [bool]$DeployOnBuild = $false
    ,[Parameter(Mandatory = $true)]        #Name of the database server to compile the project against.
    [string]$TargetServer             
    ,[Parameter(Mandatory = $true)]        #Name of the database to compile the project against. 
    [string]$TargetDatabase       
    ,[Parameter(Mandatory = $true)]        #Full path on disk to the MSBUILD executable.
    [string]$MsBuildFilePath   
    ,[Parameter(Mandatory = $true)]        #Folder on disk to store the output from the MSBUILD process.
    [string]$BuildLogPath    
    
)

Import-Module Invoke-msbuild

$path = "$WorkspaceLocation\$ProjectFolder\$ProjectName"

cd $WorkspaceLocation

#$buildParms =  "/p:DBDeployOnBuild=$DeployOnBuild /p:TargetServer=$TargetServer /p:TargetDatabase=$TargetDatabase /p:Configuration=Release /p:SkipDriftAnalysis=True /p:GenerateSqlPackage=True /p:SkipUnchangedFiles=False /p:SkipTargetPatch=True /p:SkipDeployPreview=True /verbosity:quiet"
$buildParms =  "/p:DBDeployOnBuild=$DeployOnBuild /p:TargetServer=$TargetServer /p:TargetDatabase=$TargetDatabase /p:Configuration=Release /p:SkipDriftAnalysis=True /p:GenerateSqlPackage=True /p:SkipUnchangedFiles=False /p:SkipTargetPatch=True /p:SkipDeployPreview=True /verbosity:normal "

$FullBuildLogPath = "$BuildLogPath\$projectName\"

New-Item -Path $BuildLogPath -ItemType Directory -Force | Out-Null

write-host "Path is $path"
write-host "BuildLogPath is $BuildLogPath"
write-host "BuildLogDirectoryPath is $FullBuildLogPath"
write-host "MsBuildFilePath is $MsBuildFilePath"


$buildResult = Invoke-MsBuild -Path $path -MsBuildParameters $buildParms -BuildLogDirectoryPath $FullBuildLogPath -MsBuildFilePath $MsBuildFilePath -KeepBuildLogOnSuccessfulBuilds -AutoLaunchBuildLogOnFailure -AutoLaunchBuildErrorsLogOnFailure

[bool]$return = $false


if ($buildResult.BuildSucceeded -eq $true)
{ 
    Write-Host "The build of the project completed successfully."  -ForegroundColor Green 
    $return = $true
}
elseif (!$buildResult.BuildSucceeded -eq $false)
{ 
    Write-Host "The build of the project failed. Check the build log file $($buildResult.BuildLogFilePath) for errors."  -ForegroundColor Red 
    $return = $false
}
elseif ($buildResult.BuildSucceeded -eq $null)
{ 
    Write-Host "Unsure if The build of the the project is unknown: $($buildResult.Message)"  -ForegroundColor Red 
    $return = $false
}

return $return
}