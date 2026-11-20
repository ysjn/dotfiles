import { lstat, mkdir, readdir, readlink, realpath, symlink } from 'node:fs/promises';
import { homedir } from 'node:os';
import { join, resolve, dirname } from 'node:path';

const vault = resolve(process.argv[2] ?? join(homedir(), 'Documents/Obsidian'));
const codex = resolve(process.argv[3] ?? process.env.CODEX_HOME ?? join(homedir(), '.codex'));
const base = join(vault, '30_Areas', 'ai');
const sources = [join(base, 'skills')];

async function stat(path: string) {
  try { return await lstat(path); }
  catch (error) { if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error; }
}

// A configured shared checkout must be available before any registration changes.
if (await stat(join(base, 'shared-skills'))) sources.push(await realpath(join(base, 'shared-skills', 'skills')));
const names = new Set<string>();
const links: { source: string; entry: string; exists: boolean }[] = [];
for (const source of sources) {
  if (!(await stat(source))) continue;
  const root = await realpath(source);
  const entries = (await readdir(root, { withFileTypes: true })).filter(entry => entry.isDirectory());
  for (const skill of entries) {
    const target = join(root, skill.name);
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(skill.name) || !(await stat(join(target, 'SKILL.md')))?.isFile()) continue;
    if (names.has(skill.name)) throw new Error(`Duplicate skill name: ${skill.name}`);
    names.add(skill.name);
    const entry = join(codex, 'skills', skill.name);
    links.push({ source: target, entry, exists: false });
  }
}
for (const link of links) {
  const existing = await stat(link.entry);
  if (existing && (!existing.isSymbolicLink() || resolve(dirname(link.entry), await readlink(link.entry)) !== link.source)) {
    throw new Error(`Skill registration conflicts with an existing entry: ${link.entry}`);
  }
  link.exists = !!existing;
}
if (links.length) {
  await mkdir(join(codex, 'skills'), { recursive: true });
  for (const link of links) {
    if (!link.exists) await symlink(link.source, link.entry);
    console.log(`Skill: ${link.entry} -> ${link.source}`);
  }
} else console.log(`No personal skill source yet: ${sources.join(', ')}`);
