Clear-Host
workflow devsql {
    parallel {
        inlinescript {C:\Bulent\SAH\Azure\AZ16DEVTDEVSQL01\dsk02_SnapThenCreateDiskAndAttach.ps1}
        inlinescript {C:\Bulent\SAH\Azure\AZ16DEVTDEVSQL01\dsk03_SnapThenCreateDiskAndAttach.ps1}
        inlinescript {C:\Bulent\SAH\Azure\AZ16DEVTDEVSQL01\dsk04_SnapThenCreateDiskAndAttach.ps1}
        inlinescript {C:\Bulent\SAH\Azure\AZ16DEVTDEVSQL01\dsk05_SnapThenCreateDiskAndAttach.ps1}
        inlinescript {C:\Bulent\SAH\Azure\AZ16DEVTDEVSQL01\dsk06_SnapThenCreateDiskAndAttach.ps1}
        inlinescript {C:\Bulent\SAH\Azure\AZ16DEVTDEVSQL01\dsk07_SnapThenCreateDiskAndAttach.ps1}
        inlinescript {C:\Bulent\SAH\Azure\AZ16DEVTDEVSQL01\dsk08_SnapThenCreateDiskAndAttach.ps1}
        inlinescript {C:\Bulent\SAH\Azure\AZ16DEVTDEVSQL01\dsk09_SnapThenCreateDiskAndAttach.ps1}
        }
    }
devsql

