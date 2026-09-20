#define UNICODE
#define _UNICODE
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#define WM_TRAYICON (WM_USER + 1)
#define ID_TRAY_TOGGLE 1001
#define ID_TRAY_AUTOSTART 1002
#define ID_TRAY_HELP 1003
#define ID_TRAY_EXIT 1004

static const uint32_t KEY_MAP[256][2] = {
    [0x20] = {0x0020, 0x10D22}, /* Space -> Space, Shift+Space -> 𐴢 (sakin) */
    [0x30] = {0x10D30, 0x0029}, /* 0 -> 𐴰, ) */
    [0x31] = {0x10D31, 0x0021}, /* 1 -> 𐴱, ! */
    [0x32] = {0x10D32, 0x0040}, /* 2 -> 𐴲, @ */
    [0x33] = {0x10D33, 0x0023}, /* 3 -> 𐴳, # */
    [0x34] = {0x10D34, 0x0024}, /* 4 -> 𐴴, $ */
    [0x35] = {0x10D35, 0x0025}, /* 5 -> 𐴵, % */
    [0x36] = {0x10D36, 0x005E}, /* 6 -> 𐴶, ^ */
    [0x37] = {0x10D37, 0x0026}, /* 7 -> 𐴷, & */
    [0x38] = {0x10D38, 0x002A}, /* 8 -> 𐴸, * */
    [0x39] = {0x10D39, 0x0028}, /* 9 -> 𐴹, ( */
    ['A'] = {0x10D00, 0x10D26},  /* A -> 𐴀 (A), Shift+A -> 𐴦 (Tana Harbai) */
    ['B'] = {0x10D01, 0},        /* B -> 𐴁 (BA) */
    ['C'] = {0x10D10, 0},        /* C -> 𐴐 (CA) */
    ['D'] = {0x10D0B, 0},        /* D -> 𐴋 (DA) */
    ['E'] = {0x10D20, 0},        /* E -> 𐴠 (E) */
    ['F'] = {0x10D09, 0},        /* F -> 𐴉 (FA) */
    ['G'] = {0x10D12, 0},        /* G -> 𐴒 (GA) */
    ['H'] = {0x10D07, 0x10D24},  /* H -> 𐴇 (HA), Shift+H -> 𐴤 (Harbai) */
    ['I'] = {0x10D1E, 0},        /* I -> 𐴞 (I) */
    ['J'] = {0x10D05, 0},        /* J -> 𐴅 (JA) */
    ['K'] = {0x10D11, 0},        /* K -> 𐴑 (KA) */
    ['L'] = {0x10D13, 0x061B},   /* L -> 𐴓 (LA), Shift+L -> ؛ */
    ['M'] = {0x10D14, 0},        /* M -> 𐴔 (MA) */
    ['N'] = {0x10D15, 0},        /* N -> 𐴕 (NA) */
    ['O'] = {0x10D21, 0},        /* O -> 𐴡 (O) */
    ['P'] = {0x10D02, 0},        /* P -> 𐴂 (PA) */
    ['Q'] = {0x10D08, 0},        /* Q -> 𐴈 (KHA) */
    ['R'] = {0x10D0C, 0},        /* R -> 𐴌 (RA) */
    ['S'] = {0x10D0F, 0},        /* S -> 𐴏 (SA) */
    ['T'] = {0x10D04, 0x10D25},  /* T -> 𐴄 (TA), Shift+T -> 𐴥 (Tala) */
    ['U'] = {0x10D1F, 0},        /* U -> 𐴟 (U) */
    ['V'] = {0x10D1D, 0},        /* V -> 𐴝 (VA) */
    ['W'] = {0x10D16, 0},        /* W -> 𐴖 (WA) */
    ['X'] = {0x10D1A, 0},        /* X -> 𐴚 (NGA) */
    ['Y'] = {0x10D18, 0},        /* Y -> 𐴘 (YA) */
    ['Z'] = {0x10D0E, 0},        /* Z -> 𐴎 (ZA) */
    [0xBA] = {0x10D06, 0x003A},  /* ; -> 𐴆 (CHA), Shift+; -> : */
    [0xBB] = {0x003D, 0x002B},   /* = -> =, Shift+= -> + */
    [0xBC] = {0x10D03, 0x060C},  /* , -> 𐴃 (TTA), Shift+, -> ، */
    [0xBD] = {0x002D, 0x005F},   /* - -> -, Shift+- -> _ */
    [0xBE] = {0x10D0A, 0x06D4},  /* . -> 𐴊 (DDA), Shift+. -> ۔ */
    [0xBF] = {0x10D0D, 0x061F},  /* / -> 𐴍 (RRA), Shift+/ -> ؟ */
    [0xC0] = {0x10D22, 0x10D27}, /* ` -> 𐴢 (Sakin), Shift+` -> 𐴧 (Na-Khonna) */
    [0xDB] = {0x10D17, 0x007B},  /* [ -> 𐴗 (KINNA WA), Shift+[ -> { */
    [0xDC] = {0x10D23, 0x007C},  /* \ -> 𐴣 (NAISSI), Shift+\ -> | */
    [0xDD] = {0x10D19, 0x007D},  /* ] -> 𐴙 (KINNA YA), Shift+] -> } */
    [0xDE] = {0x10D1B, 0x0022},  /* ' -> 𐴛 (NYA), Shift+' -> " */
};

