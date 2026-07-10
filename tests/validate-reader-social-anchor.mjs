import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const root = process.cwd();
const sourcePath = path.join(root, 'apps/weread-qt/SocialAnchor.js');
const source = fs.readFileSync(sourcePath, 'utf8').replace(/^\.pragma library\s*$/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(source, context, { filename: sourcePath });

assert.equal(typeof context.resolve, 'function', 'SocialAnchor must export a pure resolve function');

const title = '第一部分 什叶派帝国';
const titleBody = `${title}\n\n萨法维王朝建立后，伊朗历史进入新的阶段。`;
const titleMatch = context.resolve(titleBody, {
  text: '',
  chapter: title,
  rangeOnly: true,
  plainStart: 17,
  plainEnd: 27,
  pageStart: 0,
  pageEnd: 120,
}, {
  currentStart: 0,
  currentEnd: titleBody.length,
  chapterStart: 0,
  chapterEnd: titleBody.length,
  chapterTitle: title,
});

assert.equal(titleMatch.start, 0, 'range-only title comments must anchor to the local chapter title, not raw plainStart');
assert.equal(titleMatch.end, title.length, 'title underline must cover the rendered title exactly');
assert.equal(titleMatch.source, 'chapter-title', 'title fallback must be observable for diagnostics');

const whitespaceBody = '引言\n\n伊朗的历史，在不同时代\n呈现出复杂面貌。\n\n下一段';
const whitespaceStart = whitespaceBody.indexOf('伊朗');
const whitespaceEnd = whitespaceBody.indexOf('。', whitespaceStart) + 1;
const whitespaceMatch = context.resolve(whitespaceBody, {
  text: '伊朗的历史，在不同时代 呈现出复杂面貌。',
  plainStart: whitespaceStart + 5,
  plainEnd: whitespaceEnd + 5,
  pageStart: 0,
  pageEnd: whitespaceBody.length,
}, {
  currentStart: 0,
  currentEnd: whitespaceBody.length,
  chapterStart: 0,
  chapterEnd: whitespaceBody.length,
  chapterTitle: '第一章',
});

assert.equal(whitespaceMatch.start, whitespaceStart, 'normalized matching must correct drift caused by line breaks');
assert.equal(whitespaceMatch.end, whitespaceEnd, 'normalized matching must map the local end position too');
assert.equal(whitespaceMatch.source, 'text', 'API text must be the preferred anchor');

const repeatedBody = '共同的记忆留在开头。中间有很长的一段说明。共同的记忆出现在本页末尾。';
const repeatedStart = repeatedBody.lastIndexOf('共同的记忆');
const repeatedMatch = context.resolve(repeatedBody, {
  text: '共同的记忆',
  plainStart: repeatedStart + 2,
  plainEnd: repeatedStart + 8,
  pageStart: 0,
  pageEnd: repeatedBody.length,
}, {
  currentStart: 0,
  currentEnd: repeatedBody.length,
  chapterStart: 0,
  chapterEnd: repeatedBody.length,
  chapterTitle: '第一章',
});

assert.equal(repeatedMatch.start, repeatedStart, 'duplicate text must resolve to the occurrence nearest the approximate range');

const unsafeMatch = context.resolve(titleBody, {
  text: '�继�',
  chapter: title,
  rangeOnly: true,
  plainStart: 90,
  plainEnd: 94,
  pageStart: 0,
  pageEnd: 120,
}, {
  currentStart: 0,
  currentEnd: titleBody.length,
  chapterStart: 0,
  chapterEnd: titleBody.length,
  chapterTitle: title,
});

assert.equal(unsafeMatch.start, -1, 'broken or anchorless ranges must be suppressed instead of drawing a shifted underline');
assert.equal(unsafeMatch.end, -1, 'suppressed ranges must not expose a synthetic end offset');

console.log('reader social anchor validation ok');
