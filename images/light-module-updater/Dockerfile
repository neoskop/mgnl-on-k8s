FROM node:24-alpine@sha256:50c8e8ca1d27439048670df5883f32d57cf81cff6233222c893fd0d9884cbd81 AS builder

RUN corepack enable pnpm

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile --prod

FROM node:24-alpine@sha256:50c8e8ca1d27439048670df5883f32d57cf81cff6233222c893fd0d9884cbd81

ARG GIT_HOSTS="bitbucket.org github.com"

RUN apk add --no-cache git openssh-client tini && \
    addgroup -g 1001 -S mgnl && \
    adduser -u 1001 -S -D -h /home/node -G mgnl mgnl && \
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

USER mgnl

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "src/index.js"]
