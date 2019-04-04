Clear-Host
Get-ChildItem -Path "C:\temp\Adhoc\CS-670\" | Sort-Object { [regex]::Replace($_.Name, '\d+', { $args[0].Value.PadLeft(20) }) } | SELECT NAME