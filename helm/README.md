# Magnolia on Kubernetes

Run Magnolia CMS on Kubernetes in production with ease. This repository will
set-up two Magnolia instances (author, public) to be used as a headless CMS.
To use without a separate delivery tier you should consider adding a second
public instance for high-availability.

## Quickstart

```sh
# Add the Neoskop helm charts
$ helm repo add neoskop https://charts.neoskop.dev

# Install the helm chart
$ helm install \
    -n magnolia \
    --set mysql.rootPassword=$(pwgen 32 1) \
    --set magnoliaActivation.privateKey=$ACTIVATION_PRIVATE_KEY \
    --set magnoliaActivation.publicKey=$ACTIVATION_PUBLIC_KEY
    neoskop/mgnl \
```
