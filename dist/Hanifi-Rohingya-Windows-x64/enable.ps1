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

        # Register under language tag 'rhg-Rohg' (or 'rhg') so Windows taskbar displays 'RHG' badge
        $rohingyaLang = $languages | Where-Object { $_.LanguageTag -in @('rhg-Rohg', 'rhg') } | Select-Object -First 1
        $activeTag = if ($rohingyaLang) { $rohingyaLang.LanguageTag } else { 'rhg-Rohg' }
        
        if (-not $rohingyaLang) {
            try {
                $rohingyaLang = New-WinUserLanguageItem 'rhg-Rohg'
                $activeTag = 'rhg-Rohg'
                $languages.Add($rohingyaLang)
            } catch {
                try {
                    $rohingyaLang = New-WinUserLanguageItem 'rhg'
                    $activeTag = 'rhg'
                    $languages.Add($rohingyaLang)
                } catch {
                    $activeTag = 'en-US'
                    $rohingyaLang = $languages | Where-Object LanguageTag -eq 'en-US' | Select-Object -First 1
                    if (-not $rohingyaLang) {
                        $rohingyaLang = (New-WinUserLanguageList 'en-US')[0]
                        $languages.Add($rohingyaLang)
                    }
                }
            }
        }

        $targetTip = if ($Predictive) { "$activeTag`:{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}{4C379BE1-F64E-493A-92CD-67858A7423BE}" } else { "$activeTag`:A0F00409" }
        if (-not $rohingyaLang.InputMethodTips.Contains($targetTip)) {
            [void]$rohingyaLang.InputMethodTips.Add($targetTip)
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
    }
    Set-WinUserLanguageList $languages -Force
    if ($Remove) { Write-Host 'Keyboard removed from your input list.' }
    elseif ($Predictive) { Write-Host 'Sign out and back in, then select Hanifi Rohingya Predictive (RHG) with Win+Space. Click suggestions or press F1-F5; Escape dismisses them.' }
    else { Write-Host 'Sign out and back in, then use Win+Space to select Hanifi Rohingya (RHG). Choose Noto Sans Hanifi Rohingya in your document.' }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
