import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync, spawnSync } from 'node:child_process';
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
const changed = require('node:fs').existsSync(process.env.TEST_STATE_FILE);
if (process.env.TEST_GIT_FAILURE) { console.error('git diff failed'); process.exit(1); }
if (args[0] === 'diff') {
  assert.deepEqual(args, ['diff', '--cached', '--no-ext-diff', '--no-textconv', '--no-color']);
  process.stdout.write(process.env.TEST_DIFF + (changed && process.env.TEST_CHANGE_DIFF ? '+changed\\n' : ''));
} else if (args[0] === 'rev-parse' && args[1] === '--absolute-git-dir') {
  assert.deepEqual(args, ['rev-parse', '--absolute-git-dir']);
  process.stdout.write(require('node:path').dirname(process.env.TEST_DRAFT));
} else if (args[0] === 'symbolic-ref') {
  assert.deepEqual(args, ['symbolic-ref', '--quiet', '--short', 'HEAD']);
  process.stdout.write(changed && process.env.TEST_CHANGE_BRANCH ? 'feature/other' : 'feature/example');
} else if (args[0] === 'rev-parse') {
  assert.deepEqual(args, ['rev-parse', '--verify', '--quiet', 'HEAD']);
  process.stdout.write('abc123');
} else if (args[0] === 'for-each-ref') {
  assert.deepEqual(args, ['for-each-ref', '--format=%(refname)%00%(symref)', 'refs/heads', 'refs/remotes']);
  process.stdout.write('refs/heads/main\\0\\nrefs/heads/feature/example\\0\\n');
} else if (args[0] === 'reflog') {
  assert.deepEqual(args, ['reflog', 'show', '--format=%H%x00%gs', 'refs/heads/feature/example']);
} else if (args[0] === 'log') {
  assert.deepEqual(args, ['log', '--format=%s', '--no-merges', 'HEAD', '--not', 'refs/heads/main', '--']);
  if (process.env.TEST_HISTORY_FAILURE) { console.error('history failed'); process.exit(1); }
  process.stdout.write(process.env.TEST_HISTORY || 'fix: 日本語の履歴\\n');
} else {
  throw new Error('Unexpected Git arguments: ' + JSON.stringify(args));
}
`, { mode: 0o755 });
    writeFileSync(join(bin, 'codex'), `#!${process.execPath}
