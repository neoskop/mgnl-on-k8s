import { readdir, rm, mkdir, copyFile, stat, readFile, access } from 'node:fs/promises';
import { join, relative, dirname } from 'node:path';
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

async function removeDeletedFiles(sourceFiles, targetDir) {
  if (!(await pathExists(targetDir))) {
    return 0;
  }

  const targetFiles = await getAllFiles(targetDir);
  let removed = 0;

  for (const file of targetFiles) {
    if (!sourceFiles.has(file)) {
      await rm(join(targetDir, file), { force: true });
      removed++;
    }
  }

  return removed;
}

/**
 * Whether the target copy already has the exact content of the source file.
 *
 * Deliberately ignores mtime: a `git clone` from scratch produces a fresh
 * checkout with all-new mtimes, so an mtime comparison would report every
 * single file as changed. Size is the cheap pre-filter, content the verdict.
 *
 * Equal-sized files are read whole — bounded by the largest light module asset
 * (tens of MB), one pair at a time. Switch to streamed chunk comparison if
 * light modules ever carry files that do not fit the container's memory limit.
 */
async function isUpToDate(sourcePath, targetPath) {
  let sourceStat;
  let targetStat;

  try {
    [sourceStat, targetStat] = await Promise.all([stat(sourcePath), stat(targetPath)]);
  } catch {
    return false;
  }

  if (sourceStat.size !== targetStat.size) {
    return false;
  }

  const [sourceContent, targetContent] = await Promise.all([
    readFile(sourcePath),
    readFile(targetPath),
  ]);

  return sourceContent.equals(targetContent);
}

async function copyChangedFiles(sourceDir, targetDir, sourceFiles) {
  let copied = 0;

  for (const file of sourceFiles) {
    const sourcePath = join(sourceDir, file);
    const targetPath = join(targetDir, file);

    if (await isUpToDate(sourcePath, targetPath)) {
      continue;
    }

    await mkdir(dirname(targetPath), { recursive: true });
    await copyFile(sourcePath, targetPath);
    copied++;
  }

  return copied;
}

/**
 * Mirror the light modules from the checkout into the directory Magnolia watches.
 *
 * Only files whose content actually differs are written. Magnolia watches the
 * target through inotify and Java caps a WatchKey at 512 pending events per
 * directory (`jdk.nio.file.WatchService.maxEventsPerPoll`); past that the JVM
 * replaces the events with a single OVERFLOW, which Magnolia logs but does not
 * act on, so the changed definition is silently never reloaded. Rewriting the
 * whole tree on every sync blew through that cap and lost the one change that
 * mattered.
 */
export async function syncModules(sourceDir, targetDir) {
  logger.info(`Syncing ${bold(sourceDir)} to ${bold(targetDir)}`);

  const sourceFiles = await getAllFiles(sourceDir);
  const removed = await removeDeletedFiles(new Set(sourceFiles), targetDir);
  const copied = await copyChangedFiles(sourceDir, targetDir, sourceFiles);

  logger.info(
    `Synced ${bold(`${copied} changed`)} and ${bold(`${removed} deleted`)} of ${bold(sourceFiles.length)} files`
  );
}
