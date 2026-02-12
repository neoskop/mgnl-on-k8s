import { logger, bold } from './logger.js';

export function loadConfig() {
  const config = {
    gitRepoUrl: process.env.GIT_REPO_URL || '',
    sourceDir: process.env.SOURCE_DIR || '',
    gitBranch: process.env.GIT_BRANCH || 'master',
    checkoutTag: process.env.CHECKOUT_TAG === 'true',
    pollInterval: parseInt(process.env.POLL_INTERVAL, 10) || 5,
    repoDir: process.env.REPO_DIR || '/home/node/repo',
    targetDir: process.env.TARGET_DIR || '/home/tomcat/light-modules',
    tagFilePath: '/home/docker/config/tag',
  };

  const missing = [];
  if (!config.gitRepoUrl) missing.push('GIT_REPO_URL');
  if (!config.sourceDir) missing.push('SOURCE_DIR');

  if (missing.length > 0) {
    logger.error(`Missing required environment variables: ${missing.map(bold).join(', ')}`);
    return null;
  }

  return Object.freeze(config);
}
