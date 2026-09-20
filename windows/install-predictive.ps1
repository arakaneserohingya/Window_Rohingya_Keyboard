# Machine registration for the separate predictive TSF input method.
[CmdletBinding()]
param([switch]$Remove)
$ErrorActionPreference = 'Stop'
try {
    $arch = $env:PROCESSOR_ARCHITECTURE
    if (-not [Environment]::Is64BitProcess -or ($arch -ne 'AMD64' -and $arch -ne 'ARM64')) {
        throw 'Use 64-bit Windows PowerShell on 64-bit (x64 or ARM64) Windows.'
    }
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) {
        $tempDir = Join-Path $env:TEMP 'HanifiRohingyaInstall'
        if (-not (Test-Path $tempDir)) { New-Item $tempDir -ItemType Directory -Force | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $tempDir -Recurse -Force
        $tempScript = Join-Path $tempDir (Split-Path $PSCommandPath -Leaf)
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $tempScript
        if ($Remove) { $arguments += ' -Remove' }
        $process = Start-Process "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList $arguments -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Predictive installation failed with exit code $($process.ExitCode)."
        }
        exit 0
    }
    $folder = Join-Path $env:ProgramFiles 'Hanifi Rohingya Predictive'
    $destination = Join-Path $folder 'rohime.dll'
    $marker = Join-Path $folder 'owner.txt'
    $owner = 'HanifiRohingya.Predictive.1'
    $class = 'HKLM:\Software\Classes\CLSID\{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}\InprocServer32'
    if ((Test-Path $folder) -and ((-not (Test-Path $marker)) -or (Get-Content $marker -Raw).Trim() -ne $owner)) {
        throw 'The destination folder is not owned by this installer.'
    }
    if (Test-Path $class) {
        $registered = (Get-Item $class).GetValue('')
        if ($registered -ne $destination) { throw 'The predictive input method identifier is already in use.' }
    }
    $regsvr = Join-Path $env:SystemRoot 'System32\regsvr32.exe'
    if ($Remove) {
        if (-not (Test-Path $destination)) { Write-Host 'Predictive input method is already removed.'; exit 0 }
        $process = Start-Process $regsvr -ArgumentList ('/s /u "{0}"' -f $destination) -Wait -PassThru
        if ($process.ExitCode -ne 0) { throw "Input method unregistration failed ($($process.ExitCode))." }
        # Never recursively delete a directory: only remove files this installer owns.
        Remove-Item $destination
        Remove-Item $marker
        if (-not (Get-ChildItem $folder -Force)) { Remove-Item $folder }
        Write-Host 'Predictive input method removed. Restart applications or sign out.'
    } else {
        $source = $null
        if ($arch -eq 'ARM64') {
            if (Test-Path (Join-Path $PSScriptRoot 'arm64\rohime.dll')) {
                $source = Join-Path $PSScriptRoot 'arm64\rohime.dll'
            }
        } elseif ($arch -eq 'AMD64') {
            if (Test-Path (Join-Path $PSScriptRoot 'x64\rohime.dll')) {
                $source = Join-Path $PSScriptRoot 'x64\rohime.dll'
            }
        }
        if (-not $source -or (-not (Test-Path $source))) {
            $source = Join-Path $PSScriptRoot 'rohime.dll'
        }
        if (-not (Test-Path $source)) { throw 'rohime.dll is missing. Extract the whole ZIP.' }
        $bytes = [IO.File]::ReadAllBytes($source)
        if ($bytes.Length -lt 64) { throw 'Invalid DLL.' }
        $pe = [BitConverter]::ToInt32($bytes,60)
        if ($pe -lt 64 -or ($pe+6) -gt $bytes.Length -or [BitConverter]::ToUInt32($bytes,$pe) -ne 0x4550) {
            throw 'Invalid PE DLL.'
        }
        $machine = [BitConverter]::ToUInt16($bytes,$pe+4)
        if ($arch -eq 'ARM64' -and $machine -ne 0xAA64) {
            throw 'Expected an ARM64 Windows DLL on this ARM64 system.'
        }
        if ($arch -eq 'AMD64' -and $machine -ne 0x8664) {
            throw 'Expected an x64 Windows DLL on this x64 system.'
        }
        if ((Test-Path $destination) -and (Get-FileHash $destination).Hash -ne (Get-FileHash $source).Hash) {
            throw 'Remove the older predictive input method, sign out, then install this version.'
        }
        $created = -not (Test-Path $destination)
        New-Item $folder -ItemType Directory -Force | Out-Null
        Set-Content $marker $owner -Encoding ASCII
        try {
            if ($created) { Copy-Item $source $destination }
            $process = Start-Process $regsvr -ArgumentList ('/s "{0}"' -f $destination) -Wait -PassThru
            if ($process.ExitCode -ne 0) { throw "Input method registration failed ($($process.ExitCode))." }
        } catch {
            if ($created) {
                if (Test-Path $destination) { Remove-Item $destination }
                Remove-Item $marker
                if (-not (Get-ChildItem $folder -Force)) { Remove-Item $folder }
            }
            throw
        }
        Write-Host 'Hanifi Rohingya Predictive registered.'
    }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
