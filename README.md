**Note: This repo was only for POC, Dev work is now migrated to https://github.com/minc-org/minc**

Microshift in Podman (minp)
==========================

Make sure you are using rootful mode instead of rootless for this. (Default is `podman-machine-default-root`)
```
$ podman system connection ls
Name                         URI                                                         Identity                                                       Default     ReadWrite
podman-machine-default       ssh://core@127.0.0.1:61859/run/user/501/podman/podman.sock  /Users/prkumar/.local/share/containers/podman/machine/machine  false       true
podman-machine-default-root  ssh://root@127.0.0.1:61859/run/podman/podman.sock           /Users/prkumar/.local/share/containers/podman/machine/machine  true        true
```

Note: This is not for production use.

In windows on wsl environment make sure you have cgroupsv2 enabled which is not the case by default 
 - https://github.com/spurin/wsl-cgroupsv2
 - https://github.com/microsoft/WSL/issues/6662 (more details around cgroups-v1/v2)

Image is created using https://github.com/openshift/microshift/tree/main/okd/src#build-and-run-microshift-upstream-without-subscriptionpull-secret

NOTE: arm64 image is created using hacky way because OKD doesn't provide arm64 payload as of now.

Get the openshift client binary:
------------------------------
- Windows: https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-client-windows.zip
- Mac: https://mirror.openshift.com/pub/openshift-v4/aarch64/clients/ocp/latest/openshift-client-mac-arm64.tar.gz


Running the image:
----------------

For Windows:
```
podman run --hostname 127.0.0.1.nip.io --detach --rm -it --privileged -v /var/lib/containers/storage:/host-container:ro,rshared -p 9080:80 -p 9443:443 -p 6443:6443 --name microshift quay.io/praveenkumar/microshift-okd:4.18.0-okd-scos.1-amd64
sleep 20
podman cp microshift:/var/lib/microshift/resources/kubeadmin/127.0.0.1.nip.io/kubeconfig .
oc.exe --kubeconfig=kubeconfig get pods -A
```

For Mac:
```
podman run --hostname 127.0.0.1.nip.io --detach --rm -it --privileged -v /var/lib/containers/storage:/host-container:ro,rshared -p 9080:80 -p 9443:443 -p 6443:6443 --name microshift quay.io/praveenkumar/microshift-okd:4.18.0-okd-scos.1-arm64
sleep 20
podman cp microshift:/var/lib/microshift/resources/kubeadmin/127.0.0.1.nip.io/kubeconfig .
oc --kubeconfig=kubeconfig get pods -A
```

Deploy an application:
---------------------
```
oc --kubeconfig=kubeconfig apply -f https://raw.githubusercontent.com/praveenkumar/simple-go-server/refs/heads/main/kubernetes/deploy.yaml
oc --kubeconfig=kubeconfig expose service myserver -n demo
oc --kubeconfig=kubeconfig get route -n demo
NAME       HOST                                  ADMITTED   SERVICE    TLS
myserver   myserver-demo.apps.127.0.0.1.nip.io   True       myserver
```

Access the application on host:
------------------------------
```
$ curl http://myserver-demo.apps.127.0.0.1.nip.io:9080
hello
```

