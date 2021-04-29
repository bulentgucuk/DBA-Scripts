<#
    .Synopsis
    This function deploys a SQL Change Automation Project.      

    .Description
    This function deploys a SQL Change Automation Project using SQLCMD. 
    The user inputs properties about the project including location, name, and authentication method.
    The script then takes those inputs to create the SQLCMD string and then executes that string

    .PARAMETER DatabaseServer
    Specifies the name of the database server for deployment

    .PARAMETER DatabaseName
    Specifies the name of the database for deployment

    .PARAMETER ProjectReleaseFolder
    The Release folder created by MSBUILD during the build process where artifacts for deployment are landed

    .PARAMETER ProjectDeploymentFile
    The name of the file created by MSBUILD to deploy. This is a complete project file from SQL Change Automation.

    .PARAMETER UseWindowsAuth
    Boolean to decide what authentication method to use. Currently only Windows and SQL Authentication are supported.

    .PARAMETER DatabaseUserName
    When using SQL Authentication, a username to connect to SQL Server is required.

    .PARAMETER DatabasePassword
    When using SQL Authentication, a password to connect to SQL Server is required.
	
    .PARAMETER Environment
    #When using Environmental variables for deployment to Development or Production servers
	
	.PARAMETER UseAADCredential
    #When using Azure Active Directory Username and Password for deployment to Development or Production servers

    .Example

    Deploy-SQLChangeAutomationProject `
        -DatabaseServer 'vm-db-dev-01' `
        -DatabaseName 'msdb' `
        -ProjectReleaseFolder 'D:\Source\Repos\ssbcode\cd-db-common-master\SSB.DB.CI.MSDB\SSB.DB.CI.MSDB\bin\Release\' `
        -ProjectDeploymentFile 'SSB.DB.CI.MSDB_Package.sql' `
        -UseWindowsAuth $true `
        -DatabaseUserName '' `
        -DatabasePassword ''
		-Environment 'Development'
		-UseAADCredential $false


    .Example

    Deploy-SQLChangeAutomationProject `
        -DatabaseServer 'vm-db-dev-01' `
        -DatabaseName 'msdb' `
        -ProjectReleaseFolder 'D:\Source\Repos\ssbcode\cd-db-common-master\SSB.DB.CI.MSDB\SSB.DB.CI.MSDB\bin\Release\' `
        -ProjectDeploymentFile 'SSB.DB.CI.MSDB_Package.sql' `
        -UseWindowsAuth $false `
        -DatabaseUserName 'my_test_username' `
        -DatabasePassword 'my_test_password' `
		-UseAADCredential $false
#>

