<#
Author name:  Bulent Gucuk
Created date: 3/1/2019
Purpose: This will kick of the execution of sp_whoisactive in the runbook that webhook created for

Example: C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe -NoProfile -WindowStyle Hidden -Command C:\PowerShell\ClientDW_WhoisActive\ClientDW_WhoIsActive.ps1
    -Webhook = "https://s13events.azure-automation.net/webhooks?token=iDJ4n1rhqxstECwNaZ9QOY%2fSiI%2fAYEVrVZGcrGlrWXI%3d"
    -Method = "Post"

Copyright © 2019, SSB, All Rights Reserved 
#>

Param
(
    [string] $Webhook,
    [string] $Method
)

#For testing: Below webhook is for Boston Bruins runbook DBA_srv-bostonbruins-01_db-bostonbruins-prod_whoisactive 
#$Webhook = "https://s13events.azure-automation.net/webhooks?token=iDJ4n1rhqxstECwNaZ9QOY%2fSiI%2fAYEVrVZGcrGlrWXI%3d"
#$Method = "Post"

$Result = Invoke-WebRequest -Uri $Webhook -Method $Method -UseBasicParsing
$Result