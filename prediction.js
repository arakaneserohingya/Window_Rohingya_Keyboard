'use strict';
class RohingyaPredictor {
  constructor(model) {
    this.model = model;
    this.ids = new Map(model.words.map(([word], i) => [word, i]));
    this.ranked = model.words.map((_, i) => i).sort((a, b) => model.words[b][1] - model.words[a][1] || a - b);
  }
  suggest(prefix, previous = '', limit = 5) {
    const {words, bigrams} = this.model;
    const links = new Map(bigrams[this.ids.get(previous)] || []);
    const candidates = [];
    for (const id of this.ranked) {
      const [word, frequency] = words[id];
      if ((prefix && !word.startsWith(prefix)) || word === prefix) continue;
      // Preserve the dictionary's 4-bit word-pair score; frequency breaks ties.
      const score = (links.has(id) ? 256 + 256 * links.get(id) : 0) + frequency;
      candidates.push({word, score, id});
    }
    return candidates.sort((a, b) => b.score - a.score || a.id - b.id).slice(0, limit).map(x => x.word);
  }
  context(text, start, end = start) {
    if (start !== end) return null;
    const before = text.slice(0, start);
    const prefix = before.match(/[\u{10D00}-\u{10D27}]+$/u)?.[0] || '';
    // Only complete at word ends, never overwrite the remainder of a word.
    if (/^[\u{10D00}-\u{10D27}]/u.test(text.slice(start))) return null;
    if (!prefix && before && !/[ \t]$/.test(before)) return null;
    const previous = before.slice(0, before.length - prefix.length).match(/([\u{10D00}-\u{10D27}]+)[ \t]+$/u)?.[1] || '';
    return {prefix, previous, start: start - prefix.length, end: start};
  }
}
if (typeof module !== 'undefined') module.exports = RohingyaPredictor;