function Deploy-SQLChangeAutomationProject
{
Param(
    [Parameter(Mandatory = $true)]    #Specifies the name of the database server for deployment
    [string]$DatabaseServer,
    [Parameter(Mandatory = $true)]    #Specifies the name of the database for deployment
    [string]$DatabaseName,
    [Parameter(Mandatory = $true)]    #The Release folder created by MSBUILD during the build process where artifacts for deployment are landed
    [string]$ProjectReleaseFolder,    
    [Parameter(Mandatory = $true)]    #The name of the file created by MSBUILD to deploy. This is a complete project file from SQL Change Automation.
    [string]$ProjectDeploymentFile,   
    [Parameter(Mandatory = $false)]   #Boolean to decide what authentication method to use. Currently only Windows and SQL Authentication are supported.
    [bool]$UseWindowsAuth = $false,
    [Parameter(Mandatory = $false)]   #When using SQL Authentication, a username to connect to SQL Server is required.
    [string]$DatabaseUserName,
    [Parameter(Mandatory = $false)]   #When using SQL Authentication, a password to connect to SQL Server is required.
    [string]$DatabasePassword,
	[Parameter(Mandatory = $false)]   #When using Environmental variables for deployment
    [string]$Environment,
	[Parameter(Mandatory = $false)]   #When using Azure Active Directory Username and Password for deployment
    [string]$UseAADCredential
    
)


    #******************************************** 
    # Variable Declaration & Instantiation
    #********************************************
    #$outputFileName = "$DatabaseServer" + "_" + "$DatabaseName" + "_output.txt"
	$outputFileName = "$DatabaseServer" + "_" + "$DatabaseName" + "_output_" + (Get-Date).ToString("yyyy_MM_dd_hh_mm") + ".txt"
    $OutputFilePath = join-path $ProjectReleaseFolder $outputFileName
    $SQLPackageFilePath = join-path $ProjectReleaseFolder $ProjectDeploymentFile
    $ReleaseVersion = ''
    $DeployPath =  ''
    $ForceDeployWithoutBaseline = 'True'
    $DefaultFilePrefix  = ''
    $DefaultDataPath = ''
    $DefaultLogPath = ''
    $DefaultBackupPath = ''
    
    if (-Not (Test-Path $ProjectReleaseFolder.Trim()))
    {
        throw [System.IO.FileNotFoundException] "$OutputFilePath not found."
        return $false
    }
    if ( -Not (Test-Path $SQLPackageFilePath.Trim()))
    {
        throw [System.IO.FileNotFoundException] "$SQLPackageFilePath not found."
        return $false
    } 
      
    
    cd $ProjectReleaseFolder
    #******************************************** 
    # SQLCMD Authentication Fun
    #********************************************
    if ($UseWindowsAuth -eq $true -and  $UseAADCredential -eq $false) 
    { 
        $SqlCmdAuth = '-E'; 
        $ConnectionString = 'Data Source=' + $DatabaseServer + ';Integrated Security=SSPI'; 
    }
	#******************************************** 
    # Azure Active Directory Username and Password using -G option
    #********************************************
    if ($UseWindowsAuth -eq $false -and $UseAADCredential -eq $true) 
    { 
        if ($DatabaseUserName -eq $null) { Throw 'As SQL Server Authentication is to be used, please specify values for the DatabaseUserName and DatabasePassword variables. Alternately, specify UseWindowsAuth=True to use Windows Authentication instead.' }; 
        if ($DatabasePassword -eq $null) { Throw 'If a DatabaseUserName is specified, the DatabasePassword variable must also be provided.' }; 
        $SqlCmdAuth = '-G -U "' + $DatabaseUserName.Replace('"', '""') + '" ' + ' -P "' + $DatabasePassword.Replace('"', '""') + '" ' + ' -d "' + $DatabaseName.Replace('"', '""') + '" '; 
	    #$env:SQLCMDPASSWORD=$DatabasePassword; 
        $ConnectionString = 'Data Source=' + $DatabaseServer + ';initial catalog=' + $DatabaseName +';User Id=' + $DatabaseUserName + ';Password=' + $DatabasePassword;
    } 
    if ($UseWindowsAuth -eq $false -and $UseAADCredential -eq $false)  
    { 
        if ($DatabaseUserName -eq $null) { Throw 'As SQL Server Authentication is to be used, please specify values for the DatabaseUserName and DatabasePassword variables. Alternately, specify UseWindowsAuth=True to use Windows Authentication instead.' }; 
        if ($DatabasePassword -eq $null) { Throw 'If a DatabaseUserName is specified, the DatabasePassword variable must also be provided.' }; 
        $SqlCmdAuth = '-U "' + $DatabaseUserName.Replace('"', '""') + '" '; 
        $env:SQLCMDPASSWORD=$DatabasePassword; 
        $ConnectionString = 'Data Source=' + $DatabaseServer + ';User Id=' + $DatabaseUserName + ';Password=' + $DatabasePassword;
    };

    #*******************************************************************************************
    # Append all deployment variables set above into a single string for the SQLCMD command
    #*******************************************************************************************
    $SqlCmdVarArguments = 'DatabaseName="' + $DatabaseName.Replace('"', '""') + '"'
    $SqlCmdVarArguments += ' ReleaseVersion="' + $ReleaseVersion.Replace('"', '""') + '"'
    $SqlCmdVarArguments += ' DeployPath="' + $DeployPath.Replace('"', '""') + '"'
    $SqlCmdVarArguments += ' ForceDeployWithoutBaseline="' + $ForceDeployWithoutBaseline.Replace('"', '""') + '"'
    $SqlCmdVarArguments += ' DefaultFilePrefix="' + $DefaultFilePrefix.Replace('"', '""') + '"'
    $SqlCmdVarArguments += ' DefaultDataPath="' + $DefaultDataPath.Replace('"', '""') + '"'
    $SqlCmdVarArguments += ' DefaultLogPath="' + $DefaultLogPath.Replace('"', '""') + '"'
    $SqlCmdVarArguments += ' DefaultBackupPath="' + $DefaultBackupPath.Replace('"', '""') + '"'
	$SqlCmdVarArguments += ' Environment="' + $Environment.Replace('"', '""') + '"'


    #$SqlCmd = 'sqlcmd.exe -b -S "'+$DatabaseServer+ '" -d "'+$DatabaseName + '" -o "'+$OutputFilePath +'" -v ' + $SqlCmdVarArguments + ' -i "'+$SQLPackageFilePath+'" '
	#$SqlCmd = 'sqlcmd.exe -b -S "'+$DatabaseServer+ '"  -o "'+$OutputFilePath +'" -v ' + $SqlCmdVarArguments + ' -i "'+$SQLPackageFilePath+'" '
	$SqlCmd = "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\sqlcmd.exe"
	
	if ($UseWindowsAuth -eq $false -and $UseAADCredential -eq $false)
		{
		$SqlCmd = '"' + $SqlCmd + '"'+ ' -b -S "'+$DatabaseServer+ '"  -d "'+$DatabaseName+ '" -o "'+$OutputFilePath +'" -v ' + $SqlCmdVarArguments + ' -i "'+$SQLPackageFilePath+'" '
		}
	else
		{
		$SqlCmd = '"' + $SqlCmd + '"'+ ' -b -S "'+$DatabaseServer+ '"  -o "'+$OutputFilePath +'" -v ' + $SqlCmdVarArguments + ' -i "'+$SQLPackageFilePath+'" '
		}
	
	$SqlCmd = $SqlCmd + ' ' + $SqlCmdAuth


write-host 'Args'
#$SqlCmd
$DatabaseServer
$DatabaseName
$SQLPackageFilePath
$OutputFilePath

$Variables = @(
    "DatabaseName = $DatabaseName ",
    "ReleaseVersion = '' ",
    "DeployPath = '' ",
    "ForceDeployWithoutBaseline = True ",
    "DefaultFilePrefix = '' ",
    "DefaultDataPath = '' ",
    "DefaultBackupPath = '' ",
    "Environment = Development "
    )

$Variables

#cmd /Q /C $SqlCmd;

Invoke-Sqlcmd `
    -ServerInstance $DatabaseServer `
    -Database 'master' `
	-ConnectionTimeout 60 `
	-QueryTimeout 65535 `
    -variable $Variables `
    -InputFile $SQLPackageFilePath `
    -IncludeSqlUserErrors `
	-AbortOnError `
    -OutputSqlErrors $true `
    -Verbose *> $OutputFilePath
    #-Verbose *>> $OutputFilePath

#Invoke-Sqlcmd -ServerInstance $DatabaseServer -Database $DatabaseName -Query "select @@servername AS ServerName, DB_NAME() AS DatabaseName;" | Out-File -FilePath $OutputFilePath
#-ConnectionString "Data Source=VM-DEVOPS-01.ssbinfo.com;Initial Catalog=Bulent_DropMe;Integrated Security=True" `
#-Variable $SqlCmdVarArguments `

    IF ($LASTEXITCODE -ne 0)
    {
		Write-Host $LASTEXITCODE
		Start notepad++ $OutputFilePath;
    }
	
}