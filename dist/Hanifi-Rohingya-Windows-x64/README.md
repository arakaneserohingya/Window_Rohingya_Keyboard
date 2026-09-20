<p align="center">
  <img src="assets/icon.png" alt="Hanifi Rohingya Keyboard Logo" width="128" height="128" />
</p>

<h1 align="center">Hanifi Rohingya — Native Windows Keyboard</h1>

<p align="center">
  <b>No Keyman &bull; No Background Application &bull; No Runtime Dependency</b>
</p>

Your own Windows keyboard layout: **no Keyman, no background application, and no runtime dependency**. The package contains native `kbdroh.dll` (x64 and ARM64), installation/removal scripts, and the Noto Sans Hanifi Rohingya font.

**Target: Windows 10/11 on 64-bit platforms (Intel/AMD x64 and ARM64).** Supports both native PC hardware and Windows 11 running on Apple Silicon VMs (Parallels/VMware) as well as Snapdragon PCs. 32-bit Windows is not supported.

## Installation Options

The package provides two installation modes:

### Option 1: Standard Native Keyboard (Recommended)
Fast, ultra-lightweight Windows kernel keyboard driver (`kbdroh.dll`) with 0% CPU and 0 MB RAM overhead:
1. Download/copy [`Hanifi-Rohingya-Windows-x64.zip`](dist/Hanifi-Rohingya-Windows-x64.zip) to Windows.
2. **Extract the entire ZIP.** Open the extracted folder and double-click **`Install.cmd`**.
3. Approve the Windows administrator prompt. The script registers the DLL, enables the **RHG** language profile, and installs the Noto font.
4. Sign out and back in. Press **Win+Space** and select **Hanifi Rohingya (RHG)**.
5. In Word or your editor, select **Noto Sans Hanifi Rohingya** and **right-to-left paragraph direction**.

### Option 2: Predictive Keyboard with Word Suggestions (TSF IME)
Full Windows Text Services Framework IME (`rohime.dll`) providing **live word suggestions & completions** from an 18,200+ Rohingya word dictionary:
1. Double-click **`Install-Predictive.cmd`**.
2. Sign out and back in. Press **Win+Space** and select **Hanifi Rohingya Predictive (RHG)**.
3. As you type, candidate suggestions appear:
   - Press **F1–F5** or click a suggestion chip to insert the word.
   - Press **Escape** or keep typing to dismiss.

The layout is registered under the official Rohingya (`rhg-Rohg` / `rhg`) language profile, displaying the **RHG** language indicator and **Hanifi Rohingya** name in the Windows taskbar and <kbd>Win</kbd>+<kbd>Space</kbd> language switcher. Existing language choices and keyboards are retained.

### 📸 Installation Steps in Pictures

| Step 1: Extract ZIP & Run `Install.cmd` | Step 2: Setup Dialog (Click Install) |
| :---: | :---: |
| <img src="assets/installs/1.png" alt="Step 1: Run Install.cmd" width="450" /> | <img src="assets/installs/2.png" alt="Step 2: Welcome Setup Dialog" width="450" /> |

| Step 3: Approve Administrator Prompt | Step 4: Success & Ready to Type |
| :---: | :---: |
| <img src="assets/installs/3.png" alt="Step 3: UAC Prompt" width="450" /> | <img src="assets/installs/4.png" alt="Step 4: Installation Complete" width="450" /> |

## Remove

* **To remove standard layout:** Switch to another keyboard and run **`Uninstall.cmd`**.
* **To remove predictive layout:** Run **`Uninstall-Predictive.cmd`**.
* Each additional user should run `enable.ps1 -Remove` in their own account. The font is retained so existing documents remain readable.

## Layout and practice

Open [`preview.html`](preview.html) in the repository or extracted Windows package directly in a browser for offline practice. It includes clickable and physical keys, Shift, copying, and UTF-8 text download. Keep `layout.js`, `preview.js`, and `assets/` alongside it. The preview types only in its text box; the installed native DLL works through Windows input.

| Key | Output |
| --- | --- |
| A / B / P | Letter A / BA / PA |
| V / I / U / E / O | Vowels A / I / U / E / O |
| Top-row 0–9 | Hanifi Rohingya digits |
| Backquote or Shift+Space | Sakin |
| Backslash | Na Khonna |
| Shift+H / Shift+T / Shift+A | Harbahay / Tahala / Tana |
| Shift+Backquote | Tassi (gemination) |
| Shift+comma / period / slash | Arabic comma / full stop / question mark |
| Shift+L | Arabic semicolon |

