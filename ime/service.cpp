#define UNICODE
#define _UNICODE
#include <windows.h>
#include <msctf.h>
#include <inputscope.h>
#include <oleauto.h>
#include <new>
#include "predictor.h"
#include "keys.inc"

// Separate identity from the basic kbdroh.dll keyboard.
static const CLSID CLSID_Rohingya = {0x7dd2fb83,0xbcd2,0x4bf2,{0xb9,0x37,0xb1,0xe9,0x06,0x28,0x36,0xa1}};
static const GUID PROFILE_Rohingya = {0x4c379be1,0xf64e,0x493a,{0x92,0xcd,0x67,0x85,0x8a,0x74,0x23,0xbe}};
static HINSTANCE module;
static LONG objects = 0;
static const wchar_t *windowClass = L"HanifiRohingyaCandidates";

template<class T> struct Com {
    T *p = nullptr;
    ~Com() { if (p) p->Release(); }
    T **out() { return &p; }
    T *operator->() const { return p; }
    operator bool() const { return p != nullptr; }
};
static std::wstring wide(std::u16string_view s) {
    static_assert(sizeof(wchar_t) == sizeof(char16_t));
    return std::wstring(s.begin(), s.end());
}
static bool down(int vk) { return (GetKeyState(vk) & 0x8000) != 0; }
static bool compartment(ITfContext *ctx, REFGUID id) {
    Com<ITfCompartmentMgr> mgr; Com<ITfCompartment> value;
    if (FAILED(ctx->QueryInterface(IID_ITfCompartmentMgr, reinterpret_cast<void **>(mgr.out()))) ||
        FAILED(mgr->GetCompartment(id, value.out()))) return false;
    VARIANT v; VariantInit(&v);
    bool result = SUCCEEDED(value->GetValue(&v)) && v.vt == VT_I4 && v.lVal != 0;
    VariantClear(&v); return result;
}
static bool disabled(ITfContext *ctx) {
    TF_STATUS status{};
    return !ctx || FAILED(ctx->GetStatus(&status)) || (status.dwDynamicFlags & TS_SD_READONLY) ||
        compartment(ctx, GUID_COMPARTMENT_KEYBOARD_DISABLED) || compartment(ctx, GUID_COMPARTMENT_EMPTYCONTEXT);
}
static bool sensitive(ITfContext *ctx, TfEditCookie cookie, ITfRange *range) {
    Com<ITfProperty> prop;
    if (FAILED(ctx->GetProperty(GUID_PROP_INPUTSCOPE, prop.out()))) return false;
    VARIANT v; VariantInit(&v);
    bool result = false;
    if (SUCCEEDED(prop->GetValue(cookie, range, &v)) && v.vt == VT_UNKNOWN && v.punkVal) {
        Com<ITfInputScope> scope;
        if (SUCCEEDED(v.punkVal->QueryInterface(IID_ITfInputScope, reinterpret_cast<void **>(scope.out())))) {
            InputScope *scopes = nullptr; UINT count = 0;
            if (SUCCEEDED(scope->GetInputScopes(&scopes, &count))) {
                for (UINT i = 0; i < count; ++i)
                    if (scopes[i] == IS_PASSWORD || scopes[i] == IS_NUMERIC_PIN ||
                        scopes[i] == IS_ALPHANUMERIC_PIN || scopes[i] == IS_ALPHANUMERIC_PIN_SET) result = true;
                CoTaskMemFree(scopes);
            }
        }
    }
    VariantClear(&v); return result;
}
struct Snapshot { std::u16string before, after; rhg::Context context; };
static bool readSnapshot(ITfContext *ctx, TfEditCookie cookie, ITfRange *selection, Snapshot &out) {
    BOOL empty = FALSE;
    if (FAILED(selection->IsEmpty(cookie, &empty)) || !empty || sensitive(ctx, cookie, selection)) return false;
    Com<ITfRange> before, after;
    if (FAILED(selection->Clone(before.out())) || FAILED(selection->Clone(after.out()))) return false;
    LONG shifted = 0;
    if (FAILED(before->ShiftStart(cookie, -256, &shifted, nullptr))) return false;
    WCHAR buffer[256]; ULONG read = 0;
    if (FAILED(before->GetText(cookie, 0, buffer, 256, &read))) return false;
    out.before.assign(buffer, buffer + read);
    if (FAILED(after->ShiftEnd(cookie, 2, &shifted, nullptr))) return false;
    if (FAILED(after->GetText(cookie, 0, buffer, 2, &read))) return false;
    out.after.assign(buffer, buffer + read);
    out.context = rhg::context(out.before, out.after);
    return out.context.valid;
}
class Service;
class Edit final : public ITfEditSession {
    LONG refs = 1;
    Service *owner;
    ITfContext *ctx;
    std::u16string text;
    bool candidate;
    Snapshot expected;
public:
    Edit(Service *s, ITfContext *c, std::u16string t, bool replace, Snapshot snapshot);
    ~Edit();
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID id, void **out) override {
        if (!out) return E_POINTER;
        *out = nullptr;
        if (id == IID_IUnknown || id == IID_ITfEditSession) *out = static_cast<ITfEditSession *>(this);
        if (!*out) return E_NOINTERFACE;
        AddRef(); return S_OK;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return InterlockedIncrement(&refs); }
    ULONG STDMETHODCALLTYPE Release() override { ULONG n = InterlockedDecrement(&refs); if (!n) delete this; return n; }
    HRESULT STDMETHODCALLTYPE DoEditSession(TfEditCookie cookie) override;
};
class Service final : public ITfTextInputProcessor, public ITfKeyEventSink,
                public ITfThreadMgrEventSink, public ITfTextEditSink {
    LONG refs = 1;
    ITfThreadMgr *manager = nullptr;
    ITfContext *context = nullptr;
    TfClientId client = 0;
    DWORD managerCookie = TF_INVALID_COOKIE, editCookie = TF_INVALID_COOKIE;
    HWND popup = nullptr;
    HFONT font = nullptr;
    bool editing = false, hidden = false, foreground = true;
    std::vector<unsigned> candidates;
    Snapshot snapshot;
    friend class Edit;
public:
    Service() { InterlockedIncrement(&objects); }
    ~Service() { Deactivate(); InterlockedDecrement(&objects); }
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID id, void **out) override {
        if (!out) return E_POINTER;
        *out = nullptr;
        if (id == IID_IUnknown || id == IID_ITfTextInputProcessor) *out = static_cast<ITfTextInputProcessor *>(this);
        else if (id == IID_ITfKeyEventSink) *out = static_cast<ITfKeyEventSink *>(this);
        else if (id == IID_ITfThreadMgrEventSink) *out = static_cast<ITfThreadMgrEventSink *>(this);
        else if (id == IID_ITfTextEditSink) *out = static_cast<ITfTextEditSink *>(this);
        if (!*out) return E_NOINTERFACE;
        AddRef(); return S_OK;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return InterlockedIncrement(&refs); }
    ULONG STDMETHODCALLTYPE Release() override { ULONG n = InterlockedDecrement(&refs); if (!n) delete this; return n; }
    void hide() { if (popup) ShowWindow(popup, SW_HIDE); candidates.clear(); snapshot = {}; }
    void bind(ITfContext *next) {
        hide(); hidden = false;
        if (context) {
            Com<ITfSource> source;
            if (editCookie != TF_INVALID_COOKIE && SUCCEEDED(context->QueryInterface(IID_ITfSource, reinterpret_cast<void **>(source.out()))))
                source->UnadviseSink(editCookie);
            context->Release(); context = nullptr; editCookie = TF_INVALID_COOKIE;
        }
        if (next) {
            context = next; context->AddRef();
            Com<ITfSource> source;
            if (SUCCEEDED(context->QueryInterface(IID_ITfSource, reinterpret_cast<void **>(source.out()))))
                source->AdviseSink(IID_ITfTextEditSink, static_cast<ITfTextEditSink *>(this), &editCookie);
        }
    }
    void focus(ITfDocumentMgr *doc) {
        Com<ITfContext> next;
        if (doc) doc->GetTop(next.out());
        bind(next.p);
    }
    HRESULT STDMETHODCALLTYPE Activate(ITfThreadMgr *mgr, TfClientId id) override {
        if (!mgr) return E_INVALIDARG;
        manager = mgr; manager->AddRef(); client = id;
        Com<ITfKeystrokeMgr> keys; Com<ITfSource> source;
        HRESULT hr = manager->QueryInterface(IID_ITfKeystrokeMgr, reinterpret_cast<void **>(keys.out()));
        if (SUCCEEDED(hr)) hr = keys->AdviseKeyEventSink(client, static_cast<ITfKeyEventSink *>(this), TRUE);
        if (SUCCEEDED(hr)) hr = manager->QueryInterface(IID_ITfSource, reinterpret_cast<void **>(source.out()));
        if (SUCCEEDED(hr)) hr = source->AdviseSink(IID_ITfThreadMgrEventSink, static_cast<ITfThreadMgrEventSink *>(this), &managerCookie);
        if (FAILED(hr)) { Deactivate(); return hr; }
        WNDCLASSW wc{}; wc.hInstance = module; wc.lpfnWndProc = windowProc;
        wc.lpszClassName = windowClass; wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
        RegisterClassW(&wc);
        popup = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_TOPMOST,
            windowClass, L"Hanifi Rohingya suggestions", WS_POPUP | WS_BORDER, 0, 0, 380, 200,
            nullptr, nullptr, module, this);
        font = CreateFontW(-24, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
            OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, DEFAULT_PITCH, L"Noto Sans Hanifi Rohingya");
        Com<ITfDocumentMgr> doc; manager->GetFocus(doc.out()); focus(doc.p);
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE Deactivate() override {
        bind(nullptr);
        if (popup) { DestroyWindow(popup); popup = nullptr; }
        if (font) { DeleteObject(font); font = nullptr; }
        if (manager) {
            Com<ITfKeystrokeMgr> keys; Com<ITfSource> source;
            if (SUCCEEDED(manager->QueryInterface(IID_ITfKeystrokeMgr, reinterpret_cast<void **>(keys.out())))) keys->UnadviseKeyEventSink(client);
            if (managerCookie != TF_INVALID_COOKIE && SUCCEEDED(manager->QueryInterface(IID_ITfSource, reinterpret_cast<void **>(source.out())))) source->UnadviseSink(managerCookie);
            manager->Release(); manager = nullptr;
        }
        client = 0; managerCookie = TF_INVALID_COOKIE;
        return S_OK;
    }
    bool handles(ITfContext *ctx, WPARAM key) {
        if (disabled(ctx) || down(VK_CONTROL) || down(VK_MENU) || down(VK_LWIN) || down(VK_RWIN)) return false;
        if (!candidates.empty() && ((key >= VK_F1 && key < VK_F1 + candidates.size()) || key == VK_ESCAPE)) return true;
        return key < 256 && keyMap[key][0] != 0;
    }
    HRESULT request(ITfContext *ctx, std::u16string text, bool replace) {
        auto session = new(std::nothrow) Edit(this, ctx, std::move(text), replace, snapshot);
        if (!session) return E_OUTOFMEMORY;
        HRESULT result = E_FAIL;
        // Synchronous edits avoid swallowing a key whose deferred edit later fails.
        HRESULT hr = ctx->RequestEditSession(client, session, TF_ES_SYNC | TF_ES_READWRITE, &result);
        session->Release(); return FAILED(hr) ? hr : result;
    }
    void choose(size_t index) {
        if (!context || index >= candidates.size() || disabled(context)) { hide(); return; }
        request(context, rhg::words[candidates[index]].text, true);
    }
    HRESULT STDMETHODCALLTYPE OnTestKeyDown(ITfContext *ctx, WPARAM key, LPARAM, BOOL *eaten) override { *eaten = handles(ctx, key); return S_OK; }
    HRESULT STDMETHODCALLTYPE OnTestKeyUp(ITfContext *, WPARAM, LPARAM, BOOL *eaten) override { *eaten = FALSE; return S_OK; }
    HRESULT STDMETHODCALLTYPE OnKeyUp(ITfContext *, WPARAM, LPARAM, BOOL *eaten) override { *eaten = FALSE; return S_OK; }
    HRESULT STDMETHODCALLTYPE OnKeyDown(ITfContext *ctx, WPARAM key, LPARAM, BOOL *eaten) override {
        *eaten = FALSE;
        if (!handles(ctx, key)) { hide(); return S_OK; }
        if (ctx != context) bind(ctx);
        if (key == VK_ESCAPE) { hidden = true; hide(); *eaten = TRUE; return S_OK; }
        if (key >= VK_F1 && key <= VK_F5) { choose(key-VK_F1); *eaten = TRUE; return S_OK; }
        hidden = false;
        unsigned cp = keyMap[key][down(VK_SHIFT) ? 1 : 0];
        if (!cp) { *eaten = TRUE; return S_OK; }
        std::u16string text;
        if (cp > 0xffff) { cp -= 0x10000; text += char16_t(0xd800 + (cp >> 10)); text += char16_t(0xdc00 + (cp & 1023)); }
        else text += char16_t(cp);
        *eaten = SUCCEEDED(request(ctx, text, false));
        return S_OK;
    }
    HRESULT STDMETHODCALLTYPE OnPreservedKey(ITfContext *, REFGUID, BOOL *eaten) override { *eaten = FALSE; return S_OK; }
    HRESULT STDMETHODCALLTYPE OnSetFocus(BOOL foreground) override { this->foreground = foreground; if (!foreground) hide(); return S_OK; }
    HRESULT STDMETHODCALLTYPE OnSetFocus(ITfDocumentMgr *next, ITfDocumentMgr *) override { focus(next); return S_OK; }
    HRESULT STDMETHODCALLTYPE OnInitDocumentMgr(ITfDocumentMgr *) override { return S_OK; }
    HRESULT STDMETHODCALLTYPE OnUninitDocumentMgr(ITfDocumentMgr *) override { return S_OK; }
    HRESULT STDMETHODCALLTYPE OnPushContext(ITfContext *ctx) override { bind(ctx); return S_OK; }
    HRESULT STDMETHODCALLTYPE OnPopContext(ITfContext *) override {
        Com<ITfDocumentMgr> doc; if (manager) manager->GetFocus(doc.out()); focus(doc.p); return S_OK;
    }
    HRESULT STDMETHODCALLTYPE OnEndEdit(ITfContext *ctx, TfEditCookie cookie, ITfEditRecord *) override {
        if (!editing && ctx == context) refresh(ctx, cookie);
        return S_OK;
    }
    void refresh(ITfContext *ctx, TfEditCookie cookie) {
        hide();
        if (!foreground || hidden || disabled(ctx) || !popup) return;
        TF_SELECTION selection{}; ULONG fetched = 0;
        if (FAILED(ctx->GetSelection(cookie, TF_DEFAULT_SELECTION, 1, &selection, &fetched)) || fetched != 1) return;
        Com<ITfRange> range; range.p = selection.range;
        if (!readSnapshot(ctx, cookie, range.p, snapshot)) return;
        // Do not cover an empty field with a popup before the user has typed.
        if (snapshot.before.empty()) return;
        candidates = rhg::suggest(snapshot.context.prefix, snapshot.context.previous);
        if (candidates.empty()) return;
        Com<ITfContextView> view; RECT rect{}; BOOL clipped = FALSE;
        if (FAILED(ctx->GetActiveView(view.out())) || FAILED(view->GetTextExt(cookie, range.p, &rect, &clipped)) || clipped) { hide(); return; }
        int width = 380, height = int(candidates.size()) * 40;
        MONITORINFO info{}; info.cbSize = sizeof(info);
        if (GetMonitorInfoW(MonitorFromRect(&rect, MONITOR_DEFAULTTONEAREST), &info)) {
            rect.left = std::max(info.rcWork.left, std::min(rect.left, info.rcWork.right-width));
            if (rect.bottom+height > info.rcWork.bottom) rect.bottom = std::max(info.rcWork.top, rect.top-height);
        }
        SetWindowPos(popup, HWND_TOPMOST, rect.left, rect.bottom, width, height, SWP_NOACTIVATE | SWP_SHOWWINDOW);
        InvalidateRect(popup, nullptr, TRUE);
    }
    static LRESULT CALLBACK windowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
        auto self = reinterpret_cast<Service *>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
        if (msg == WM_NCCREATE) {
            self = static_cast<Service *>(reinterpret_cast<CREATESTRUCTW *>(lp)->lpCreateParams);
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
        }
        if (!self) return DefWindowProcW(hwnd, msg, wp, lp);
        if (msg == WM_MOUSEACTIVATE) return MA_NOACTIVATE;
        if (msg == WM_LBUTTONUP) { self->choose(static_cast<unsigned>(HIWORD(lp))/40); return 0; }
        if (msg == WM_PAINT) {
            PAINTSTRUCT ps; HDC dc = BeginPaint(hwnd, &ps);
            RECT rect; GetClientRect(hwnd, &rect); FillRect(dc, &rect, GetSysColorBrush(COLOR_WINDOW));
            auto old = SelectObject(dc, self->font); SetBkMode(dc, TRANSPARENT); SetTextColor(dc, GetSysColor(COLOR_WINDOWTEXT));
            for (size_t i = 0; i < self->candidates.size(); ++i) {
                RECT label{8, LONG(i*40), 60, LONG((i+1)*40)};
                auto shortcut = L"F" + std::to_wstring(i+1);
                DrawTextW(dc, shortcut.c_str(), -1, &label, DT_LEFT | DT_SINGLELINE | DT_VCENTER);
                RECT word{65, LONG(i*40), rect.right-12, LONG((i+1)*40)};
                auto text = wide(rhg::words[self->candidates[i]].text);
                DrawTextW(dc, text.c_str(), int(text.size()), &word, DT_RIGHT | DT_RTLREADING | DT_SINGLELINE | DT_VCENTER | DT_END_ELLIPSIS);
            }
            SelectObject(dc, old); EndPaint(hwnd, &ps); return 0;
        }
        return DefWindowProcW(hwnd, msg, wp, lp);
    }
};
Edit::Edit(Service *s, ITfContext *c, std::u16string t, bool replace, Snapshot shot)
    : owner(s), ctx(c), text(std::move(t)), candidate(replace), expected(std::move(shot)) { owner->AddRef(); ctx->AddRef(); }
