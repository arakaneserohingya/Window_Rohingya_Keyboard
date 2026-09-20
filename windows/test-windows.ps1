# After installation, verifies actual Windows ToUnicodeEx output for every mapped state.
$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class RohingyaNativeTest {
 [DllImport("user32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
 public static extern IntPtr LoadKeyboardLayout(string name, uint flags);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)]
 public static extern int ToUnicodeEx(uint vk, uint scan, byte[] state, [Out] char[] output, int size, uint flags, IntPtr layout);
 [DllImport("user32.dll")]
 public static extern uint MapVirtualKeyEx(uint code, uint type, IntPtr layout);
 [DllImport("user32.dll")]
 public static extern bool UnloadKeyboardLayout(IntPtr layout);
}
'@
$layout = [RohingyaNativeTest]::LoadKeyboardLayout('A0F00409',0)
if ($layout -eq [IntPtr]::Zero) { throw 'Windows could not load the installed keyboard.' }
try {
    $cases = Get-Content (Join-Path $PSScriptRoot 'expected-layout.json') -Raw | ConvertFrom-Json
    $count = 0
    foreach ($case in $cases) {
        $vk = [uint32]$case[0]
        for ($modifier=0; $modifier -lt 4; $modifier++) {
            foreach ($caps in @(0,1)) {
                $keys = New-Object byte[] 256
                $keys[0x14] = $caps
                if ($modifier -band 1) { $keys[0x10]=128 }
                if ($modifier -band 2) { $keys[0x11]=128 }
                $output = New-Object char[] 8
                $scan = [RohingyaNativeTest]::MapVirtualKeyEx($vk,0,$layout)
                $length = [RohingyaNativeTest]::ToUnicodeEx($vk,$scan,$keys,$output,8,0,$layout)
                $cp = $case[1][$modifier]
                $expected = if ($null -eq $cp) { '' } else { [char]::ConvertFromUtf32([int]$cp) }
                $actual = if ($length -gt 0) { -join $output[0..($length-1)] } else { '' }
                if ($actual -cne $expected) { throw "Mismatch: VK=$vk modifier=$modifier caps=$caps returned $length UTF-16 units; expected U+$cp" }
                $count++
            }
        }
    }
    Write-Host "Passed $count Windows translation checks, including Caps Lock and supplementary Unicode."
} finally {
    [void][RohingyaNativeTest]::UnloadKeyboardLayout($layout)
}
