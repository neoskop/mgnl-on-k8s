# Magnolia on Kubernetes

A mono repo to setup Magnolia with custom light modules in Kubernetes fast.

## Quickstart

```sh
# Specify light module repo
$ export REPO_URL=git@github.com/example.git
# Specify path to light module directory
$ export SOURCE_DIR=/
# Specify private key in case of private repository
$ export SSH_PRIVATE_KEY=$(cat some/dir/id_rsa | base64)
# Install Magnolia with a single MySQL instance to the current cluster
$ ./scripts/quickstart.sh scripts/quickstart.sh
```

## Structure

- `helm` contains a helm chart to setup a working Magnolia installation which is per default based on our custom images
- `images` contains all custom images that the helm chart uses with the following functions:
  - `light-module-updater` polls a Git repository containing light modules and updates the light modules of the running Magnolia instances without restarting them
  - `runtime-env` contains a Tomcat servlet container and a small Java app to wait for the database to become available which is executed before Tomcat
  - `webapp` is a container that just copies a custom Magnolia WAR to the runtime environment.

For more details check the individual README files in the subdirectories.

## Requirements

Building the images:

- Docker 17.05+

To use the helm chart:

- Helm 2+
- Kubernetes 1.13+

To use the release and update scripts:

- jq
- yq
- git
- curl
- helm
- cr
- npm
- yarn

To use the `generate-activation-keypair.sh` script:

- openssl
- xxd
- tr

## Outlook

We are still working on a sidecar container that will auto-update the Magnolia instance in a defined maintenance window if a new version becomes available.
