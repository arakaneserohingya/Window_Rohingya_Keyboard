import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
layout_text = (ROOT / 'layout.js').read_text()
json_str = layout_text.replace('const ROHINGYA = ', '').rstrip(';\n ')
data = json.loads(json_str)
font_path = str(ROOT / 'assets/NotoSansHanifiRohingya-Regular.ttf')

# Windows ANSI 104/Laptop Keyboard Layout Definition
windows_layout = [
    # Row 1 (Number row)
    [
        ('`', '~', '`', 1.0, False, 'normal'),
        ('1', '!', '1', 1.0, False, 'normal'),
        ('2', '@', '2', 1.0, False, 'normal'),
        ('3', '#', '3', 1.0, False, 'normal'),
        ('4', '$', '4', 1.0, False, 'normal'),
        ('5', '%', '5', 1.0, False, 'normal'),
        ('6', '^', '6', 1.0, False, 'normal'),
        ('7', '&', '7', 1.0, False, 'normal'),
        ('8', '*', '8', 1.0, False, 'normal'),
        ('9', '(', '9', 1.0, False, 'normal'),
        ('0', ')', '0', 1.0, False, 'normal'),
        ('-', '_', '-', 1.0, False, 'normal'),
        ('=', '+', '=', 1.0, False, 'normal'),
        ('Backspace', '', 'Backspace', 2.0, True, 'win_backspace')
    ],
    # Row 2 (QWERTY row)
    [
        ('Tab', '', 'Tab', 1.5, True, 'win_tab'),
        ('Q', '', 'Q', 1.0, False, 'normal'),
        ('W', '𐴧', 'W', 1.0, False, 'normal'),
        ('E', '', 'E', 1.0, False, 'normal'),
        ('R', '', 'R', 1.0, False, 'normal'),
        ('T', '', 'T', 1.0, False, 'normal'),
        ('Y', '𐴤', 'Y', 1.0, False, 'normal'),
        ('U', '', 'U', 1.0, False, 'normal'),
        ('I', '', 'I', 1.0, False, 'normal'),
        ('O', '', 'O', 1.0, False, 'normal'),
        ('P', '', 'P', 1.0, False, 'normal'),
        ('[', '{', '[', 1.0, False, 'normal'),
        (']', '}', ']', 1.0, False, 'normal'),
        ('\\', '|', '\\', 1.5, False, 'normal')
    ],
    # Row 3 (Home row)
    [
        ('Caps Lock', '', 'CapsLock', 1.75, True, 'win_caps'),
        ('A', '', 'A', 1.0, False, 'normal'),
        ('S', '𐴥', 'S', 1.0, False, 'normal'),
        ('D', '', 'D', 1.0, False, 'normal'),
        ('F', '', 'F', 1.0, False, 'normal'),
        ('G', '', 'G', 1.0, False, 'normal'),
        ('H', '', 'H', 1.0, False, 'normal'),
        ('J', '', 'J', 1.0, False, 'normal'),
        ('K', '', 'K', 1.0, False, 'normal'),
        ('L', '؛', 'L', 1.0, False, 'normal'),
        (';', ':', ';', 1.0, False, 'normal'),
        ("'", '"', "'", 1.0, False, 'normal'),
        ('Enter', '', 'Enter', 2.25, True, 'win_enter')
    ],
    # Row 4 (Shift row)
    [
        ('Shift', '', 'ShiftLeft', 2.25, True, 'win_shift'),
        ('Z', '', 'Z', 1.0, False, 'normal'),
        ('X', '', 'X', 1.0, False, 'normal'),
        ('C', '', 'C', 1.0, False, 'normal'),
        ('V', '', 'V', 1.0, False, 'normal'),
        ('B', '', 'B', 1.0, False, 'normal'),
        ('N', '', 'N', 1.0, False, 'normal'),
        ('M', '', 'M', 1.0, False, 'normal'),
        (',', '،', ',', 1.0, False, 'normal'),
        ('.', '۔', '.', 1.0, False, 'normal'),
        ('/', '؟', '/', 1.0, False, 'normal'),
        ('Shift', '', 'ShiftRight', 2.75, True, 'win_shift')
    ],
    # Row 5 (Bottom row)
    [
        ('Ctrl', '', 'CtrlLeft', 1.25, True, 'win_ctrl'),
        ('Win', '', 'WinLeft', 1.25, True, 'win_logo'),
        ('Alt', '', 'AltLeft', 1.25, True, 'win_alt'),
        ('Space', '𐴢', ' ', 6.25, False, 'space'),
        ('Alt', '', 'AltRight', 1.25, True, 'win_alt'),
        ('Win', '', 'WinRight', 1.25, True, 'win_logo'),
        ('Menu', '', 'Menu', 1.25, True, 'win_menu'),
        ('Ctrl', '', 'CtrlRight', 1.25, True, 'win_ctrl')
    ]
]

