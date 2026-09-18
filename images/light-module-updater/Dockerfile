FROM node:24-alpine@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1 AS builder

RUN corepack enable pnpm

WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile --prod

FROM node:24-alpine@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1

ARG GIT_HOSTS="bitbucket.org github.com"
# Same forges on their alternative SSH endpoints. Egress to port 22 is blocked or
# throttled on plenty of networks, and both offer SSH on 443; using one only needs
# a GIT_REPO_URL of ssh://git@ssh.github.com:443/<org>/<repo>.git. known_hosts keys
# on host *and* port, so the 443 endpoints need their own entries.
ARG GIT_HOSTS_443="ssh.github.com altssh.bitbucket.org"

RUN apk add --no-cache git openssh-client tini && \
    addgroup -g 1001 -S mgnl && \
    adduser -u 1001 -S -D -h /home/node -G mgnl mgnl && \
    mkdir -p /home/node/repo /home/node/.ssh /home/tomcat/light-modules && \
    for host in $GIT_HOSTS; do \
      ssh-keyscan "$host" >> /home/node/.ssh/known_hosts 2>/dev/null; \
      grep -q "^$host " /home/node/.ssh/known_hosts || { echo "ssh-keyscan $host produced no keys"; exit 1; }; \
    done && \
    for host in $GIT_HOSTS_443; do \
      ssh-keyscan -p 443 "$host" >> /home/node/.ssh/known_hosts 2>/dev/null; \
      grep -q "^\[$host\]:443 " /home/node/.ssh/known_hosts || { echo "ssh-keyscan -p 443 $host produced no keys"; exit 1; }; \
    done && \
    chown -R 1001:1001 /home/node /home/tomcat/light-modules && \
    chmod 700 /home/node/.ssh && \
    chmod 644 /home/node/.ssh/known_hosts

WORKDIR /home/node

ENV HOME=/home/node \
    GIT_BRANCH=master \
    CHECKOUT_TAG=false \
    POLL_INTERVAL=30 \
    REPO_DIR=/home/node/repo \
    TARGET_DIR=/home/tomcat/light-modules \
    NODE_ENV=production

COPY --from=builder --chown=1001:1001 /app/node_modules ./node_modules
COPY --chown=1001:1001 src ./src
COPY --chown=1001:1001 package.json ./

USER mgnl

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "src/index.js"]
