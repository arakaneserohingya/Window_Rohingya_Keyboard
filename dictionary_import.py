"""Decode the supplied LatinIME v202 static trie into portable prediction data.

Format fields checked against the Android project's PatriciaTrieReadingUtils,
ByteArrayUtils and BigramListReadWriteUtils. No Android runtime is required.
"""
import hashlib
import json
from pathlib import Path


class DictionaryError(ValueError):
    pass


class Reader:
    def __init__(self, data):
        self.data = data
        self.pos = 0

    def uint(self, size):
        if size < 1 or self.pos < 0 or self.pos + size > len(self.data):
            raise DictionaryError('Truncated dictionary or invalid address')
        value = int.from_bytes(self.data[self.pos:self.pos + size], 'big')
        self.pos += size
        return value

    def char(self):
        first = self.uint(1)
        if first == 0x1f:
            return None
        cp = (first << 16 | self.uint(2)) if first < 0x20 else first
        if cp > 0x10ffff or 0xd800 <= cp <= 0xdfff:
            raise DictionaryError('Invalid Unicode scalar')
        return chr(cp)

    def string(self):
        chars = []
        while True:
            ch = self.char()
            if ch is None:
                return ''.join(chars)
            chars.append(ch)


def decode(data):
    r = Reader(data)
    if r.uint(4) != 0x9bc13afe or r.uint(2) != 202:
        raise DictionaryError('Expected a LatinIME version 202 dictionary')
    if r.uint(2) != 0:
        raise DictionaryError('Unsupported dictionary header flags')
    header_end = r.uint(4)
    if not 12 <= header_end < len(data):
        raise DictionaryError('Invalid header size')
    metadata = {}
    while r.pos < header_end:
        key = r.string()
        metadata[key] = r.string()
    if r.pos != header_end or 'codePointTable' in metadata:
        raise DictionaryError('Unsupported or malformed header')
    nodes = {}
    visited = set()

    def array(pos, prefix):
        if pos in visited or len(prefix) > 128:
            raise DictionaryError('Cyclic trie or excessive word length')
        visited.add(pos)
        r.pos = pos
        count = r.uint(1)
        if count & 0x80:
            count = ((count & 0x7f) << 8) | r.uint(1)
        children = []
        for _ in range(count):
            address = r.pos
            flags = r.uint(1)
            chars = r.string() if flags & 0x20 else r.char()
            if not chars:
                raise DictionaryError('Empty trie node')
            word = prefix + chars
            frequency = r.uint(1) if flags & 0x10 else None
            size = flags >> 6
            if size:
                origin = r.pos
                child = origin + r.uint(size)
                children.append((child, word))
            if flags & 0x08:
                # Shortcuts are not word-completion entries. Skip their sized block.
                origin = r.pos
                length = r.uint(2)
                if length < 2 or origin + length > len(data):
                    raise DictionaryError('Invalid shortcut block')
                r.pos = origin + length
            bigrams = []
            if flags & 0x04:
                while True:
                    attributes = r.uint(1)
                    origin = r.pos
                    width = (attributes >> 4) & 3
                    offset = r.uint(width)
                    target = origin + (-offset if attributes & 0x40 else offset)
                    bigrams.append((target, attributes & 15))
                    if not attributes & 0x80:
                        break
            if address in nodes:
                raise DictionaryError('Overlapping trie nodes')
            nodes[address] = (word, frequency, flags, bigrams)
        for child, word in children:
            array(child, word)

    array(header_end, '')
    eligible = {pos: node for pos, node in nodes.items()
                if node[1] is not None and not node[2] & 2}
    ordered = sorted(eligible, key=lambda pos: eligible[pos][0])
    indices = {pos: index for index, pos in enumerate(ordered)}
    words = [[eligible[pos][0], eligible[pos][1]] for pos in ordered]
    if len({word for word, _ in words}) != len(words):
        raise DictionaryError('Duplicate words in trie')
    pairs = {}
    for pos in ordered:
        entries = []
        for target, score in eligible[pos][3]:
            if target not in nodes or nodes[target][1] is None:
                raise DictionaryError('Bigram target is not a terminal node')
            if target in indices:
                entries.append([indices[target], score])
        if entries:
            pairs[str(indices[pos])] = entries
    return {'metadata': metadata, 'sha256': hashlib.sha256(data).hexdigest(),
            'words': words, 'bigrams': pairs}


def generate(root):
    model = decode((root/'dictionary/main_rhg.dict').read_bytes())
    output = json.dumps(model, ensure_ascii=False, separators=(',', ':'))
    (root/'dictionary/model.json').write_text(output + '\n', encoding='utf-8')
    (root/'dictionary/model.js').write_text('const ROHINGYA_DICTIONARY = ' + output + ';\n', encoding='utf-8')
    # UTF-16 literals also compile on hosts whose wchar_t is 32-bit.
    def literal(word):
        raw = word.encode('utf-16-le')
        return 'u"' + ''.join('\\x%04x' % int.from_bytes(raw[i:i+2], 'little') for i in range(0, len(raw), 2)) + '"'
    rows, pairs = [], []
    for index, (word, frequency) in enumerate(model['words']):
        links = model['bigrams'].get(str(index), [])
        rows.append('  {%s,%d,%d,%d},' % (literal(word), frequency, len(pairs), len(links)))
        pairs.extend(links)
    (root/'ime').mkdir(exist_ok=True)
    (root/'ime/model.inc').write_text('// Generated by dictionary_import.py.\nstatic const Word words[] = {\n' + '\n'.join(rows) + '\n};\nstatic const Pair pairs[] = {\n' + '\n'.join('  {%d,%d},' % tuple(pair) for pair in pairs) + '\n};\n')
    return model


if __name__ == '__main__':
    model = generate(Path(__file__).resolve().parent)
    print(f"Decoded {len(model['words'])} words and {sum(map(len, model['bigrams'].values()))} word pairs")
