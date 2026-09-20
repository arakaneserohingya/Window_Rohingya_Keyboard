'use strict';
const editor = document.getElementById('editor');
let stickyShift = false, physicalShift = false, enabled = true, capsLock = false;

const fullLayoutRows = [
  [
    {id:'`', label:'`', shift:'~', flex:1},
    {id:'1', label:'1', shift:'!', flex:1}, {id:'2', label:'2', shift:'@', flex:1},
    {id:'3', label:'3', shift:'#', flex:1}, {id:'4', label:'4', shift:'$', flex:1},
    {id:'5', label:'5', shift:'%', flex:1}, {id:'6', label:'6', shift:'^', flex:1},
    {id:'7', label:'7', shift:'&', flex:1}, {id:'8', label:'8', shift:'*', flex:1},
    {id:'9', label:'9', shift:'(', flex:1}, {id:'0', label:'0', shift:')', flex:1},
    {id:'-', label:'-', shift:'_', flex:1}, {id:'=', label:'=', shift:'+', flex:1},
    {id:'Backspace', label:'Backspace', action:'backspace', flex:2, mod:true}
  ],
  [
    {id:'Tab', label:'Tab', action:'tab', flex:1.5, mod:true},
    {id:'Q', label:'Q', flex:1}, {id:'W', label:'W', flex:1}, {id:'E', label:'E', flex:1},
    {id:'R', label:'R', flex:1}, {id:'T', label:'T', flex:1}, {id:'Y', label:'Y', flex:1},
    {id:'U', label:'U', flex:1}, {id:'I', label:'I', flex:1}, {id:'O', label:'O', flex:1},
    {id:'P', label:'P', flex:1}, {id:'[', label:'[', shift:'{', flex:1}, {id:']', label:']', shift:'}', flex:1},
    {id:'\\', label:'\\', shift:'|', flex:1.5}
  ],
  [
    {id:'CapsLock', label:'Caps Lock', action:'caps', flex:1.75, mod:true},
    {id:'A', label:'A', flex:1}, {id:'S', label:'S', flex:1}, {id:'D', label:'D', flex:1},
    {id:'F', label:'F', flex:1}, {id:'G', label:'G', flex:1}, {id:'H', label:'H', flex:1},
    {id:'J', label:'J', flex:1}, {id:'K', label:'K', flex:1}, {id:'L', label:'L', flex:1},
    {id:';', label:';', shift:':', flex:1}, {id:"'", label:"'", shift:'"', flex:1},
    {id:'Enter', label:'Enter', action:'enter', flex:2.25, mod:true}
  ],
  [
    {id:'ShiftLeft', label:'Shift', action:'shift', flex:2.25, mod:true},
    {id:'Z', label:'Z', flex:1}, {id:'X', label:'X', flex:1}, {id:'C', label:'C', flex:1},
    {id:'V', label:'V', flex:1}, {id:'B', label:'B', flex:1}, {id:'N', label:'N', flex:1},
    {id:'M', label:'M', flex:1}, {id:',', label:',', shift:'<', flex:1}, {id:'.', label:'.', shift:'>', flex:1},
    {id:'/', label:'/', shift:'?', flex:1},
    {id:'ShiftRight', label:'Shift', action:'shift', flex:2.75, mod:true}
  ],
  [
    {id:'CtrlLeft', label:'Ctrl', flex:1.25, mod:true},
    {id:'WinLeft', label:'Win', flex:1.25, mod:true},
    {id:'AltLeft', label:'Alt', flex:1.25, mod:true},
    {id:' ', label:'Space', flex:6.25, isSpace:true},
    {id:'AltRight', label:'Alt', flex:1.25, mod:true},
    {id:'WinRight', label:'Win', flex:1.25, mod:true},
    {id:'Menu', label:'Menu', flex:1.25, mod:true},
    {id:'CtrlRight', label:'Ctrl', flex:1.25, mod:true}
  ]
];

