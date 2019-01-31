$SavePath = "C:\DBObjects\Databases"
$DateFolder = get-date -format yyyyMMddHHmm
$Server = '.'
$Log = "C:\DBObjects\Logs\$DateFolder.log"
#$ErrorActionPreference = "SilentlyContinue"

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
$SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $Server
$DatabaseList = $SMOserver.Databases 

Write-output "Scripting Server $Server" | Out-File $Log -append

foreach ($Database in $DatabaseList)
{
	$DatabaseName = $Database.Name
	[array]$Objects = @()

	Write-output "Scripting Database $DatabaseName " | Out-File $Log -append

	if (($DatabaseName -ne "tempdb") -and
		($DatabaseName -ne "model") -and
		($DatabaseName -ne "distribution") -and
		($DatabaseName -ne "msdb"))
	{	
		$db = $SMOserver.databases[$DatabaseName]

		#Objects to script and save to file:
		$Objects = $db.ApplicationRoles
		$Objects += $db.Assemblies
		$Objects += $db.ExtendedStoredProcedures
		$Objects += $db.ExtendedProperties
		$Objects += $db.PartitionFunctions
		$Objects += $db.PartitionSchemes
		$Objects += $db.Roles
		$Objects += $db.Rules
		$Objects += $db.Schemas
		$Objects += $db.StoredProcedures
		$Objects += $db.Synonyms
		$Objects += $db.Tables
		$Objects += $db.Triggers
		$Objects += $db.UserDefinedAggregates
		$Objects += $db.UserDefinedDataTypes
		$Objects += $db.UserDefinedFunctions
		$Objects += $db.UserDefinedTableTypes
		$Objects += $db.UserDefinedTypes
		$Objects += $db.Users
        $Objects += $db.Views
		
		if (!(Test-Path -Path "$SavePath\$DatabaseName")) 
		{
			new-item -type directory -name "$DatabaseName" -path "$SavePath"
		}
		if (!(Test-Path -Path "$SavePath\$DatabaseName\$DateFolder")) 
		{
			new-item -type directory -name "\$DateFolder" -path "$SavePath\$DatabaseName"
		}

		foreach ($ScriptThis in $Objects | where {!($_.IsSystemObject)}) 
		{
			#Need to Add Some mkDirs for the different $Fldr=$ScriptThis.GetType().Name
			$scriptr = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
			$scriptr.Options.AppendToFile = $true
			$scriptr.Options.AllowSystemObjects = $False
			$scriptr.Options.ClusteredIndexes = $True
			$scriptr.Options.DriAll = $True
			$scriptr.Options.ScriptDrops = $False
			$scriptr.Options.IncludeHeaders = $True
			$scriptr.Options.ToFileOnly = $True
			$scriptr.Options.Indexes = $True
			$scriptr.Options.Permissions = $False
			$scriptr.Options.WithDependencies = $False
			$scriptr.Options.SchemaQualifyForeignKeysReferences = $True
		
			<#Script the Drop too#>
			$ScriptDrop = new-object ('Microsoft.SqlServer.Management.Smo.Scripter') ($SMOserver)
			$ScriptDrop.Options.AppendToFile = $True
			$ScriptDrop.Options.AllowSystemObjects = $False
			$ScriptDrop.Options.ClusteredIndexes = $True
			$ScriptDrop.Options.DriAll = $True
			$ScriptDrop.Options.ScriptDrops = $True
			$ScriptDrop.Options.IncludeHeaders = $True
			$ScriptDrop.Options.ToFileOnly = $True
			$ScriptDrop.Options.Indexes = $True
			$ScriptDrop.Options.WithDependencies = $False
			$ScriptDrop.Options.SchemaQualifyForeignKeysReferences = $True
            $ScriptDrop.Options.IncludeIfNotExists = $True

			#This is where each object actually gets scripted one at a time.		
			$TypeFolder=$ScriptThis.GetType().Name

			if (!(Test-Path -Path "$SavePath\$DatabaseName\$DateFolder\$TypeFolder")) 
			{
				new-item -type directory -name "$TypeFolder"-path "$SavePath\$DatabaseName\$DateFolder"
			} 

			"Scripting Out $TypeFolder $ScriptThis"
			Write-output "Scripting Out $TypeFolder $ScriptThis" | Out-File $Log -append

			$ScriptFile = $ScriptThis -replace "\[|\]|\\"
			$scriptr.Options.FileName = "$SavePath\$DatabaseName\$DateFolder\$TypeFolder\$ScriptFile.SQL"
			$ScriptDrop.Options.FileName = "$SavePath\$DatabaseName\$DateFolder\$TypeFolder\$ScriptFile.SQL"			
			$ScriptDrop.Script($ScriptThis)				
			$scriptr.Script($ScriptThis)				

		} #This ends the Objects loop
	} #This ends the skip db check
} #This ends the DatabaseList loop
