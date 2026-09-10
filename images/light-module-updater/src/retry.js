import pRetry from 'p-retry';
import { logger } from './logger.js';

export function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * p-retry v8 hands `onFailedAttempt` a context object (`{error, attemptNumber,
 * retriesLeft}`), not the error itself, so neither `error.message` nor
 * `JSON.stringify(error)` ever produced a usable reason — the latter logged the
 * context's shape with the Error, which has no enumerable own properties,
 * rendered as `{}`. Unwrap the context first.
 */
function formatError(failure) {
  const error = failure?.error ?? failure;
  return error?.message || error?.git?.message || String(error);
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
          `${operationName} attempt ${error.attemptNumber}/${maxRetries + 1} failed: ${formatError(error)}`
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
            `${operationName} attempt ${error.attemptNumber}/6 failed: ${formatError(error)}`
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
