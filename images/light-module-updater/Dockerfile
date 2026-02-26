FROM node:24-alpine AS builder

RUN corepack enable pnpm

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile --prod

FROM node:24-alpine

ARG GIT_HOSTS="bitbucket.org github.com"

RUN apk add --no-cache git openssh-client && \
    mkdir -p /home/node/repo /home/node/.ssh /home/tomcat/light-modules && \
    for host in $GIT_HOSTS; do \
      ssh-keyscan "$host" >> /home/node/.ssh/known_hosts 2>/dev/null; \
    done && \
    chown -R 1001:1001 /home/node /home/tomcat/light-modules && \
    chmod 700 /home/node/.ssh && \
    chmod 644 /home/node/.ssh/known_hosts

WORKDIR /home/node

ENV HOME=/home/node \
    GIT_BRANCH=master \
    CHECKOUT_TAG=false \
    POLL_INTERVAL=5 \
    REPO_DIR=/home/node/repo \
    TARGET_DIR=/home/tomcat/light-modules \
    NODE_ENV=production

COPY --from=builder --chown=1001:1001 /app/node_modules ./node_modules
COPY --chown=1001:1001 src ./src
COPY --chown=1001:1001 package.json ./

USER 1001:1001

CMD ["node", "src/index.js"]