Edit::~Edit() { ctx->Release(); owner->Release(); }
HRESULT Edit::DoEditSession(TfEditCookie cookie) {
    if (ctx != owner->context || disabled(ctx)) return E_FAIL;
    TF_SELECTION selection{}; ULONG fetched = 0;
    HRESULT hr = ctx->GetSelection(cookie, TF_DEFAULT_SELECTION, 1, &selection, &fetched);
    if (FAILED(hr) || fetched != 1) return E_FAIL;
    Com<ITfRange> range; range.p = selection.range;
    if (candidate) {
        Snapshot current;
        if (!readSnapshot(ctx, cookie, range.p, current) || current.before != expected.before || current.after != expected.after) {
            owner->hide(); return E_FAIL;
        }
        LONG shifted = 0;
        LONG count = -LONG(current.context.prefix.size());
        hr = range->ShiftStart(cookie, count, &shifted, nullptr);
        if (FAILED(hr) || shifted != count) return E_FAIL;
        if (current.after.empty() || current.after.front() != u' ') text += u' ';
    }
    owner->editing = true;
    auto value = wide(text);
    hr = range->SetText(cookie, 0, value.c_str(), LONG(value.size()));
    if (SUCCEEDED(hr)) hr = range->Collapse(cookie, TF_ANCHOR_END);
    if (SUCCEEDED(hr)) {
        selection.style.ase = TF_AE_NONE; selection.style.fInterimChar = FALSE;
        hr = ctx->SetSelection(cookie, 1, &selection);
    }
    owner->editing = false;
    if (SUCCEEDED(hr)) owner->refresh(ctx, cookie); else owner->hide();
    return hr;
}

