/* Minimal x64 Windows keyboard-layout ABI. Field layout follows Windows SDK kbd.h.
 * No Windows SDK or external runtime is required to compile this data-only DLL.
 * This deliberately supports only 64-bit targets; 32-bit layouts have different
 * pointer rules and must not be compiled from these declarations.
 */
#ifndef ROHINGYA_KEYBOARD_ABI_H
#define ROHINGYA_KEYBOARD_ABI_H
#include <stdint.h>
#include <stddef.h>
typedef struct { uint8_t vk, bits; } VK_TO_BIT;
typedef struct { VK_TO_BIT *keys; uint16_t max_bits; uint8_t states[4]; } MODIFIERS;
typedef struct { uint8_t vk, attributes; uint16_t chars[4]; } VK_TO_WCHARS4;
typedef struct { VK_TO_WCHARS4 *entries; uint8_t count, size; } VK_TO_WCHAR_TABLE;
typedef struct { uint8_t scan; uint16_t vk; } VSC_VK;
typedef struct { uint8_t scan; const uint16_t *name; } VSC_LPWSTR;
typedef struct { uint8_t vk; uint16_t state, chars[2]; } LIGATURE2;
typedef struct {
    MODIFIERS *modifiers;
    VK_TO_WCHAR_TABLE *characters;
    void *dead_keys;
    VSC_LPWSTR *names, *extended_names;
    void *dead_names;
    uint16_t *scancodes;
    uint8_t scancode_count;
    VSC_VK *e0, *e1;
    uint32_t locale_flags;
    uint8_t max_ligature, ligature_size;
    LIGATURE2 *ligatures;
    uint32_t type, subtype;
} KBDTABLES;
#define WCH_NONE 0xF000
#define WCH_LGTR 0xF002
_Static_assert(sizeof(void *) == 8, "Only 64-bit keyboard layout builds are supported");
_Static_assert(sizeof(KBDTABLES) == 104, "KBDTABLES ABI mismatch");
_Static_assert(offsetof(KBDTABLES, ligatures) == 88, "Ligature pointer ABI mismatch");
_Static_assert(offsetof(MODIFIERS, states) == 10, "Modifiers ABI mismatch");
_Static_assert(sizeof(VK_TO_WCHARS4) == 10, "Character entry ABI mismatch");
_Static_assert(sizeof(LIGATURE2) == 8, "Ligature ABI mismatch");
_Static_assert(sizeof(VSC_VK) == 4, "Scancode ABI mismatch");
_Static_assert(sizeof(VSC_LPWSTR) == 16, "Key-name ABI mismatch");
#endif