The layout exposes 49 Hanifi characters. U+10D1C (letter VA) is not assigned in the published SIL layout. Unused shifted letters produce no text; shifted numbers produce US punctuation. Caps Lock does not change the output. The number pad retains ASCII digits for numeric entry. Ctrl control characters and ordinary navigation keys are preserved; Alt combinations do not emit Rohingya text.

Type in logical reading order, with combining signs following their base; do not reverse stored text. Font shaping, right-to-left paragraph direction, and deletion behavior belong to the application. A native layout cannot force an application's paragraph direction or fix its Unicode handling.

## Repository Structure

- `build.py`: single source of truth for key mappings; generates C tables, preview data, and Windows test expectations.
- `dictionary_import.py`: decodes `dictionary/main_rhg.dict` and generates `model.json`, `model.js`, and C++ `ime/model.inc`.
- `dictionary/`: binary dictionary source (`main_rhg.dict`) and web prediction models (`model.json`, `model.js`).
- `native/`: Windows scan codes, modifiers, key names, ABI definitions (`keyboard.c`, `keyboard_abi.h`, `layout.inc`).
- `ime/`: Windows Text Services Framework predictive IME (`service.cpp`, `predictor.h`, `keys.inc`, `model.inc`).
- `windows/`: installation/removal scripts and Windows acceptance tests.
- `assets/`: icon, author branding, and Noto Sans Hanifi Rohingya font.
- `preview.html`: interactive offline browser practice editor and virtual keyboard.
- `dist/Hanifi-Rohingya-Windows-x64.zip`: native package ready to transfer to Windows.

## Build

Requires Python 3.9+ and [Zig 0.14.1](https://ziglang.org/download/). The cross-platform build uses Zig's C compiler and linker; no Windows SDK is required.

```sh
python3 build.py --compile --zig /path/to/zig
python3 -m unittest discover -s tests
```

Or, with `zig` on PATH, run `npm run build`. Node.js is only used for optional browser tests:

```sh
npm ci
npx playwright install chromium
npm run test:browser
```

`BROWSER_EXECUTABLE` can point to an existing Chromium-family browser. To regenerate the mapping without compiling, run `python3 build.py`.

The DLL uses a minimal entry point that performs no initialization and has no imported runtime functions. Each supplementary Unicode scalar is emitted as a two-unit UTF-16 surrogate pair using Windows' ligature table. Microsoft's [ToUnicode documentation](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-tounicode) explicitly describes supplementary-character output as surrogate pairs.

## Windows verification

After installation, open Windows PowerShell in the extracted folder and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\test-windows.ps1
```

This exercises **Windows' actual ToUnicodeEx function** across every generated key/state with Caps Lock both off and on. It is provided for Windows validation and has not been run from this macOS workspace. Then test Word/Notepad/browser input, combining marks, backspace, Ctrl+C/V/Z, navigation, Win+Space switching, restart persistence, and uninstall. Unicode behavior in older applications may vary.

The installer registers `A0F00409` / Layout Id `0F00`, refuses identifier collisions, and will not overwrite a different existing DLL. Removal checks ownership. Installation modifies the machine's keyboard registry and copies the DLL to System32; user input preferences and font registration are handled separately in the original user's account.

## Layout Source and Specification

Normal and Shift key positions follow [SIL Global’s published Hanifi Rohingya layout](https://github.com/keymanapp/keyboards/blob/master/release/h/hanifi_rohingya/source/hanifi_rohingya.kmn), with its [MIT attribution](keyboard/LICENSE.md) retained. That mapping is data only; this native implementation does not use its keyboard engine. The upstream source is preserved in `keyboard/hanifi_rohingya.reference.kmn` for comparison. “Published SIL layout” identifies the source; this project does not claim government certification. The Noto font is distributed under its [SIL Open Font License](assets/OFL.txt).

The Unicode repertoire is [U+10D00–U+10D3F](https://www.unicode.org/charts/PDF/U10D00.pdf). Native table structure and scan-code conventions were checked against the Windows SDK `kbd.h` and Microsoft's [keyboard layout sample](https://github.com/microsoft/Windows-driver-samples/tree/main/input/layout/kbdus). Windows input-list registration follows [Get-WinUserLanguageList](https://learn.microsoft.com/en-us/powershell/module/international/get-winuserlanguagelist) and [keyboard registry documentation](https://learn.microsoft.com/en-us/windows/win32/intl/using-registry-string-redirection).

## Author & Developer

<p align="left">
  <img src="assets/author.jpg" alt="Ahkter Husin" width="120" style="border-radius: 50%;" />
</p>

* **Developer**: **Ahkter Husin**
* **GitHub**: [@arakaneserohingya](https://github.com/arakaneserohingya)
* **Website**: [rohingyahub.org](https://rohingyahub.org)