static HHOOK g_hook = NULL;
static HWND g_hwnd = NULL;
static NOTIFYICONDATAW g_nid = {0};
static bool g_enabled = true;
static bool g_injected = false;
static HICON g_iconActive = NULL;
static HICON g_iconInactive = NULL;

static HICON CreateTrayIcon(bool active) {
    int size = GetSystemMetrics(SM_CXSMICON);
    if (size <= 0) size = 16;
    HDC hdcScreen = GetDC(NULL);
    HDC hdcMem = CreateCompatibleDC(hdcScreen);
    HBITMAP hbmColor = CreateCompatibleBitmap(hdcScreen, size, size);
    HBITMAP hbmMask = CreateCompatibleBitmap(hdcScreen, size, size);
    
    HBITMAP hOld = (HBITMAP)SelectObject(hdcMem, hbmColor);
    HBRUSH bgBrush = CreateSolidBrush(active ? RGB(0, 128, 90) : RGB(100, 110, 120));
    RECT rc = {0, 0, size, size};
    FillRect(hdcMem, &rc, bgBrush);
    DeleteObject(bgBrush);

    SetBkMode(hdcMem, TRANSPARENT);
    SetTextColor(hdcMem, RGB(255, 255, 255));
    HFONT hFont = CreateFontW(size * 7 / 10, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                             DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                             CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
    HFONT hOldFont = (HFONT)SelectObject(hdcMem, hFont);
    DrawTextW(hdcMem, L"RH", -1, &rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
    
    SelectObject(hdcMem, hbmMask);
    HBRUSH maskBrush = CreateSolidBrush(RGB(0, 0, 0));
    FillRect(hdcMem, &rc, maskBrush);
    DeleteObject(maskBrush);

    SelectObject(hdcMem, hOldFont);
    DeleteObject(hFont);
    SelectObject(hdcMem, hOld);
    DeleteDC(hdcMem);
    ReleaseDC(NULL, hdcScreen);

    ICONINFO ii = {0};
    ii.fIcon = TRUE;
    ii.hbmMask = hbmMask;
    ii.hbmColor = hbmColor;
    HICON hIcon = CreateIconIndirect(&ii);

    DeleteObject(hbmColor);
    DeleteObject(hbmMask);
    return hIcon;
}

static void UpdateTray() {
    g_nid.hIcon = g_enabled ? g_iconActive : g_iconInactive;
    wcscpy(g_nid.szTip, g_enabled ? L"Hanifi Rohingya Keyboard: ON (Ctrl+Shift to toggle)" : L"Hanifi Rohingya Keyboard: OFF (Ctrl+Shift to toggle)");
    Shell_NotifyIconW(NIM_MODIFY, &g_nid);
}

static void ToggleState() {
    g_enabled = !g_enabled;
    UpdateTray();
    
    // Show notification balloon on toggle
    g_nid.uFlags |= NIF_INFO;
    wcscpy(g_nid.szInfoTitle, L"Hanifi Rohingya Keyboard");
    wcscpy(g_nid.szInfo, g_enabled ? L"Typing in Hanifi Rohingya (ON)\nPress Ctrl+Shift to switch to English." : L"Typing in English (OFF)\nPress Ctrl+Shift to switch to Rohingya.");
    g_nid.dwInfoFlags = NIIF_INFO;
    Shell_NotifyIconW(NIM_MODIFY, &g_nid);
    g_nid.uFlags &= ~NIF_INFO;
}

static bool IsAutoStartEnabled() {
    HKEY hKey;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, L"Software\\Microsoft\\Windows\\CurrentVersion\\Run", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        DWORD type = 0, size = 0;
        LONG res = RegQueryValueExW(hKey, L"HanifiRohingyaKeyboard", NULL, &type, NULL, &size);
        RegCloseKey(hKey);
        return (res == ERROR_SUCCESS);
    }
    return false;
}

static void SetAutoStart(bool enable) {
    HKEY hKey;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, L"Software\\Microsoft\\Windows\\CurrentVersion\\Run", 0, KEY_SET_VALUE, &hKey) == ERROR_SUCCESS) {
        if (enable) {
            WCHAR path[MAX_PATH];
            GetModuleFileNameW(NULL, path, MAX_PATH);
            RegSetValueExW(hKey, L"HanifiRohingyaKeyboard", 0, REG_SZ, (const BYTE*)path, (wcslen(path) + 1) * sizeof(WCHAR));
        } else {
            RegDeleteValueW(hKey, L"HanifiRohingyaKeyboard");
        }
        RegCloseKey(hKey);
    }
}