const codeKeys = {Backquote:'`',Minus:'-',Equal:'=',BracketLeft:'[',BracketRight:']',Backslash:'\\',Semicolon:';',Quote:"'",Comma:',',Period:'.',Slash:'/',Space:' '};
function isShifted() { return stickyShift || physicalShift; }
function currentLayer() { return ROHINGYA.layers[isShifted() ? 'shift' : 'base']; }

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
  const keysContainer = document.getElementById('keys');
  keysContainer.replaceChildren();
  const shifted = isShifted();
  
  for (const row of fullLayoutRows) {
    const rowEl = document.createElement('div');
    rowEl.className = 'row';
    
    for (const keyDef of row) {
      const button = document.createElement('button');
      button.className = 'key' + (keyDef.mod ? ' key-mod' : '');
      button.style.flex = `${keyDef.flex} 1 0%`;
      
      if (keyDef.mod) {
        if (keyDef.action === 'shift' && shifted) button.classList.add('active');
        if (keyDef.action === 'caps' && capsLock) button.classList.add('active');
        const label = document.createElement('small');
        label.textContent = keyDef.label;
        button.append(label);
        
        button.addEventListener('mousedown', e => e.preventDefault());
        button.addEventListener('click', () => {
          if (keyDef.action === 'backspace') backspace();
          else if (keyDef.action === 'shift') { stickyShift = !stickyShift; render(); }
          else if (keyDef.action === 'caps') { capsLock = !capsLock; render(); }
          else if (keyDef.action === 'enter') insert('\n');
          else if (keyDef.action === 'tab') insert('\t');
          editor.focus();
        });
      } else if (keyDef.isSpace) {
        const val = currentLayer()[' '];
        const label = document.createElement('small');
        label.textContent = shifted ? '𐴢 (Sakin)' : 'Space';
        button.append(label);
        button.addEventListener('mousedown', e => e.preventDefault());
        button.addEventListener('click', () => insert(val || ' '));
      } else {
        const keyId = keyDef.id;
        const val = currentLayer()[keyId];
        const baseVal = ROHINGYA.layers['base'][keyId];
        const shiftVal = ROHINGYA.layers['shift'][keyId];
        
        const topRow = document.createElement('div');
        topRow.style.display = 'flex';
        topRow.style.justifyContent = 'space-between';
        topRow.style.width = '100%';
        
        const latinLabel = document.createElement('small');
        latinLabel.textContent = keyDef.label;
        topRow.append(latinLabel);
        
        if (keyDef.shift) {
          const shiftHint = document.createElement('small');
          shiftHint.style.color = '#8ca9a0';
          shiftHint.textContent = keyDef.shift;
          topRow.append(shiftHint);
        } else if (shiftVal && shiftVal !== baseVal) {
          const shiftHint = document.createElement('small');
          shiftHint.style.color = '#006852';
          shiftHint.style.fontWeight = 'bold';
          shiftHint.textContent = shiftVal;
          topRow.append(shiftHint);
        }
        
        const glyph = document.createElement('span');
        glyph.className = 'glyph';
        glyph.dir = 'rtl';
        glyph.textContent = val || '';
        
        button.title = val ? `${ROHINGYA.names[val] || ''} · U+${val.codePointAt(0).toString(16).toUpperCase()}` : 'Unmapped';
        button.disabled = !val;
        button.append(topRow, glyph);
        
        button.addEventListener('mousedown', e => e.preventDefault());
        button.addEventListener('click', () => { if (val) insert(val); });
      }
      rowEl.append(button);
    }
    keysContainer.append(rowEl);
  }
  
  const shiftBtn = document.getElementById('shift');
  if (shiftBtn) {
    shiftBtn.textContent = `Shift: ${shifted ? 'on' : 'off'}`;
    shiftBtn.setAttribute('aria-pressed', String(shifted));
    shiftBtn.classList.toggle('active', shifted);
  }
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