const assert = require('node:assert/strict');
const fs = require('node:fs');
const args = process.argv.slice(2);
assert.deepEqual(args.slice(0, 11), ['exec', '--model', 'gpt-6-luna', '--config', 'model_reasoning_effort="low"', '--sandbox', 'read-only', '--ephemeral', '--color', 'never', '--output-last-message']);
assert.equal(fs.readFileSync(0, 'utf8'), process.env.TEST_DIFF);
assert.ok(args.at(-1).includes('コミット件名を' + (process.env.TEST_LANGUAGE || '日本語') + 'で1行だけ'));
if (process.env.TEST_CODEX_FAILURE) { console.error('generation failed'); process.exit(1); }
if (!process.env.TEST_MISSING_OUTPUT) fs.writeFileSync(args[args.indexOf('--output-last-message') + 1], process.env.TEST_MESSAGE);
if (process.env.TEST_RACE_DRAFT) fs.writeFileSync(process.env.TEST_DRAFT, 'preserve concurrent draft');
if (process.env.TEST_CHANGE_BRANCH || process.env.TEST_CHANGE_DIFF) fs.writeFileSync(process.env.TEST_STATE_FILE, 'changed');
console.log('unrelated stdout');
console.error('progress log');
`, { mode: 0o755 });
    const run = (overrides: NodeJS.ProcessEnv = {}) => {
      const draftPath = overrides.TEST_DRAFT ?? join(mkdtempSync(join(root, 'case with spaces-')), 'LAZYGIT_PENDING_COMMIT');
      const result = spawnSync(process.execPath, [script], {
        env: { ...process.env, PATH: bin, TEST_DIFF: patch, TEST_MESSAGE: `${message}\n`, TEST_DRAFT: draftPath, TEST_STATE_FILE: join(draftPath, '..', 'state'), ...overrides },
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
      { TEST_HISTORY_FAILURE: '1' },
      { TEST_CHANGE_BRANCH: '1' },
      { TEST_CHANGE_DIFF: '1' },
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

    rmSync(valid.draftPath);
    const repeated = run({ TEST_DRAFT: valid.draftPath, TEST_HISTORY: 'fix: English one\nfix: English two\nfix: 日本語\n', TEST_LANGUAGE: '英語' });
    assert.equal(repeated.status, 0, repeated.stderr);
    assert.match(repeated.stdout, /言語: 英語/u);
    assert.deepEqual(readdirSync(join(valid.draftPath, '..')), ['LAZYGIT_PENDING_COMMIT']);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test('select the majority language from real branch or repository history', async t => {
  const root = mkdtempSync(join(tmpdir(), 'lazygit-language-test-'));
  const bin = join(root, 'bin');
  mkdirSync(bin);
  const script = fileURLToPath(new URL('./generate-commit-message.ts', import.meta.url));
  const env = {
    ...process.env,
    PATH: `${bin}:${process.env.PATH}`,
    GIT_CONFIG_GLOBAL: '/dev/null', GIT_CONFIG_NOSYSTEM: '1', GIT_OPTIONAL_LOCKS: '0',
    GIT_AUTHOR_NAME: 'Test', GIT_AUTHOR_EMAIL: 'test@example.invalid',
    GIT_COMMITTER_NAME: 'Test', GIT_COMMITTER_EMAIL: 'test@example.invalid',
  };
  const git = (cwd: string, ...args: string[]) => execFileSync('git', [
    '-c', 'core.hooksPath=/dev/null', '-c', 'commit.gpgSign=false', ...args,
  ], { cwd, env, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
  let sequence = 0;
  const repo = (...subjects: string[]) => {
    const path = join(root, `repo ${++sequence}`);
    mkdirSync(path);
    git(path, 'init', '--initial-branch=main');
    for (const subject of subjects) git(path, 'commit', '--allow-empty', '-m', subject);
    return path;
  };
  const commit = (path: string, ...subjects: string[]) => {
    for (const subject of subjects) git(path, 'commit', '--allow-empty', '-m', subject);
  };
  const generate = (cwd: string, language: string) => {
    writeFileSync(join(cwd, 'example.txt'), `example ${++sequence}\n`);
    git(cwd, 'add', '--', 'example.txt');
    const draft = join(git(cwd, 'rev-parse', '--absolute-git-dir'), 'LAZYGIT_PENDING_COMMIT');
    const result = spawnSync(process.execPath, [script], {
      cwd, env: { ...env, TEST_LANGUAGE: language }, encoding: 'utf8',
    });
    assert.equal(result.status, 0, result.stderr);
    assert.ok(result.stdout.includes(`言語: ${language}`), result.stdout);
    assert.equal(readFileSync(draft, 'utf8'), 'chore: example');
    const commonDir = git(cwd, 'rev-parse', '--path-format=absolute', '--git-common-dir');
    assert.ok(!existsSync(join(commonDir, 'lazygit-ai-languages')));
    rmSync(draft);
  };
  try {
    writeFileSync(join(bin, 'codex'), `#!${process.execPath}
