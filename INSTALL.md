## There has a useful gitbook for kubernetes install
<https://k8s-install.opsnull.com/>


## Pre requiments installing for a new host
* At the very first, You need to init server follow the article 'new host machine init'

## For every master and node
* Download and install kubernetes binaries, you can find every release at [github](https://github.com/kubernetes/kubernetes/releases), now the newest version is 1.12.1
```
wget https://dl.k8s.io/v1.12.1/kubernetes-server-linux-amd64.tar.gz && \
tar zxvf kubernetes-server-linux-amd64.tar.gz && \
cp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler,kubectl,kubelet,kube-proxy} /usr/bin/
```

* Make every possible directory, if don't create , may cause error
```
mkdir -p /etc/kubernetes/conf
mkdir -p /etc/kubernetes/ssl
mkdir -p /etc/etcd/ssl
mkdir -p /etc/flanneld/ssl
mkdir -p /var/lib/docker
mkdir -p /var/lib/kubelet
mkdir -p /var/lib/kube-proxy
mkdir -p /var/lib/etcd

* Clone config file
```
git clone https://github.com/hahaliu005/kube-install.git
```

* Config etc/kubernetes/conf/common.conf
```
cp kube-install/etc/kubernetes/conf/common.conf /etc/kubernetes/conf/common.conf
```
* Export config variables to shell, Then you can use these variables in command line
```
echo "source /etc/kubernetes/conf/common.conf" >> ~/.bashrc && exec bash
```
* Update hosts file so that Master and Nodes can find server
```
# cat /etc/hosts
<master-ip> kube-master.prod
<etcd-ip> kube-etcd.prod
```

* Install flannel, (Please install this after install etcd in master, For install in node need after copy ca files)
Write flanneld network config to etcd, only once
```
/usr/local/bin/etcdctl \
  --endpoints=${KUBE_ETCD_SERVERS} \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/flanneld/ssl/flanneld.pem \
  --key-file=/etc/flanneld/ssl/flanneld-key.pem \
  set ${KUBE_FLANNEL_ETCD_PREFIX}/config '{"Network":"'${KUBE_CLUSTER_CIDR}'", "SubnetLen": 24, "Backend": {"Type": "vxlan"}}'
```
Download and install flanneld
```
mkdir flannel
wget https://github.com/coreos/flannel/releases/download/v0.8.0/flannel-v0.8.0-linux-amd64.tar.gz
tar -xzvf flannel-v0.8.0-linux-amd64.tar.gz -C flannel
cp flannel/{flanneld,mk-docker-opts.sh} /usr/local/bin
```
Config etc/systemd/system/flanneld.service
```
cp etc/systemd/system/flanneld.service /etc/systemd/system/flanneld.service
```
Start flanneld and check
```
systemctl daemon-reload
systemctl enable flanneld
systemctl start flanneld
systemctl status flanneld
```
```
/usr/local/bin/etcdctl \
  --endpoints=${KUBE_ETCD_SERVERS} \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/flanneld/ssl/flanneld.pem \
  --key-file=/etc/flanneld/ssl/flanneld-key.pem \
  get /kubernetes/network/config
  
/usr/local/bin/etcdctl \
  --endpoints=${KUBE_ETCD_SERVERS} \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/flanneld/ssl/flanneld.pem \
  --key-file=/etc/flanneld/ssl/flanneld-key.pem \
  ls /kubernetes/network/subnets
```

## Only for master
* Install CFSSL
```
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 && \
mv cfssl_linux-amd64 /usr/local/bin/cfssl && \
chmod +x /usr/local/bin/cfssl && \
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 && \
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson && \
chmod +x /usr/local/bin/cfssljson && \
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 && \
mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo && \
chmod +x /usr/local/bin/cfssl-certinfo
```
* Create all the ca and tsl config file
For CA

Ca files
```
cp etc/kubernetes/ssl/ca-config.json /etc/kubernetes/ssl/ca-config.json
cp etc/kubernetes/ssl/ca-csr.json /etc/kubernetes/ssl/ca-csr.json
```
For etcd
```
cp etc/kubernetes/ssl/etcd-csr.json /etc/kubernetes/ssl/etcd-csr.json
# Replace ${KUBE_NODE_IP}, ${KUBE_ETCD_DOMAIN}
```
Admin for kubectl
```
cp etc/kubernetes/ssl/admin-csr.json /etc/kubernetes/ssl/admin-csr.json
```
For flanneld
```
cp etc/kubernetes/ssl/flanneld-csr.json /etc/kubernetes/ssl/flanneld-csr.json
```
For kubernetes
```
cp etc/kubernetes/ssl/kubernetes-csr.json /etc/kubernetes/ssl/kubernetes-csr.json
# Replace ${KUBE_MASTER_IP}, ${KUBE_CLUSTER_KUBERNETES_SVC_IP}, ${KUBE_MASTER_DOMAIN}
```
For kuber-apiserver token
```
cp etc/kubernetes/ssl/token.csv /etc/kubernetes/ssl/token.csv
# Replace ${KUBE_BOOTSTRAP_TOKEN}
```
For kube-proxy
```
cp etc/kubernetes/ssl/kube-proxy-csr.json /etc/kubernetes/ssl/kube-proxy-csr.json
```
Make all the certificates:
```
cd /etc/kubernetes/ssl/
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
# For etcd
cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca-config.json \
  -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
mv etcd*.pem /etc/etcd/ssl
# For kubectl
cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca-config.json \
  -profile=kubernetes admin-csr.json | cfssljson -bare admin
# Create kubectl kubeconfig, will put into ~/.kube/config
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_MASTER_SERVERS}
kubectl config set-credentials admin \
  --client-certificate=/etc/kubernetes/ssl/admin.pem \
  --embed-certs=true \
  --client-key=/etc/kubernetes/ssl/admin-key.pem
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin
kubectl config use-context kubernetes
# For flannel
cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca-config.json \
  -profile=kubernetes flanneld-csr.json | cfssljson -bare flanneld
