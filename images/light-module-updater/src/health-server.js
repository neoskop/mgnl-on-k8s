import Fastify from 'fastify';
import { logger } from './logger.js';

const fastify = Fastify({ logger: false });

let isHealthy = false;
let isReady = false;

export function setHealthy(healthy) {
  isHealthy = healthy;
}

export function setReady(ready) {
  isReady = ready;
}

fastify.get('/health', async (request, reply) => {
  if (isHealthy) {
    return reply.code(200).send({ status: 'healthy' });
  }
  return reply.code(503).send({ status: 'unhealthy' });
});

fastify.get('/ready', async (request, reply) => {
  if (isReady) {
    return reply.code(200).send({ status: 'ready' });
  }
  return reply.code(503).send({ status: 'not ready' });
});

export async function startHealthServer(port = 8081) {
  try {
    await fastify.listen({ port, host: '0.0.0.0' });
    logger.info(`Health server listening on port ${port}`);
  } catch (err) {
    logger.error(`Failed to start health server: ${err.message}`);
  }
}
