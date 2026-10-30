import { constants } from 'node:fs';
import { copyFile, lstat, mkdir, readdir } from 'node:fs/promises';
import { homedir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const target = resolve(process.argv[2] ?? join(homedir(), 'Documents/Obsidian'));
const source = join(dirname(fileURLToPath(import.meta.url)), 'vault');

async function directory(path: string) {
  await mkdir(path, { recursive: true });
  if (!(await lstat(path)).isDirectory()) throw new Error(`Not a real directory: ${path}`);
}

async function seed(from: string, to: string) {
  await directory(to);
  for (const entry of await readdir(from, { withFileTypes: true })) {
    const destination = join(to, entry.name);
    if (entry.isDirectory()) await seed(join(from, entry.name), destination);
    else {
      try {
        await copyFile(join(from, entry.name), destination, constants.COPYFILE_EXCL);
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code !== 'EEXIST') throw error;
      }
    }
  }
}

await seed(source, target);
for (const folder of ['00_Inbox', '10_Daily', '20_Projects', '30_Areas', '40_Resources', '60_Archive', '80_Attachments']) {
  await directory(join(target, folder));
}
console.log(`Obsidian vault ready: ${target} (existing files preserved)`);