# Apple Magic Keyboard (US ANSI Layout)
mac_layout_rows = [
    # Row 1 (Number row)
    [
        ('`', '~', '`', 1.0, False, 'normal'),
        ('1', '!', '1', 1.0, False, 'normal'),
        ('2', '@', '2', 1.0, False, 'normal'),
        ('3', '#', '3', 1.0, False, 'normal'),
        ('4', '$', '4', 1.0, False, 'normal'),
        ('5', '%', '5', 1.0, False, 'normal'),
        ('6', '^', '6', 1.0, False, 'normal'),
        ('7', '&', '7', 1.0, False, 'normal'),
        ('8', '*', '8', 1.0, False, 'normal'),
        ('9', '(', '9', 1.0, False, 'normal'),
        ('0', ')', '0', 1.0, False, 'normal'),
        ('-', '_', '-', 1.0, False, 'normal'),
        ('=', '+', '=', 1.0, False, 'normal'),
        ('delete', '', 'delete', 2.0, True, 'mac_delete')
    ],
    # Row 2 (QWERTY row)
    [
        ('tab', '', 'tab', 1.5, True, 'mac_tab'),
        ('Q', '', 'Q', 1.0, False, 'normal'),
        ('W', '𐴧', 'W', 1.0, False, 'normal'),
        ('E', '', 'E', 1.0, False, 'normal'),
        ('R', '', 'R', 1.0, False, 'normal'),
        ('T', '', 'T', 1.0, False, 'normal'),
        ('Y', '𐴤', 'Y', 1.0, False, 'normal'),
        ('U', '', 'U', 1.0, False, 'normal'),
        ('I', '', 'I', 1.0, False, 'normal'),
        ('O', '', 'O', 1.0, False, 'normal'),
        ('P', '', 'P', 1.0, False, 'normal'),
        ('[', '{', '[', 1.0, False, 'normal'),
        (']', '}', ']', 1.0, False, 'normal'),
        ('\\', '|', '\\', 1.5, False, 'normal')
    ],
    # Row 3 (Home row)
    [
        ('caps lock', '', 'caps', 1.75, True, 'mac_caps'),
        ('A', '', 'A', 1.0, False, 'normal'),
        ('S', '𐴥', 'S', 1.0, False, 'normal'),
        ('D', '', 'D', 1.0, False, 'normal'),
        ('F', '', 'F', 1.0, False, 'normal'),
        ('G', '', 'G', 1.0, False, 'normal'),
        ('H', '', 'H', 1.0, False, 'normal'),
        ('J', '', 'J', 1.0, False, 'normal'),
        ('K', '', 'K', 1.0, False, 'normal'),
        ('L', '؛', 'L', 1.0, False, 'normal'),
        (';', ':', ';', 1.0, False, 'normal'),
        ("'", '"', "'", 1.0, False, 'normal'),
        ('return', '', 'return', 2.25, True, 'mac_return')
    ],
    # Row 4 (Shift row)
    [
        ('shift', '', 'shift_l', 2.25, True, 'mac_shift'),
        ('Z', '', 'Z', 1.0, False, 'normal'),
        ('X', '', 'X', 1.0, False, 'normal'),
        ('C', '', 'C', 1.0, False, 'normal'),
        ('V', '', 'V', 1.0, False, 'normal'),
        ('B', '', 'B', 1.0, False, 'normal'),
        ('N', '', 'N', 1.0, False, 'normal'),
        ('M', '', 'M', 1.0, False, 'normal'),
        (',', '،', ',', 1.0, False, 'normal'),
        ('.', '۔', '.', 1.0, False, 'normal'),
        ('/', '؟', '/', 1.0, False, 'normal'),
        ('shift', '', 'shift_r', 2.75, True, 'mac_shift')
    ],
    # Row 5 (Bottom row with authentic Apple Inverted-T arrow cluster)
    [
        ('fn', '', 'fn', 1.0, True, 'mac_fn'),
        ('control', '', 'ctrl', 1.0, True, 'mac_ctrl'),
        ('option', '', 'opt_l', 1.25, True, 'mac_opt'),
        ('command', '', 'cmd_l', 1.25, True, 'mac_cmd'),
        ('Space', '𐴢', ' ', 5.5, False, 'space'),
        ('command', '', 'cmd_r', 1.25, True, 'mac_cmd'),
        ('option', '', 'opt_r', 1.0, True, 'mac_opt'),
        ('arrows', '', 'arrows', 2.75, True, 'mac_arrows')
    ]
]

