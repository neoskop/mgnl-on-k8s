import pRetry from 'p-retry';
import { logger } from './logger.js';

export function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function withRetry(operation, options = {}) {
  const {
    maxRetries = 5,
    operationName = 'operation',
  } = options;

  try {
    const result = await pRetry(operation, {
      retries: maxRetries,
      onFailedAttempt: (error) => {
        logger.warn(
          `${operationName} attempt ${error.attemptNumber}/${maxRetries + 1} failed: ${error.message}`
        );
      },
    });
    return { success: true, result };
  } catch (error) {
    return { success: false, error };
  }
}

export async function retryForever(operation, options = {}) {
  const {
    pauseBetweenCyclesMs = 30000,
    operationName = 'operation',
  } = options;

  while (true) {
    try {
      const result = await pRetry(operation, {
        retries: 5,
        onFailedAttempt: (error) => {
          logger.warn(
            `${operationName} attempt ${error.attemptNumber}/6 failed: ${error.message}`
          );
        },
      });
      return result;
    } catch {
      logger.warn(
        `${operationName} failed after retries, waiting ${pauseBetweenCyclesMs / 1000}s before next cycle...`
      );
      await sleep(pauseBetweenCyclesMs);
    }
  }
}
