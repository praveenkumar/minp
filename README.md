Microshift in Podman (minp)
==========================

Note: This is not for production use only for testing purpose.

In windows on wsl environment make sure you have cgroupsv2 enabled which is not the case by default 
 - https://github.com/spurin/wsl-cgroupsv2
 - https://github.com/microsoft/WSL/issues/6662 (more details around cgroups-v1/v2)

Image is created using https://github.com/eslutsky/microshift/blob/main/okd/src/README.md#build-and-run-microshift-upstream-without-subscriptionpull-secret

Since OKD payload only available for amd64 and not for arm64 so as of now only amd64 build is available.

Running the image:
----------------
```bash
podman run --hostname 127.0.0.1.nip.io --detach --rm -it --privileged -v 00-dns.yaml:/etc/microshift/config.d/00-dns.yaml:ro -p 9080:80 -p 9443:443 -p 6443:6443 --name microshift quay.io/praveenkumar/microshift-okd:flannel-amd64
podman cp microshift:/var/lib/microshift/resources/kubeadmin/127.0.0.1.nip.io/kubeconfig .
kubectl.exe --kubeconfig=kubeconfig get pods -A
```

