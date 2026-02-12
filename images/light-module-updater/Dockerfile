FROM node:22-alpine AS builder

RUN corepack enable pnpm

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile --prod

FROM node:22-alpine

ARG GIT_HOSTS="bitbucket.org github.com"

RUN apk add --no-cache git openssh-client && \
    mkdir -p /home/node/repo /home/tomcat/light-modules && \
    chown node /home/node/repo /home/tomcat/light-modules

USER node
WORKDIR /home/node

RUN mkdir -p ~/.ssh && \
    for host in $GIT_HOSTS; do \
      ssh-keyscan "$host" >> ~/.ssh/known_hosts 2>/dev/null; \
    done

ENV GIT_BRANCH=master \
    CHECKOUT_TAG=false \
    POLL_INTERVAL=5 \
    REPO_DIR=/home/node/repo \
    TARGET_DIR=/home/tomcat/light-modules \
    NODE_ENV=production

COPY --from=builder /app/node_modules ./node_modules
COPY --chown=node:node src ./src
COPY --chown=node:node package.json ./

CMD ["node", "src/index.js"]
