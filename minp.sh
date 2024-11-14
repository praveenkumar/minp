#!/bin/bash

set -exuo pipefail

podman run --hostname 127.0.0.1.nip.io --arch=amd64 --detach --rm -it --privileged -p 9080:80 -p 9443:443 -p 6443:6443 -v $(pwd)/00-dns.yaml:/etc/microshift/config.d/00-dns.yaml --name microshift quay.io/praveenkumar/microshift-okd:flannel-arm64

sleep 20

podman cp  microshift:/var/lib/microshift/resources/kubeadmin/127.0.0.1.nip.io/kubeconfig .
