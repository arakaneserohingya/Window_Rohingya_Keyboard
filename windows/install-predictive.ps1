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
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue }
        New-Item $tempDir -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$PSScriptRoot\*" -Destination $tempDir -Recurse -Force
        
        $tempScript = Join-Path $tempDir (Split-Path $PSCommandPath -Leaf)
        $logFile = Join-Path $tempDir 'install-predictive.log'
        if (Test-Path $logFile) { Remove-Item $logFile -Force -ErrorAction SilentlyContinue }
        
        $cmd = "& '$tempScript' $(if ($Remove) { '-Remove' }) *>&1 | Out-File -FilePath '$logFile' -Encoding utf8"
        $arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
        $process = Start-Process "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList $arguments -Wait -PassThru
        
        if (Test-Path $logFile) {
            Get-Content $logFile | ForEach-Object { Write-Host $_ }
        }
        
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
    $regsvr = Join-Path $env:SystemRoot 'System32\regsvr32.exe'
    if ($Remove) {
        if (-not (Test-Path $destination)) { Write-Host 'Predictive input method is already removed.'; exit 0 }
        $process = Start-Process $regsvr -ArgumentList ('/s /u "{0}"' -f $destination) -Wait -PassThru
        if ($process.ExitCode -ne 0) { throw "Input method unregistration failed ($($process.ExitCode))." }
        Remove-Item $destination -Force -ErrorAction SilentlyContinue
        Remove-Item $marker -Force -ErrorAction SilentlyContinue
        if (-not (Get-ChildItem $folder -Force -ErrorAction SilentlyContinue)) { Remove-Item $folder -Force -ErrorAction SilentlyContinue }
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
        if (-not (Test-Path $source)) { throw "rohime.dll is missing in $PSScriptRoot. Extract the whole ZIP." }
        $bytes = [IO.File]::ReadAllBytes($source)
        if ($bytes.Length -lt 64) { throw 'Invalid DLL.' }
        $pe = [BitConverter]::ToInt32($bytes,60)
        if ($pe -lt 64 -or ($pe+6) -gt $bytes.Length -or [BitConverter]::ToUInt32($bytes,$pe) -ne 0x4550) {
            throw 'Invalid PE DLL.'
        }
        $peMachineType = [BitConverter]::ToUInt16($bytes,$pe+4)
        if ($arch -eq 'ARM64' -and $peMachineType -ne 0xAA64) {
            $armSource = Join-Path $PSScriptRoot 'arm64\rohime.dll'
            if (Test-Path $armSource) {
                $source = $armSource
                $bytes = [IO.File]::ReadAllBytes($source)
                $pe = [BitConverter]::ToInt32($bytes,60)
                $peMachineType = [BitConverter]::ToUInt16($bytes,$pe+4)
            }
            if ($peMachineType -ne 0xAA64) {
                throw "Expected an ARM64 Windows DLL on this ARM64 system, found 0x$($peMachineType.ToString('X4'))."
            }
        }
        if ($arch -eq 'AMD64' -and $peMachineType -ne 0x8664) {
            throw "Expected an x64 Windows DLL on this x64 system, found 0x$($peMachineType.ToString('X4'))."
        }
        New-Item $folder -ItemType Directory -Force | Out-Null
        Set-Content $marker $owner -Encoding ASCII
        try {
            Copy-Item $source $destination -Force
        } catch {
            Write-Warning "rohime.dll is locked by an active process; updating registration."
        }
        $process = Start-Process $regsvr -ArgumentList ('/s "{0}"' -f $destination) -Wait -PassThru
        if ($process.ExitCode -ne 0) { throw "Input method registration failed ($($process.ExitCode))." }
        Write-Host 'Hanifi Rohingya Predictive registered.'
    }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
