import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, readlink, rm, symlink, lstat, realpath } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

test('register skills once; preserve existing directories and foreign links', async () => {
  const root = await realpath(await mkdtemp(join(tmpdir(), 'link-skills-')));
  const vault = join(root, 'Vault with spaces'); const codex = join(root, 'codex');
  const source = join(vault, '30_Areas/ai/skills');
  const run = () => spawnSync(process.execPath, [fileURLToPath(new URL('./link-skills.ts', import.meta.url)), vault, codex], { encoding: 'utf8' });
  try {
    assert.equal(run().status, 0);
    await mkdir(join(source, 'sample'), { recursive: true });
    await writeFile(join(source, 'sample/SKILL.md'), '---\nname: sample\ndescription: example\n---\n');
    assert.equal(run().status, 0);
    assert.equal(await readlink(join(codex, 'skills/sample')), join(source, 'sample'));
    assert.equal(run().status, 0);
    await rm(join(codex, 'skills/sample'));
    await mkdir(join(codex, 'skills/sample'));
    assert.notEqual(run().status, 0);
    await rm(join(codex, 'skills/sample'), { recursive: true });
    await symlink(root, join(codex, 'skills/sample'));
    assert.notEqual(run().status, 0);
    assert.equal(await readlink(join(codex, 'skills/sample')), root);
  } finally { await rm(root, { recursive: true }); }
});


test('register private and shared skills through one parent link; reject duplicates before writing', async () => {
  const root = await realpath(await mkdtemp(join(tmpdir(), 'link-shared-skills-')));
  const vault = join(root, 'Vault with spaces'); const codex = join(root, 'codex');
  const base = join(vault, '30_Areas/ai');
  const shared = join(root, 'shared checkout');
  const run = () => spawnSync(process.execPath, [fileURLToPath(new URL('./link-skills.ts', import.meta.url)), vault, codex], { encoding: 'utf8' });
  const skill = async (parent: string, name: string) => {
    await mkdir(join(parent, name), { recursive: true });
    await writeFile(join(parent, name, 'SKILL.md'), `---\nname: ${name}\ndescription: example\n---\n`);
  };
  try {
    await skill(join(base, 'skills'), 'private-sample');
    await skill(join(shared, 'skills'), 'shared-sample');
    await symlink(shared, join(base, 'shared-skills'));
    assert.equal(run().status, 0);
    assert.equal(await readlink(join(codex, 'skills/private-sample')), join(base, 'skills/private-sample'));
    assert.equal(await readlink(join(codex, 'skills/shared-sample')), join(shared, 'skills/shared-sample'));
    assert.equal(run().status, 0);
    await skill(join(base, 'skills'), 'another-sample');
    await skill(join(base, 'skills'), 'shared-sample');
    const duplicate = run();
    assert.notEqual(duplicate.status, 0);
    assert.match(duplicate.stderr, /Duplicate skill name/);
    await assert.rejects(lstat(join(codex, 'skills/another-sample')), { code: 'ENOENT' });
    assert.equal(await readlink(join(codex, 'skills/shared-sample')), join(shared, 'skills/shared-sample'));
  } finally { await rm(root, { recursive: true }); }
});

test('a broken shared parent link stops before registering private skills', async () => {
  const root = await realpath(await mkdtemp(join(tmpdir(), 'link-broken-shared-')));
  const vault = join(root, 'vault'); const codex = join(root, 'codex');
  const base = join(vault, '30_Areas/ai');
  try {
    await mkdir(join(base, 'skills/private-sample'), { recursive: true });
    await writeFile(join(base, 'skills/private-sample/SKILL.md'), '---\nname: private-sample\ndescription: example\n---\n');
    await symlink(join(root, 'missing-checkout'), join(base, 'shared-skills'));
    const result = spawnSync(process.execPath, [fileURLToPath(new URL('./link-skills.ts', import.meta.url)), vault, codex], { encoding: 'utf8' });
    assert.notEqual(result.status, 0);
    await assert.rejects(lstat(join(codex, 'skills')), { code: 'ENOENT' });
  } finally { await rm(root, { recursive: true }); }
});
