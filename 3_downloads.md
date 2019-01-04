```
wget https://dl.k8s.io/v1.12.4/kubernetes-server-linux-amd64.tar.gz && \
tar zxvf kubernetes-server-linux-amd64.tar.gz && \
tar zxvf kubernetes/kubernetes-src.tar.gz -C kubernetes
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kubelet,kube-proxy,kubeadm} root@${node_ip}:/opt/k8s/bin/
  done
```

```
wget https://github.com/coreos/etcd/releases/download/v3.3.7/etcd-v3.3.7-linux-amd64.tar.gz && \
tar -xvf etcd-v3.3.7-linux-amd64.tar.gz
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp etcd-v3.3.7-linux-amd64/etcd* root@${node_ip}:/opt/k8s/bin
  done
```

```
mkdir flannel
wget https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-amd64.tar.gz && \
tar -xzvf flannel-v0.10.0-linux-amd64.tar.gz -C flannel
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp  flannel/{flanneld,mk-docker-opts.sh} root@${node_ip}:/opt/k8s/bin/
  done
```

```
wget https://download.docker.com/linux/static/stable/x86_64/docker-18.06.1-ce.tgz && \
tar -xvf docker-18.06.1-ce.tgz
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp docker/docker*  root@${node_ip}:/opt/k8s/bin/
  done
```

