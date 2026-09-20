# Machine registration only. Install.cmd enables it for the original user after elevation.
[CmdletBinding()]
param([switch]$Machine)
$ErrorActionPreference = 'Stop'

function Show-WelcomeDialog {
    param([string]$ImagePath, [string]$LogoPath, [string]$IconPath)
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop

        $form = New-Object System.Windows.Forms.Form
        $form.Text = 'Hanifi Rohingya Keyboard Setup'
        $form.Size = New-Object System.Drawing.Size(490, 320)
        $form.StartPosition = 'CenterScreen'
        $form.FormBorderStyle = 'FixedDialog'
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false
        $form.BackColor = [System.Drawing.Color]::FromArgb(245, 248, 246)

        if ($IconPath -and (Test-Path $IconPath)) {
            $form.Icon = New-Object System.Drawing.Icon($IconPath)
        }

        # App Logo
        if ($LogoPath -and (Test-Path $LogoPath)) {
            $pbLogo = New-Object System.Windows.Forms.PictureBox
            $pbLogo.Location = New-Object System.Drawing.Point(20, 20)
            $pbLogo.Size = New-Object System.Drawing.Size(90, 90)
            $pbLogo.SizeMode = 'Zoom'
            $pbLogo.Image = [System.Drawing.Image]::FromFile($LogoPath)
            $form.Controls.Add($pbLogo)
        }

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Location = New-Object System.Drawing.Point(125, 18)
        $lblTitle.Size = New-Object System.Drawing.Size(330, 26)
        $lblTitle.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
        $lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(21, 60, 55)
        $lblTitle.Text = 'Hanifi Rohingya Keyboard'
        $form.Controls.Add($lblTitle)

        $lblAuthor = New-Object System.Windows.Forms.Label
        $lblAuthor.Location = New-Object System.Drawing.Point(125, 46)
        $lblAuthor.Size = New-Object System.Drawing.Size(330, 22)
        $lblAuthor.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
        $lblAuthor.ForeColor = [System.Drawing.Color]::FromArgb(0, 104, 82)
        $lblAuthor.Text = 'Brought to you by: Ahkter Husin'
        $form.Controls.Add($lblAuthor)

        $lblLinks = New-Object System.Windows.Forms.Label
        $lblLinks.Location = New-Object System.Drawing.Point(125, 70)
        $lblLinks.Size = New-Object System.Drawing.Size(330, 40)
        $lblLinks.Font = New-Object System.Drawing.Font('Segoe UI', 9)
        $lblLinks.ForeColor = [System.Drawing.Color]::FromArgb(88, 113, 104)
        $lblLinks.Text = "Website: rohingyahub.org`nGitHub: @arakaneserohingya"
        $form.Controls.Add($lblLinks)

        $lblDesc = New-Object System.Windows.Forms.Label
        $lblDesc.Location = New-Object System.Drawing.Point(20, 130)
        $lblDesc.Size = New-Object System.Drawing.Size(435, 50)
        $lblDesc.Font = New-Object System.Drawing.Font('Segoe UI', 9)
        $lblDesc.Text = 'Click "Install" to install the native Hanifi Rohingya keyboard layout (x64 / ARM64) and Noto font for Windows.'
        $form.Controls.Add($lblDesc)

        $btnInstall = New-Object System.Windows.Forms.Button
        $btnInstall.Location = New-Object System.Drawing.Point(260, 220)
        $btnInstall.Size = New-Object System.Drawing.Size(100, 34)
        $btnInstall.Text = 'Install'
        $btnInstall.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
        $btnInstall.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $btnInstall
        $form.Controls.Add($btnInstall)

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Location = New-Object System.Drawing.Point(370, 220)
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
        $logo = Join-Path $PSScriptRoot 'assets\icon.png'
        if (-not (Test-Path $logo)) { $logo = Join-Path $PSScriptRoot 'icon.png' }
        $ico = Join-Path $PSScriptRoot 'assets\icon.ico'
        if (-not (Test-Path $ico)) { $ico = Join-Path $PSScriptRoot 'icon.ico' }

        Write-Host '======================================================' -ForegroundColor Cyan
        Write-Host '       Hanifi Rohingya Keyboard for Windows' -ForegroundColor Green
        Write-Host '         Brought to you by: Ahkter Husin' -ForegroundColor Yellow
        Write-Host '    Website: rohingyahub.org | GitHub: @arakaneserohingya' -ForegroundColor Gray
        Write-Host '======================================================' -ForegroundColor Cyan

        $proceed = Show-WelcomeDialog -ImagePath $img -LogoPath $logo -IconPath $ico
        if (-not $proceed) {
            Write-Host 'Installation cancelled.'
            exit 0
        }
    }

    if (-not [Environment]::Is64BitProcess) { throw 'Run with 64-bit Windows PowerShell.' }
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($arch -ne 'AMD64' -and $arch -ne 'ARM64') {
        throw 'This package supports 64-bit Windows (x64 and ARM64) only; 32-bit Windows is not supported.'
    }
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $admin) {
        $tempDir = Join-Path $env:TEMP 'HanifiRohingyaInstall'
        if (-not (Test-Path $tempDir)) { New-Item $tempDir -ItemType Directory -Force | Out-Null }
        Copy-Item -Path "$PSScriptRoot\*" -Destination $tempDir -Recurse -Force
        $tempScript = Join-Path $tempDir (Split-Path $PSCommandPath -Leaf)
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Machine' -f $tempScript
        $process = Start-Process "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList $arguments -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Machine installation failed with exit code $($process.ExitCode)."
        }
        exit 0
    }
    $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\A0F00409'
    $root = Split-Path $key
    $owner = 'HanifiRohingya.Native.1'
    
    # Pick the appropriate DLL for the system architecture (ARM64 vs x64)
    $source = $null
    if ($arch -eq 'ARM64') {
        if (Test-Path (Join-Path $PSScriptRoot 'arm64\kbdroh.dll')) {
            $source = Join-Path $PSScriptRoot 'arm64\kbdroh.dll'
        }
    } elseif ($arch -eq 'AMD64') {
        if (Test-Path (Join-Path $PSScriptRoot 'x64\kbdroh.dll')) {
            $source = Join-Path $PSScriptRoot 'x64\kbdroh.dll'
        }
    }
    if (-not $source -or (-not (Test-Path $source))) {
        $source = Join-Path $PSScriptRoot 'kbdroh.dll'
    }
    $destination = Join-Path $env:SystemRoot 'System32\kbdroh.dll'
    if (-not (Test-Path $source)) { throw 'kbdroh.dll is missing. Extract the entire ZIP before installing.' }
    
    # Verify the PE machine before copying any system files.
    $bytes = [IO.File]::ReadAllBytes($source)
    if ($bytes.Length -lt 64) { throw 'Invalid DLL.' }
    $pe = [BitConverter]::ToInt32($bytes,60)
    if ($pe -lt 64 -or ($pe+6) -gt $bytes.Length -or [BitConverter]::ToUInt32($bytes,$pe) -ne 0x4550) {
        throw 'Invalid PE DLL header.'
    }
    $machine = [BitConverter]::ToUInt16($bytes,$pe+4)
    if ($arch -eq 'ARM64' -and $machine -ne 0xAA64) {
        throw 'Expected an ARM64 Windows DLL on this ARM64 system.'
    }
    if ($arch -eq 'AMD64' -and $machine -ne 0x8664) {
        throw 'Expected an x64 Windows DLL on this x64 system.'
    }
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