class Factory final : public IClassFactory {
    LONG refs = 1;
public:
    Factory() { InterlockedIncrement(&objects); }
    ~Factory() { InterlockedDecrement(&objects); }
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID id, void **out) override {
        if (!out) return E_POINTER; *out = nullptr;
        if (id != IID_IUnknown && id != IID_IClassFactory) return E_NOINTERFACE;
        *out = static_cast<IClassFactory *>(this); AddRef(); return S_OK;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return InterlockedIncrement(&refs); }
    ULONG STDMETHODCALLTYPE Release() override { ULONG n = InterlockedDecrement(&refs); if (!n) delete this; return n; }
    HRESULT STDMETHODCALLTYPE CreateInstance(IUnknown *outer, REFIID id, void **out) override {
        if (outer) return CLASS_E_NOAGGREGATION;
        auto service = new(std::nothrow) Service;
        if (!service) return E_OUTOFMEMORY;
        HRESULT hr = service->QueryInterface(id, out); service->Release(); return hr;
    }
    HRESULT STDMETHODCALLTYPE LockServer(BOOL lock) override { if (lock) InterlockedIncrement(&objects); else InterlockedDecrement(&objects); return S_OK; }
};
extern "C" HRESULT __stdcall DllGetClassObject(REFCLSID cls, REFIID id, void **out) {
    if (cls != CLSID_Rohingya) return CLASS_E_CLASSNOTAVAILABLE;
    auto factory = new(std::nothrow) Factory;
    if (!factory) return E_OUTOFMEMORY;
    HRESULT hr = factory->QueryInterface(id, out); factory->Release(); return hr;
}
extern "C" HRESULT __stdcall DllCanUnloadNow() {
    if (objects) return S_FALSE;
    UnregisterClassW(windowClass, module);
    return S_OK;
}
static std::wstring classKey() { return L"Software\\Classes\\CLSID\\{7DD2FB83-BCD2-4BF2-B937-B1E9062836A1}"; }
extern "C" HRESULT __stdcall DllUnregisterServer() {
    HRESULT init = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    Com<ITfInputProcessorProfiles> profiles; Com<ITfCategoryMgr> categories;
    HRESULT hr = CoCreateInstance(CLSID_TF_InputProcessorProfiles, nullptr, CLSCTX_INPROC_SERVER, IID_ITfInputProcessorProfiles, reinterpret_cast<void **>(profiles.out()));
    if (SUCCEEDED(hr)) hr = profiles->Unregister(CLSID_Rohingya);
    if (SUCCEEDED(CoCreateInstance(CLSID_TF_CategoryMgr, nullptr, CLSCTX_INPROC_SERVER, IID_ITfCategoryMgr, reinterpret_cast<void **>(categories.out()))))
        categories->UnregisterCategory(CLSID_Rohingya, GUID_TFCAT_TIP_KEYBOARD, CLSID_Rohingya);
    RegDeleteTreeW(HKEY_LOCAL_MACHINE, classKey().c_str());
    // Release COM objects before uninitializing this apartment.
    if (profiles.p) { profiles.p->Release(); profiles.p = nullptr; }
    if (categories.p) { categories.p->Release(); categories.p = nullptr; }
    if (SUCCEEDED(init)) CoUninitialize();
    return hr;
}
extern "C" HRESULT __stdcall DllRegisterServer() {
    WCHAR path[MAX_PATH]; DWORD length = GetModuleFileNameW(module, path, MAX_PATH);
    if (!length || length == MAX_PATH) return E_FAIL;
    HKEY key = nullptr;
    LONG error = RegCreateKeyExW(HKEY_LOCAL_MACHINE, (classKey()+L"\\InprocServer32").c_str(), 0, nullptr, 0, KEY_WRITE, nullptr, &key, nullptr);
    if (error) return HRESULT_FROM_WIN32(error);
    error = RegSetValueExW(key, nullptr, 0, REG_SZ, reinterpret_cast<const BYTE *>(path), (length+1)*sizeof(WCHAR));
    if (!error) error = RegSetValueExW(key, L"ThreadingModel", 0, REG_SZ, reinterpret_cast<const BYTE *>(L"Apartment"), sizeof(L"Apartment"));
    RegCloseKey(key);
    if (error) return HRESULT_FROM_WIN32(error);
    HRESULT init = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    Com<ITfInputProcessorProfiles> profiles; Com<ITfCategoryMgr> categories;
    HRESULT hr = CoCreateInstance(CLSID_TF_InputProcessorProfiles, nullptr, CLSCTX_INPROC_SERVER, IID_ITfInputProcessorProfiles, reinterpret_cast<void **>(profiles.out()));
    if (SUCCEEDED(hr)) hr = profiles->Register(CLSID_Rohingya);
    const WCHAR name[] = L"Hanifi Rohingya Predictive";
    if (SUCCEEDED(hr)) hr = profiles->AddLanguageProfile(CLSID_Rohingya, 0x0409, PROFILE_Rohingya, name, (sizeof(name)/sizeof(WCHAR))-1, path, length, 0);
    if (SUCCEEDED(hr)) hr = profiles->EnableLanguageProfileByDefault(CLSID_Rohingya, 0x0409, PROFILE_Rohingya, TRUE);
    if (SUCCEEDED(hr)) hr = CoCreateInstance(CLSID_TF_CategoryMgr, nullptr, CLSCTX_INPROC_SERVER, IID_ITfCategoryMgr, reinterpret_cast<void **>(categories.out()));
    if (SUCCEEDED(hr)) hr = categories->RegisterCategory(CLSID_Rohingya, GUID_TFCAT_TIP_KEYBOARD, CLSID_Rohingya);
    if (profiles.p) { profiles.p->Release(); profiles.p = nullptr; }
    if (categories.p) { categories.p->Release(); categories.p = nullptr; }
    if (SUCCEEDED(init)) CoUninitialize();
    if (FAILED(hr)) DllUnregisterServer();
    return hr;
}
extern "C" BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) module = instance;
    return TRUE;
}
