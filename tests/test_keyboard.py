import json
import re
import unittest
import zipfile
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from build import ROOT, mappings, native_entries, utf16


class KeyboardTests(unittest.TestCase):
    def test_published_sil_positions(self):
        source = (ROOT/'keyboard/hanifi_rohingya.reference.kmn').read_text(encoding='utf-8-sig')
        aliases = dict(COMMA=',', COLON=';', PERIOD='.', SLASH='/', LBRKT='[',
                       RBRKT=']', QUOTE="'", BKQUOTE='`', BKSLASH='\\', SPACE=' ')
        layers = mappings()
        for group in ('digits', 'Letters', 'Vowels', 'Other'):
            keys = re.search(r'store\(' + group + r'K\)(.*?)store', source, re.S)[1]
            values = re.search(r'store\(' + group + r'U\)([^\n]+)', source)[1]
            cps = []
            for first, last in re.findall(r'U\+([0-9A-F]+)(?:\s*\.\.\s*U\+([0-9A-F]+))?', values):
                cps.extend(range(int(first,16), int(last or first,16)+1))
            positions = re.findall(r'\[(SHIFT )?K_(\w+)\]', keys)
            self.assertEqual(len(positions), len(cps))
            for (shift, key), cp in zip(positions, cps):
                self.assertEqual(layers['shift' if shift else 'base'][aliases.get(key,key)], chr(cp))
        for key in re.search(r'store\(nul\) "([A-Z]+)"', source)[1]:
            self.assertIsNone(layers['shift'][key])
        self.assertEqual(layers['shift'][' '], '\U00010d22')

    def test_published_repertoire(self):
        actual = {ord(v) for layer in mappings().values() for v in layer.values() if v and ord(v) > 0xFFFF}
        expected = (set(range(0x10D00,0x10D28)) | set(range(0x10D30,0x10D3A))) - {0x10D1C}
        self.assertEqual(actual, expected)

    def test_generated_tables(self):
        js = (ROOT/'layout.js').read_text()
        self.assertEqual(json.loads(js.removeprefix('const ROHINGYA = ').rstrip(';\n'))['layers'],mappings())
        self.assertEqual(json.loads((ROOT/'windows/expected-layout.json').read_text()),
                         [[vk, values] for vk, values in native_entries()])
        native = (ROOT/'native/layout.inc').read_text()
        for vk, values in native_entries():
            for state, cp in enumerate(values):
                if cp and cp > 0xFFFF:
                    hi, lo = utf16(cp)
                    self.assertIn(f'{{0x{vk:02X},{state},{{0x{hi:04X},0x{lo:04X}}}}}', native)
                    self.assertEqual(bytes([hi & 255, hi >> 8, lo & 255, lo >> 8]).decode('utf-16-le'), chr(cp))
        self.assertIn('{0x56,0,{WCH_LGTR,WCH_NONE,0x0016,0x0016}}', native)

    def test_native_package(self):
        prefix = 'Hanifi-Rohingya-Windows-x64/'
        with zipfile.ZipFile(ROOT/'dist/Hanifi-Rohingya-Windows-x64.zip') as package:
            self.assertIsNone(package.testzip())
            for name in ('Install.cmd','Uninstall.cmd','install.ps1','uninstall.ps1','enable.ps1',
                         'test-windows.ps1','expected-layout.json','preview.html','preview.js','layout.js',
                         'assets/NotoSansHanifiRohingya-Regular.ttf','LAYOUT-LICENSE.txt'):
                self.assertIn(prefix+name, package.namelist())
            dll = package.read(prefix+'kbdroh.dll')
            self.assertEqual(dll[:2], b'MZ')
            pe = int.from_bytes(dll[60:64], 'little')
            self.assertEqual(dll[pe:pe+6], b'PE\0\0\x64\x86')
            self.assertIn(b'KbdLayerDescriptor', dll)
            self.assertEqual(package.read(prefix+'layout.js'), (ROOT/'layout.js').read_bytes())