def draw_win_logo(draw, cx, cy, size, color):
    half = size / 2.0
    gap = size * 0.15
    tile = (half - gap / 2.0)
    # 4 tiles
    # Top-Left
    draw.rectangle([cx - half, cy - half, cx - half + tile, cy - half + tile], fill=color)
    # Top-Right
    draw.rectangle([cx + gap/2, cy - half, cx + gap/2 + tile, cy - half + tile], fill=color)
    # Bottom-Left
    draw.rectangle([cx - half, cy + gap/2, cx - half + tile, cy + gap/2 + tile], fill=color)
    # Bottom-Right
    draw.rectangle([cx + gap/2, cy + gap/2, cx + gap/2 + tile, cy + gap/2 + tile], fill=color)

def draw_apple_logo(draw, cx, cy, size, color):
    # Apple silhouette approximation with clean circles
    r = size * 0.42
    draw.ellipse([cx - r*0.9, cy - r*0.7, cx + r*0.1, cy + r*0.9], fill=color)
    draw.ellipse([cx - r*0.1, cy - r*0.7, cx + r*0.9, cy + r*0.9], fill=color)
    # Leaf
    draw.ellipse([cx - r*0.1, cy - r*1.3, cx + r*0.6, cy - r*0.7], fill=color)

def render_keyboard(layout_rows, is_mac, is_shift, output_path):
    scale = 2
    unit_px = 64 * scale
    gap = 6 * scale
    padding_x = 26 * scale
    padding_top = 74 * scale
    padding_bottom = 26 * scale
    
    total_w = int(padding_x * 2 + 15.0 * unit_px + 14 * gap)
    total_h = int(padding_top + 5 * (unit_px * 0.96 + gap) + padding_bottom)
    
    # Authentic OS chassis styling
    if is_mac:
        bg_color = (232, 235, 238, 255) # Sleek Apple Aluminum finish
        border_color = (200, 206, 212)
        shadow_color = (195, 200, 205)
    else:
        bg_color = (238, 242, 241, 255) # Microsoft Surface / Windows 11 Slate
        border_color = (195, 208, 202)
        shadow_color = (185, 198, 192)
        
    img = Image.new('RGBA', (total_w, total_h), bg_color)
    draw = ImageDraw.Draw(img)
    
    # Fonts
    font_glyph = ImageFont.truetype(font_path, int(27 * scale))
    font_shift_glyph = ImageFont.truetype(font_path, int(16 * scale))
    
    try:
        font_latin = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(12.5 * scale))
        font_mod = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(11 * scale))
        font_title = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(16 * scale))
        font_badge = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(11 * scale))
    except:
        font_latin = ImageFont.load_default()
        font_mod = ImageFont.load_default()
        font_title = ImageFont.load_default()
        font_badge = ImageFont.load_default()

    # Outer Hardware Chassis Bezel with smooth modern curvature
    draw.rounded_rectangle([4, 4, total_w-4, total_h-4], radius=22*scale, outline=border_color, width=2*scale)
    
    # Header Platform Title
    title_x = padding_x
    title_y = 26 * scale
    if is_mac:
        draw_apple_logo(draw, title_x + 9*scale, title_y + 10*scale, 14*scale, (30, 41, 59))
        title_text = "Apple macOS (Magic Keyboard / MacBook)  •  " + ("Shift Layer (Tone Marks, Punctuation & Signs)" if is_shift else "Base Layer (Letters, Vowels & Digits)")
        draw.text((title_x + 24*scale, title_y), title_text, fill=(30, 41, 59), font=font_title)
    else:
        draw_win_logo(draw, title_x + 9*scale, title_y + 10*scale, 14*scale, (0, 102, 204))
        title_text = "Microsoft Windows 11 / PC  •  " + ("Shift Layer (Tone Marks, Punctuation & Signs)" if is_shift else "Base Layer (Letters, Vowels & Digits)")
        draw.text((title_x + 24*scale, title_y), title_text, fill=(20, 50, 45), font=font_title)
    
    # Status Pill / Badge
    badge_text = "●  SHIFT ACTIVE" if is_shift else "○  BASE LAYER"
    badge_w = 142 * scale
    badge_h = 28 * scale
    badge_x = total_w - padding_x - badge_w
    badge_y = 21 * scale
    badge_bg = (175, 226, 202) if is_shift else ((215, 235, 250) if is_mac else (220, 240, 232))
    badge_fg = (0, 110, 80) if is_shift else ((0, 95, 150) if is_mac else (0, 105, 80))
    draw.rounded_rectangle([badge_x, badge_y, badge_x + badge_w, badge_y + badge_h], radius=14*scale, fill=badge_bg)
    draw.text((badge_x + 16*scale, badge_y + 5.5*scale), badge_text, fill=badge_fg, font=font_badge)

    current_y = padding_top
    row_height = unit_px * 0.96
    
    for row in layout_rows:
        current_x = padding_x
        for label, shift_label, key_id, width_units, is_mod, custom_type in row:
            key_w = width_units * unit_px + (width_units - 1.0) * gap
            
            # Special case: Apple Inverted-T Arrow Cluster
            if custom_type == 'mac_arrows':
                w_left = 0.8 * unit_px
                w_mid = 0.95 * unit_px
                w_right = 0.8 * unit_px
                half_h = (row_height - gap) / 2
                
                bg_arrow = (244, 246, 248)
                bd_arrow = (212, 218, 222)
                tx_arrow = (65, 80, 90)
                
                # 1. Left Arrow (bottom half)
                lx = current_x
                ly = current_y + half_h + gap
                draw.rounded_rectangle([lx, ly + 2*scale, lx + w_left, ly + half_h + 2*scale], radius=5*scale, fill=shadow_color)
                draw.rounded_rectangle([lx, ly, lx + w_left, ly + half_h], radius=5*scale, fill=bg_arrow, outline=bd_arrow, width=int(1.5*scale))
                # Triangle Left
                draw.polygon([(lx + w_left/2 + 4*scale, ly + half_h/2 - 5*scale),
                              (lx + w_left/2 - 5*scale, ly + half_h/2),
                              (lx + w_left/2 + 4*scale, ly + half_h/2 + 5*scale)], fill=tx_arrow)
                
                # 2. Middle Up Arrow (top half)
                mx = current_x + w_left + gap
                my_up = current_y
                draw.rounded_rectangle([mx, my_up + 2*scale, mx + w_mid, my_up + half_h + 2*scale], radius=5*scale, fill=shadow_color)
                draw.rounded_rectangle([mx, my_up, mx + w_mid, my_up + half_h], radius=5*scale, fill=bg_arrow, outline=bd_arrow, width=int(1.5*scale))
                # Triangle Up
                draw.polygon([(mx + w_mid/2, my_up + half_h/2 - 5*scale),
                              (mx + w_mid/2 - 5*scale, my_up + half_h/2 + 4*scale),
                              (mx + w_mid/2 + 5*scale, my_up + half_h/2 + 4*scale)], fill=tx_arrow)
                
                # 3. Middle Down Arrow (bottom half)
                my_down = current_y + half_h + gap
                draw.rounded_rectangle([mx, my_down + 2*scale, mx + w_mid, my_down + half_h + 2*scale], radius=5*scale, fill=shadow_color)
                draw.rounded_rectangle([mx, my_down, mx + w_mid, my_down + half_h], radius=5*scale, fill=bg_arrow, outline=bd_arrow, width=int(1.5*scale))
                # Triangle Down
                draw.polygon([(mx + w_mid/2, my_down + half_h/2 + 5*scale),
                              (mx + w_mid/2 - 5*scale, my_down + half_h/2 - 4*scale),
                              (mx + w_mid/2 + 5*scale, my_down + half_h/2 - 4*scale)], fill=tx_arrow)
                
                # 4. Right Arrow (bottom half)
                rx = current_x + w_left + gap + w_mid + gap
                ry = current_y + half_h + gap
                draw.rounded_rectangle([rx, ry + 2*scale, rx + w_right, ry + half_h + 2*scale], radius=5*scale, fill=shadow_color)
                draw.rounded_rectangle([rx, ry, rx + w_right, ry + half_h], radius=5*scale, fill=bg_arrow, outline=bd_arrow, width=int(1.5*scale))
                # Triangle Right
                draw.polygon([(rx + w_right/2 - 4*scale, ry + half_h/2 - 5*scale),
                              (rx + w_right/2 + 5*scale, ry + half_h/2),
                              (rx + w_right/2 - 4*scale, ry + half_h/2 + 5*scale)], fill=tx_arrow)
                
                current_x += key_w + gap
                continue

            # Standard Key Colors
            if is_mod:
                bg_k = (242, 245, 247) if is_mac else (224, 231, 228)
                if is_shift and ('shift' in key_id.lower() or 'Shift' in label):
                    bg_k = (182, 228, 206)
                bd_k = (210, 216, 222) if is_mac else (182, 200, 194)
                tx_k = (70, 85, 95) if is_mac else (55, 80, 72)
            else:
                bg_k = (255, 255, 255)
                bd_k = (215, 220, 225) if is_mac else (195, 212, 205)
                tx_k = (15, 30, 35) if is_mac else (18, 55, 48)
                
            # Key 3D bevel & drop shadow
            draw.rounded_rectangle([current_x, current_y + 2.5*scale, current_x + key_w, current_y + row_height + 2.5*scale], radius=7*scale, fill=shadow_color)
            draw.rounded_rectangle([current_x, current_y, current_x + key_w, current_y + row_height], radius=7*scale, fill=bg_k, outline=bd_k, width=int(1.5*scale))
            
            # Draw Modifier Keys Content
            if is_mod:
                if is_mac:
                    # Apple style: lower left label
                    draw.text((current_x + 8*scale, current_y + row_height - 18*scale), label, fill=tx_k, font=font_mod)
                    if custom_type == 'mac_caps':
                        # Green LED light
                        draw.ellipse([current_x + 8*scale, current_y + 8*scale, current_x + 14*scale, current_y + 14*scale], fill=(0, 215, 100))
                    elif custom_type == 'mac_shift':
                        draw.text((current_x + key_w - 18*scale, current_y + 6*scale), '⇧', fill=tx_k, font=font_mod)
                    elif custom_type == 'mac_delete':
                        draw.text((current_x + key_w - 18*scale, current_y + 6*scale), '⌫', fill=tx_k, font=font_mod)
                    elif custom_type == 'mac_cmd':
                        draw.text((current_x + key_w - 18*scale, current_y + 6*scale), '⌘', fill=tx_k, font=font_mod)
                    elif custom_type == 'mac_opt':
                        draw.text((current_x + key_w - 18*scale, current_y + 6*scale), '⌥', fill=tx_k, font=font_mod)
                    elif custom_type == 'mac_ctrl':
                        draw.text((current_x + key_w - 18*scale, current_y + 6*scale), '⌃', fill=tx_k, font=font_mod)
                else:
                    # Windows style
                    if custom_type == 'win_logo':
                        draw_win_logo(draw, current_x + key_w/2, current_y + row_height/2, 16*scale, (0, 102, 204))
                    else:
                        draw.text((current_x + 8*scale, current_y + row_height - 18*scale), label, fill=tx_k, font=font_mod)
            elif custom_type == 'space':
                # Spacebar Key
                sp_text = '𐴢   (Sakin — Shift + Space)' if is_shift else 'Space'
                bbox = draw.textbbox((0, 0), sp_text, font=font_glyph if is_shift else font_mod)
                tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
                draw.text((current_x + (key_w - tw)/2, current_y + (row_height - th)/2 - 2*scale), sp_text, fill=(0, 120, 85) if is_shift else tx_k, font=font_glyph if is_shift else font_mod)
            else:
                # Alphanumeric / Character Key
                clean_key = key_id
                base_char = data['layers']['base'].get(clean_key, '')
                shift_char = data['layers']['shift'].get(clean_key, '')
                
                # 1. Top-Left: Latin Base Letter / Symbol
                draw.text((current_x + 7*scale, current_y + 5*scale), label, fill=(105, 120, 115), font=font_latin)
                
                # 2. Top-Right: Shift Latin / Shift Character Indicator
                if shift_char and shift_char != base_char and shift_char not in ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '{', '}', '|', ':', '"']:
                    # Special Rohingya Shift Mark (e.g. 𐴥, 𐴧, 𐴤, 𐴦, ؛, ،, ۔, ؟)
                    bbox_s = draw.textbbox((0, 0), shift_char, font=font_shift_glyph)
                    stw = bbox_s[2] - bbox_s[0]
                    draw.text((current_x + key_w - stw - 7*scale, current_y + 3*scale), shift_char, fill=(0, 140, 95), font=font_shift_glyph)
                elif shift_label:
                    bbox_s = draw.textbbox((0, 0), shift_label, font=font_latin)
                    stw = bbox_s[2] - bbox_s[0]
                    draw.text((current_x + key_w - stw - 7*scale, current_y + 5*scale), shift_label, fill=(145, 160, 155), font=font_latin)
                
                # 3. Center: Prominent Active Character
                if is_shift:
                    if shift_char:
                        # Active Shift Character (Bright Emerald)
                        use_font = font_shift_glyph if shift_char in ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '{', '}', '|', ':', '"'] else font_glyph
                        bbox_g = draw.textbbox((0, 0), shift_char, font=use_font)
                        gw, gh = bbox_g[2] - bbox_g[0], bbox_g[3] - bbox_g[1]
                        draw.text((current_x + (key_w - gw)/2, current_y + (row_height - gh)/2 + 3*scale), shift_char, fill=(0, 125, 90), font=use_font)
                    else:
                        # Base character faded/muted in shift mode so user sees context
                        if base_char:
                            bbox_g = draw.textbbox((0, 0), base_char, font=font_glyph)
                            gw, gh = bbox_g[2] - bbox_g[0], bbox_g[3] - bbox_g[1]
                            draw.text((current_x + (key_w - gw)/2, current_y + (row_height - gh)/2 + 3*scale), base_char, fill=(210, 220, 218), font=font_glyph)
                else:
                    # Base Character (Deep High-Contrast Ink)
                    if base_char:
                        bbox_g = draw.textbbox((0, 0), base_char, font=font_glyph)
                        gw, gh = bbox_g[2] - bbox_g[0], bbox_g[3] - bbox_g[1]
                        draw.text((current_x + (key_w - gw)/2, current_y + (row_height - gh)/2 + 3*scale), base_char, fill=tx_k, font=font_glyph)

            current_x += key_w + gap
        current_y += row_height + gap

    img.save(output_path, 'PNG', optimize=True)
    print(f'Successfully rendered: {output_path}')

# Render Windows layouts
render_keyboard(windows_layout, False, False, str(ROOT / 'assets/keyboard_layout.png'))
render_keyboard(windows_layout, False, True, str(ROOT / 'assets/keyboard_shift_layout.png'))

# Render Mac layouts
render_keyboard(mac_layout_rows, True, False, str(ROOT / 'assets/keyboard_mac_layout.png'))
render_keyboard(mac_layout_rows, True, True, str(ROOT / 'assets/keyboard_mac_shift_layout.png'))