mv flanneld*.pem /etc/flanneld/ssl
# For kubernetes
cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca-config.json \
  -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
# For node's kubelet
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_MASTER_SERVERS} \
  --kubeconfig=/etc/kubernetes/bootstrap.kubeconfig
kubectl config set-credentials kubelet-bootstrap \
  --token=${KUBE_BOOTSTRAP_TOKEN} \
  --kubeconfig=/etc/kubernetes/bootstrap.kubeconfig
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=/etc/kubernetes/bootstrap.kubeconfig
kubectl config use-context default --kubeconfig=/etc/kubernetes/bootstrap.kubeconfig
# For node's kube-proxy
cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca-config.json \
  -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
# kube-proxy's kubeconfig
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_MASTER_SERVERS} \
  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig
kubectl config set-credentials kube-proxy \
  --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
  --client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig
kubectl config use-context default --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig
```
* Install etcd, you can find etcd release in [github](https://github.com/coreos/etcd/releases)
```
wget https://github.com/coreos/etcd/releases/download/v3.2.7/etcd-v3.2.7-linux-amd64.tar.gz
tar zxvf etcd-v3.2.7-linux-amd64.tar.gz
mv etcd-v3.2.7-linux-amd64/{etcd,etcdctl} /usr/local/bin
```
Create etcd.service file
```
cp etc/systemd/system/etcd.service /etc/systemd/system/etcd.service
```
Start etcd
```
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
systemctl status etcd
```
> Do not forget to install flanneld for every node after you install etcd
* Install kube-apiserver
Create kube-apiserver.service
```
cp etc/systemd/system/kube-apiserver.service /etc/systemd/system/kube-apiserver.service
```
Start kube-apiserver
```
systemctl daemon-reload
systemctl enable kube-apiserver
systemctl start kube-apiserver
systemctl status kube-apiserver
```
```
# For kubelet roll bind
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
```
Create kube-controller-manager.service
```
cp etc/systemd/system/kube-controller-manager.service /etc/systemd/system/kube-controller-manager.service
```
Start kube-controller-manager
```
systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl start kube-controller-manager
systemctl status kube-controller-manager
```
Create kube-scheduler.service
```
cp etc/systemd/system/kube-scheduler.service /etc/systemd/system/kube-scheduler.service
```
Start kube-scheduler
```
systemctl daemon-reload
systemctl enable kube-scheduler
systemctl start kube-scheduler
systemctl status kube-scheduler
```
Check components status:
```
kubectl get componentstatuses
```

## Only For Node

* You need copy some certificate file to node from master
```
# blow command need to exec in master
COPY_NODE_IP=<the-ip-which-node-you-want-to-copy>
scp /etc/kubernetes/ssl/ca.pem root@${COPY_NODE_IP}:/etc/kubernetes/ssl/ca.pem
scp -r /etc/flanneld/ssl/* root@${COPY_NODE_IP}:/etc/flanneld/ssl/
scp /etc/kubernetes/bootstrap.kubeconfig root@${COPY_NODE_IP}:/etc/kubernetes/bootstrap.kubeconfig
scp /etc/kubernetes/kube-proxy.kubeconfig root@${COPY_NODE_IP}:/etc/kubernetes/kube-proxy.kubeconfig
```
* Don't forget to install flanneld
* Install docker , please follow the article 'Docker install' to install docker.
* Update docker.service
```
cp etc/systemd/system/docker.service /lib/systemd/system/docker.service
```
Start docker 
```
systemctl daemon-reload
systemctl enable docker
systemctl start docker
systemctl status docker
```
* Install kubelet
Create kubelet.service
```
cp etc/systemd/system/kubelet.service /etc/systemd/system/kubelet.service
```
Start kubelet
```
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
systemctl status kubelet
```
Approve TLS requests
Get csr requests which not be approved
```
$ kubectl get csr
NAME        AGE       REQUESTOR           CONDITION
csr-1234   4m        kubelet-bootstrap   Pending
```
```
kubectl certificate approve csr-1234
```
After that , it will auto generate key and config at node
```
ls -l /etc/kubernetes/kubelet.kubeconfig
ls -l /etc/kubernetes/ssl/kubelet*
```
* Install kube-proxy
Create kube-proxy.service
```
cp etc/systemd/system/kube-proxy.service /etc/systemd/system/kube-proxy.service
```
Start kube-proxy
```
systemctl daemon-reload
systemctl enable kube-proxy
systemctl start kube-proxy
systemctl status kube-proxy
```

## Install dns (in master)
* Dns yaml files located at addons/dns
* Files list
```
cat addons/dns/kubedns-cm.yaml

# Replace ${KUBE_CLUSTER_DNS_DOMAIN}
cat addons/dns/kubedns-controller.yaml

cat addons/dns/kubedns-sa.yaml

# Replace ${KUBE_CLUSTER_DNS_SVC_IP}
cat addons/dns/kubedns-svc.yaml
```
Because of added nodeSelector, need to add label to the node you want to run
```
kubectl label nodes <node-name> kube-master=true
```
Start dns
```
# files : kubedns-cm.yaml,kubedns-controller.yaml,kubedns-sa.yaml,kubedns-svc.yaml
kubectl create -f addons/dns
```

## Install Dashboard
* Dashboard yaml files located at addons/dashboard
Start Dashboard
```
# exec files: dashboard-controller.yaml,dashboard-rbac.yaml,dashboard-service.yaml
kubectl create -f addons/dashboard
```

## Install Heapster
* Heapster yaml files located at addons/heapster
Start heapster
```
# files : grafana-deployment.yaml,grafana-service.yaml,heapster-deployment.yaml,heapster-rbac.yaml,heapster-service.yaml,influxdb-cm.yaml,influxdb-deployment.yaml,influxdb-service.yaml
kubectl create -f addons/heapster
```

## Deploy EFK
* efk yaml files located at addons/efk
Start EFK
```
# files : es-controller.yaml,es-rbac.yaml,es-service.yaml,fluentd-es-ds.yaml,fluentd-es-rbac.yaml,kibana-controller.yaml,kibana-service.yaml
kubectl create -f addons/efk
```

## Test Cluster
Create a daemonSet for test
```
# cat nginx-ds.yml
apiVersion: v1
kind: Service
metadata:
  name: nginx-ds
  labels:
    app: nginx-ds
spec:
  type: NodePort
  selector:
    app: nginx-ds
  ports:
  - name: http
    port: 80
    targetPort: 80

---

apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: nginx-ds
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  template:
    metadata:
      labels:
        app: nginx-ds
    spec:
      containers:
      - name: my-nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```
Run and check
```
kubectl create -f nginx-ds.yml
kubectl get nodes
kubectl get pods  -o wide|grep nginx-ds
kubectl get svc |grep nginx-ds
curl <node_ip>:<svc_port>
```

## Access Cluster from browser
List cluster info
```
kubectl cluster-info
```
Generate p12file and download it
```
openssl pkcs12 -export -in /etc/kubernetes/ssl/admin.pem  -out /etc/kubernetes/ssl/admin.p12 -inkey /etc/kubernetes/ssl/admin-key.pem
```
Import it to your computer, then you can access cluster site use your computer
For MacOs : Keychain Access => login => drag the 'admin.p12' in to area

> For a service , if you can not connect you self with service name, you need to set  promisc on
```
ip link set docker0 promisc on
```
