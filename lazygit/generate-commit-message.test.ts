import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

test('show progress, save a valid draft and preserve drafts on failure or concurrent writes', () => {
  const root = mkdtempSync(join(tmpdir(), 'lazygit-ai-test-'));
  const bin = join(root, 'bin');
  mkdirSync(bin);
  const script = fileURLToPath(new URL('./generate-commit-message.ts', import.meta.url));
  const patch = 'diff --git a/example.txt b/example.txt\n+example\n';
  const message = 'fix: 引用符 " と $() と ` を保持';
  try {
    writeFileSync(join(bin, 'git'), `#!${process.execPath}
const assert = require('node:assert/strict');
const args = process.argv.slice(2);
if (process.env.TEST_GIT_FAILURE) { console.error('git diff failed'); process.exit(1); }
if (args[0] === 'diff') {
  assert.deepEqual(args, ['diff', '--cached', '--no-ext-diff', '--no-textconv', '--no-color']);
  process.stdout.write(process.env.TEST_DIFF);
} else {
  assert.deepEqual(args, ['rev-parse', '--absolute-git-dir']);
  process.stdout.write(require('node:path').dirname(process.env.TEST_DRAFT));
}
`, { mode: 0o755 });
    writeFileSync(join(bin, 'codex'), `#!${process.execPath}
const assert = require('node:assert/strict');
const fs = require('node:fs');
const args = process.argv.slice(2);
assert.deepEqual(args.slice(0, 11), ['exec', '--model', 'gpt-6-luna', '--config', 'model_reasoning_effort="low"', '--sandbox', 'read-only', '--ephemeral', '--color', 'never', '--output-last-message']);
assert.equal(fs.readFileSync(0, 'utf8'), process.env.TEST_DIFF);
if (process.env.TEST_CODEX_FAILURE) { console.error('generation failed'); process.exit(1); }
if (!process.env.TEST_MISSING_OUTPUT) fs.writeFileSync(args[args.indexOf('--output-last-message') + 1], process.env.TEST_MESSAGE);
if (process.env.TEST_RACE_DRAFT) fs.writeFileSync(process.env.TEST_DRAFT, 'preserve concurrent draft');
console.log('unrelated stdout');
console.error('progress log');
`, { mode: 0o755 });
    const run = (overrides: NodeJS.ProcessEnv = {}) => {
      const draftPath = overrides.TEST_DRAFT ?? join(mkdtempSync(join(root, 'case with spaces-')), 'LAZYGIT_PENDING_COMMIT');
      const result = spawnSync(process.execPath, [script], {
        env: { ...process.env, PATH: bin, TEST_DIFF: patch, TEST_MESSAGE: `${message}\n`, TEST_DRAFT: draftPath, ...overrides },
        encoding: 'utf8',
      });
      return { ...result, draftPath };
    };
    const valid = run();
    assert.equal(valid.status, 0, valid.stderr);
    assert.match(valid.stdout, /^Working:/u);
    assert.ok(valid.stdout.includes(message));
    assert.match(valid.stdout, /c で下書きを開き/u);
    assert.ok(!valid.stdout.includes('unrelated stdout'));
    assert.equal(valid.stderr, '');
    assert.equal(readFileSync(valid.draftPath, 'utf8'), message);

    const existing = run({ TEST_DRAFT: valid.draftPath });
    assert.notEqual(existing.status, 0);
    assert.equal(existing.stdout, '');
    assert.match(existing.stderr, /draft already exists/u);
    assert.equal(readFileSync(valid.draftPath, 'utf8'), message);

    const concurrent = run({ TEST_RACE_DRAFT: '1' });
    assert.notEqual(concurrent.status, 0);
    assert.equal(readFileSync(concurrent.draftPath, 'utf8'), 'preserve concurrent draft');

    for (const overrides of [
      { TEST_DIFF: '' },
      { TEST_GIT_FAILURE: '1' },
      { TEST_CODEX_FAILURE: '1' },
      { TEST_MISSING_OUTPUT: '1' },
      { TEST_MESSAGE: '' },
      { TEST_MESSAGE: '  \n' },
      { TEST_MESSAGE: 'fix: first\nsecond\n' },
      { TEST_MESSAGE: 'fix: escape\u001b[31m' },
    ]) {
      const invalid = run(overrides);
      assert.notEqual(invalid.status, 0, JSON.stringify(overrides));
      assert.ok(!invalid.stdout.includes('生成完了'));
      assert.notEqual(invalid.stderr, '');
      assert.ok(!existsSync(invalid.draftPath));
    }
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
