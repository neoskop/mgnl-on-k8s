import simpleGit from 'simple-git';
import { existsSync } from 'node:fs';
import { rm, mkdir, readdir } from 'node:fs/promises';
import { join } from 'node:path';
import { logger, bold } from './logger.js';

export class GitManager {
  constructor(config) {
    this.config = config;
    this.git = null;
  }

  async initialize() {
    await this.configureGitMemory();

    this.git = simpleGit({
      baseDir: this.config.repoDir,
      binary: 'git',
      maxConcurrentProcesses: 1,
    });

    // Configure git settings
    await this.git.addConfig('pull.ff', 'only', false, 'global');
    await this.git.addConfig('advice.detachedHead', 'false', false, 'global');
  }

  async configureGitMemory() {
    let memoryLimitMb = 250; // Default fallback

    try {
      const { readFile } = await import('node:fs/promises');

      // Try cgroup v2 first, then v1
      const memFiles = ['/sys/fs/cgroup/memory.max', '/sys/fs/cgroup/memory/memory.limit_in_bytes'];

      for (const memFile of memFiles) {
        try {
          const content = await readFile(memFile, 'utf8');
          const bytes = parseInt(content.trim(), 10);
          if (!isNaN(bytes) && bytes > 0 && bytes < Number.MAX_SAFE_INTEGER) {
            memoryLimitMb = Math.floor(bytes / 1024 / 1024);
            break;
          }
        } catch {
          // Try next file
        }
      }
    } catch {
      // Use default
    }

    logger.info(`Configuring Git for memory limit of ${bold(`${memoryLimitMb} MiB`)}`);

    const git = simpleGit();
    await git.addConfig('core.packedGitWindowSize', `${Math.floor(memoryLimitMb / 10)}m`, false, 'global');
    await git.addConfig('core.packedGitLimit', `${Math.floor(memoryLimitMb / 2)}m`, false, 'global');
    await git.addConfig('pack.deltaCacheSize', `${Math.floor(memoryLimitMb / 4)}m`, false, 'global');
    await git.addConfig('pack.packSizeLimit', `${Math.floor(memoryLimitMb / 4)}m`, false, 'global');
    await git.addConfig('pack.windowMemory', `${Math.floor(memoryLimitMb / 4)}m`, false, 'global');
    await git.addConfig('pack.threads', '1', false, 'global');
  }

  async clone() {
    const { gitRepoUrl, repoDir, sourceDir, gitBranch } = this.config;

    logger.info(`Cloning ${bold(gitRepoUrl)} to ${bold(repoDir)}`);

    // Clean contents of repo directory (don't remove dir itself — it may be a mount point)
    const entries = await readdir(repoDir);
    await Promise.all(entries.map((e) => rm(join(repoDir, e), { recursive: true, force: true })));

    // Initialize git in the directory
    this.git = simpleGit({
      baseDir: repoDir,
      binary: 'git',
      maxConcurrentProcesses: 1,
    });

    // Sparse clone
    await this.git.clone(gitRepoUrl, repoDir, [
      '--filter=blob:none',
      '--no-checkout',
      '--sparse',
    ]);

    // Re-initialize git after clone
    this.git = simpleGit({
      baseDir: repoDir,
      binary: 'git',
      maxConcurrentProcesses: 1,
    });

    // Set sparse checkout path
    await this.git.raw(['sparse-checkout', 'add', sourceDir]);

    // Checkout branch
    await this.git.checkout(gitBranch);

    logger.info(`Repository cloned and checked out to branch ${bold(gitBranch)}`);
  }

  async fetch() {
    await this.git.fetch('origin');
  }

  async hasRemoteChanges() {
    const localRef = await this.git.revparse(['HEAD']);
    const remoteRef = await this.git.revparse([`origin/${this.config.gitBranch}`]);
    return localRef.trim() !== remoteRef.trim();
  }

  async pull() {
    logger.info('Pulling changes');
    await this.git.pull('origin', this.config.gitBranch);
  }

  async checkoutTag(tag) {
    logger.info(`Checking out tag ${bold(tag)}`);
    await this.fetch();
    await this.git.checkout(`tags/${tag}`);
  }

  isCloned() {
    return existsSync(join(this.config.repoDir, '.git'));
  }

  async cloneFromScratch() {
    await this.clone();
  }
}
