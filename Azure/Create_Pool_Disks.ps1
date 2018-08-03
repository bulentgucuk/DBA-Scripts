$poolName = "Log Pool" #set this
$diskName = "Log Disks" #set this
$FileSystemLabel =  "DWLogs" #set this
$Pool = Get-PhysicalDisk -CanPool $True
$PhysicalDisks = Get-PhysicalDisk | Where-Object {$_.CanPool -eq "true"}
New-StoragePool -FriendlyName $poolName -StorageSubsystemFriendlyName "Windows Storage*" -PhysicalDisks $PhysicalDisks | New-VirtualDisk -FriendlyName $diskName -Interleave 262144 -NumberOfColumns $pool.Count -ResiliencySettingName simple –UseMaximumSize |Initialize-Disk -PartitionStyle GPT -PassThru |New-Partition -AssignDriveLetter -UseMaximumSize |Format-Volume -FileSystem NTFS -NewFileSystemLabel $FileSystemLabel -AllocationUnitSize 65536 -Confirm:$false