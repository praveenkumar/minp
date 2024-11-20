#!/bin/bash

set -exuo pipefail

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Function to handle base-image repository
base_image() {
  local repo_url="https://github.com/openshift/images"
  local dockerfile_path="base/Dockerfile.rhel9"
  local repo=$(basename ${repo_url})

  git clone --branch "$BRANCH" --single-branch "$repo_url"
  cd $repo || { echo "Failed to access repo directory"; return 1; }

  # Replace lines that begin with 'FROM registry.ci.openshift.org/ocp'
  sed -i 's|^FROM registry.ci.openshift.org/ocp/.*|FROM quay.io/centos/centos:stream9|' "$dockerfile_path"

  podman build -t quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9 -f "$dockerfile_path" .
  podman push quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9

  cd ..
  rm -fr $repo
}

# Function to handle router-image repository
router_image() {
  local repo_url="https://github.com/openshift/router"
  local dockerfile_base_path="images/router/base/Dockerfile.ocp"
  local dockerfile_haproxy_path="images/router/haproxy/Dockerfile.ocp"
  local repo=$(basename ${repo_url})

  git clone --branch "$BRANCH" --single-branch "$repo_url"
  cd $repo || { echo "Failed to access repo directory"; return 1; }

  # Apply sed commands for both Dockerfiles in router repo
  sed -i 's|^FROM registry.ci.openshift.org/ocp/builder.*|FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.22-builder-multi-openshift-4.18 AS builder|' "$dockerfile_base_path"
  sed -i "s|^FROM registry.ci.openshift.org/ocp/.*:base-rhel9|FROM quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9|" "$dockerfile_base_path"
  
  podman build -t quay.io/okd-arm/haproxy-router-base:${OKD_VERSION} -f "$dockerfile_base_path" .
  podman push quay.io/okd-arm/haproxy-router-base:${OKD_VERSION}
  
  sed -i "s|^FROM registry.ci.openshift.org/ocp/.*|FROM quay.io/okd-arm/haproxy-router-base:${OKD_VERSION}|" "$dockerfile_haproxy_path"
  sed -i "s|haproxy28|https://github.com/praveenkumar/minp/releases/download/v0.0.1/haproxy28-2.8.10-1.rhaos4.17.el9.aarch64.rpm|" "$dockerfile_haproxy_path"
  sed -i 's|yum install -y $INSTALL_PKGS|yum --disablerepo=rt install -y $INSTALL_PKGS|' "$dockerfile_haproxy_path"

  podman build -t quay.io/okd-arm/haproxy-router:${OKD_VERSION} -f "$dockerfile_haproxy_path" .
  podman push quay.io/okd-arm/haproxy-router:${OKD_VERSION}

  cd ..
  rm -fr $repo
}

# Function to handle kube-proxy repository
kube_proxy_image() {
  local repo_url="https://github.com/openshift/sdn"
  local dockerfile_path="images/kube-proxy/Dockerfile.rhel"
  local repo=$(basename ${repo_url})

  git clone --branch "$BRANCH" --single-branch "$repo_url"
  cd $repo || { echo "Failed to access repo directory"; return 1; }

  # Apply sed commands for both Dockerfiles in router repo
  sed -i 's|^FROM registry.ci.openshift.org/ocp/builder.*|FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.22-builder-multi-openshift-4.18 AS builder|' "$dockerfile_path"
  sed -i "s|^FROM registry.ci.openshift.org/ocp/.*:base-rhel9|FROM quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9|" "$dockerfile_path"
  sed -i 's|yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS|yum --disablerepo=rt install -y --setopt=tsflags=nodocs $INSTALL_PKGS|' "$dockerfile_path"

  podman build -t quay.io/okd-arm/kube-proxy:${OKD_VERSION} -f "$dockerfile_path" .
  podman push quay.io/okd-arm/kube-proxy:${OKD_VERSION}

  cd ..
  rm -fr $repo
}


