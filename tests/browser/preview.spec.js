const {test, expect} = require('@playwright/test');
const {pathToFileURL} = require('node:url');
const path = require('node:path');
test.beforeEach(async ({page}) => {
  await page.goto(pathToFileURL(path.resolve('preview.html')).href);
});
test('offline fonts, typing, shifts, and Unicode backspace', async ({page}) => {
  const editor = page.locator('#editor');
  await editor.focus();
  await page.keyboard.press('a'); await page.keyboard.press('b'); await page.keyboard.press('v');
  await page.keyboard.press('Shift+h'); await page.keyboard.press('1');
  await expect(editor).toHaveValue('\u{10d00}\u{10d01}\u{10d1d}\u{10d24}\u{10d31}');
  await page.keyboard.press('Backspace');
  await expect(editor).toHaveValue('\u{10d00}\u{10d01}\u{10d1d}\u{10d24}');
  await page.keyboard.press('Shift+v');
  await expect(editor).toHaveValue('\u{10d00}\u{10d01}\u{10d1d}\u{10d24}');
  await page.evaluate(()=>document.fonts.ready);
  expect(await page.evaluate(()=>document.fonts.check('32px Rohingya'))).toBe(true);
  await expect(editor).toHaveAttribute('dir','rtl');
});
test('clickable keys replace selection and preserve supplementary characters', async ({page}) => {
  const editor = page.locator('#editor');
  await editor.fill('\u{10d00}\u{10d01}');
  await editor.evaluate(el=>{el.focus();el.setSelectionRange(0,2);});
  await page.getByRole('button',{name:'P: HANIFI ROHINGYA LETTER PA',exact:false}).click();
  await expect(editor).toHaveValue('\u{10d02}\u{10d01}');
  await page.locator('#shift').click();
  await expect(page.getByRole('button',{name:'V: Unmapped',exact:true})).toBeDisabled();
  await page.getByRole('button',{name:'H: HANIFI ROHINGYA SIGN HARBAHAY',exact:false}).click();
  await expect(editor).toHaveValue('\u{10d02}\u{10d24}\u{10d01}');
});
test('English mode, shortcuts, and UTF-8 download', async ({page}) => {
  await page.locator('#mode').click();
  await page.keyboard.type('hello');
  await expect(page.locator('#editor')).toHaveValue('hello');
  await page.locator('#mode').click();
  await page.keyboard.press('Control+a');
  // A modifier shortcut must not insert the Rohingya A character.
  expect(await page.locator('#editor').inputValue()).toBe('hello');
  await page.locator('#editor').fill('\u{10d00}\u{10d31}');
  const downloading = page.waitForEvent('download');
  await page.locator('#download').click();
  const download = await downloading;
  expect(download.suggestedFilename()).toBe('rohingya.txt');
  const stream = await download.createReadStream(); const chunks=[];
  for await (const chunk of stream) chunks.push(chunk);
  expect(Buffer.concat(chunks).toString('utf8')).toBe('\u{10d00}\u{10d31}');
});
