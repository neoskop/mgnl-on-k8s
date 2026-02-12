import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { loadConfig } from './config.js';
import { logger, bold } from './logger.js';
import { GitManager } from './git-manager.js';
import { syncModules } from './sync-manager.js';
import { sleep, retryForever, withRetry } from './retry.js';
import { startHealthServer, setHealthy, setReady } from './health-server.js';

let currentTag = null;

async function readTagFromFile(tagFilePath) {
  try {
    if (existsSync(tagFilePath)) {
      const tag = (await readFile(tagFilePath, 'utf8')).trim();
      return tag || null;
    }
  } catch {
    // Ignore read errors
  }
  return null;
}

async function handleTagMode(git, config) {
  const newTag = await readTagFromFile(config.tagFilePath);

  if (!newTag) {
    return;
  }

  if (newTag !== currentTag) {
    if (currentTag === null) {
      logger.info(`Tag was set to ${bold(newTag)}. Fetching and checking out tag`);
    } else {
      logger.info(`Tag was changed from ${bold(currentTag)} to ${bold(newTag)}. Fetching and checking out tag`);
    }

    const result = await withRetry(
      async () => {
        await git.checkoutTag(newTag);
      },
      { operationName: 'tag checkout' }
    );

    if (result.success) {
      const sourceFullPath = join(config.repoDir, config.sourceDir);
      await syncModules(sourceFullPath, config.targetDir);
      currentTag = newTag;
    }
  }
}

async function handleBranchMode(git, config) {
  const fetchResult = await withRetry(
    async () => {
      await git.fetch();
    },
    { operationName: 'fetch' }
  );

  if (!fetchResult.success) {
    logger.warn(`${bold('git fetch')} failed ... will try to clone from scratch`);
    await cloneFromScratch(git, config);
    return;
  }

  try {
    const hasChanges = await git.hasRemoteChanges();

    if (hasChanges) {
      const pullResult = await withRetry(
        async () => {
          await git.pull();
        },
        { operationName: 'pull' }
      );

      if (pullResult.success) {
        const sourceFullPath = join(config.repoDir, config.sourceDir);
        await syncModules(sourceFullPath, config.targetDir);
      } else {
        logger.warn(`${bold(`git pull origin ${config.gitBranch}`)} failed ... will try to clone from scratch`);
        await cloneFromScratch(git, config);
      }
    }
  } catch (error) {
    logger.warn(`Error checking for changes: ${error.message}`);
  }
}

async function cloneFromScratch(git, config) {
  try {
    await git.cloneFromScratch();
    const sourceFullPath = join(config.repoDir, config.sourceDir);
    await syncModules(sourceFullPath, config.targetDir);
  } catch (error) {
    logger.error(`Clone from scratch failed: ${error.message}`);
  }
}

async function pollLoop(git, config) {
  if (config.checkoutTag) {
    logger.info(`Starting to check tag config file (${bold(config.tagFilePath)}) for changes...`);
  } else {
    logger.info('Starting to check repository for changes...');
  }

  let consecutiveFailures = 0;

  while (true) {
    try {
      if (config.checkoutTag) {
        await handleTagMode(git, config);
      } else {
        await handleBranchMode(git, config);
      }
      consecutiveFailures = 0;
      setHealthy(true);
    } catch (error) {
      logger.error(`Poll cycle error: ${error.message}`);
      consecutiveFailures++;
      if (consecutiveFailures >= 3) {
        setHealthy(false);
      }
      // Continue to next iteration - never exit
    }

    await sleep(config.pollInterval * 1000);
  }
}

async function main() {
  logger.info('Light Module Updater starting...');

  // Start health server
  await startHealthServer();

  // Load configuration - retry forever if missing
  let config = null;
  while (config === null) {
    config = loadConfig();
    if (config === null) {
      logger.warn('Waiting for configuration...');
      await sleep(10000);
    }
  }

  // Initialize Git manager
  const git = new GitManager(config);
  await git.initialize();

  // Initial clone if not already cloned
  if (!git.isCloned()) {
    await retryForever(
      async () => {
        await git.clone();
      },
      { operationName: 'initial clone' }
    );
  }

  // Initial sync
  logger.info('Copying modules initially');
  const sourceFullPath = join(config.repoDir, config.sourceDir);
  await retryForever(
    async () => {
      await syncModules(sourceFullPath, config.targetDir);
    },
    { operationName: 'initial sync' }
  );

  // Mark as ready and healthy after initial sync
  setReady(true);
  setHealthy(true);

  // Check for initial tag if in tag mode
  if (config.checkoutTag) {
    const tag = await readTagFromFile(config.tagFilePath);
    if (tag) {
      currentTag = tag;
      await git.checkoutTag(tag);
      await syncModules(sourceFullPath, config.targetDir);
    } else {
      logger.warn(`${bold('CHECKOUT_TAG')} is true, yet no tag is specified`);
    }
  }

  // Start polling loop - runs forever
  await pollLoop(git, config);
}

// Entry point - NEVER exits
async function run() {
  while (true) {
    try {
      await main();
    } catch (error) {
      logger.error(`Fatal error: ${error.message}`);
      logger.info('Restarting in 10 seconds...');
      await sleep(10000);
    }
  }
}

run();
