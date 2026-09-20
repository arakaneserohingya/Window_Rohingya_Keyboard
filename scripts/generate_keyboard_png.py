import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
layout_text = (ROOT / 'layout.js').read_text()
json_str = layout_text.replace('const ROHINGYA = ', '').rstrip(';\n ')
data = json.loads(json_str)
font_path = str(ROOT / 'assets/NotoSansHanifiRohingya-Regular.ttf')

# Complete 100% Full Windows Physical Keyboard Map with proportional key widths
full_keyboard = [
    # Row 1 (15.0 units total)
    [
        ('`', '~', '`', 1.0, False), ('1', '!', '1', 1.0, False), ('2', '@', '2', 1.0, False),
        ('3', '#', '3', 1.0, False), ('4', '$', '4', 1.0, False), ('5', '%', '5', 1.0, False),
        ('6', '^', '6', 1.0, False), ('7', '&', '7', 1.0, False), ('8', '*', '8', 1.0, False),
        ('9', '(', '9', 1.0, False), ('0', ')', '0', 1.0, False), ('-', '_', '-', 1.0, False),
        ('=', '+', '=', 1.0, False), ('Backspace', '', 'Backspace', 2.0, True)
    ],
    # Row 2 (15.0 units total)
    [
        ('Tab', '', 'Tab', 1.5, True),
        ('Q', '', 'Q', 1.0, False), ('W', '', 'W', 1.0, False), ('E', '', 'E', 1.0, False),
        ('R', '', 'R', 1.0, False), ('T', '', 'T', 1.0, False), ('Y', '', 'Y', 1.0, False),
        ('U', '', 'U', 1.0, False), ('I', '', 'I', 1.0, False), ('O', '', 'O', 1.0, False),
        ('P', '', 'P', 1.0, False), ('[', '{', '[', 1.0, False), (']', '}', ']', 1.0, False),
        ('\\', '|', '\\', 1.5, False)
    ],
    # Row 3 (15.0 units total)
    [
        ('Caps Lock', '', 'CapsLock', 1.75, True),
        ('A', '', 'A', 1.0, False), ('S', '', 'S', 1.0, False), ('D', '', 'D', 1.0, False),
        ('F', '', 'F', 1.0, False), ('G', '', 'G', 1.0, False), ('H', '', 'H', 1.0, False),
        ('J', '', 'J', 1.0, False), ('K', '', 'K', 1.0, False), ('L', '', 'L', 1.0, False),
        (';', ':', ';', 1.0, False), ("'", '"', "'", 1.0, False),
        ('Enter', '', 'Enter', 2.25, True)
    ],
    # Row 4 (15.0 units total)
    [
        ('Shift', '', 'ShiftLeft', 2.25, True),
        ('Z', '', 'Z', 1.0, False), ('X', '', 'X', 1.0, False), ('C', '', 'C', 1.0, False),
        ('V', '', 'V', 1.0, False), ('B', '', 'B', 1.0, False), ('N', '', 'N', 1.0, False),
        ('M', '', 'M', 1.0, False), (',', '<', ',', 1.0, False), ('.', '>', '.', 1.0, False),
        ('/', '?', '/', 1.0, False), ('Shift', '', 'ShiftRight', 2.75, True)
    ],
    # Row 5 (15.0 units total)
    [
        ('Ctrl', '', 'CtrlLeft', 1.25, True), ('Win', '', 'WinLeft', 1.25, True), ('Alt', '', 'AltLeft', 1.25, True),
        ('Space', '𐴢', ' ', 6.25, False),
        ('Alt', '', 'AltRight', 1.25, True), ('Win', '', 'WinRight', 1.25, True), ('Menu', '', 'Menu', 1.25, True), ('Ctrl', '', 'CtrlRight', 1.25, True)
    ]
]

