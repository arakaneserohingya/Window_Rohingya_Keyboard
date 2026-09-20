import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
layout_text = (ROOT / 'layout.js').read_text()
json_str = layout_text.replace('const ROHINGYA = ', '').rstrip(';\n ')
data = json.loads(json_str)
font_path = str(ROOT / 'assets/NotoSansHanifiRohingya-Regular.ttf')

# Mac Apple Magic Keyboard physical layout (15 units total width per row)
mac_keyboard = [
    # Row 1 (15.0 units)
    [
        ('`', '~', '`', 1.0, False), ('1', '!', '1', 1.0, False), ('2', '@', '2', 1.0, False),
        ('3', '#', '3', 1.0, False), ('4', '$', '4', 1.0, False), ('5', '%', '5', 1.0, False),
        ('6', '^', '6', 1.0, False), ('7', '&', '7', 1.0, False), ('8', '*', '8', 1.0, False),
        ('9', '(', '9', 1.0, False), ('0', ')', '0', 1.0, False), ('-', '_', '-', 1.0, False),
        ('=', '+', '=', 1.0, False), ('delete ⌫', '', 'delete', 2.0, True)
    ],
    # Row 2 (15.0 units)
    [
        ('tab ⇥', '', 'tab', 1.5, True),
        ('Q', '', 'Q', 1.0, False), ('W', '', 'W', 1.0, False), ('E', '', 'E', 1.0, False),
        ('R', '', 'R', 1.0, False), ('T', '', 'T', 1.0, False), ('Y', '', 'Y', 1.0, False),
        ('U', '', 'U', 1.0, False), ('I', '', 'I', 1.0, False), ('O', '', 'O', 1.0, False),
        ('P', '', 'P', 1.0, False), ('[', '{', '[', 1.0, False), (']', '}', ']', 1.0, False),
        ('\\', '|', '\\', 1.5, False)
    ],
    # Row 3 (15.0 units)
    [
        ('caps lock ⇪', '', 'caps', 1.75, True),
        ('A', '', 'A', 1.0, False), ('S', '', 'S', 1.0, False), ('D', '', 'D', 1.0, False),
        ('F', '', 'F', 1.0, False), ('G', '', 'G', 1.0, False), ('H', '', 'H', 1.0, False),
        ('J', '', 'J', 1.0, False), ('K', '', 'K', 1.0, False), ('L', '', 'L', 1.0, False),
        (';', ':', ';', 1.0, False), ("'", '"', "'", 1.0, False),
        ('return ↩', '', 'return', 2.25, True)
    ],
    # Row 4 (15.0 units)
    [
        ('shift ⇧', '', 'shift_l', 2.25, True),
        ('Z', '', 'Z', 1.0, False), ('X', '', 'X', 1.0, False), ('C', '', 'C', 1.0, False),
        ('V', '', 'V', 1.0, False), ('B', '', 'B', 1.0, False), ('N', '', 'N', 1.0, False),
        ('M', '', 'M', 1.0, False), (',', '<', ',', 1.0, False), ('.', '>', '.', 1.0, False),
        ('/', '?', '/', 1.0, False), ('shift ⇧', '', 'shift_r', 2.75, True)
    ],
    # Row 5 (15.0 units)
    [
        ('fn 🌐', '', 'fn', 1.0, True), ('control ⌃', '', 'ctrl', 1.25, True),
        ('option ⌥', '', 'opt_l', 1.25, True), ('command ⌘', '', 'cmd_l', 1.5, True),
        ('Space', '𐴢', ' ', 5.0, False),
        ('command ⌘', '', 'cmd_r', 1.5, True), ('option ⌥', '', 'opt_r', 1.25, True),
        ('◀', '', 'left', 0.75, True), ('▲/▼', '', 'updown', 0.75, True), ('▶', '', 'right', 0.75, True)
    ]
]

