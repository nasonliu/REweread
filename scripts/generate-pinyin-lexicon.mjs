import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const sourcePath = process.argv[2];
if (!sourcePath) {
  throw new Error('usage: node scripts/generate-pinyin-lexicon.mjs /path/to/pinyin_simp.dict.yaml');
}

const expectedSha256 = 'e341598343a0f0f2035bb1aafc34a7f3bb7887deeecb3f60796262aaa2983e6b';
const source = fs.readFileSync(sourcePath, 'utf8');
const actualSha256 = crypto.createHash('sha256').update(source).digest('hex');
if (actualSha256 !== expectedSha256) {
  throw new Error(`unexpected Rime dictionary SHA-256: ${actualSha256}`);
}

const groups = new Map();
for (const line of source.split(/\r?\n/)) {
  if (!line || line.startsWith('#') || line === '---' || line === '...') continue;
  const [word, reading, rawWeight] = line.split('\t');
  if (!word || !reading || !/^[\u3400-\u9fff]+$/.test(word)) continue;
  const key = reading.toLowerCase().replace(/[\s']/g, '').replace(/ü/g, 'v');
  if (!groups.has(key)) groups.set(key, []);
  groups.get(key).push({ word, weight: Number(rawWeight) || 0 });
}

const lexicon = {};
for (const [key, entries] of groups) {
  entries.sort((left, right) => right.weight - left.weight || left.word.localeCompare(right.word, 'zh-Hans-CN'));
  const seen = new Set();
  lexicon[key] = entries.filter(({ word }) => !seen.has(word) && seen.add(word)).slice(0, 16).map(({ word }) => word);
}

const output = `// SPDX-License-Identifier: Apache-2.0\n// Generated from rime/rime-pinyin-simp commit 0c6861ef7420ee780270ca6d993d18d4101049d0.\n// Source: https://github.com/rime/rime-pinyin-simp (pinyin_simp.dict.yaml)\n// Source SHA-256: ${expectedSha256}\n// See docs/third-party-notices.md before redistributing this file.\n.pragma library\nvar LEXICON = ${JSON.stringify(lexicon)}\nfunction candidates(key, limit) {\n    var values = LEXICON[String(key || \"\")] || []\n    return values.slice(0, Math.max(1, Number(limit) || 8))\n}\n`;
const destination = path.resolve('apps/weread-qt/PinyinLexicon.js');
const qmlOutput = ".pragma library\n" + output.replace("\n.pragma library\n", "\n");
fs.writeFileSync(destination, qmlOutput);
console.log(`generated ${destination} (${Object.keys(lexicon).length} keys)`);
