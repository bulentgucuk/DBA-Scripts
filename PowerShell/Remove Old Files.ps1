#https://jdhitsolutions.com/blog/powershell/8241/cleaning-with-powershell-revisited/
Function Remove-File {
    [cmdletbinding(SupportsShouldProcess)]
    [Alias("rfi")]
    Param(
        [Parameter(Position = 0)]
        [ValidateScript( { Test-Path $_ })]
        [string]$Path = $env:temp,
        [Parameter(Position = 1, Mandatory, HelpMessage = "Enter a cutoff date. All files modified BEFORE this date will be removed.")]
        [ValidateScript( { $_ -lt (Get-Date) })]
        [datetime]$Cutoff,
        [Switch]$Recurse,
        [Switch]$Force
    )

    Write-Verbose "Starting $($MyInvocation.MyCommand)"
    Write-Verbose "Removing files in $path older than $cutoff"

    #clean up PSBoundParameters which will be splatted to Get-ChildItem
    [void]$PSBoundParameters.Add("File", $True)
    [void]$PSBoundParameters.Remove("CutOff")
    if ($WhatIfPreference) {
        [void]$PSBoundParameters.Remove("Whatif")
    }

    Write-Verbose "Using these parameters: `n $($PSBoundParameters | Out-String)"
    Try {
        $files = Get-ChildItem @PSBoundParameters -ErrorAction Stop | Where-Object { $_.lastwritetime -lt $cutoff }
    }
    Catch {
        Write-Warning "Failed to enumerate files in $path"
        Write-Warning $_.Exception.Message
        #Bail out
        Return
    }

    if ($files) {
        Write-Verbose "Found $($files.count) file(s) to delete."
        $stats = $files | Measure-Object -Sum length
        $msg = "Removing {0} files for a total of {1} MB ({2} bytes) from {3}." -f $stats.count, ($stats.sum / 1MB -as [int]), $stats.sum, $path.toUpper()
        Write-Verbose $msg

        #only remove files if anything was found
        $files | Remove-Item -Force

        #Display a WhatIf Summary
        if ($WhatIfPreference) {
            Write-Host "What if: $msg" -ForegroundColor CYAN
        }

    } #if $files
    else {
        Write-Warning "No files found to remove in $($path.ToUpper()) older than $Cutoff."
    }

    Write-Verbose "Ending $($MyInvocation.MyCommand)"
} #close function