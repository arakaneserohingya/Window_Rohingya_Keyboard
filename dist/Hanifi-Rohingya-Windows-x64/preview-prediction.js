'use strict';
const predictor = new RohingyaPredictor(ROHINGYA_DICTIONARY);
const suggestions = document.getElementById('suggestions');
const predictionToggle = document.getElementById('prediction-toggle');
let predicting = true, composing = false;
function updateSuggestions() {
  suggestions.replaceChildren();
  if (!enabled || !predicting || composing) return;
  const context = predictor.context(editor.value, editor.selectionStart, editor.selectionEnd);
  if (!context) return;
  const snapshot = editor.value;
  for (const word of predictor.suggest(context.prefix, context.previous)) {
    const button = document.createElement('button');
    button.type = 'button'; button.dir = 'rtl'; button.lang = 'rhg-Rohg';
    button.textContent = word;
    button.setAttribute('aria-label', `Insert suggestion ${word}`);
    button.onmousedown = e => e.preventDefault();
    button.onclick = () => {
      if (editor.value !== snapshot || editor.selectionStart !== context.end || editor.selectionEnd !== context.end) {
        updateSuggestions(); return;
      }
      editor.setSelectionRange(context.start, context.end);
      insert(word + (editor.value.slice(context.end).startsWith(' ') ? '' : ' '));
    };
    suggestions.append(button);
  }
}
predictionToggle.onclick = () => {
  predicting = !predicting;
  predictionToggle.textContent = `Suggestions: ${predicting ? 'on' : 'off'}`;
  predictionToggle.setAttribute('aria-pressed', String(predicting));
  updateSuggestions();
};
editor.addEventListener('compositionstart', () => {composing = true; updateSuggestions();});
editor.addEventListener('compositionend', () => {composing = false; updateSuggestions();});
for (const event of ['input', 'click', 'keyup', 'select']) editor.addEventListener(event, updateSuggestions);
document.addEventListener('selectionchange', () => {if (document.activeElement === editor) updateSuggestions();});
document.getElementById('mode').addEventListener('click', updateSuggestions);
updateSuggestions();
