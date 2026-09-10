import assert from 'node:assert/strict';
import test from 'node:test';
import { mkdtemp, mkdir, writeFile, readFile, stat, rm, utimes } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { syncModules } from '../src/sync-manager.js';

async function fixture() {
  const root = await mkdtemp(join(tmpdir(), 'lmu-'));
  const source = join(root, 'source');
  const target = join(root, 'target');

  await mkdir(join(source, 'templates'), { recursive: true });
  await mkdir(join(source, '.git'), { recursive: true });
  await mkdir(target, { recursive: true });
  await writeFile(join(source, 'templates', 'page.yaml'), 'title: page\n');
  await writeFile(join(source, 'templates', 'area.yaml'), 'title: area\n');
  await writeFile(join(source, '.git', 'HEAD'), 'ref: refs/heads/main\n');

  return { root, source, target };
}

async function mtimes(dir, files) {
  const entries = await Promise.all(files.map((f) => stat(join(dir, f))));
  return entries.map((e) => e.mtimeMs);
}

test('copies the tree and skips excluded directories', async (t) => {
  const { root, source, target } = await fixture();
  t.after(() => rm(root, { recursive: true, force: true }));

  await syncModules(source, target);

  assert.equal(await readFile(join(target, 'templates', 'page.yaml'), 'utf8'), 'title: page\n');
  await assert.rejects(() => stat(join(target, '.git', 'HEAD')));
});

test('writes nothing when the source content is unchanged', async (t) => {
  const { root, source, target } = await fixture();
  t.after(() => rm(root, { recursive: true, force: true }));

  const watched = ['templates/page.yaml', 'templates/area.yaml'];
  await syncModules(source, target);
  const before = await mtimes(target, watched);

  // A `git clone` from scratch gives every source file a fresh mtime while the
  // content stays identical — the sync must still not touch the target, or
  // Magnolia's watcher drowns in events and drops the real change.
  const future = new Date(Date.now() + 60_000);
  await Promise.all(watched.map((f) => utimes(join(source, f), future, future)));

  await new Promise((resolve) => setTimeout(resolve, 20));
  await syncModules(source, target);

  assert.deepEqual(await mtimes(target, watched), before);
});

test('copies only the file that actually changed', async (t) => {
  const { root, source, target } = await fixture();
  t.after(() => rm(root, { recursive: true, force: true }));

  await syncModules(source, target);
  const [, areaBefore] = await mtimes(target, ['templates/page.yaml', 'templates/area.yaml']);

  await new Promise((resolve) => setTimeout(resolve, 20));
  await writeFile(join(source, 'templates', 'page.yaml'), 'title: changed\n');
  await syncModules(source, target);

  const [pageAfter, areaAfter] = await mtimes(target, ['templates/page.yaml', 'templates/area.yaml']);
  assert.equal(await readFile(join(target, 'templates', 'page.yaml'), 'utf8'), 'title: changed\n');
  assert.equal(areaAfter, areaBefore);
  assert.ok(pageAfter > areaBefore);
});

test('removes files that disappeared from the source', async (t) => {
  const { root, source, target } = await fixture();
  t.after(() => rm(root, { recursive: true, force: true }));

  await syncModules(source, target);
  await rm(join(source, 'templates', 'area.yaml'));
  await syncModules(source, target);

  await assert.rejects(() => stat(join(target, 'templates', 'area.yaml')));
});
