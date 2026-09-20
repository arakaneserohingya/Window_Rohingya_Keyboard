# Machine registration only. Install.cmd enables it for the original user after elevation.
[CmdletBinding()]
param([switch]$Machine)
$ErrorActionPreference = 'Stop'

function Show-WelcomeDialog {
    param([string]$ImagePath)
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop

        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'Hanifi Rohingya Keyboard Setup'
        $form.Size = New-Object System.Drawing.Size(460, 300)
        $form.StartPosition = 'CenterScreen'
        $form.FormBorderStyle = 'FixedDialog'
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false
        $form.BackColor = [System.Drawing.Color]::FromArgb(245, 248, 246)

        if ($ImagePath -and (Test-Path $ImagePath)) {
            $pb = New-Object System.Windows.Forms.PictureBox
            $pb.Location = New-Object System.Drawing.Point(20, 20)
            $pb.Size = New-Object System.Drawing.Size(100, 100)
            $pb.SizeMode = 'Zoom'
            $pb.Image = [System.Drawing.Image]::FromFile($ImagePath)
            $form.Controls.Add($pb)
        }

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Location = New-Object System.Drawing.Point(135, 20)
        $lblTitle.Size = New-Object System.Drawing.Size(300, 26)
        $lblTitle.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
        $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(21, 60, 55)
        $lblTitle.Text = 'Hanifi Rohingya Keyboard'
        $form.Controls.Add($lblTitle)

        $lblAuthor = New-Object System.Windows.Forms.Label
        $lblAuthor.Location = New-Object System.Drawing.Point(135, 50)
        $lblAuthor.Size = New-Object System.Drawing.Size(300, 22)
        $lblAuthor.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
        $lblAuthor.ForeColor = [System.Drawing.Color]::FromArgb(0, 104, 82)
        $lblAuthor.Text = 'Brought to you by: Ahkter Husin'
        $form.Controls.Add($lblAuthor)

        $lblLinks = New-Object System.Windows.Forms.Label
        $lblLinks.Location = New-Object System.Drawing.Point(135, 75)
        $lblLinks.Size = New-Object System.Drawing.Size(300, 40)
        $lblLinks.Font = New-Object System.Drawing.Font('Segoe UI', 9)
        $lblLinks.ForeColor = [System.Drawing.Color]::FromArgb(88, 113, 104)
        $lblLinks.Text = "Website: rohingyahub.org`nGitHub: @arakaneserohingya"
        $form.Controls.Add($lblLinks)

        $lblDesc = New-Object System.Windows.Forms.Label
        $lblDesc.Location = New-Object System.Drawing.Point(20, 140)
        $lblDesc.Size = New-Object System.Drawing.Size(405, 45)
        $lblDesc.Font = New-Object System.Drawing.Font('Segoe UI', 9)
        $lblDesc.Text = 'Click "Install" to install the native Hanifi Rohingya keyboard layout and font for Windows.'
        $form.Controls.Add($lblDesc)

        $btnInstall = New-Object System.Windows.Forms.Button
        $btnInstall.Location = New-Object System.Drawing.Point(235, 205)
        $btnInstall.Size = New-Object System.Drawing.Size(100, 34)
        $btnInstall.Text = 'Install'
        $btnInstall.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
        $btnInstall.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $btnInstall
        $form.Controls.Add($btnInstall)

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Location = New-Object System.Drawing.Point(345, 205)
        $btnCancel.Size = New-Object System.Drawing.Size(85, 34)
        $btnCancel.Text = 'Cancel'
        $btnCancel.Font = New-Object System.Drawing.Font('Segoe UI', 9)
        $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.CancelButton = $btnCancel
        $form.Controls.Add($btnCancel)

        $result = $form.ShowDialog()
        return ($result -eq [System.Windows.Forms.DialogResult]::OK)
    } catch {
        return $true
    }
}

try {
    if (-not $Machine) {
        $img = Join-Path $PSScriptRoot 'assets\author.jpg'
        if (-not (Test-Path $img)) { $img = Join-Path $PSScriptRoot 'author.jpg' }
        Write-Host '======================================================' -ForegroundColor Cyan
        Write-Host '       Hanifi Rohingya Keyboard for Windows' -ForegroundColor Green
        Write-Host '         Brought to you by: Ahkter Husin' -ForegroundColor Yellow
        Write-Host '    Website: rohingyahub.org | GitHub: @arakaneserohingya' -ForegroundColor Gray
        Write-Host '======================================================' -ForegroundColor Cyan

        $proceed = Show-WelcomeDialog -ImagePath $img
        if (-not $proceed) {
            Write-Host 'Installation cancelled.'
            exit 0
        }
    }

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
