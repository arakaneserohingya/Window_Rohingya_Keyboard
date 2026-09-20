[CmdletBinding()]
param([switch]$Machine)
$ErrorActionPreference = 'Stop'
try {
    if (-not [Environment]::Is64BitProcess) { throw 'Use 64-bit Windows PowerShell.' }
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) {
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Machine' -f $PSCommandPath
        $process = Start-Process "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList $arguments -Wait -PassThru
        exit $process.ExitCode
    }
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\A0F00409'
    if (-not (Test-Path $key)) { Write-Host 'Keyboard is not registered.'; exit 0 }
    $properties = Get-ItemProperty $key
    if ($properties.RohingyaOwner -ne 'HanifiRohingya.Native.1' -or $properties.'Layout File' -ne 'kbdroh.dll') { throw 'Registration is not owned by this keyboard; nothing removed.' }
    $dll = Join-Path $env:SystemRoot 'System32\kbdroh.dll'
    # Delete first; if Windows is using the DLL, keep registration so removal is retryable.
    if (Test-Path $dll) {
        try { Remove-Item $dll -Force }
        catch { throw 'Windows is still using the keyboard DLL. Restart Windows, keep an English keyboard selected, and run Uninstall.cmd again.' }
    }
    Remove-Item $key -Recurse -Force
    Write-Host 'Native keyboard removed. The font is retained for existing documents. Other users should run enable.ps1 -Remove in their own account.'
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
