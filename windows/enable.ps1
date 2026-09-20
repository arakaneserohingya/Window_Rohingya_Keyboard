# Run as the person who will type, not as a different administrator account.
[CmdletBinding()]
param([switch]$Remove, [switch]$Predictive)
$ErrorActionPreference = 'Stop'
try {
    $languages = Get-WinUserLanguageList
    $tips = @(
        'rhg-Rohg:{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}{4C379BE1-F64E-493A-92CD-67858A7423BE}',
        'rhg-Rohg:A0F00409',
        'rhg:{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}{4C379BE1-F64E-493A-92CD-67858A7423BE}',
        'rhg:A0F00409',
        '0409:{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}{4C379BE1-F64E-493A-92CD-67858A7423BE}',
        '0409:A0F00409'
    )

    if ($Remove) {
        $toRemove = @()
        foreach ($language in $languages) {
            foreach ($tip in $tips) {
                if ($language.InputMethodTips.Contains($tip)) {
                    [void]$language.InputMethodTips.Remove($tip)
                }
            }
            if ($language.LanguageTag -in @('rhg-Rohg', 'rhg') -and $language.InputMethodTips.Count -eq 0) {
                $toRemove += $language
            }
            if ($language.LanguageTag -eq 'en-US' -and $language.InputMethodTips.Count -eq 0) {
                [void]$language.InputMethodTips.Add('0409:00000409')
            }
        }
        foreach ($rem in $toRemove) {
            [void]$languages.Remove($rem)
        }
    } else {
        $registration = if ($Predictive) { 'HKLM:\Software\Classes\CLSID\{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}\InprocServer32' } else { 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\A0F00409' }
        if (-not (Test-Path $registration)) { throw 'Run the matching Install command first.' }

        # Register under English (US) and rhg-Rohg so Windows input switcher is guaranteed to work
        $en = $languages | Where-Object { $_.LanguageTag -eq 'en-US' } | Select-Object -First 1
        if (-not $en) {
            $en = (New-WinUserLanguageList 'en-US')[0]
            $languages.Add($en)
        }
        
        $nativeTipEn = '0409:A0F00409'
        $predictiveTipEn = '0409:{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}{4C379BE1-F64E-493A-92CD-67858A7423BE}'
        $activeTipEn = if ($Predictive) { $predictiveTipEn } else { $nativeTipEn }
        
        if (-not $en.InputMethodTips.Contains($activeTipEn)) {
            [void]$en.InputMethodTips.Add($activeTipEn)
        }
        if (-not $en.InputMethodTips.Contains('0409:00000409')) {
            [void]$en.InputMethodTips.Add('0409:00000409')
        }

        # Also register under custom language tag 'rhg-Rohg' (or 'rhg')
        $rohingyaLang = $languages | Where-Object { $_.LanguageTag -in @('rhg-Rohg', 'rhg') } | Select-Object -First 1
        if (-not $rohingyaLang) {
            try {
                $rohingyaLang = New-WinUserLanguageItem 'rhg-Rohg'
                $languages.Add($rohingyaLang)
            } catch {
                try {
                    $rohingyaLang = New-WinUserLanguageItem 'rhg'
                    $languages.Add($rohingyaLang)
                } catch {}
            }
        }

        if ($rohingyaLang) {
            $tag = $rohingyaLang.LanguageTag
            $rohingyaTip = if ($Predictive) { "$tag`:{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}{4C379BE1-F64E-493A-92CD-67858A7423BE}" } else { "$tag`:A0F00409" }
            if (-not $rohingyaLang.InputMethodTips.Contains($rohingyaTip)) {
                [void]$rohingyaLang.InputMethodTips.Add($rohingyaTip)
            }
        }

        # Install the bundled font for this user, retaining existing shared fonts.
        $fontName = 'NotoSansHanifiRohingya-Regular.ttf'
        $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
        $fontPath = Join-Path $fontDir $fontName
        $source = Join-Path $PSScriptRoot $fontName
        New-Item $fontDir -ItemType Directory -Force | Out-Null
        if (-not (Test-Path $fontPath)) { Copy-Item $source $fontPath }
        $fontKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
        New-Item $fontKey -Force | Out-Null
        New-ItemProperty $fontKey -Name 'Noto Sans Hanifi Rohingya (TrueType)' -Value $fontPath -PropertyType String -Force | Out-Null

        # Configure registry preloads to make Hanifi Rohingya the primary keyboard
        $preloadKey = 'HKCU:\Keyboard Layout\Preload'
        if (-not (Test-Path $preloadKey)) { New-Item $preloadKey -Force | Out-Null }
        Set-ItemProperty -Path $preloadKey -Name '1' -Value 'A0F00409' -Force | Out-Null
        Set-ItemProperty -Path $preloadKey -Name '2' -Value '00000409' -Force | Out-Null

        # Set default input method override so all newly opened windows (Notepad, Word, Browser, etc.) default to Hanifi Rohingya
        try {
            Set-WinDefaultInputMethodOverride -InputTip $activeTipEn -ErrorAction SilentlyContinue
        } catch {}

        # Live activate in the current session via Win32 API
        try {
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class LiveKeyboardHelper {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr LoadKeyboardLayout(string pwszKLID, uint Flags);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr ActivateKeyboardLayout(IntPtr hkl, uint Flags);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
"@ -ErrorAction SilentlyContinue
            $hkl = [LiveKeyboardHelper]::LoadKeyboardLayout('A0F00409', 0x00000001 -bor 0x00000008)
            if ($hkl -ne [IntPtr]::Zero) {
                [LiveKeyboardHelper]::ActivateKeyboardLayout($hkl, 0x00000100)
                [LiveKeyboardHelper]::PostMessage([IntPtr]0xFFFF, 0x0050, [IntPtr]0, $hkl)
            }
        } catch {}
    }
    Set-WinUserLanguageList $languages -Force
    if ($Remove) { Write-Host 'Keyboard removed from your input list.' }
    elseif ($Predictive) { Write-Host 'Hanifi Rohingya Predictive is enabled as your default input method. Press Win+Space anytime to switch.' }
    else { Write-Host 'Hanifi Rohingya keyboard is enabled as your default input method across Windows. Press Win+Space anytime to switch.' }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