def render_full_windows_keyboard(is_shift, output_path):
    scale = 2
    unit_px = 64 * scale
    gap = 6 * scale
    padding_x = 24 * scale
    padding_y = 60 * scale
    
    total_w = int(padding_x * 2 + 15.0 * unit_px + 14 * gap)
    total_h = int(padding_y + 5 * (unit_px * 0.95 + gap) + 24 * scale)
    
    img = Image.new('RGBA', (total_w, total_h), (235, 240, 238, 255))
    draw = ImageDraw.Draw(img)
    
    try:
        font_glyph = ImageFont.truetype(font_path, int(26 * scale))
        font_shift_glyph = ImageFont.truetype(font_path, int(15 * scale))
        font_latin = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(12 * scale))
        font_mod = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(11 * scale))
        font_title = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(16 * scale))
        font_badge = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(12 * scale))
    except:
        font_glyph = ImageFont.truetype(font_path, int(26 * scale))
        font_shift_glyph = ImageFont.truetype(font_path, int(15 * scale))
        font_latin = ImageFont.load_default()
        font_mod = ImageFont.load_default()
        font_title = ImageFont.load_default()
        font_badge = ImageFont.load_default()

    # Outer frame with rounded bezel
    draw.rounded_rectangle([4, 4, total_w-4, total_h-4], radius=16*scale, outline=(190, 210, 202), width=2*scale)
    
    # Title & Header
    title_text = 'Full Windows Hanifi Rohingya Keyboard • ' + ('Shift Mode (Tone Marks & Punctuation)' if is_shift else 'Normal Mode (Base Letters & Digits)')
    draw.text((padding_x, 20*scale), title_text, fill=(21, 60, 55), font=font_title)
    
    # Mode Badge
    badge_text = '[ SHIFT ACTIVE ]' if is_shift else '[ STANDARD MODE ]'
    badge_w = 140 * scale
    badge_h = 26 * scale
    badge_x = total_w - padding_x - badge_w
    badge_y = 17 * scale
    draw.rounded_rectangle([badge_x, badge_y, badge_x + badge_w, badge_y + badge_h], radius=13*scale, fill=(217, 238, 229) if not is_shift else (184, 228, 208))
    draw.text((badge_x + 16*scale, badge_y + 4*scale), badge_text, fill=(0, 104, 82), font=font_badge)

    current_y = padding_y
    row_height = unit_px * 0.95
    
    for row in full_keyboard:
        current_x = padding_x
        for label, shift_label, key_id, width_units, is_mod in row:
            key_w = width_units * unit_px + (width_units - 1.0) * gap
            
            # Colors
            if is_mod:
                bg_color = (220, 228, 225) if not (is_shift and 'Shift' in label) else (184, 228, 208)
                border_color = (175, 195, 188)
                text_color = (60, 85, 78)
            else:
                bg_color = (255, 255, 255)
                border_color = (195, 212, 205)
                text_color = (21, 60, 55)
                
            # Key 3D bevel / shadow
            draw.rounded_rectangle([current_x, current_y + 2.5*scale, current_x + key_w, current_y + row_height + 2.5*scale], radius=7*scale, fill=(185, 200, 194))
            draw.rounded_rectangle([current_x, current_y, current_x + key_w, current_y + row_height], radius=7*scale, fill=bg_color, outline=border_color, width=int(1.5*scale))
            
            if is_mod:
                # Modifier Key Label
                bbox = draw.textbbox((0, 0), label, font=font_mod)
                tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
                draw.text((current_x + 8*scale, current_y + row_height - th - 8*scale), label, fill=text_color, font=font_mod)
            elif key_id == ' ':
                # Spacebar
                sp_text = '𐴢 (Sakin)' if is_shift else 'Space'
                bbox = draw.textbbox((0, 0), sp_text, font=font_glyph)
                tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
                draw.text((current_x + (key_w - tw)/2, current_y + (row_height - th)/2 - 3*scale), sp_text, fill=text_color, font=font_glyph)
            else:
                # Normal typing key
                clean_key = key_id
                base_char = data['layers']['base'].get(clean_key, '')
                shift_char = data['layers']['shift'].get(clean_key, '')
                
                # Top-Left: Latin Base Label
                draw.text((current_x + 7*scale, current_y + 5*scale), label, fill=(90, 115, 106), font=font_latin)
                
                # Top-Right: Shift Latin / Shift Symbol
                if shift_label:
                    bbox_s = draw.textbbox((0, 0), shift_label, font=font_latin)
                    stw = bbox_s[2] - bbox_s[0]
                    draw.text((current_x + key_w - stw - 7*scale, current_y + 5*scale), shift_label, fill=(130, 150, 142), font=font_latin)
                elif shift_char and shift_char != base_char:
                    bbox_s = draw.textbbox((0, 0), shift_char, font=font_shift_glyph)
                    stw = bbox_s[2] - bbox_s[0]
                    draw.text((current_x + key_w - stw - 7*scale, current_y + 3*scale), shift_char, fill=(0, 104, 82), font=font_shift_glyph)
                
                # Center: Main active character (highlighted based on is_shift)
                active_char = shift_char if is_shift else base_char
                if active_char:
                    bbox_g = draw.textbbox((0, 0), active_char, font=font_glyph)
                    gw, gh = bbox_g[2] - bbox_g[0], bbox_g[3] - bbox_g[1]
                    draw.text((current_x + (key_w - gw)/2, current_y + (row_height - gh)/2 + 4*scale), active_char, fill=(0, 104, 82) if is_shift else (21, 60, 55), font=font_glyph)

            current_x += key_w + gap
        current_y += row_height + gap

    img.save(output_path, 'PNG', optimize=True)
    print(f'Rendered full 100% Windows keyboard layout to {output_path}')

render_full_windows_keyboard(False, str(ROOT / 'assets/keyboard_layout.png'))
render_full_windows_keyboard(True, str(ROOT / 'assets/keyboard_shift_layout.png'))
