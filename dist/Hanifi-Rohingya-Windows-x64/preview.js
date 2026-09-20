'use strict';
const editor = document.getElementById('editor');
let stickyShift = false, physicalShift = false, enabled = true;
const rows = ['`1234567890-=', 'QWERTYUIOP[]\\', "ASDFGHJKL;'", 'ZXCVBNM,./', ' '];
const codeKeys = {Backquote:'`',Minus:'-',Equal:'=',BracketLeft:'[',BracketRight:']',Backslash:'\\',Semicolon:';',Quote:"'",Comma:',',Period:'.',Slash:'/',Space:' '};
function currentLayer() { return ROHINGYA.layers[stickyShift || physicalShift ? 'shift' : 'base']; }
function insert(text) {
  editor.setRangeText(text, editor.selectionStart, editor.selectionEnd, 'end');
  editor.focus();
  editor.dispatchEvent(new Event('input', {bubbles:true}));
}
function backspace() {
  const end = editor.selectionEnd;
  let start = editor.selectionStart;
  if (start === end && start > 0) {
    const previous = Array.from(editor.value.slice(0, start)).pop();
    start -= previous.length;
  }
  editor.setSelectionRange(start, end);
  insert('');
}
function render() {
  document.getElementById('keys').replaceChildren();
  for (const row of rows) {
    const container = document.createElement('div'); container.className = 'row';
    for (const key of row) {
      const value = currentLayer()[key];
      const button = document.createElement('button'); button.className = 'key';
      button.disabled = !value;
      const label = document.createElement('small'); label.textContent = key === ' ' ? 'Space' : key;
      const glyph = document.createElement('span'); glyph.className = 'glyph'; glyph.dir = 'rtl';
      glyph.textContent = value === ' ' ? '␣' : value || '';
      button.title = value ? `${ROHINGYA.names[value]} · U+${value.codePointAt(0).toString(16).toUpperCase()}` : 'Unmapped';
      button.setAttribute('aria-label', `${label.textContent}: ${button.title}`);
      button.append(label, glyph);
      button.addEventListener('mousedown', e => e.preventDefault());
      button.addEventListener('click', () => insert(value)); container.append(button);
    }
    document.getElementById('keys').append(container);
  }
  const shift = document.getElementById('shift');
  shift.textContent = `Shift: ${stickyShift || physicalShift ? 'on' : 'off'}`;
  shift.setAttribute('aria-pressed', String(stickyShift || physicalShift));
  shift.classList.toggle('active', stickyShift || physicalShift);
}
document.getElementById('shift').onclick = () => {stickyShift = !stickyShift;render();editor.focus();};
document.getElementById('mode').onclick = e => {enabled = !enabled;e.target.textContent = `Rohingya: ${enabled ? 'on' : 'off'}`;e.target.setAttribute('aria-pressed',String(enabled));editor.focus();};
document.addEventListener('keydown', e => {if(e.key === 'Shift' && !physicalShift){physicalShift=true;render();}});
document.addEventListener('keyup', e => {if(e.key === 'Shift'){physicalShift=false;render();}});
window.addEventListener('blur', () => {physicalShift=false;render();});
editor.addEventListener('keydown', e => {
  if (!enabled || e.ctrlKey || e.altKey || e.metaKey || e.isComposing) return;
  if(e.key === 'Backspace'){e.preventDefault();backspace();return;}
  const key = codeKeys[e.code] || (/^(Key[A-Z]|Digit[0-9])$/.test(e.code) ? e.code.slice(-1) : null);
  const value = currentLayer()[key];
  if(key !== null && Object.hasOwn(currentLayer(), key)){
    e.preventDefault();
    if(value) insert(value);
  }
});
document.getElementById('backspace').onmousedown = e => e.preventDefault();
document.getElementById('backspace').onclick = backspace;
document.getElementById('copy').onclick = async () => {
  try {await navigator.clipboard.writeText(editor.value);document.getElementById('status').textContent='Text copied.';}
  catch {editor.focus();editor.select();document.getElementById('status').textContent='Press Ctrl+C (Command+C on Mac) to copy the selected text.';}
};
document.getElementById('download').onclick = () => {
  const url=URL.createObjectURL(new Blob([editor.value],{type:'text/plain;charset=utf-8'}));
  const a=document.createElement('a');a.href=url;a.download='rohingya.txt';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
};
render();
