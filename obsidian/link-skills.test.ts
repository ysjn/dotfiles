import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, writeFile, readlink, rm, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

test('register skills once; preserve existing directories and foreign links', async () => {
  const root = await mkdtemp(join(tmpdir(), 'link-skills-'));
  const vault = join(root, 'Vault with spaces'); const codex = join(root, 'codex');
  const source = join(vault, '30_Areas/agent-operations/skills');
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
