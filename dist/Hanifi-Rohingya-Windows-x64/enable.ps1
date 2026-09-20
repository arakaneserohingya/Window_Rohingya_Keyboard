# Run as the person who will type, not as a different administrator account.
[CmdletBinding()]
param([switch]$Remove, [switch]$Predictive)
$ErrorActionPreference = 'Stop'
try {
    $tip = if ($Predictive) { '0409:{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}{4C379BE1-F64E-493A-92CD-67858A7423BE}' } else { '0409:A0F00409' }
    $languages = Get-WinUserLanguageList
    if ($Remove) {
        foreach ($language in $languages) {
            if ($language.InputMethodTips.Contains($tip)) {
                [void]$language.InputMethodTips.Remove($tip)
                # Keep a usable input method for this language.
                if ($language.LanguageTag -eq 'en-US' -and $language.InputMethodTips.Count -eq 0) {
                    [void]$language.InputMethodTips.Add('0409:00000409')
                }
            }
        }
    } else {
        $registration = if ($Predictive) { 'HKLM:\Software\Classes\CLSID\{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}\InprocServer32' } else { 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\A0F00409' }
        if (-not (Test-Path $registration)) { throw 'Run the matching Install command first.' }
        $english = $languages | Where-Object LanguageTag -eq 'en-US' | Select-Object -First 1
        if (-not $english) {
            $english = (New-WinUserLanguageList 'en-US')[0]
            $languages.Add($english)
        }
        if (-not $english.InputMethodTips.Contains($tip)) { [void]$english.InputMethodTips.Add($tip) }
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
    elseif ($Predictive) { Write-Host 'Sign out and back in, then select Hanifi Rohingya Predictive with Win+Space. Click suggestions or press F1-F5; Escape dismisses them.' }
    else { Write-Host 'Sign out and back in, then use Win+Space to select Hanifi Rohingya. Choose Noto Sans Hanifi Rohingya in your document.' }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
