# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Magnolia on Kubernetes (mgnl-on-k8s) is a production-ready Kubernetes deployment system for Magnolia CMS. It provides:
- Custom Docker images for running Magnolia with light modules in Kubernetes
- Helm charts for managing complete Magnolia installations (author and public instances)
- Automated image building and version management

## Build Commands

### Docker Images

**Runtime Environment Image** (Tomcat + JDK 17 + startup helper):
```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -f images/runtime-env/Dockerfile \
  -t neoskop/mgnl-runtime-env:TAG --push .
```

**Light Module Updater Image**:
```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -f images/light-module-updater/Dockerfile \
  -t neoskop/mgnl-light-module-updater:TAG --push .
```

**Magnolia Webapp Images** (builds WAR from Magnolia Nexus):
```bash
cd images/webapp/magnolia-build/ce  # or ce-damfs, dx, dx-damfs
mvn -DmagnoliaBundleVersion=6.4.0 package
docker buildx build --build-arg VERSION=6.4.0 -t neoskop/mgnl-webapp-ce:6.4.0 --push .
```

### Local Testing

```bash
cd images/runtime-env
docker-compose up -d
```

### Release Process

```bash
./scripts/release.sh patch  # or minor, major
```

This bumps version in Chart.yaml and values.yaml, creates git tag, packages and publishes Helm chart.

### Dependency Updates

```bash
./scripts/update-deps.sh
```

Fetches latest versions from Docker Hub and Magnolia Nexus, updates Dockerfiles and values.yaml.

## Architecture

```
External Git Repo (Light Modules)
         |
    [Light Module Updater] <- polls via Git SSH
         |
    Shared Volume: /home/tomcat/light-modules
         |
    [Magnolia Runtime (Tomcat)] <- loads modules at startup
    |-- Author Instance (with admin UI)
    |-- Public Instance (headless CMS delivery)
         |
    [MySQL Database] <- persistence layer
```

### Core Images

1. **light-module-updater** (`images/light-module-updater/`)
   - Ubuntu 24.04 base, polls Git repository on interval
   - Syncs modules via rsync to shared volume
   - Supports SSH key authentication for private repos

2. **runtime-env** (`images/runtime-env/`)
   - Multi-stage build: Maven compiles Java entrypoint -> Tomcat base
   - Java entrypoint waits for MySQL connectivity before starting Tomcat
   - Exposes port 8080 (HTTP) and 5005 (debug)

3. **magnolia-webapp** (`images/webapp/magnolia-build/`)
   - Four variants: ce, ce-damfs, dx, dx-damfs
   - Dynamically builds WAR files from Magnolia Nexus (min version 6.4.0)

### Helm Chart (`helm/`)

- Two-instance deployment (author + public)
- MySQL backend with optional persistence
- ConfigMaps for datasource configuration
- Secrets for MySQL passwords and license keys
- Optional 1Password integration for license key management

## Key Configuration Files

| File | Purpose |
|------|---------|
| `helm/Chart.yaml` | Helm chart metadata and version |
| `helm/values.yaml` | K8s resource config and image versions |
| `helm/datasource-author.json` | Magnolia JDBC datasource for author |
| `helm/datasource-public.json` | Magnolia JDBC datasource for public |
| `images/runtime-env/build/entrypoint/pom.xml` | Java startup helper dependencies |

## CI/CD Workflows

- **build-runtime-env.yml**: Builds runtime-env image on tag push
- **build-lmu.yml**: Builds light-module-updater image on tag push
- **build-webapp.yml**: Daily automated webapp image building from Magnolia Nexus

All images are built for both amd64 and arm64 architectures.

## Commit Message Convention

Uses Conventional Commits style:
```
type(scope): description

Examples:
- chore: Bump version to 1.1.1.
- fix: use complete path for `magnolia.license.location`
- feat: add option to load license from external source
```

## Tools Required for Development

- Docker 17.05+ with buildx
- Helm 2+
- Maven 3.9.x (for webapp builds)
- jq, yq, xmlstarlet (for scripts)
- openssl (for key generation)
