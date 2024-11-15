build-okd.sh
===========

This script is use to create arm64 bits for OKD components which is consumed by microshift.

It create the container images and push it to quay.io/okd-arm, you need to change the image
if you want to push it some different registry.

Before run this script you first need to login `registry.ci.openshift.org` repo which you can
do by following the docs https://docs.ci.openshift.org/docs/how-tos/use-registries-in-build-farm/#summary-of-available-registries

To build the image
-----------------

```
./build-okd.sh release-4.18 4.18.3
```
