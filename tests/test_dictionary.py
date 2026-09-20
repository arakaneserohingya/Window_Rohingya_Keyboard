import hashlib
import json
import unittest
from pathlib import Path
from dictionary_import import decode, DictionaryError

ROOT = Path(__file__).resolve().parents[1]


class DictionaryTests(unittest.TestCase):
    def test_supplied_dictionary_roundtrip(self):
        data = (ROOT/'dictionary/main_rhg.dict').read_bytes()
        model = decode(data)
        self.assertEqual(len(model['words']), 18253)
        self.assertEqual(sum(map(len, model['bigrams'].values())), 13356)
        self.assertEqual(model['metadata']['locale'], 'rhg')
        self.assertEqual(model['sha256'], hashlib.sha256(data).hexdigest())
        self.assertEqual(model, json.loads((ROOT/'dictionary/model.json').read_text()))
        self.assertIn(['𐴀𐴝𐴌', 255], model['words'])
        for previous, pairs in model['bigrams'].items():
            self.assertLess(int(previous), len(model['words']))
            for target, score in pairs:
                self.assertTrue(0 <= target < len(model['words']))
                self.assertTrue(0 <= score <= 15)

    def test_invalid_input_is_rejected(self):
        data = (ROOT/'dictionary/main_rhg.dict').read_bytes()
        for invalid in (b'', b'not a dictionary', data[:100], data[:-100], data[:4]+b'\0\x02'+data[6:]):
            with self.subTest(length=len(invalid)), self.assertRaises(DictionaryError):
                decode(invalid)