# Function to handle coredns-image repository
coredns_image() {
  local repo_url="https://github.com/openshift/coredns"
  local dockerfile_path="Dockerfile.ocp"
  local repo=$(basename ${repo_url})

  git clone --branch "$BRANCH" --single-branch "$repo_url"
  cd $repo || { echo "Failed to access repo directory"; return 1; }

  # Apply the sed commands for the coredns Dockerfile
  sed -i 's|^FROM registry.ci.openshift.org/ocp/builder.*|FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.22-builder-multi-openshift-4.18 AS builder|' "$dockerfile_path"
  sed -i "s|^FROM registry.ci.openshift.org/ocp/.*:base-rhel9|FROM quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9|" "$dockerfile_path"

  podman build -t quay.io/okd-arm/coredns:${OKD_VERSION} -f "$dockerfile_path" .
  podman push quay.io/okd-arm/coredns:${OKD_VERSION}
  
  cd ..
  rm -fr $repo
}

# Function to handle csi-external-snapshotter-image repository
csi_external_snapshotter_image() {
  local repo_url="https://github.com/openshift/csi-external-snapshotter"
  local dockerfile_snapshot_controller_path="Dockerfile.snapshot-controller.openshift.rhel7"
  local dockerfile_webhook_path="Dockerfile.webhook.openshift.rhel7"
  local repo=$(basename ${repo_url})

  git clone --branch "$BRANCH" --single-branch "$repo_url"
  cd $repo || { echo "Failed to access repo directory"; return 1; }

  # Apply the sed commands for both Dockerfiles
  sed -i 's|^FROM registry.ci.openshift.org/ocp/builder.*|FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.22-builder-multi-openshift-4.18 AS builder|' "$dockerfile_snapshot_controller_path"
  sed -i "s|^FROM registry.ci.openshift.org/ocp/.*:base-rhel9|FROM quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9|" "$dockerfile_snapshot_controller_path"
  
  podman build -t quay.io/okd-arm/csi-snapshot-controller:${OKD_VERSION} -f "$dockerfile_snapshot_controller_path" .
  podman push quay.io/okd-arm/csi-snapshot-controller:${OKD_VERSION}
  
  sed -i 's|^FROM registry.ci.openshift.org/ocp/builder.*|FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.22-builder-multi-openshift-4.18 AS builder|' "$dockerfile_webhook_path"
  sed -i "s|^FROM registry.ci.openshift.org/ocp/.*:base-rhel9|FROM quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9|" "$dockerfile_webhook_path"

  podman build -t quay.io/okd-arm/csi-snapshot-validation-webhook:${OKD_VERSION} -f "$dockerfile_webhook_path" .
  podman push quay.io/okd-arm/csi-snapshot-validation-webhook:${OKD_VERSION}

  cd ..
  rm -fr $repo
}

# Function to handle kube-rbac-proxy-image repository
kube_rbac_proxy_image() {
  local repo_url="https://github.com/openshift/kube-rbac-proxy"
  local dockerfile_path="Dockerfile.ocp"
  local repo=$(basename ${repo_url})

  git clone --branch "$BRANCH" --single-branch "$repo_url"
  cd $repo || { echo "Failed to access repo directory"; return 1; }

  # Apply the sed commands for the kube-rbac-proxy Dockerfile
  sed -i 's|^FROM registry.ci.openshift.org/ocp/builder.*|FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.22-builder-multi-openshift-4.18 AS builder|' "$dockerfile_path"
  sed -i "s|^FROM registry.ci.openshift.org/ocp/.*:base-rhel9|FROM quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9|" "$dockerfile_path"

  podman build -t quay.io/okd-arm/kube-rbac-proxy:${OKD_VERSION} -f "$dockerfile_path" .
  podman push quay.io/okd-arm/kube-rbac-proxy:${OKD_VERSION}
  
  cd ..
  rm -fr $repo
}

# Function to handle pod-image repository
pod_image() {
  local repo_url="https://github.com/openshift/kubernetes"
  local dockerfile_path="build/pause/Dockerfile.Rhel"
  local repo=$(basename ${repo_url})

  git clone --branch "$BRANCH" --single-branch "$repo_url"
  cd $repo || { echo "Failed to access repo directory"; return 1; }

  # Apply the sed commands for the pod Dockerfile
  sed -i 's|^FROM registry.ci.openshift.org/ocp/builder.*|FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.22-builder-multi-openshift-4.18 AS builder|' "$dockerfile_path"
  sed -i "s|^FROM registry.ci.openshift.org/ocp/.*:base-rhel9|FROM quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9|" "$dockerfile_path"

  pushd build/pause && podman build -t quay.io/okd-arm/pod:${OKD_VERSION} -f $(basename "$dockerfile_path") . &&  popd
  podman push quay.io/okd-arm/pod:${OKD_VERSION}

  cd ..
  rm -fr $repo
}