static void SendUnicodeScalar(uint32_t codepoint) {
    INPUT inputs[4] = {0};
    int count = 0;
    
    if (codepoint > 0xFFFF) {
        // Surrogate pair for SMP characters (U+10D00 - U+10D39)
        uint16_t high = (uint16_t)(0xD800 + ((codepoint - 0x10000) >> 10));
        uint16_t low  = (uint16_t)(0xDC00 + ((codepoint - 0x10000) & 0x3FF));
        
        inputs[0].type = INPUT_KEYBOARD;
        inputs[0].ki.wScan = high;
        inputs[0].ki.dwFlags = KEYEVENTF_UNICODE;
        
        inputs[1].type = INPUT_KEYBOARD;
        inputs[1].ki.wScan = low;
        inputs[1].ki.dwFlags = KEYEVENTF_UNICODE;
        
        inputs[2].type = INPUT_KEYBOARD;
        inputs[2].ki.wScan = high;
        inputs[2].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
        
        inputs[3].type = INPUT_KEYBOARD;
        inputs[3].ki.wScan = low;
        inputs[3].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
        count = 4;
    } else {
        inputs[0].type = INPUT_KEYBOARD;
        inputs[0].ki.wScan = (uint16_t)codepoint;
        inputs[0].ki.dwFlags = KEYEVENTF_UNICODE;
        
        inputs[1].type = INPUT_KEYBOARD;
        inputs[1].ki.wScan = (uint16_t)codepoint;
        inputs[1].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
        count = 2;
    }
    
    g_injected = true;
    SendInput(count, inputs, sizeof(INPUT));
    g_injected = false;
}

static LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION && !g_injected) {
        KBDLLHOOKSTRUCT *p = (KBDLLHOOKSTRUCT*)lParam;
        
        // Check for Hotkey: Ctrl+Shift or F12
        if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
            bool ctrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
            bool shift = (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
            if (p->vkCode == VK_F12 || (ctrl && (p->vkCode == VK_SHIFT || p->vkCode == VK_LSHIFT || p->vkCode == VK_RSHIFT))) {
                ToggleState();
                return 1;
            }
        }
        
        // If enabled and not combining with Ctrl or Alt or Windows key
        if (g_enabled && (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN)) {
            bool ctrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
            bool alt  = (GetAsyncKeyState(VK_MENU) & 0x8000) != 0;
            bool win  = ((GetAsyncKeyState(VK_LWIN) & 0x8000) != 0) || ((GetAsyncKeyState(VK_RWIN) & 0x8000) != 0);
            
            if (!ctrl && !alt && !win && p->vkCode < 256) {
                bool shift = (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
                uint32_t cp = KEY_MAP[p->vkCode][shift ? 1 : 0];
                if (cp != 0) {
                    SendUnicodeScalar(cp);
                    return 1; // Suppress original keystroke
                }
            }
        } else if (g_enabled && (wParam == WM_KEYUP || wParam == WM_SYSKEYUP)) {
            bool ctrl = (GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0;
            bool alt  = (GetAsyncKeyState(VK_MENU) & 0x8000) != 0;
            bool win  = ((GetAsyncKeyState(VK_LWIN) & 0x8000) != 0) || ((GetAsyncKeyState(VK_RWIN) & 0x8000) != 0);
            if (!ctrl && !alt && !win && p->vkCode < 256) {
                bool shift = (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
                if (KEY_MAP[p->vkCode][shift ? 1 : 0] != 0) {
                    return 1; // Suppress keyup
                }
            }
        }
    }
    return CallNextHookEx(g_hook, nCode, wParam, lParam);
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_TRAYICON:
            if (lParam == WM_LBUTTONUP) {
                ToggleState();
            } else if (lParam == WM_RBUTTONUP) {
                POINT pt;
                GetCursorPos(&pt);
                HMENU hMenu = CreatePopupMenu();
                AppendMenuW(hMenu, MF_STRING | (g_enabled ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_TOGGLE, L"&Hanifi Rohingya (Ctrl+Shift)");
                AppendMenuW(hMenu, MF_STRING | (IsAutoStartEnabled() ? MF_CHECKED : MF_UNCHECKED), ID_TRAY_AUTOSTART, L"&Start with Windows");
                AppendMenuW(hMenu, MF_SEPARATOR, 0, NULL);
                AppendMenuW(hMenu, MF_STRING, ID_TRAY_HELP, L"&Website / Info");
                AppendMenuW(hMenu, MF_STRING, ID_TRAY_EXIT, L"E&xit");
                
                SetForegroundWindow(hwnd);
                int cmd = TrackPopupMenu(hMenu, TPM_RETURNCMD | TPM_NONOTIFY, pt.x, pt.y, 0, hwnd, NULL);
                DestroyMenu(hMenu);
                
                if (cmd == ID_TRAY_TOGGLE) {
                    ToggleState();
                } else if (cmd == ID_TRAY_AUTOSTART) {
                    SetAutoStart(!IsAutoStartEnabled());
                } else if (cmd == ID_TRAY_HELP) {
                    ShellExecuteW(NULL, L"open", L"https://rohingyahub.org", NULL, NULL, SW_SHOWNORMAL);
                } else if (cmd == ID_TRAY_EXIT) {
                    PostQuitMessage(0);
                }
            }
            break;
        case WM_DESTROY:
            Shell_NotifyIconW(NIM_DELETE, &g_nid);
            PostQuitMessage(0);
            break;
        default:
            return DefWindowProcW(hwnd, msg, wParam, lParam);
    }
    return 0;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    (void)hPrevInstance; (void)lpCmdLine; (void)nCmdShow;

    // Single instance mutex
    HANDLE hMutex = CreateMutexW(NULL, TRUE, L"HanifiRohingyaKeyboardMutex");
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        MessageBoxW(NULL, L"Hanifi Rohingya Keyboard is already running in your system tray.\nPress Ctrl+Shift to toggle typing.", L"Hanifi Rohingya Keyboard", MB_OK | MB_ICONINFORMATION);
        return 0;
    }

    WNDCLASSEXW wc = {0};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = L"HanifiRohingyaKeyboardClass";
    RegisterClassExW(&wc);

    g_hwnd = CreateWindowExW(0, wc.lpszClassName, L"Hanifi Rohingya Keyboard", 0, 0, 0, 0, 0, HWND_MESSAGE, NULL, hInstance, NULL);

    g_iconActive = CreateTrayIcon(true);
    g_iconInactive = CreateTrayIcon(false);

    g_nid.cbSize = sizeof(g_nid);
    g_nid.hWnd = g_hwnd;
    g_nid.uID = 1;
    g_nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP | NIF_INFO;
    g_nid.uCallbackMessage = WM_TRAYICON;
    g_nid.hIcon = g_iconActive;
    wcscpy(g_nid.szTip, L"Hanifi Rohingya Keyboard: ON (Ctrl+Shift to toggle)");
    wcscpy(g_nid.szInfoTitle, L"Hanifi Rohingya Keyboard Active");
    wcscpy(g_nid.szInfo, L"Now active across Windows!\nType in Notepad, Word, or any app.\nPress Ctrl+Shift anytime to switch to English.");
    g_nid.dwInfoFlags = NIIF_INFO;
    Shell_NotifyIconW(NIM_ADD, &g_nid);
    g_nid.uFlags &= ~NIF_INFO;

    // Install global low-level keyboard hook
    g_hook = SetWindowsHookExW(WH_KEYBOARD_LL, LowLevelKeyboardProc, hInstance, 0);
    if (!g_hook) {
        MessageBoxW(NULL, L"Failed to initialize keyboard hook.", L"Error", MB_ICONERROR);
        return 1;
    }

    MSG msg;
    while (GetMessageW(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    if (g_hook) UnhookWindowsHookEx(g_hook);
    if (hMutex) ReleaseMutex(hMutex);
    return 0;
}