const assert = require('node:assert/strict');
const fs = require('node:fs');
const args = process.argv.slice(2);
assert.ok(args.at(-1).includes('コミット件名を' + process.env.TEST_LANGUAGE + 'で1行だけ'));
assert.ok(fs.readFileSync(0, 'utf8').startsWith('diff --git '));
fs.writeFileSync(args[args.indexOf('--output-last-message') + 1], 'chore: example');
`, { mode: 0o755 });

    await t.test('Japanese branch majority overrides English repository history', () => {
      const path = repo('chore: one', 'chore: two', 'chore: three');
      git(path, 'switch', '-c', 'feature/example');
      commit(path, 'fix: 日本語一', 'fix: 日本語二', 'fix: English');
      generate(path, '日本語');
    });
    await t.test('English branch majority overrides Japanese repository history', () => {
      const path = repo('chore: 初期設定', 'chore: 設定追加', 'chore: 整理');
      git(path, 'switch', '-c', 'feature/example');
      commit(path, 'fix: English one', 'fix: English two', 'fix: 日本語');
      generate(path, '英語');
    });
    await t.test('a new branch falls back to repository majority', () => {
      const path = repo('chore: English one', 'chore: English two', 'fix: 日本語');
      git(path, 'switch', '-c', 'new/branch');
      generate(path, '英語');
    });
    await t.test('the default branch uses repository history', () => {
      generate(repo('chore: 初期設定', 'fix: 日本語', 'fix: English'), '日本語');
    });
    await t.test('ties use the most recent subject and are recalculated', () => {
      const path = repo('chore: initial');
      git(path, 'switch', '-c', 'feature/example');
      commit(path, 'fix: 日本語', 'fix: English');
      generate(path, '英語');
      commit(path, 'fix: English two', 'fix: 日本語二', 'fix: 日本語三');
      generate(path, '日本語');
      commit(path, 'fix: English three');
      generate(path, '英語');
    });
    await t.test('an initial commit with no history uses Japanese', () => generate(repo(), '日本語'));
    await t.test('detached HEAD uses repository history', () => {
      const path = repo('chore: English one', 'chore: English two', 'fix: 日本語');
      git(path, 'switch', '--detach');
      generate(path, '英語');
    });
    await t.test('the remote default branch can have a custom name', () => {
      const path = repo('chore: initial');
      git(path, 'branch', '-m', 'develop');
      git(path, 'update-ref', 'refs/remotes/origin/develop', 'HEAD');
      git(path, 'symbolic-ref', 'refs/remotes/origin/HEAD', 'refs/remotes/origin/develop');
      git(path, 'switch', '-c', 'feature/example');
      commit(path, 'fix: 日本語');
      git(path, 'reflog', 'expire', '--expire=all', '--all');
      generate(path, '日本語');
    });
    await t.test('nested branches exclude inherited parent commits', () => {
      const path = repo('chore: initial');
      git(path, 'switch', '-c', 'parent/child');
      commit(path, 'fix: 日本語一', 'fix: 日本語二', 'fix: 日本語三');
      git(path, 'switch', '-c', 'child');
      commit(path, 'fix: English');
      generate(path, '英語');
    });
    await t.test('a checkout of an existing remote branch keeps its earlier branch commits', () => {
      const path = repo('chore: initial one', 'chore: initial two', 'chore: initial three');
      git(path, 'remote', 'add', 'origin', path);
      git(path, 'update-ref', 'refs/remotes/origin/main', 'HEAD');
      git(path, 'switch', '-c', 'temporary');
      commit(path, 'fix: 日本語');
      git(path, 'update-ref', 'refs/remotes/origin/feature/example', 'HEAD');
      git(path, 'switch', '-c', 'feature/example', 'origin/feature/example');
      generate(path, '日本語');
    });
    await t.test('merged default-branch changes and merge subjects do not affect branch majority', () => {
      const path = repo('chore: initial');
      git(path, 'switch', '-c', 'feature/example');
      commit(path, 'fix: 日本語');
      git(path, 'switch', 'main');
      commit(path, 'fix: English one', 'fix: English two');
      git(path, 'switch', 'feature/example');
      git(path, 'merge', '--no-ff', 'main', '-m', 'Merge main');
      generate(path, '日本語');
    });
    await t.test('a linked worktree keeps its draft isolated and creates no language cache', () => {
      const path = repo('chore: initial');
      const worktree = join(root, 'linked worktree');
      git(path, 'worktree', 'add', '-b', 'feature/worktree', worktree);
      commit(worktree, 'fix: 日本語');
      generate(worktree, '日本語');
      assert.ok(!existsSync(join(path, '.git', 'LAZYGIT_PENDING_COMMIT')));
    });
    await t.test('an expired fork reflog still uses the default branch as a base', () => {
      const path = repo('chore: initial one', 'chore: initial two');
      git(path, 'switch', '-c', 'feature/example');
      commit(path, 'fix: 日本語');
      git(path, 'reflog', 'expire', '--expire=all', '--all');
      generate(path, '日本語');
    });
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
