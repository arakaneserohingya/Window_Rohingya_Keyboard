const {test} = require('node:test');
const assert = require('node:assert/strict');
const Predictor = require('../prediction.js');
const model = require('../dictionary/model.json');
const predictor = new Predictor(model);
test('completion ranks by frequency and keeps typed prefix', () => {
  const suggestions = predictor.suggest('𐴀');
  assert.equal(suggestions[0], '𐴀𐴝𐴌');
  assert.equal(suggestions.length, 5);
  assert(suggestions.every(w => w.startsWith('𐴀')));
  assert(!predictor.suggest('𐴀𐴝𐴌').includes('𐴀𐴝𐴌'));
  assert.deepEqual(predictor.suggest('xyz'), []);
});
test('next-word candidates use actual bigram targets and scores', () => {
  const previous = Object.keys(model.bigrams).find(i => model.bigrams[i].some(([,s]) => s > 0));
  const links = model.bigrams[previous];
  const best = [...links].sort(([a,sa],[b,sb]) => (256*sb+model.words[b][1])-(256*sa+model.words[a][1]) || a-b)[0][0];
  assert.equal(predictor.suggest('', model.words[previous][0])[0], model.words[best][0]);
  assert.notDeepEqual(predictor.suggest('', model.words[previous][0]), predictor.suggest(''));
});
test('UTF-16 caret and punctuation boundaries', () => {
  assert.deepEqual(predictor.context('𐴀𐴝 𐴁', 7), {prefix:'𐴁',previous:'𐴀𐴝',start:5,end:7});
});

test('suppresses selection, mid-word, and punctuation prediction', () => {
  assert.equal(predictor.context('𐴀𐴁', 2), null);
  assert.equal(predictor.context('𐴀𐴁', 0, 4), null);
  assert.equal(predictor.context('𐴀؟', 3), null);
  assert.equal(predictor.context('𐴀\n', 3), null);
  assert.deepEqual(predictor.context('𐴀 ', 3), {prefix:'',previous:'𐴀',start:3,end:3});
});
