import { readdir, rm, utimes, cp, access } from 'node:fs/promises';
import { join, basename, relative } from 'node:path';
import { logger, bold } from './logger.js';

const EXCLUDE_DIRS = new Set(['.git', 'mtk']);

async function pathExists(path) {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
}

async function getAllFiles(dir, baseDir = dir) {
  const files = [];

  if (!(await pathExists(dir))) {
    return files;
  }

  const entries = await readdir(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    const relativePath = relative(baseDir, fullPath);

    if (entry.isDirectory()) {
      if (!EXCLUDE_DIRS.has(entry.name)) {
        const subFiles = await getAllFiles(fullPath, baseDir);
        files.push(...subFiles);
      }
    } else {
      files.push(relativePath);
    }
  }

  return files;
}

async function removeDeletedFiles(sourceDir, targetDir) {
  if (!(await pathExists(targetDir))) {
    return;
  }

  const sourceFiles = new Set(await getAllFiles(sourceDir));
  const targetFiles = await getAllFiles(targetDir);

  for (const file of targetFiles) {
    if (!sourceFiles.has(file)) {
      await rm(join(targetDir, file), { force: true });
    }
  }
}

async function touchYamlFiles(dir) {
  if (!(await pathExists(dir))) {
    return;
  }

  const entries = await readdir(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = join(dir, entry.name);

    if (entry.isDirectory()) {
      await touchYamlFiles(fullPath);
    } else if (entry.name.endsWith('.yaml') || entry.name.endsWith('.yml')) {
      const now = new Date();
      await utimes(fullPath, now, now);
    }
  }
}

export async function syncModules(sourceDir, targetDir) {
  logger.info(`Copying ${bold(sourceDir)} to ${bold(targetDir)}`);

  // Remove files that no longer exist in source
  await removeDeletedFiles(sourceDir, targetDir);

  // Copy all files from source to target, excluding .git and mtk
  await cp(sourceDir, targetDir, {
    recursive: true,
    force: true,
    filter: (src) => !EXCLUDE_DIRS.has(basename(src)),
  });

  // Touch all yaml files to trigger Magnolia reload
  await touchYamlFiles(targetDir);
}
