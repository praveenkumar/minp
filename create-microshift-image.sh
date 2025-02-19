#!/bin/bash

set -exuo pipefail

# Detect the system architecture
ARCH=$(uname -m)

# Map system architectures to container image architectures
case "$ARCH" in
  "x86_64")
    ARCH="amd64"
    REPO="registry.ci.openshift.org/origin/release-scos"
    ;;
  "aarch64")
    ARCH="arm64"
    REPO="quay.io/okd-arm/okd-arm-release"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# Variables
VERSION_TAG="4.18.0-okd-scos.1"
IMAGE_NAME="quay.io/praveenkumar/microshift-okd"
IMAGE_ARCH_TAG="${IMAGE_NAME}:${VERSION_TAG}-${ARCH}"
CONTAINERFILE="okd/src/microshift-okd-multi-build.Containerfile"

# check if image already exist
if skopeo --override-os="linux" --override-arch="${ARCH}" inspect --format "Digest: {{.Digest}}" docker://${IMAGE_ARCH_TAG}; then
   echo "${IMAGE_ARCH_TAG} already exist"
   exit 0
fi

echo "Building image for architecture: $ARCH using repository: $REPO"

git clone https://github.com/openshift/microshift
pushd microshift

# Build the image
sudo podman build \
  --build-arg OKD_REPO="$REPO" \
  --build-arg OKD_VERSION_TAG="$VERSION_TAG" \
  --env WITH_FLANNEL=1 \
  --env EMBED_CONTAINER_IMAGES=1 \
  --file "$CONTAINERFILE" \
  --tag "$IMAGE_ARCH_TAG" \
  .

# Push the image
echo "Pushing image: $IMAGE_ARCH_TAG"
sudo podman push "$IMAGE_ARCH_TAG"
popd

rm -fr microshift
