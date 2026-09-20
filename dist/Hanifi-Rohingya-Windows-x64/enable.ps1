# Run as the person who will type, not as a different administrator account.
[CmdletBinding()]
param([switch]$Remove)
$ErrorActionPreference = 'Stop'
try {
    $tip = '0409:A0F00409'
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
        if (-not (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\A0F00409')) { throw 'Run Install.cmd first.' }
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
    else { Write-Host 'Sign out and back in, then use Win+Space to select Hanifi Rohingya. Choose Noto Sans Hanifi Rohingya in your document.' }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
