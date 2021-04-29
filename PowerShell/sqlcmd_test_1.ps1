Clear-Host
sqlcmd.exe -S localhost\sql2017 `
    -d msdb `
    -Q "set nocount on; select subsystem, max_worker_threads from dbo.syssubsystems" `
    -E -b `
    -o "C:\temp\sqlcmd_test_output.txt"
IF ($LASTEXITCODE -ne 0)
    {
    Write-Host $LASTEXITCODE
    STart notepad++.exe C:\temp\sqlcmd_test_output.txt
    }
    Write-Host $LASTEXITCODE