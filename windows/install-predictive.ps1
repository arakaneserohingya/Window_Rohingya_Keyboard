# Machine registration for the separate predictive TSF input method.
[CmdletBinding()]
param([switch]$Remove)
$ErrorActionPreference = 'Stop'
try {
    if (-not [Environment]::Is64BitProcess -or $env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
        throw 'Use 64-bit Windows PowerShell on Intel/AMD x64 Windows.'
    }
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) {
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $PSCommandPath
        if ($Remove) { $arguments += ' -Remove' }
        $process = Start-Process "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList $arguments -Wait -PassThru
        exit $process.ExitCode
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
        $source = Join-Path $PSScriptRoot 'rohime.dll'
        if (-not (Test-Path $source)) { throw 'rohime.dll is missing. Extract the whole ZIP.' }
        $bytes = [IO.File]::ReadAllBytes($source)
        if ($bytes.Length -lt 64) { throw 'Invalid DLL.' }
        $pe = [BitConverter]::ToInt32($bytes,60)
        if ($pe -lt 64 -or ($pe+6) -gt $bytes.Length -or [BitConverter]::ToUInt32($bytes,$pe) -ne 0x4550 -or [BitConverter]::ToUInt16($bytes,$pe+4) -ne 0x8664) { throw 'Expected an x64 Windows DLL.' }
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
