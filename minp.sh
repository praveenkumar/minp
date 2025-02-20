#!/bin/bash

set -exuo pipefail

sudo podman run --hostname 127.0.0.1.nip.io --detach --rm -it --privileged -p 9080:80 -p 9443:443 -p 6443:6443 \
    -v /var/lib/containers/storage:/host-container:ro,rshared \
    --name microshift quay.io/praveenkumar/microshift-okd:4.18.0-okd-scos.1-amd64

sleep 20

sudo podman cp  microshift:/var/lib/microshift/resources/kubeadmin/127.0.0.1.nip.io/kubeconfig .
sudo chown $USER:$USER kubeconfig
