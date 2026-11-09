import { lstat, mkdir, readdir, readlink, symlink } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, resolve, dirname } from 'node:path';

const vault = resolve(process.argv[2] ?? join(homedir(), 'Documents/Obsidian'));
const codex = resolve(process.argv[3] ?? process.env.CODEX_HOME ?? join(homedir(), '.codex'));
const source = join(vault, '30_Areas', 'agent-operations', 'skills');

async function stat(path: string) {
  try { return await lstat(path); }
  catch (error) { if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error; }
}

if (await stat(source)) {
  const entries = (await readdir(source, { withFileTypes: true })).filter(entry => entry.isDirectory());
  const links: { source: string; entry: string; exists: boolean }[] = [];
  for (const skill of entries) {
    const target = join(source, skill.name);
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(skill.name) || !(await stat(join(target, 'SKILL.md')))?.isFile()) continue;
    const entry = join(codex, 'skills', skill.name);
    const existing = await stat(entry);
    if (existing && (!existing.isSymbolicLink() || resolve(dirname(entry), await readlink(entry)) !== target)) {
      throw new Error(`Skill registration conflicts with an existing entry: ${entry}`);
    }
    links.push({ source: target, entry, exists: !!existing });
  }
  await mkdir(join(codex, 'skills'), { recursive: true });
  for (const link of links) {
    if (!link.exists) await symlink(link.source, link.entry);
    console.log(`Skill: ${link.entry} -> ${link.source}`);
  }
} else console.log(`No personal skill source yet: ${source}`);
