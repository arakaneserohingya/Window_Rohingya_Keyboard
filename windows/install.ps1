# Machine registration only. Install.cmd enables it for the original user after elevation.
[CmdletBinding()]
param([switch]$Machine)
$ErrorActionPreference = 'Stop'
try {
    if (-not [Environment]::Is64BitProcess) { throw 'Run with 64-bit Windows PowerShell.' }
    $osArch = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
    if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64' -or $osArch -notmatch '64') {
        throw 'This package supports Intel/AMD x64 Windows only; ARM64 and 32-bit Windows are not supported.'
    }
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) {
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Machine' -f $PSCommandPath
        $process = Start-Process "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList $arguments -Wait -PassThru
        exit $process.ExitCode
    }
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\A0F00409'
    $root = Split-Path $key
    $owner = 'HanifiRohingya.Native.1'
    $source = Join-Path $PSScriptRoot 'kbdroh.dll'
    $destination = Join-Path $env:SystemRoot 'System32\kbdroh.dll'
    if (-not (Test-Path $source)) { throw 'kbdroh.dll is missing. Extract the entire ZIP before installing.' }
    # Verify the PE machine before copying any system files.
    $bytes = [IO.File]::ReadAllBytes($source)
    if ($bytes.Length -lt 64) { throw 'Invalid DLL.' }
    $pe = [BitConverter]::ToInt32($bytes,60)
    if ($pe -lt 64 -or ($pe+6) -gt $bytes.Length -or [BitConverter]::ToUInt32($bytes,$pe) -ne 0x4550 -or [BitConverter]::ToUInt16($bytes,$pe+4) -ne 0x8664) { throw 'Expected an x64 Windows DLL.' }
    if (Test-Path $key) {
        if ((Get-ItemProperty $key).RohingyaOwner -ne $owner) { throw 'Keyboard identifier is already owned by another layout. Nothing was changed.' }
    }
    foreach ($other in Get-ChildItem $root) {
        if ($other.PSChildName -ne 'A0F00409' -and (Get-ItemProperty $other.PSPath -Name 'Layout Id' -ErrorAction SilentlyContinue).'Layout Id' -eq '0F00') {
            throw 'Layout Id 0F00 is already in use. Nothing was changed.'
        }
    }
    if (Test-Path $destination) {
        if ((Get-FileHash $destination).Hash -ne (Get-FileHash $source).Hash) {
            throw 'A different kbdroh.dll already exists. Remove the previous version and restart Windows before installing this build.'
        }
    }
    $createdFile = -not (Test-Path $destination)
    $createdKey = -not (Test-Path $key)
    try {
        if ($createdFile) { Copy-Item $source $destination }
        New-Item $key -Force | Out-Null
        New-ItemProperty $key -Name 'Layout File' -Value 'kbdroh.dll' -PropertyType String -Force | Out-Null
        New-ItemProperty $key -Name 'Layout Text' -Value 'Hanifi Rohingya' -PropertyType String -Force | Out-Null
        New-ItemProperty $key -Name 'Layout Id' -Value '0F00' -PropertyType String -Force | Out-Null
        New-ItemProperty $key -Name 'RohingyaOwner' -Value $owner -PropertyType String -Force | Out-Null
    } catch {
        if ($createdKey -and (Test-Path $key)) { Remove-Item $key -Recurse -Force }
        if ($createdFile -and (Test-Path $destination)) { Remove-Item $destination -Force }
        throw
    }
    Write-Host 'Native Hanifi Rohingya keyboard registered.'
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
