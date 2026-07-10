import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const json = read('apps/weread-move/lib/json_util.lua');
const runner = read('tests/run-all.mjs');

assert(json.includes('function Json.decode'), 'json util must expose decode');
assert(json.includes('decode_without_module'), 'json util must provide a native decode fallback');
assert(json.includes('parse_object'), 'native JSON fallback must parse objects');
assert(json.includes('parse_array'), 'native JSON fallback must parse arrays');
assert(json.includes('parse_string'), 'native JSON fallback must parse strings');
assert(json.includes('unicode escape'), 'native JSON fallback must document unicode escape behavior');
assert(runner.includes('validate-native-json-fallback.mjs'), 'run-all must include native JSON fallback validation');

console.log('native json fallback ok');