def render_mac_keyboard(is_shift, output_path):
    scale = 2
    unit_px = 64 * scale
    gap = 6 * scale
    padding_x = 24 * scale
    padding_y = 60 * scale
    
    total_w = int(padding_x * 2 + 15.0 * unit_px + 14 * gap)
    total_h = int(padding_y + 5 * (unit_px * 0.95 + gap) + 24 * scale)
    
    # Apple silver/space gray chassis finish
    img = Image.new('RGBA', (total_w, total_h), (232, 235, 238, 255))
    draw = ImageDraw.Draw(img)
    
    try:
        font_glyph = ImageFont.truetype(font_path, int(26 * scale))
        font_shift_glyph = ImageFont.truetype(font_path, int(15 * scale))
        font_latin = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(12 * scale))
        font_mod = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(10 * scale))
        font_title = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(16 * scale))
        font_badge = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(12 * scale))
    except:
        font_glyph = ImageFont.truetype(font_path, int(26 * scale))
        font_shift_glyph = ImageFont.truetype(font_path, int(15 * scale))
        font_latin = ImageFont.load_default()
        font_mod = ImageFont.load_default()
        font_title = ImageFont.load_default()
        font_badge = ImageFont.load_default()

    # Outer Mac bezel
    draw.rounded_rectangle([4, 4, total_w-4, total_h-4], radius=18*scale, outline=(205, 210, 215), width=2*scale)
    
    # Title & Apple Logo / Header
    title_text = ' Apple macOS Hanifi Rohingya Keyboard • ' + ('Shift Mode (Tone Marks & Punctuation)' if is_shift else 'Normal Mode (Base Letters & Digits)')
    draw.text((padding_x, 20*scale), title_text, fill=(30, 45, 55), font=font_title)
    
    # Badge
    badge_text = '[ macOS SHIFT: ON ]' if is_shift else '[ macOS SHIFT: OFF ]'
    badge_w = 150 * scale
    badge_h = 26 * scale
    badge_x = total_w - padding_x - badge_w
    badge_y = 17 * scale
    draw.rounded_rectangle([badge_x, badge_y, badge_x + badge_w, badge_y + badge_h], radius=13*scale, fill=(215, 235, 248) if not is_shift else (184, 228, 208))
    draw.text((badge_x + 14*scale, badge_y + 4*scale), badge_text, fill=(0, 100, 160) if not is_shift else (0, 104, 82), font=font_badge)

    current_y = padding_y
    row_height = unit_px * 0.95
    
    for row in mac_keyboard:
        current_x = padding_x
        for label, shift_label, key_id, width_units, is_mod in row:
            key_w = width_units * unit_px + (width_units - 1.0) * gap
            
            # Key appearance
            if is_mod:
                bg_color = (245, 246, 248) if not (is_shift and 'shift' in key_id) else (195, 230, 215)
                border_color = (210, 215, 220)
                text_color = (80, 90, 100)
            else:
                bg_color = (255, 255, 255)
                border_color = (215, 220, 225)
                text_color = (20, 40, 45)
                
            # Apple chiclet shadow & keycap
            draw.rounded_rectangle([current_x, current_y + 2*scale, current_x + key_w, current_y + row_height + 2*scale], radius=6*scale, fill=(195, 200, 205))
            draw.rounded_rectangle([current_x, current_y, current_x + key_w, current_y + row_height], radius=6*scale, fill=bg_color, outline=border_color, width=int(1.5*scale))
            
            if is_mod:
                # Modifier Key Label
                bbox = draw.textbbox((0, 0), label, font=font_mod)
                tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
                draw.text((current_x + 6*scale, current_y + row_height - th - 6*scale), label, fill=text_color, font=font_mod)
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
                draw.text((current_x + 7*scale, current_y + 5*scale), label, fill=(100, 115, 125), font=font_latin)
                
                # Top-Right: Shift Latin / Shift Symbol
                if shift_label:
                    bbox_s = draw.textbbox((0, 0), shift_label, font=font_latin)
                    stw = bbox_s[2] - bbox_s[0]
                    draw.text((current_x + key_w - stw - 7*scale, current_y + 5*scale), shift_label, fill=(140, 150, 160), font=font_latin)
                elif shift_char and shift_char != base_char:
                    bbox_s = draw.textbbox((0, 0), shift_char, font=font_shift_glyph)
                    stw = bbox_s[2] - bbox_s[0]
                    draw.text((current_x + key_w - stw - 7*scale, current_y + 3*scale), shift_char, fill=(0, 120, 90), font=font_shift_glyph)
                
                # Center: Main active character
                active_char = shift_char if is_shift else base_char
                if active_char:
                    bbox_g = draw.textbbox((0, 0), active_char, font=font_glyph)
                    gw, gh = bbox_g[2] - bbox_g[0], bbox_g[3] - bbox_g[1]
                    draw.text((current_x + (key_w - gw)/2, current_y + (row_height - gh)/2 + 4*scale), active_char, fill=(0, 120, 90) if is_shift else (20, 40, 45), font=font_glyph)

            current_x += key_w + gap
        current_y += row_height + gap

    img.save(output_path, 'PNG', optimize=True)
    print(f'Rendered Apple macOS keyboard layout to {output_path}')

render_mac_keyboard(False, str(ROOT / 'assets/keyboard_mac_layout.png'))
render_mac_keyboard(True, str(ROOT / 'assets/keyboard_mac_shift_layout.png'))