# Function to handle cli-image repository
cli_image() {
  local repo_url="https://github.com/openshift/oc"
  local dockerfile_path="images/cli/Dockerfile.rhel"
  local repo=$(basename ${repo_url})

  git clone --branch "$BRANCH" --single-branch "$repo_url"
  cd $repo || { echo "Failed to access repo directory"; return 1; }

  # Apply the sed commands for the cli Dockerfile
  sed -i 's|^FROM registry.ci.openshift.org/ocp/builder.*|FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.22-builder-multi-openshift-4.18 AS builder|' "$dockerfile_path"
  sed -i "s|^FROM registry.ci.openshift.org/ocp/.*:base-rhel9|FROM quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9|" "$dockerfile_path"

  podman build -t quay.io/okd-arm/cli:${OKD_VERSION} -f "$dockerfile_path" .
  podman push quay.io/okd-arm/cli:${OKD_VERSION}

  cd ..
  rm -fr $repo
}

# Function to handle service-ca-operator-image repository
service_ca_operator_image() {
  local repo_url="https://github.com/openshift/service-ca-operator"
  local dockerfile_path="Dockerfile.rhel7"
  local repo=$(basename ${repo_url})

  git clone --branch "$BRANCH" --single-branch "$repo_url"
  cd $repo || { echo "Failed to access repo directory"; return 1; }

  # Apply the sed commands for the service-ca-operator Dockerfile
  sed -i 's|^FROM registry.ci.openshift.org/ocp/builder.*|FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.22-builder-multi-openshift-4.18 AS builder|' "$dockerfile_path"
  sed -i "s|^FROM registry.ci.openshift.org/ocp/.*:base-rhel9|FROM quay.io/okd-arm/scos-${OKD_VERSION}:base-stream9|" "$dockerfile_path"

  podman build -t quay.io/okd-arm/service-ca-operator:${OKD_VERSION} -f "$dockerfile_path" .
  podman push quay.io/okd-arm/service-ca-operator:${OKD_VERSION}

  cd ..
  rm -fr $repo
}

# Create a new release of okd using oc

create_new_okd_release() {
    oc adm release new --from-release registry.ci.openshift.org/origin/release-scos:scos-4.18 \
       --keep-manifest-list \
       cli=quay.io/okd-arm/cli:${OKD_VERSION} \
	haproxy-router=quay.io/okd-arm/haproxy-router:${OKD_VERSION} \
	kube-proxy=quay.io/okd-arm/kube-proxy:${OKD_VERSION} \
	coredns=quay.io/okd-arm/coredns:${OKD_VERSION} \
       csi-snapshot-controller=quay.io/okd-arm/csi-snapshot-controller:${OKD_VERSION} \
       csi-snapshot-validation-webhook=quay.io/okd-arm/csi-snapshot-validation-webhook:${OKD_VERSION} \
	kube-rbac-proxy=quay.io/okd-arm/kube-rbac-proxy:${OKD_VERSION} \
	pod=quay.io/okd-arm/pod:${OKD_VERSION} \
	service-ca-operator=quay.io/okd-arm/service-ca-operator:${OKD_VERSION} \
	--to-image quay.io/okd-arm/okd-arm-release:${OKD_VERSION}
}

# Main function to run all the image update functions
update_images() {
  base_image
  router_image
  kube_proxy_image
  coredns_image
  csi_external_snapshotter_image
  kube_rbac_proxy_image
  pod_image
  cli_image
  service_ca_operator_image
}

# Check if branch and version argument is provided
if [ -z "$1" ]; then
  echo "Error: Branch argument is missing"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Error: VERSION argument is missing"
  exit 1
fi

BRANCH="$1"
OKD_VERSION="$2"

# Run the update process
update_images
create_new_okd_release
