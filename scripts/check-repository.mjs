#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const root = path.resolve(import.meta.dirname, '..');
const output = execFileSync(
  'git',
  ['ls-files', '--cached', '--others', '--exclude-standard', '-z'],
  { cwd: root },
).toString('utf8');

const files = output.split('\0').filter(Boolean);
const failures = [];

const forbiddenPrefixes = [
  '.superpowers/',
  'apps/weread-qt/build/',
  'build/',
  'downloads/',
  'packages/',
  'third_party/',
  'tmp/',
];

const forbiddenNames = new Set([
  '.env',
  'config.lua',
  'session.json',
  'credentials.json',
  'cookies.json',
  'shelf.json',
  'book-status.json',
  'downloads.json',
  'reader-progress.json',
  'reader-bookmarks.json',
  'reader-highlights.json',
  'reader-strokes.json',
  'social-comments-cache.json',
  'reviews.json',
]);

const forbiddenExtensions = new Set([
  '.epub', '.mobi', '.azw', '.azw3', '.pdf', '.cbz', '.cbr',
  '.ttf', '.ttc', '.otf', '.pem', '.p12', '.pfx', '.key',
  '.tar', '.tgz', '.zip',
]);

const secretPatterns = [
  ['private key', /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/],
  ['WeRead API key', /\bwrk-[A-Za-z0-9_-]{16,}\b/],
  ['WeRead Cookie header', /\bCookie\s*:[^\n]*\b(?:wr_skey|wr_vid|wr_rt)=/i],
  ['WeRead cookie value', /\b(?:wr_skey|wr_rt|wr_vid)\s*[=:]\s*["']?[A-Za-z0-9_%-]{12,}/i],
  ['access token value', /["']accessToken["']\s*[:=]\s*["'][^"'<>]{12,}["']/i],
  ['API key assignment', /\bapi[_-]?key\s*[:=]\s*["'][A-Za-z0-9_-]{16,}["']/i],
  ['embedded SSH password', /\bsshpass\s+(?:-[^\s]+\s+)*-p\b/i],
  ['live WeRead QR uid', /weread\.qq\.com\/web\/confirm\?uid=[A-Za-z0-9_-]{12,}/i],
  ['hard-coded real book self-test', /enterReaderForBook\(\s*["'][0-9]{6,}["']/],
];

for (const relative of files) {
  const normalized = relative.replaceAll('\\', '/');
  const base = path.basename(normalized);
  const extension = path.extname(base).toLowerCase();

  if (forbiddenPrefixes.some((prefix) => normalized.startsWith(prefix))) {
    failures.push(`${relative}: dependency, build, cache or local workspace path`);
    continue;
  }
  if (forbiddenNames.has(base) || base.startsWith('.env.')) {
    failures.push(`${relative}: credential or user-state filename`);
    continue;
  }
  if (forbiddenExtensions.has(extension) || normalized.endsWith('.tar.gz')) {
    failures.push(`${relative}: dependency, credential or book binary`);
    continue;
  }

  const absolute = path.join(root, relative);
  if (!fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) {
    continue;
  }
  const size = fs.statSync(absolute).size;
  if (size > 5 * 1024 * 1024) {
    failures.push(`${relative}: source file is unexpectedly larger than 5 MiB`);
    continue;
  }

  const buffer = fs.readFileSync(absolute);
  if (buffer.includes(0)) {
    continue;
  }
  const text = buffer.toString('utf8');
  for (const [label, pattern] of secretPatterns) {
    if (pattern.test(text)) {
      failures.push(`${relative}: possible ${label}`);
    }
  }
}

if (failures.length > 0) {
  console.error('Repository safety check failed:');
  for (const failure of [...new Set(failures)].sort()) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log(`repository safety ok (${files.length} candidate files checked)`);
