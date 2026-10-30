import { lstat, mkdir, readFile, readlink, rename, symlink, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';

const vault = resolve(process.argv[2] ?? join(homedir(), 'Documents/Obsidian'));
const codex = resolve(process.argv[3] ?? process.env.CODEX_HOME ?? join(homedir(), '.codex'));
const target = join(vault, 'AGENTS.md');
const entry = join(codex, 'AGENTS.md');
const rules = await readFile(target, 'utf8');

async function stat(path: string) {
  try { return await lstat(path); }
  catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error;
  }
}

if (await stat(join(codex, 'AGENTS.override.md'))) {
  throw new Error('AGENTS.override.md exists and takes precedence; review it before linking.');
}
await mkdir(codex, { recursive: true });
const existing = await stat(entry);
if (existing?.isSymbolicLink()) {
  if (resolve(codex, await readlink(entry)) !== target) {
    throw new Error(`Existing symlink points elsewhere: ${entry}`);
  }
} else {
  if (existing) {
    if (!existing.isFile()) throw new Error(`Not a regular file: ${entry}`);
    const previous = await readFile(entry, 'utf8');
    const backup = `${entry}.backup-${Date.now()}`;
    if (await stat(backup)) throw new Error(`Backup already exists: ${backup}`);
    if (previous.trim() && !rules.includes(previous.trim())) {
      const vaultBackup = `${target}.backup-${Date.now()}`;
      await writeFile(vaultBackup, rules, { flag: 'wx' });
      await writeFile(target, `${previous.trimEnd()}\n\n${rules}`);
      console.log(`Vault rules backup: ${vaultBackup}`);
    }
    await rename(entry, backup);
    console.log(`Previous Codex rules: ${backup}`);
  }
  await symlink(target, entry);
}
console.log(`Codex common instructions: ${entry} -> ${target}`);
