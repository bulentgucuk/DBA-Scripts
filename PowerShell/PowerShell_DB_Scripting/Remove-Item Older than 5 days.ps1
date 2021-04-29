#uncomment the Remove-Item to delete the files and folders which last write time older than 5 days
Clear-Host;
Get-ChildItem -Path  'G:\SQLBackups\FIIMSOSTGDPSQCL$AG01' -Recurse | Where-Object LastWriteTime -LT (Get-Date).AddDays(-5)  #| Remove-Item -Recurse;