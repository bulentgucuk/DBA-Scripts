#https://jdhitsolutions.com/blog/powershell/8241/cleaning-with-powershell-revisited/
Function Remove-EmptyFolder {
    [cmdletbinding(SupportsShouldProcess)]
    [alias("ref")]
    [outputType("None")]
    Param(
      [Parameter(Position = 0, Mandatory, HelpMessage = "Enter a root directory path")]
      [ValidateScript( {
          Try {
            Convert-Path -Path $_ -ErrorAction stop
            if ((Get-Item $_).PSProvider.Name -ne 'FileSystem') {
              Throw "$_ is not a file system path."
            }
            $true
          }
          Catch {
            Write-Warning $_.exception.message
            Throw "Try again."
          }
        })]
      [string]$Path
    )
  
    Write-Verbose "Starting $($myinvocation.mycommand)"
  
    Write-Verbose "Enumerating folders in $Path"
  
    $folders = (Get-Item -Path $Path -force).EnumerateDirectories("*", [System.IO.SearchOption]::AllDirectories).foreach( {
        if ($((Get-Item $_.FullName -force).EnumerateFiles("*", [System.IO.SearchOption]::AllDirectories)).count -eq 0) {
          $_.fullname
        } })
  
    If ($folders.count -gt 0) {
  
      $msg = "Removing $($folders.count) empty folder(s) in $($path.ToUpper())"
      Write-Verbose $msg
      #Test each path to make sure it still exists and then delete it
      foreach ($folder in $folders) {
        If (Test-Path -Path $Folder) {
          Write-Verbose "Removing $folder"
          Remove-Item -Path $folder -Force -Recurse
        }
      }
  
      #Display a WhatIf Summary
      if ($WhatIfPreference) {
        Write-Host "What if: $msg" -ForegroundColor CYAN
      }
    }
    else {
      Write-Warning "No empty folders found under $($path.ToUpper())."
    }
  
    Write-Verbose "Ending $($myinvocation.mycommand)"
  
  } #end Remove-EmptyFolder